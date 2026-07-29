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
from django.template.loader import render_to_string
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.conf import settings

from apps.users.serializers import RegisterSerializer, UpdateLanguageSerializer
from apps.users.models import User
from apps.profiles.models import UserProfile, ProfessionalProfile

logger = logging.getLogger(__name__)


def is_admin(user):
    return user.is_authenticated and user.role == 'admin'


class RegisterView(APIView):
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(
                {"message": "User created successfully"},
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

        user = authenticate(request, username=email, password=password)
        if user:
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
                # ✅ i18n — null means the app should upload its locally
                # selected language instead of overriding it.
                "preferred_language": user.preferred_language,
            })
        return Response(
            {"error": "Invalid email or password."},
            status=status.HTTP_401_UNAUTHORIZED
        )


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
        })

    # ── Save / update this device's FCM token ──────────────────────
    def patch(self, request):
        fcm_token = request.data.get('fcm_token')
        if fcm_token is None:
            return Response(
                {"error": "fcm_token is required."},
                status=status.HTTP_400_BAD_REQUEST
            )
        user = request.user
        user.fcm_token = fcm_token
        user.save(update_fields=['fcm_token'])
        return Response({"message": "FCM token saved."})


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
                item['photo_url'] = up.photo_url.url if up.photo_url else ''
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
                    item['photo_url']     = pp.photo_url.url if pp.photo_url else item['photo_url']
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
    Starts the password-reset flow.

    Security design:
    - The response is IDENTICAL whether or not the email is registered —
      this endpoint must never be usable to enumerate accounts.
    - Any SMTP/delivery failure is logged server-side only; the client
      never sees exception details.
    - Rate-limited (see `throttle_scope` + settings.DEFAULT_THROTTLE_RATES)
      to blunt abuse — both inbox-spamming a real user and enumeration.
    """
    permission_classes = [AllowAny]
    throttle_classes   = [ScopedRateThrottle]
    throttle_scope     = 'forgot_password'

    GENERIC_MESSAGE = (
        "If an account exists with this email address, "
        "a password reset link has been sent."
    )

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        if not email:
            return Response(
                {"success": False, "error": "Email is required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user = User.objects.get(email=email)
            self._send_reset_email(request, user)
        except User.DoesNotExist:
            # Deliberately silent — falls through to the same generic
            # response as the success path below.
            pass
        except Exception:
            # Covers SMTP auth failures, network timeouts to Brevo, etc.
            # Never bubble this up to the client.
            logger.exception("Password reset email failed to send for %s", email)

        return Response({"success": True, "message": self.GENERIC_MESSAGE})

    def _send_reset_email(self, request, user):
        token = default_token_generator.make_token(user)
        uid   = urlsafe_base64_encode(force_bytes(user.pk))
        reset_url = f"{settings.PUBLIC_BASE_URL}/api/users/reset-password/{uid}/{token}/"

        context = {
            "user_name":     getattr(user, "name", None) or user.email.split('@')[0],
            "reset_url":     reset_url,
            "expiry_hours":  settings.PASSWORD_RESET_TIMEOUT // 3600,
            "support_email": settings.SUPPORT_EMAIL,
        }

        text_body = render_to_string("emails/password_reset.txt", context)
        html_body = render_to_string("emails/password_reset.html", context)

        message = EmailMultiAlternatives(
            subject="Reset your ProFinder password",
            body=text_body,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[user.email],
        )
        message.attach_alternative(html_body, "text/html")
        # fail_silently=False so failures are raised here and caught (and
        # logged) by the caller — we still never let them reach the client.
        message.send(fail_silently=False)
        logger.info("Password reset email sent to user_id=%s", user.pk)


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