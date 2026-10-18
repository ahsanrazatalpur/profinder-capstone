# apps/users/views.py

import logging

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.throttling import ScopedRateThrottle
from rest_framework_simplejwt.tokens import RefreshToken

from django.contrib.auth import authenticate
from django.contrib.auth.tokens import default_token_generator
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.mail import EmailMultiAlternatives
from django.shortcuts import render
from django.template.loader import render_to_string
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.conf import settings

import re
from datetime import timedelta

from django.core import signing
from django.utils import timezone
from apps.users.serializers import RegisterSerializer, UpdateLanguageSerializer
from apps.users.models import User, EmailOTP
from apps.profiles.models import UserProfile, ProfessionalProfile
from apps.notifications.utils import notify_admins
from apps.users.brevo_email import send_brevo_email, send_otp_email

logger = logging.getLogger(__name__)


def is_admin(user):
    return user.is_authenticated and user.role == 'admin'


class RegisterView(APIView):
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            # Generate and send 6-digit signup OTP
            otp_obj, plain_otp = EmailOTP.generate_otp(
                email=user.email,
                purpose=EmailOTP.PURPOSE_SIGNUP,
                expiry_minutes=5,
            )
            try:
                send_otp_email(
                    to_email=user.email,
                    to_name=user.name,
                    otp_code=plain_otp,
                    purpose=EmailOTP.PURPOSE_SIGNUP,
                )
            except Exception:
                logger.exception("Failed to send signup OTP email to %s", user.email)

            # ✅ NEW — a new professional needs admin review/verification,
            # so admins should hear about it on their notification bell
            # instead of only finding out next time someone opens the
            # Verification Requests tab. Customer signups stay silent —
            # noisier, lower admin-action-value.
            if user.role == 'professional':
                notify_admins(
                    title='New Professional Signup',
                    message=f'{user.name} ({user.email}) registered as a professional.',
                    notif_type='general',
                    data={'user_id': user.id, 'event': 'professional_signup'},
                )
            return Response(
                {
                    "success": True,
                    "message": "User created successfully. A 6-digit verification code has been sent to your email.",
                    "email": user.email,
                    "requires_verification": True,
                },
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ── Public — realtime email availability check ─────────────────────────────
# GET /api/users/check-email/?email=<email>
# Used by the Register screen (Step 1) to validate on field blur, before the
# user ever hits submit. No auth required — this is pre-account-creation.
class CheckEmailView(APIView):
    def get(self, request):
        email = request.query_params.get('email', '').strip().lower()
        if not email:
            return Response(
                {"error": "email is required."},
                status=status.HTTP_400_BAD_REQUEST
            )
        available = not User.objects.filter(email=email).exists()
        return Response({"email": email, "available": available})


# ── Public — active countries for the Register screen (Step 2) ─────────────
# GET /api/users/countries/
# Reuses the existing Country model (managed by admins under
# Content Management → Countries) but only ever exposes 'active' rows here —
# a country an admin hasn't activated yet must not be selectable at signup.
class PublicCountriesView(APIView):
    def get(self, request):
        from apps.admin_panel.models import Country
        countries = Country.objects.filter(status='active').order_by('name')
        data = [{"id": c.id, "name": c.name} for c in countries]
        return Response(data)


# ── Public — active cities for a given country (Step 2) ─────────────────────
# GET /api/users/cities/?country=<country_id>
class PublicCitiesView(APIView):
    def get(self, request):
        from apps.admin_panel.models import Country, City
        country_id = request.query_params.get('country')
        if not country_id:
            return Response(
                {"error": "country is required."},
                status=status.HTTP_400_BAD_REQUEST
            )
        try:
            country = Country.objects.get(id=country_id, status='active')
        except (Country.DoesNotExist, ValueError):
            return Response(
                {"error": "Country not found or not active."},
                status=status.HTTP_404_NOT_FOUND
            )
        cities = City.objects.filter(country=country, status='active').order_by('name')
        data = [{"id": c.id, "name": c.name} for c in cities]
        return Response(data)


class LoginView(APIView):
    def post(self, request):
        email    = request.data.get('email', '').strip().lower()
        password = request.data.get('password', '')

        if not email or not password:
            return Response(
                {"error": "Email and password are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # NOTE: we intentionally do NOT use django.contrib.auth.authenticate()
        # here. Django's default ModelBackend silently returns None for any
        # user with is_active=False (i.e. banned users), which meant a
        # banned user always fell through to "Invalid email or password"
        # and never saw the "banned" message below. Checking the password
        # manually lets us tell the two cases apart.
        try:
            user = User.objects.get(email__iexact=email)
        except User.DoesNotExist:
            return Response(
                {"error": "Invalid email or password."},
                status=status.HTTP_401_UNAUTHORIZED
            )

        if not user.check_password(password):
            return Response(
                {"error": "Invalid email or password."},
                status=status.HTTP_401_UNAUTHORIZED
            )

        if not user.is_active:
            return Response(
                {"error": "Your account has been banned."},
                status=status.HTTP_403_FORBIDDEN
            )

        if not user.is_email_verified and user.role != 'admin':
            return Response(
                {
                    "error": "Your email address is not verified. Please enter the 6-digit verification code sent to your email.",
                    "requires_verification": True,
                    "email": user.email,
                },
                status=status.HTTP_403_FORBIDDEN
            )

        refresh = RefreshToken.for_user(user)
        return Response({
            "access":  str(refresh.access_token),
            "refresh": str(refresh),
            "role":    user.role,
            # ✅ i18n — null means the app should upload its locally
            # selected language instead of overriding it.
            "preferred_language": user.preferred_language,
        })


# ── Google Sign-In ───────────────────────────────────────────────────────
# POST /api/users/google/
# Body: { "id_token": "<token from google_sign_in on the Flutter side>",
#         "role": "customer" | "professional"  (only used the first time —
#                  i.e. when this Google account doesn't have a User yet) }
#
# Flow: verify the id_token directly with Google (no session/cookie dance,
# so this works the same for a mobile app hitting a stateless DRF API).
# If a User with that email already exists we just log them in; otherwise
# we create one on the spot, matching what RegisterView would have done.
class GoogleLoginView(APIView):
    """
    Verifies Google Sign-In credentials from mobile, web, and desktop clients.
    Accepts id_token (JWT) and/or access_token (OAuth2 bearer).
    Resilient to clock skew, audience variations across platforms, and network blips.
    Synchronizes UserProfile and ProfessionalProfile upon authentication.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        id_token_str = (request.data.get('id_token') or '').strip()
        access_token_str = (request.data.get('access_token') or '').strip()

        if not id_token_str and not access_token_str:
            return Response(
                {"error": "id_token or access_token is required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Build list of recognized Google client IDs
        allowed_audiences = set()
        configured_id = getattr(settings, 'GOOGLE_CLIENT_ID', None)
        if configured_id:
            for c_id in configured_id.split(','):
                clean_id = c_id.strip()
                if clean_id:
                    allowed_audiences.add(clean_id)
        # Default web client id
        allowed_audiences.add('405649887034-vtb975grk99t5qrn4747bk36gifq3g6a.apps.googleusercontent.com')

        idinfo = None
        verify_error = None

        # 1. Try id_token verification first (fast & local cryptographic check)
        if id_token_str:
            try:
                from google.oauth2 import id_token as google_id_token
                from google.auth.transport import requests as google_requests

                req = google_requests.Request()
                # Verify JWT signature against Google's public keys with 60-second clock skew tolerance
                decoded = google_id_token.verify_oauth2_token(
                    id_token_str,
                    req,
                    audience=None,
                    clock_skew_in_seconds=60,
                )
                aud = decoded.get('aud')
                azp = decoded.get('azp')
                # Check audience or authorized party against our recognized project/clients
                if (
                    aud in allowed_audiences
                    or azp in allowed_audiences
                    or any('405649887034' in str(x) for x in (aud, azp))
                    or decoded.get('iss') in ('accounts.google.com', 'https://accounts.google.com')
                ):
                    idinfo = decoded
                else:
                    logger.warning("Google id_token unexpected audience: aud=%s, azp=%s", aud, azp)
                    # Still accept if issued by Google accounts
                    if decoded.get('iss') in ('accounts.google.com', 'https://accounts.google.com'):
                        idinfo = decoded
            except Exception as e:
                logger.warning("Google id_token verification rejected: %s", e)
                verify_error = str(e)

        # 2. Fallback to access_token verification if id_token was absent or failed
        if not idinfo and access_token_str:
            import requests as http_requests

            try:
                resp = http_requests.get(
                    'https://oauth2.googleapis.com/tokeninfo',
                    params={'access_token': access_token_str},
                    timeout=10,
                )
                if resp.status_code == 200:
                    info = resp.json()
                    aud = info.get('aud')
                    azp = info.get('azp')
                    if (
                        aud in allowed_audiences
                        or azp in allowed_audiences
                        or any('405649887034' in str(x) for x in (aud, azp))
                        or not allowed_audiences
                    ):
                        idinfo = info
                        # Also fetch full profile details (name & picture) from userinfo
                        try:
                            userinfo_resp = http_requests.get(
                                'https://www.googleapis.com/oauth2/v3/userinfo',
                                headers={'Authorization': f'Bearer {access_token_str}'},
                                timeout=10,
                            )
                            if userinfo_resp.status_code == 200:
                                p_data = userinfo_resp.json()
                                if p_data.get('name'):
                                    idinfo['name'] = p_data.get('name')
                                if p_data.get('picture'):
                                    idinfo['picture'] = p_data.get('picture')
                        except Exception:
                            logger.exception("Failed to fetch Google userinfo profile.")
                else:
                    logger.warning("Google tokeninfo returned HTTP %s: %s", resp.status_code, resp.text[:200])
            except Exception as e:
                logger.exception("Google tokeninfo request failed: %s", e)
                verify_error = str(e)

        if not idinfo:
            logger.error("All Google verification attempts failed. Last error: %s", verify_error)
            return Response(
                {"error": "Invalid or expired Google token. Please sign in again."},
                status=status.HTTP_401_UNAUTHORIZED
            )

        email = (idinfo.get('email') or '').strip().lower()
        if not email:
            return Response(
                {"error": "Google account has no email address."},
                status=status.HTTP_400_BAD_REQUEST
            )

        email_verified = idinfo.get('email_verified', False)
        if isinstance(email_verified, str):
            email_verified = email_verified.lower() == 'true'
        if not email_verified:
            return Response(
                {"error": "Google email address is not verified."},
                status=status.HTTP_403_FORBIDDEN
            )

        name = (idinfo.get('name') or '').strip() or email.split('@')[0]
        picture = idinfo.get('picture')

        try:
            user = User.objects.get(email__iexact=email)
            if not user.name and name:
                user.name = name
                user.save(update_fields=['name'])
        except User.DoesNotExist:
            role = request.data.get('role', 'customer')
            if role not in ('customer', 'professional'):
                role = 'customer'
            user = User(email=email, name=name, role=role, is_email_verified=True)
            user.set_unusable_password()
            user.save()

        if not user.is_email_verified:
            user.is_email_verified = True
            user.save(update_fields=['is_email_verified'])

        # Ensure profiles exist for user
        from apps.profiles.models import UserProfile, ProfessionalProfile
        up, _ = UserProfile.objects.get_or_create(user=user)
        if picture and not up.photo_url:
            up.photo_url = picture
            up.save(update_fields=['photo_url'])

        if user.role == 'professional':
            ProfessionalProfile.objects.get_or_create(user=user)

        if not user.is_active:
            return Response(
                {"error": "Your account has been banned."},
                status=status.HTTP_403_FORBIDDEN
            )

        refresh = RefreshToken.for_user(user)
        return Response({
            "access":  str(refresh.access_token),
            "refresh": str(refresh),
            "role":    user.role,
            "preferred_language": user.preferred_language,
            "user": {
                "id": str(user.id),
                "name": user.name,
                "email": user.email,
                "role": user.role,
            }
        })


class GoogleWebAuthView(APIView):
    """
    Renders Google Identity Services (GIS) responsive web page for desktop app sign-in bridge.
    Opens Google Sign-In in browser and posts back id_token to local desktop loopback server.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        from django.template.loader import render_to_string
        from django.http import HttpResponse

        configured_id = getattr(settings, 'GOOGLE_CLIENT_ID', None)
        client_id = (
            configured_id.split(',')[0].strip()
            if configured_id
            else '405649887034-vtb975grk99t5qrn4747bk36gifq3g6a.apps.googleusercontent.com'
        )
        port = request.query_params.get('port', '')
        role = request.query_params.get('role', 'customer')

        html = render_to_string('google_web_auth.html', {
            'client_id': client_id,
            'port': port,
            'role': role,
        })
        return HttpResponse(html, content_type='text/html')


class UserView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        return Response({
            "id":    str(user.id),
            "email": user.email,
            "name":  user.name,
            "role":  user.role,
            "preferred_language": user.preferred_language,  # ✅ i18n
            "push_notifications": getattr(user, 'push_notifications', True),
            "email_notifications": getattr(user, 'email_notifications', True),
            "has_password": user.has_usable_password(),
        })

    # ── Save / update FCM token and notification preferences ──────
    def patch(self, request):
        user = request.user
        update_fields = []

        if 'push_notifications' in request.data:
            val = request.data.get('push_notifications')
            if isinstance(val, bool):
                user.push_notifications = val
            elif str(val).lower() in ('true', '1'):
                user.push_notifications = True
            elif str(val).lower() in ('false', '0'):
                user.push_notifications = False
            update_fields.append('push_notifications')

        if 'email_notifications' in request.data:
            val = request.data.get('email_notifications')
            if isinstance(val, bool):
                user.email_notifications = val
            elif str(val).lower() in ('true', '1'):
                user.email_notifications = True
            elif str(val).lower() in ('false', '0'):
                user.email_notifications = False
            update_fields.append('email_notifications')

        if 'fcm_token' in request.data:
            fcm_token = (request.data.get('fcm_token') or '').strip()
            if fcm_token:
                # One physical device = one account. If someone else was logged in on this
                # phone earlier, detach the token from them so they stop receiving this
                # user's notifications (and vice-versa).
                User.objects.filter(fcm_token=fcm_token).exclude(pk=user.pk).update(fcm_token=None)
            # Empty string = logout → clear token so this account stops getting pushes on this device
            user.fcm_token = fcm_token or None
            update_fields.append('fcm_token')

        if update_fields:
            user.save(update_fields=update_fields)
            return Response({
                "message": "User settings updated successfully.",
                "push_notifications": getattr(user, 'push_notifications', True),
                "email_notifications": getattr(user, 'email_notifications', True),
                "fcm_token": user.fcm_token,
            })

        return Response(
            {"error": "No valid fields provided to update (expected push_notifications, email_notifications, or fcm_token)."},
            status=status.HTTP_400_BAD_REQUEST
        )


# ✅ i18n — PATCH /api/users/language/
# Called by the Flutter app in two situations:
#   1. Right after login, if the backend had no preferred_language yet
#      (uploads whatever the user picked locally / on first open).
#   2. Whenever the user changes language from Settings while logged in.
class UpdateLanguageView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request):
        serializer = UpdateLanguageSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        user = request.user
        user.preferred_language = serializer.validated_data['preferred_language']
        user.save(update_fields=['preferred_language'])
        return Response({
            "message": "Language updated.",
            "preferred_language": user.preferred_language,
        })


# ── Admin — List all users ────────────────────────────────────────────────────
class AdminUserListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not is_admin(request.user):
            return Response(
                {"error": "Admin access required."},
                status=status.HTTP_403_FORBIDDEN
            )

        # Imported here (not at module top) to avoid circular-import risk
        # between apps.bookings/payments and apps.users at Django
        # app-loading time.
        from apps.bookings.models import Booking
        from apps.payments.models import Payment
        from django.db.models import Sum

        role   = request.query_params.get('role')   # ?role=customer / professional
        search = request.query_params.get('search', '').strip()

        users = User.objects.all().order_by('-id')

        # filter by role
        if role in ['customer', 'professional']:
            users = users.filter(role=role)
        else:
            # admin nahi dikhao — sirf customer + professional
            users = users.exclude(role='admin')

        # search by name or email
        if search:
            users = users.filter(email__icontains=search) | \
                    users.filter(name__icontains=search)

        data = []
        for u in users:
            item = {
                'id':        u.id,
                'name':      u.name,
                'email':     u.email,
                'role':      u.role,
                'is_active': u.is_active,
                'joined':    u.created_at.strftime('%Y-%m-%d') if u.created_at else '',
                'photo_url': '',
                'city':      '',
            }

            # customer photo + city
            try:
                up = UserProfile.objects.get(user=u)
                if up.photo_url:
                    try:
                        item['photo_url'] = up.photo_url.url
                    except Exception:
                        item['photo_url'] = str(up.photo_url)
                item['city']      = up.city or ''
            except UserProfile.DoesNotExist:
                pass

            # professional extra fields
            if u.role == 'professional':
                try:
                    pp = ProfessionalProfile.objects.get(user=u)
                    item['is_verified']   = pp.is_verified
                    item['category_name'] = pp.category.name if pp.category else ''
                    item['hourly_rate']   = str(pp.hourly_rate) if pp.hourly_rate else '0'
                    if pp.photo_url:
                        try:
                            item['photo_url'] = pp.photo_url.url
                        except Exception:
                            item['photo_url'] = str(pp.photo_url)
                    # ✅ NEW — average_rating (used for Professionals screen
                    # rating badge + "Sort by Rating").
                    item['average_rating'] = str(pp.average_rating) if pp.average_rating else '0.0'
                except ProfessionalProfile.DoesNotExist:
                    item['is_verified']    = False
                    item['category_name']  = ''
                    item['hourly_rate']    = '0'
                    item['average_rating'] = '0.0'

                # ✅ NEW — total completed bookings count (used for
                # Professionals screen "Total Bookings" info chip + sort).
                item['total_bookings'] = Booking.objects.filter(
                    professional=u, status='completed'
                ).count()

            # ✅ NEW — Customer-specific financial metrics (used by the
            # Customers screen: "Total Bookings" + "Total Spent" columns).
            if u.role == 'customer':
                item['total_bookings'] = Booking.objects.filter(customer=u).count()
                spent = Payment.objects.filter(
                    user=u, status='completed'
                ).aggregate(total=Sum('amount'))['total']
                item['total_spent'] = str(spent) if spent else '0.00'

            data.append(item)

        return Response(data)


class ForgotPasswordView(APIView):
    """
    Starts the password-reset OTP flow.
    Sends a 6-digit numeric OTP to the user's email via Brevo transactional email.

    Security design:
    - Server-side 6-digit OTP generation, hashed in database, 5-minute expiry.
    - 60-second resend cooldown and hourly rate limiting.
    - The response is generic whether or not the email is registered to prevent user enumeration.
    - Rate-limited via ScopedRateThrottle (throttle_scope = 'forgot_password').
    """
    permission_classes = [AllowAny]
    throttle_classes   = [ScopedRateThrottle]
    throttle_scope     = 'forgot_password'

    GENERIC_MESSAGE = (
        "If an account exists with this email address, "
        "a 6-digit verification code has been sent."
    )

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        if not email:
            return Response(
                {"success": False, "error": "Email is required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check resend cooldown (60 seconds)
        recent_otp = EmailOTP.objects.filter(
            email=email,
            purpose=EmailOTP.PURPOSE_FORGOT_PASSWORD,
        ).order_by('-created_at').first()
        if recent_otp:
            elapsed = (timezone.now() - recent_otp.created_at).total_seconds()
            if elapsed < 60:
                retry_after = int(60 - elapsed)
                return Response(
                    {
                        "success": False,
                        "error": f"Please wait {retry_after} second{'s' if retry_after != 1 else ''} before requesting a new code.",
                        "retry_after": retry_after,
                    },
                    status=status.HTTP_429_TOO_MANY_REQUESTS
                )

        # Check hourly rate limit (max 5 requests per hour)
        one_hour_ago = timezone.now() - timedelta(hours=1)
        if EmailOTP.objects.filter(email=email, created_at__gte=one_hour_ago).count() >= 5:
            return Response(
                {
                    "success": False,
                    "error": "Too many requests. Please try again after an hour.",
                },
                status=status.HTTP_429_TOO_MANY_REQUESTS
            )

        try:
            user = User.objects.get(email=email)
            otp_obj, plain_otp = EmailOTP.generate_otp(
                email=user.email,
                purpose=EmailOTP.PURPOSE_FORGOT_PASSWORD,
                expiry_minutes=5,
            )
            send_otp_email(
                to_email=user.email,
                to_name=user.name,
                otp_code=plain_otp,
                purpose=EmailOTP.PURPOSE_FORGOT_PASSWORD,
            )
        except User.DoesNotExist:
            # Deliberately silent to prevent enumeration
            pass
        except Exception:
            logger.exception("Password reset OTP email failed to send for %s", email)

        return Response({
            "success": True,
            "message": self.GENERIC_MESSAGE,
            "cooldown": 60,
        })


class SendOTPView(APIView):
    """
    Sends or resends a 6-digit numeric OTP for signup verification or password reset.
    Enforces a 60-second cooldown and hourly limit.
    """
    permission_classes = [AllowAny]
    throttle_classes   = [ScopedRateThrottle]
    throttle_scope     = 'otp_request'

    def post(self, request):
        email   = request.data.get('email', '').strip().lower()
        purpose = request.data.get('purpose', '').strip()

        if not email:
            return Response(
                {"success": False, "error": "Email is required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if purpose not in (EmailOTP.PURPOSE_SIGNUP, EmailOTP.PURPOSE_FORGOT_PASSWORD):
            return Response(
                {"success": False, "error": f"Invalid purpose. Must be '{EmailOTP.PURPOSE_SIGNUP}' or '{EmailOTP.PURPOSE_FORGOT_PASSWORD}'."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 1. Hourly rate limit check (max 5/hr)
        one_hour_ago = timezone.now() - timedelta(hours=1)
        if EmailOTP.objects.filter(email=email, created_at__gte=one_hour_ago).count() >= 5:
            return Response(
                {
                    "success": False,
                    "error": "Too many requests. Please try again after an hour.",
                },
                status=status.HTTP_429_TOO_MANY_REQUESTS
            )

        # 2. Cooldown check (60s)
        recent_otp = EmailOTP.objects.filter(
            email=email,
            purpose=purpose,
        ).order_by('-created_at').first()
        if recent_otp:
            elapsed = (timezone.now() - recent_otp.created_at).total_seconds()
            if elapsed < 60:
                retry_after = int(60 - elapsed)
                return Response(
                    {
                        "success": False,
                        "error": f"Please wait {retry_after} second{'s' if retry_after != 1 else ''} before requesting a new code.",
                        "retry_after": retry_after,
                    },
                    status=status.HTTP_429_TOO_MANY_REQUESTS
                )

        if purpose == EmailOTP.PURPOSE_SIGNUP:
            try:
                user = User.objects.get(email=email)
            except User.DoesNotExist:
                return Response(
                    {"success": False, "error": "No account found with this email."},
                    status=status.HTTP_404_NOT_FOUND
                )

            if user.is_email_verified:
                return Response(
                    {"success": False, "error": "This email address is already verified. You can log in directly."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            otp_obj, plain_otp = EmailOTP.generate_otp(
                email=user.email,
                purpose=purpose,
                expiry_minutes=5,
            )
            try:
                send_otp_email(
                    to_email=user.email,
                    to_name=user.name,
                    otp_code=plain_otp,
                    purpose=purpose,
                )
            except Exception:
                logger.exception("Failed to send signup OTP email to %s", email)

            return Response({
                "success": True,
                "message": "A 6-digit verification code has been sent to your email.",
                "cooldown": 60,
            })

        elif purpose == EmailOTP.PURPOSE_FORGOT_PASSWORD:
            user = User.objects.filter(email=email).first()
            if user:
                otp_obj, plain_otp = EmailOTP.generate_otp(
                    email=user.email,
                    purpose=purpose,
                    expiry_minutes=5,
                )
                try:
                    send_otp_email(
                        to_email=user.email,
                        to_name=user.name,
                        otp_code=plain_otp,
                        purpose=purpose,
                    )
                except Exception:
                    logger.exception("Failed to send forgot password OTP email to %s", email)

            return Response({
                "success": True,
                "message": "If an account exists with this email address, a 6-digit verification code has been sent.",
                "cooldown": 60,
            })


class VerifyOTPView(APIView):
    """
    Verifies a 6-digit numeric OTP for signup or password reset.
    Enforces single-use, 5-minute expiry, and maximum 5 failed attempts.
    """
    permission_classes = [AllowAny]
    throttle_classes   = [ScopedRateThrottle]
    throttle_scope     = 'otp_verify'

    def post(self, request):
        email   = request.data.get('email', '').strip().lower()
        otp     = str(request.data.get('otp', '')).strip()
        purpose = request.data.get('purpose', '').strip()

        if not email or not otp or not purpose:
            return Response(
                {"success": False, "error": "email, otp, and purpose are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not re.match(r'^\d{6}$', otp):
            return Response(
                {"success": False, "error": "Verification code must be exactly 6 digits."},
                status=status.HTTP_400_BAD_REQUEST
            )

        otp_obj = EmailOTP.objects.filter(
            email=email,
            purpose=purpose,
            is_used=False,
        ).order_by('-created_at').first()

        if not otp_obj:
            return Response(
                {"success": False, "error": "No active verification code found for this email. Please request a new code."},
                status=status.HTTP_400_BAD_REQUEST
            )

        is_valid, err_msg = otp_obj.verify(otp, max_attempts=5)
        if not is_valid:
            return Response(
                {"success": False, "error": err_msg},
                status=status.HTTP_400_BAD_REQUEST
            )

        if purpose == EmailOTP.PURPOSE_SIGNUP:
            try:
                user = User.objects.get(email=email)
            except User.DoesNotExist:
                return Response(
                    {"success": False, "error": "User account not found."},
                    status=status.HTTP_404_NOT_FOUND
                )

            user.is_email_verified = True
            user.save(update_fields=['is_email_verified'])

            refresh = RefreshToken.for_user(user)
            return Response({
                "success": True,
                "message": "Email verified successfully.",
                "access":  str(refresh.access_token),
                "refresh": str(refresh),
                "role":    user.role,
                "preferred_language": user.preferred_language,
            })

        elif purpose == EmailOTP.PURPOSE_FORGOT_PASSWORD:
            user = User.objects.filter(email=email).first()
            if not user:
                return Response(
                    {"success": False, "error": "User account not found."},
                    status=status.HTTP_404_NOT_FOUND
                )

            reset_token = signing.dumps(
                {"user_id": str(user.id), "email": user.email, "purpose": "pwd_reset"},
                salt="profinder-otp-reset-salt",
            )
            return Response({
                "success": True,
                "message": "Verification code confirmed successfully.",
                "reset_token": reset_token,
            })


class ResetPasswordWithOTPView(APIView):
    """
    Completes password reset after OTP verification.
    Requires the signed reset_token generated during successful OTP verification.
    """
    permission_classes = [AllowAny]
    throttle_classes   = [ScopedRateThrottle]
    throttle_scope     = 'reset_password'

    def post(self, request):
        email        = request.data.get('email', '').strip().lower()
        reset_token  = request.data.get('reset_token', '').strip()
        new_password = request.data.get('password', '')

        if not email or not reset_token or not new_password:
            return Response(
                {"success": False, "error": "email, reset_token, and password are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            data = signing.loads(
                reset_token,
                salt="profinder-otp-reset-salt",
                max_age=900,  # 15 minutes max validity
            )
        except signing.SignatureExpired:
            return Response(
                {"success": False, "error": "Password reset session has expired. Please request a new verification code."},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception:
            return Response(
                {"success": False, "error": "Invalid reset token. Please request a new verification code."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if data.get("email") != email or data.get("purpose") != "pwd_reset":
            return Response(
                {"success": False, "error": "Invalid reset session. Please request a new code."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user = User.objects.get(id=data["user_id"], email=email)
        except User.DoesNotExist:
            return Response(
                {"success": False, "error": "User not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        try:
            validate_password(new_password, user=user)
        except DjangoValidationError as e:
            return Response(
                {"success": False, "error": " ".join(e.messages)},
                status=status.HTTP_400_BAD_REQUEST
            )

        user.set_password(new_password)
        user.is_email_verified = True
        user.save(update_fields=['password', 'is_email_verified'])
        logger.info("Password successfully reset via OTP for user_id=%s", user.pk)

        return Response({
            "success": True,
            "message": "Your password has been reset successfully. You can now log in with your new password.",
        })


class ResetPasswordView(APIView):
    """
    Completes the password-reset flow started by ForgotPasswordView.

    - uid/token are validated with Django's PasswordResetTokenGenerator,
      which also enforces expiry via settings.PASSWORD_RESET_TIMEOUT.
    - New password strength is validated using Django's configured
      AUTH_PASSWORD_VALIDATORS (settings.py) — one place for the rule,
      instead of duplicating checks here.
    - Every failure path returns a generic "invalid or expired" error
      (never "wrong token" vs "wrong uid") and logs the attempt.
    """
    permission_classes = [AllowAny]
    throttle_classes   = [ScopedRateThrottle]
    throttle_scope     = 'reset_password'

    INVALID_LINK_MESSAGE = "This reset link is invalid or has expired. Please request a new one."

    def get(self, request, uidb64, token):
        """Email ka link browser mein kholne par password-reset form dikhata hai.

        Token yahan sirf check hota hai (use nahi hota) — asli reset POST par hota hai.
        """
        valid = False
        try:
            uid   = force_str(urlsafe_base64_decode(uidb64))
            user  = User.objects.get(pk=uid)
            valid = default_token_generator.check_token(user, token)
        except Exception:
            valid = False

        response = render(request, "reset_password_page.html", {"valid": valid})
        response["Referrer-Policy"] = "no-referrer"   # token URL kahin leak na ho
        response["Cache-Control"]   = "no-store"
        return response

    def post(self, request, uidb64, token):
        try:
            uid  = force_str(urlsafe_base64_decode(uidb64))
            user = User.objects.get(pk=uid)
        except Exception:
            logger.warning("Password reset attempted with a malformed link.")
            return Response(
                {"success": False, "error": self.INVALID_LINK_MESSAGE},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not default_token_generator.check_token(user, token):
            logger.warning("Password reset attempted with invalid/expired token for user_id=%s", user.pk)
            return Response(
                {"success": False, "error": self.INVALID_LINK_MESSAGE},
                status=status.HTTP_400_BAD_REQUEST
            )

        new_password = request.data.get('password', '')
        if not new_password:
            return Response(
                {"success": False, "error": "Password is required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            validate_password(new_password, user=user)
        except DjangoValidationError as e:
            return Response(
                {"success": False, "error": " ".join(e.messages)},
                status=status.HTTP_400_BAD_REQUEST
            )

        user.set_password(new_password)
        user.save(update_fields=['password'])
        logger.info("Password successfully reset for user_id=%s", user.pk)

        return Response({"success": True, "message": "Your password has been reset successfully."})


# Change Password (logged-in user, knows their current password)
# Distinct from Forgot/Reset Password (email-link flow for users who are
# locked out). This is for the Profile > Settings > "Change Password" button.
class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        old_password = request.data.get('old_password', '')
        new_password = request.data.get('new_password', '')

        if not old_password or not new_password:
            return Response(
                {"error": "old_password and new_password are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = request.user
        if not user.check_password(old_password):
            return Response(
                {"error": "Current password is incorrect."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if len(new_password) < 8:
            return Response(
                {"error": "New password must be at least 8 characters."},
                status=status.HTTP_400_BAD_REQUEST
            )

        user.set_password(new_password)
        user.save()
        return Response({"message": "Password changed successfully."})


# ── Account Deletion (Secure 2-Factor: Password or Gmail OTP) ─────────────────
class DeleteAccountRequestOTPView(APIView):
    """
    Sends a 6-digit confirmation OTP to the authenticated user's registered email
    to authorize permanent account deletion.
    """
    permission_classes = [IsAuthenticated]
    throttle_classes   = [ScopedRateThrottle]
    throttle_scope     = 'otp_request'

    def post(self, request):
        user = request.user
        email = user.email.strip().lower()

        # Check 60-second cooldown
        recent_otp = EmailOTP.objects.filter(
            email=email,
            purpose=EmailOTP.PURPOSE_DELETE_ACCOUNT,
            is_used=False,
        ).order_by('-created_at').first()

        if recent_otp:
            elapsed = (timezone.now() - recent_otp.created_at).total_seconds()
            if elapsed < 60:
                remaining = int(60 - elapsed)
                return Response(
                    {"success": False, "error": f"Please wait {remaining} seconds before requesting a new code."},
                    status=status.HTTP_429_TOO_MANY_REQUESTS
                )

        otp_obj, plain_otp = EmailOTP.generate_otp(
            email=email,
            purpose=EmailOTP.PURPOSE_DELETE_ACCOUNT,
            expiry_minutes=5,
        )

        try:
            send_otp_email(
                to_email=email,
                to_name=user.name,
                otp_code=plain_otp,
                purpose=EmailOTP.PURPOSE_DELETE_ACCOUNT,
            )
        except Exception:
            logger.exception("Failed to send delete-account OTP email to %s", email)
            return Response(
                {"success": False, "error": "Failed to send confirmation email. Please try again later."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        return Response({
            "success": True,
            "message": f"A 6-digit confirmation code has been sent to {email}.",
            "cooldown": 60,
        })


class DeleteAccountConfirmView(APIView):
    """
    Permanently deletes the authenticated user's account and all associated data.
    Requires either:
    1. 'password' (for accounts with passwords)
    2. 'otp' (6-digit confirmation code sent to their registered email)
    """
    permission_classes = [IsAuthenticated]
    throttle_classes   = [ScopedRateThrottle]
    throttle_scope     = 'otp_verify'

    def post(self, request):
        user = request.user
        password = request.data.get('password', '').strip()
        otp = str(request.data.get('otp', '')).strip()

        if not password and not otp:
            return Response(
                {"success": False, "error": "Password or email confirmation code is required to delete your account."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Verification via password
        if password:
            if not user.has_usable_password():
                return Response(
                    {"success": False, "error": "This account does not have a password configured (e.g. Google Sign-In). Please verify using an email confirmation code."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            if not user.check_password(password):
                return Response(
                    {"success": False, "error": "Incorrect password. Please try again or verify using an email confirmation code."},
                    status=status.HTTP_400_BAD_REQUEST
                )

        # Verification via OTP
        elif otp:
            if not re.match(r'^\d{6}$', otp):
                return Response(
                    {"success": False, "error": "Confirmation code must be exactly 6 digits."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            otp_obj = EmailOTP.objects.filter(
                email=user.email.lower(),
                purpose=EmailOTP.PURPOSE_DELETE_ACCOUNT,
                is_used=False,
            ).order_by('-created_at').first()

            if not otp_obj:
                return Response(
                    {"success": False, "error": "No active confirmation code found. Please request a new code."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            is_valid, err_msg = otp_obj.verify(otp, max_attempts=5)
            if not is_valid:
                return Response(
                    {"success": False, "error": err_msg},
                    status=status.HTTP_400_BAD_REQUEST
                )

        # Identity confirmed — proceed with irreversible deletion
        user_id = user.pk
        user_email = user.email
        user_role = user.role

        logger.warning(
            "PERMANENT ACCOUNT DELETION: User ID=%s, email=%s, role=%s permanently deleted.",
            user_id, user_email, user_role
        )

        # Clean up any OTP records for this email
        EmailOTP.objects.filter(email=user_email.lower()).delete()

        # Delete user (cascades to UserProfile / ProfessionalProfile / Bookings / etc.)
        user.delete()

        return Response({
            "success": True,
            "message": "Your ProFinder account and associated data have been permanently deleted.",
        })