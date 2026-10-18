# apps/users/tests.py

import re
from datetime import timedelta
from unittest.mock import MagicMock, patch

from django.core import mail, signing
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from apps.users.brevo_email import send_otp_email
from apps.users.models import EmailOTP, User


class EmailOTPTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.test_email = "tester@example.com"
        self.user = User.objects.create_user(
            email=self.test_email,
            name="Test User",
            role="customer",
            password="StrongPassword123!",
            is_email_verified=False,
        )
        # Mock send_brevo_email so automated tests do not make real network calls
        self.brevo_patcher = patch("apps.users.brevo_email.send_brevo_email", return_value="mock-brevo-msg-id")
        self.mock_brevo = self.brevo_patcher.start()

    def tearDown(self):
        self.brevo_patcher.stop()

    def test_generate_otp_is_six_digits_and_hashed(self):
        """OTP must be a 6-digit numeric string, and plain OTP must NOT be stored in DB."""
        otp_obj, plain_otp = EmailOTP.generate_otp(self.test_email, EmailOTP.PURPOSE_SIGNUP)
        self.assertEqual(len(plain_otp), 6)
        self.assertTrue(plain_otp.isdigit())

        # Verify plain OTP is NOT stored in the database
        otp_from_db = EmailOTP.objects.get(pk=otp_obj.pk)
        self.assertNotEqual(otp_from_db.otp_hash, plain_otp)
        self.assertNotIn(plain_otp, otp_from_db.otp_hash)

        # Hash check with salt
        expected_hash = EmailOTP.hash_otp(plain_otp, otp_from_db.salt)
        self.assertEqual(otp_from_db.otp_hash, expected_hash)

    def test_verify_otp_success_and_one_time_use(self):
        """Valid OTP verifies once, and cannot be reused."""
        otp_obj, plain_otp = EmailOTP.generate_otp(self.test_email, EmailOTP.PURPOSE_SIGNUP)

        # First verification succeeds
        success, msg = otp_obj.verify(plain_otp)
        self.assertTrue(success)
        self.assertTrue(otp_obj.is_used)

        # Second verification fails (one-time use)
        success2, msg2 = otp_obj.verify(plain_otp)
        self.assertFalse(success2)
        self.assertIn("already been used", msg2)

    def test_verify_otp_max_attempts_limit(self):
        """5 failed attempts invalidates the OTP permanently."""
        otp_obj, plain_otp = EmailOTP.generate_otp(self.test_email, EmailOTP.PURPOSE_SIGNUP)

        for attempt in range(4):
            success, msg = otp_obj.verify("000000")
            self.assertFalse(success)
            self.assertFalse(otp_obj.is_used)
            self.assertEqual(otp_obj.attempts, attempt + 1)

        # 5th failed attempt invalidates OTP
        success, msg = otp_obj.verify("000000")
        self.assertFalse(success)
        self.assertTrue(otp_obj.is_used)
        self.assertIn("Too many failed attempts", msg)

        # Even if the correct OTP is entered afterwards, it is rejected
        success, msg = otp_obj.verify(plain_otp)
        self.assertFalse(success)

    def test_verify_otp_expired(self):
        """Expired OTP (>5 minutes) is rejected and invalidated."""
        otp_obj, plain_otp = EmailOTP.generate_otp(self.test_email, EmailOTP.PURPOSE_SIGNUP)
        # Fast-forward expiry into the past
        otp_obj.expires_at = timezone.now() - timedelta(seconds=10)
        otp_obj.save()

        success, msg = otp_obj.verify(plain_otp)
        self.assertFalse(success)
        self.assertTrue(otp_obj.is_used)
        self.assertIn("expired", msg)

    def test_send_otp_cooldown_60s(self):
        """Requesting another OTP within 60 seconds returns HTTP 429."""
        EmailOTP.generate_otp(self.test_email, EmailOTP.PURPOSE_SIGNUP)

        resp = self.client.post("/api/users/send-otp/", {
            "email": self.test_email,
            "purpose": EmailOTP.PURPOSE_SIGNUP,
        })
        self.assertEqual(resp.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertIn("retry_after", resp.data)

    def test_send_otp_hourly_limit(self):
        """More than 5 OTP requests in 1 hour returns HTTP 429."""
        now = timezone.now()
        # Create 5 past OTPs within the last hour spaced apart
        for i in range(5):
            otp = EmailOTP.objects.create(
                email=self.test_email,
                otp_hash="dummy",
                salt="dummy",
                purpose=EmailOTP.PURPOSE_SIGNUP,
                expires_at=now + timedelta(minutes=5),
                is_used=True,
            )
            # auto_now_add requires update() to force past timestamp
            EmailOTP.objects.filter(pk=otp.pk).update(created_at=now - timedelta(minutes=50 - (i * 5)))

        resp = self.client.post("/api/users/send-otp/", {
            "email": self.test_email,
            "purpose": EmailOTP.PURPOSE_SIGNUP,
        })
        self.assertEqual(resp.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertIn("Too many requests", resp.data["error"])

    def test_signup_flow_blocks_unverified_login_until_otp_verified(self):
        """Unverified user cannot log in until OTP is verified. Once verified, JWT is granted."""
        # Unverified user login attempt
        login_resp = self.client.post("/api/users/login/", {
            "email": self.test_email,
            "password": "StrongPassword123!",
        })
        self.assertEqual(login_resp.status_code, status.HTTP_403_FORBIDDEN)
        self.assertTrue(login_resp.data.get("requires_verification"))

        # Generate signup OTP
        otp_obj, plain_otp = EmailOTP.generate_otp(self.test_email, EmailOTP.PURPOSE_SIGNUP)

        # Verify OTP
        verify_resp = self.client.post("/api/users/verify-otp/", {
            "email": self.test_email,
            "otp": plain_otp,
            "purpose": EmailOTP.PURPOSE_SIGNUP,
        })
        self.assertEqual(verify_resp.status_code, status.HTTP_200_OK)
        self.assertIn("access", verify_resp.data)
        self.assertIn("refresh", verify_resp.data)

        # User is now verified in DB
        self.user.refresh_from_db()
        self.assertTrue(self.user.is_email_verified)

        # Subsequent login now succeeds
        login_resp2 = self.client.post("/api/users/login/", {
            "email": self.test_email,
            "password": "StrongPassword123!",
        })
        self.assertEqual(login_resp2.status_code, status.HTTP_200_OK)
        self.assertIn("access", login_resp2.data)

    def test_forgot_password_and_reset_with_otp(self):
        """Forgot password flow sends OTP, verifies OTP, and resets password using signed token."""
        # 1. Request reset
        forgot_resp = self.client.post("/api/users/forgot-password/", {
            "email": self.test_email,
        })
        self.assertEqual(forgot_resp.status_code, status.HTTP_200_OK)

        otp_obj = EmailOTP.objects.filter(
            email=self.test_email,
            purpose=EmailOTP.PURPOSE_FORGOT_PASSWORD,
            is_used=False,
        ).first()
        self.assertIsNotNone(otp_obj)

        # Re-generate plain OTP to verify
        plain_otp = "847291"
        salt = otp_obj.salt
        otp_obj.otp_hash = EmailOTP.hash_otp(plain_otp, salt)
        otp_obj.save()

        # 2. Verify OTP
        verify_resp = self.client.post("/api/users/verify-otp/", {
            "email": self.test_email,
            "otp": plain_otp,
            "purpose": EmailOTP.PURPOSE_FORGOT_PASSWORD,
        })
        self.assertEqual(verify_resp.status_code, status.HTTP_200_OK)
        reset_token = verify_resp.data.get("reset_token")
        self.assertIsNotNone(reset_token)

        # 3. Reset password with signed token
        new_pass = "BrandNewPassword2026!"
        reset_resp = self.client.post("/api/users/reset-password-otp/", {
            "email": self.test_email,
            "reset_token": reset_token,
            "password": new_pass,
        })
        self.assertEqual(reset_resp.status_code, status.HTTP_200_OK)

        # 4. Login with old password fails, new password succeeds
        fail_login = self.client.post("/api/users/login/", {
            "email": self.test_email,
            "password": "StrongPassword123!",
        })
        self.assertEqual(fail_login.status_code, status.HTTP_401_UNAUTHORIZED)

        ok_login = self.client.post("/api/users/login/", {
            "email": self.test_email,
            "password": new_pass,
        })
        self.assertEqual(ok_login.status_code, status.HTTP_200_OK)

    def test_email_template_rendering_html_and_text(self):
        """Test that send_otp_email renders both responsive ProFinder HTML and text alternative."""
        with override_settings(BREVO_API_KEY="test-brevo-key"):
            msg_id = send_otp_email(
                to_email="customer@example.com",
                to_name="Jane Doe",
                otp_code="948210",
                purpose="signup",
            )
            self.assertEqual(msg_id, "mock-brevo-msg-id")
            self.mock_brevo.assert_called()
            call_kwargs = self.mock_brevo.call_args.kwargs
            html_body = call_kwargs["html_body"]
            text_body = call_kwargs["text_body"]

            # Ensure ProFinder branding and code in HTML
            self.assertIn("ProFinder", html_body)
            self.assertIn("948210", html_body)
            self.assertIn("5 minutes", html_body)

            # Ensure plain text alternative is complete
            self.assertIn("948210", text_body)
            self.assertIn("ProFinder", text_body)
            self.assertIn("5 minutes", text_body)

    @patch("google.oauth2.id_token.verify_oauth2_token")
    def test_google_login_success_and_profile_sync(self, mock_verify):
        """Test Google login verifies token, creates user, marks email verified, and syncs profiles."""
        mock_verify.return_value = {
            "iss": "https://accounts.google.com",
            "aud": "405649887034-vtb975grk99t5qrn4747bk36gifq3g6a.apps.googleusercontent.com",
            "email": "googleuser@example.com",
            "email_verified": True,
            "name": "Google User",
            "picture": "https://lh3.googleusercontent.com/test-pic",
        }

        resp = self.client.post("/api/users/google/", {
            "id_token": "valid-mock-google-id-token",
            "role": "professional",
        })
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn("access", resp.data)
        self.assertIn("refresh", resp.data)
        self.assertEqual(resp.data["role"], "professional")

        # Verify database state
        user = User.objects.get(email="googleuser@example.com")
        self.assertTrue(user.is_email_verified)
        self.assertEqual(user.role, "professional")
        self.assertEqual(user.name, "Google User")

        # Verify profiles created
        from apps.profiles.models import UserProfile, ProfessionalProfile
        up = UserProfile.objects.get(user=user)
        self.assertTrue(bool(up.photo_url))
        self.assertTrue(ProfessionalProfile.objects.filter(user=user).exists())

    def test_google_web_auth_view(self):
        """Test desktop Google web auth HTML bridge returns 200 and renders client_id."""
        resp = self.client.get("/api/users/google/web-auth/?port=8085&role=customer")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn(b"Desktop Authentication", resp.content)
        self.assertIn(b"405649887034", resp.content)

    def test_delete_account_with_password_success(self):
        """User can permanently delete their account using their account password."""
        self.client.force_authenticate(user=self.user)
        resp = self.client.post("/api/users/delete-account/confirm/", {
            "password": "StrongPassword123!",
        })
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertTrue(resp.data["success"])
        self.assertFalse(User.objects.filter(email=self.test_email).exists())

    def test_delete_account_with_wrong_password_fails(self):
        """Wrong password fails account deletion."""
        self.client.force_authenticate(user=self.user)
        resp = self.client.post("/api/users/delete-account/confirm/", {
            "password": "WrongPassword999!",
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(resp.data["success"])
        self.assertTrue(User.objects.filter(email=self.test_email).exists())

    def test_delete_account_with_otp_success(self):
        """User can request a 6-digit OTP and confirm permanent account deletion."""
        self.client.force_authenticate(user=self.user)
        req_resp = self.client.post("/api/users/delete-account/request-otp/")
        self.assertEqual(req_resp.status_code, status.HTTP_200_OK)
        self.assertTrue(req_resp.data["success"])

        # Fetch plain OTP from brevo mock call
        self.assertTrue(self.mock_brevo.called)
        otp_record = EmailOTP.objects.filter(
            email=self.test_email,
            purpose=EmailOTP.PURPOSE_DELETE_ACCOUNT,
            is_used=False,
        ).first()
        self.assertIsNotNone(otp_record)

        # Mock the verification call using generate_otp plain return
        otp_obj, plain_otp = EmailOTP.generate_otp(self.test_email, EmailOTP.PURPOSE_DELETE_ACCOUNT)
        confirm_resp = self.client.post("/api/users/delete-account/confirm/", {
            "otp": plain_otp,
        })
        self.assertEqual(confirm_resp.status_code, status.HTTP_200_OK)
        self.assertTrue(confirm_resp.data["success"])
        self.assertFalse(User.objects.filter(email=self.test_email).exists())


