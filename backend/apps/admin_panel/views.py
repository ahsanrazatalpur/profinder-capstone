# apps/admin_panel/views.py

import logging
import threading

from django.utils import timezone
from django.db import models, transaction, close_old_connections
from django.db.models import Q
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
import cloudinary.uploader 

from apps.admin_panel.models import (
    AdminLog, PromoBanner, UserReport, Complaint, NotificationBroadcast,
    Language, TranslationKey, TranslationString,
    Country, City, Announcement, ModerationAction, Appeal,
    ContentTranslation, TRANSLATABLE_FIELDS, normalize_lang,
)
from apps.admin_panel import moderation_notifications
from apps.admin_panel.appeals import submit_appeal, approve_appeal, reject_appeal
from apps.admin_panel.moderation import (
    ModerationError, STATUS_CHOICES as MODERATION_STATUS_CHOICES,
    create_moderation_action, reverse_moderation_action,
    record_legacy_report_ban, sync_moderation_after_legacy_unban,
)
from apps.admin_panel import enforcement
from apps.admin_panel.serializers import (
    AdminLogSerializer, PromoBannerSerializer,
    UserReportSerializer, CreateUserReportSerializer, MyUserReportSerializer,
    ComplaintSerializer, NotificationBroadcastSerializer,
    LanguageSerializer, CountrySerializer, CitySerializer, AnnouncementSerializer,
    ModerationActionSerializer, CreateModerationActionSerializer,
    MyModerationActionSerializer,
    ReverseModerationActionSerializer,
    AppealSubmitSerializer, MyAppealSerializer, AdminAppealSerializer,
    AppealApproveSerializer, AppealRejectSerializer,
)
from apps.users.models import User
from apps.bookings.models import Booking
from apps.bookings.serializers import BookingSerializer
from apps.notifications.utils import notify_user, send_fcm_push, style_push_title
from apps.subscriptions.models import SubscriptionPlan, PlanFeature, Subscription
from apps.subscriptions.serializers import SubscriptionPlanSerializer


def _is_admin(user):
    return user.is_authenticated and user.role == 'admin'


# ─── Logs ────────────────────────────────────────────────────────────────────

class AdminLogView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        logs = AdminLog.objects.select_related('admin', 'target_user').all()
        return Response(AdminLogSerializer(logs, many=True).data)


class AdminLogDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, log_id=None):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        if log_id:
            AdminLog.objects.filter(id=log_id).delete()
        else:
            AdminLog.objects.all().delete()
        return Response({'message': 'Deleted.'})


# ─── User Management ─────────────────────────────────────────────────────────

class AdminUserDetailView(APIView):
    """
    Admin: full "User Details" drawer data for any single user — richer
    than the /users/ list endpoint (which stays lightweight for table
    rendering). Used by Users / Professionals / Customers screens when
    the admin taps "View Details".

    GET /api/admin-panel/users/<user_id>/details/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        from apps.bookings.models import Booking
        from apps.payments.models import Payment
        from apps.profiles.models import UserProfile, ProfessionalProfile, Portfolio
        from apps.reviews.models import Review
        from django.db.models import Sum, Avg

        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=404)

        data = {
            'id': user.id, 'name': user.name, 'email': user.email,
            'role': user.role, 'is_active': user.is_active,
            'joined': user.created_at.strftime('%Y-%m-%d') if user.created_at else '',
        }

        try:
            up = UserProfile.objects.get(user=user)
            data.update({
                'phone': up.phone, 'city': up.city, 'area': up.area,
                'country': up.country,
                'photo_url': up.photo_url.url if up.photo_url else '',
            })
        except UserProfile.DoesNotExist:
            pass

        if user.role == 'professional':
            try:
                pp = ProfessionalProfile.objects.get(user=user)
                data.update({
                    'bio': pp.bio,
                    'category_name': pp.category.name if pp.category else '',
                    'experience_years': pp.experience_years,
                    'hourly_rate': str(pp.hourly_rate),
                    'is_verified': pp.is_verified,
                    'is_available': pp.is_available,
                    'average_rating': str(pp.average_rating),
                    'cnic_url': pp.cnic_url.url if pp.cnic_url else '',
                    'license_url': pp.license_url.url if pp.license_url else '',
                    'photo_url': pp.photo_url.url if pp.photo_url else data.get('photo_url', ''),
                })
            except ProfessionalProfile.DoesNotExist:
                pass

            data['portfolio_count'] = Portfolio.objects.filter(professional=user).count()
            data['total_reviews']   = Review.objects.filter(professional=user).count()
            data['total_bookings']  = Booking.objects.filter(
                professional=user, status='completed').count()
            earnings = Payment.objects.filter(
                user=user, status='completed').aggregate(total=Sum('amount'))['total']
            data['total_earnings'] = str(earnings) if earnings else '0.00'

            recent = (Booking.objects.filter(professional=user)
                      .order_by('-created_at')[:5])
            data['recent_bookings'] = [
                {'id': b.id, 'customer': b.customer.name, 'date': str(b.date), 'status': b.status}
                for b in recent
            ]

        if user.role == 'customer':
            data['total_bookings'] = Booking.objects.filter(customer=user).count()
            spent = Payment.objects.filter(
                user=user, status='completed').aggregate(total=Sum('amount'))['total']
            data['total_spent'] = str(spent) if spent else '0.00'

            recent = (Booking.objects.filter(customer=user)
                      .order_by('-created_at')[:5])
            data['recent_bookings'] = [
                {'id': b.id, 'professional': b.professional.name, 'date': str(b.date), 'status': b.status}
                for b in recent
            ]

        return Response(data)


class BanUserView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, user_id):
        """Toggle ban state — kept for backward compatibility (single-user
        toggle buttons that don't know the current state)."""
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=404)

        user.is_active = not user.is_active
        user.save()
        if user.is_active:
            # Legacy unban must also lift any ModerationAction that the legacy
            # report-ban flow recorded, or Part 3 enforcement would keep
            # treating an explicitly-unbanned user as suspended.
            sync_moderation_after_legacy_unban(user=user, admin=request.user)
        action = 'unban' if user.is_active else 'ban'
        AdminLog.objects.create(admin=request.user, action=action, target_user=user,
                                note=request.data.get('note', ''))
        return Response({'message': f'User {"unbanned" if user.is_active else "banned"}.',
                         'is_active': user.is_active})

    def patch(self, request, user_id):
        """
        Explicit ban/unban — used by bulk actions and any screen where
        toggling is unsafe (e.g. bulk-selecting a mix of already-banned
        and active users — a blind toggle would incorrectly unban some).
        Body: { "action": "ban" | "unban" }
        """
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=404)

        action = request.data.get('action')
        if action not in ('ban', 'unban'):
            return Response({'error': "action must be 'ban' or 'unban'."}, status=400)

        user.is_active = (action == 'unban')
        user.save()
        if user.is_active:
            sync_moderation_after_legacy_unban(user=user, admin=request.user)
        AdminLog.objects.create(admin=request.user, action=action, target_user=user,
                                note=request.data.get('note', ''))
        return Response({'message': 'User banned.' if action == 'ban' else 'User unbanned.',
                         'is_active': user.is_active})


class VerifyProfessionalView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, user_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            user = User.objects.get(id=user_id, role='professional')
            prof = user.professionalprofile
        except (User.DoesNotExist, Exception):
            return Response({'error': 'Professional not found.'}, status=404)

        prof.is_verified = not prof.is_verified
        prof.save()
        AdminLog.objects.create(
            admin=request.user, action='verify', target_user=user,
            note='Verified' if prof.is_verified else 'Unverified')
        return Response({'is_verified': prof.is_verified})


class RemindProfessionalView(APIView):
    """
    Admin: Send a profile-completion / verification reminder notification
    to a professional (used by the Professionals screen's "Send Reminder"
    action — single or as part of a bulk operation).
    POST /api/admin-panel/users/<user_id>/remind/
    Body (optional): { "message": "custom text" }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, user_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            user = User.objects.get(id=user_id, role='professional')
        except User.DoesNotExist:
            return Response({'error': 'Professional not found.'}, status=404)

        message = request.data.get(
            'message',
            'Please complete your profile (portfolio, category, rate) to '
            'get verified and start receiving bookings on ProFinder.'
        )
        notify_user(user, 'Complete Your Profile 📋', message)

        AdminLog.objects.create(
            admin=request.user, action='remind', target_user=user,
            note='Sent profile-completion reminder')
        return Response({'message': 'Reminder sent.'})


class AdminBlockedUsersView(APIView):
    """
    Admin: dedicated "Blocked Users" queue — everyone currently is_active=False,
    with WHO blocked them and WHY (pulled from the most recent 'ban' AdminLog
    entry for that user, since there's no direct block-reason field on User).
    GET /api/admin-panel/blocked-users/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        blocked = list(User.objects.filter(is_active=False).order_by('-id'))
        if not blocked:
            return Response([])

        blocked_ids = [u.id for u in blocked]
        ban_logs = (
            AdminLog.objects.filter(target_user_id__in=blocked_ids, action='ban')
            .select_related('admin')
            .order_by('target_user_id', '-created_at')
        )
        latest_ban_map = {}
        for log in ban_logs:
            if log.target_user_id not in latest_ban_map:
                latest_ban_map[log.target_user_id] = log

        data = []
        for user in blocked:
            last_ban_log = latest_ban_map.get(user.id)
            data.append({
                'id': user.id,
                'name': user.name,
                'email': user.email,
                'role': user.role,
                'blocked_at': last_ban_log.created_at if last_ban_log else None,
                'blocked_by': last_ban_log.admin.email if last_ban_log else None,
                'reason': last_ban_log.note if last_ban_log else '',
            })
        return Response(data)


class AdminVerificationRequestsView(APIView):
    """
    Admin: professionals awaiting verification — a FIFO queue (oldest
    signup first, so nobody's request is skipped indefinitely).
    GET /api/admin-panel/verification-requests/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        from apps.profiles.models import ProfessionalProfile

        pending = (
            ProfessionalProfile.objects
            .filter(is_verified=False)
            .select_related('user', 'category')
            .order_by('user__created_at')  # oldest request first — FIFO fairness
        )
        data = []
        for prof in pending:
            data.append({
                'user_id':          prof.user.id,
                'name':              prof.user.name,
                'email':             prof.user.email,
                'category':          prof.category.name if prof.category else None,
                'experience_years':  prof.experience_years,
                'bio':               prof.bio,
                'cnic_url':          prof.cnic_url.url if prof.cnic_url else None,
                'license_url':       prof.license_url.url if prof.license_url else None,
                'submitted_at':      prof.user.created_at,
            })
        return Response(data)


class AdminVerificationActionView(APIView):
    """
    Admin: approve or reject a single verification request (with reason
    on reject, for the professional's own record + audit log).
    POST /api/admin-panel/verification-requests/<user_id>/action/
    Body: { "action": "approve" | "reject", "reason": "optional text" }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, user_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            user = User.objects.get(id=user_id, role='professional')
            prof = user.professionalprofile
        except (User.DoesNotExist, Exception):
            return Response({'error': 'Professional not found.'}, status=404)

        action = request.data.get('action')
        if action not in ('approve', 'reject'):
            return Response({'error': "action must be 'approve' or 'reject'."}, status=400)

        reason = request.data.get('reason', '')
        prof.is_verified = (action == 'approve')
        prof.save()

        AdminLog.objects.create(
            admin=request.user, action='verify', target_user=user,
            note=(f'Verification approved' if action == 'approve'
                  else f'Verification rejected — {reason}' if reason
                  else 'Verification rejected'))

        if action == 'reject':
            notify_user(
                user, 'Verification Update',
                reason or 'Your verification request needs more information. '
                          'Please review your documents and resubmit.')

        return Response({'is_verified': prof.is_verified, 'action': action})


# ─── Bookings ────────────────────────────────────────────────────────────────

class AdminBookingView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        bookings = Booking.objects.select_related('customer', 'professional').all().order_by('-created_at')

        # ✅ NEW — ?search= support, used by the admin panel's global
        # search (header search icon). Matches booking id, or the
        # customer's/professional's name or email.
        search = request.query_params.get('search', '').strip()
        if search:
            from django.db.models import Q
            booking_id = int(search) if search.isdigit() else None
            bookings = bookings.filter(
                Q(id=booking_id) |
                Q(customer__name__icontains=search) |
                Q(customer__email__icontains=search) |
                Q(professional__name__icontains=search) |
                Q(professional__email__icontains=search)
            )

        return Response(BookingSerializer(bookings, many=True).data)


class AdminCancelBookingView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            booking = Booking.objects.get(id=booking_id)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found.'}, status=404)

        if booking.status in ['completed', 'cancelled']:
            return Response({'error': f'Already {booking.status}.'}, status=400)

        reason = request.data.get('cancel_reason', 'Cancelled by admin').strip()
        booking.status        = 'cancelled'
        booking.cancel_reason = reason
        booking.cancelled_by  = 'admin'
        booking.save()

        prof_name = getattr(booking.professional, 'name', 'the professional')
        cust_name = getattr(booking.customer, 'name', 'the customer')
        notify_user(booking.customer,     'Booking Cancelled by Admin ❌', f'Your booking with {prof_name} was cancelled by admin.\nReason: {reason}')
        notify_user(booking.professional, 'Booking Cancelled by Admin ❌', f'Your booking with {cust_name} was cancelled by admin.\nReason: {reason}')

        AdminLog.objects.create(admin=request.user, action='cancel_booking',
                                target_user=booking.customer, note=reason)
        return Response(BookingSerializer(booking).data)


# ─── Promo Banner Image Upload ────────────────────────────────────────────────

class PromoBannerImageUploadView(APIView):
    """
    Admin: gallery se image pick karke upload karo.
    POST /api/admin-panel/promo-banners/upload-image/
    Body: multipart/form-data, key = 'image'
    Response: { 'url': 'https://cloudinary.com/...' }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        image = request.FILES.get('image')
        if not image:
            return Response({'error': 'No image file provided.'}, status=400)

        try:
            result = cloudinary.uploader.upload(image, folder='promo_banners')
            return Response({'url': result['secure_url']})
        except Exception as e:
            return Response({'error': f'Upload failed: {str(e)}'}, status=500)


# ─── PromoBanner CRUD ─────────────────────────────────────────────────────────

class PromoBannerAdminView(APIView):
    """
    Admin: Full CRUD for popup banners.
    GET    /api/admin-panel/promo-banners/           → sab banners
    POST   /api/admin-panel/promo-banners/           → new banner create
    PATCH  /api/admin-panel/promo-banners/<id>/      → update
    DELETE /api/admin-panel/promo-banners/<id>/      → delete
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        banners = PromoBanner.objects.all()
        return Response(ContentTranslation.attach_rows(
            'promobanner', PromoBannerSerializer(banners, many=True).data))

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        serializer = PromoBannerSerializer(data=request.data)
        if serializer.is_valid():
            banner = serializer.save()
            AdminLog.objects.create(admin=request.user, action='create_banner',
                                    note=f'Created: {banner.title}')
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

    def patch(self, request, banner_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            banner = PromoBanner.objects.get(id=banner_id)
        except PromoBanner.DoesNotExist:
            return Response({'error': 'Banner not found.'}, status=404)
        serializer = PromoBannerSerializer(banner, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            AdminLog.objects.create(admin=request.user, action='edit_banner',
                                    note=f'Updated: {banner.title}')
            return Response(serializer.data)
        return Response(serializer.errors, status=400)

    def delete(self, request, banner_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            banner = PromoBanner.objects.get(id=banner_id)
            banner.delete()
            return Response({'message': 'Deleted.'})
        except PromoBanner.DoesNotExist:
            return Response({'error': 'Not found.'}, status=404)


class ActivePromoBannerView(APIView):
    """
    Flutter app: Active banners fetch karo based on user type + trigger.
    GET /api/admin-panel/promo-banners/active/?trigger=home&user_type=free_customer
    No auth needed — guest ke liye bhi kaam kare.

    FIX: 'all_customers' aur 'all_professionals' audience ab properly match
    hoti hai. Pehle sirf exact match tha — ab broad group bhi check hota hai.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        trigger   = request.query_params.get('trigger', 'home')
        user_type = request.query_params.get('user_type', 'guest')

        # Broad group match: free_customer/premium_customer → all_customers
        broad_group = None
        if 'customer' in user_type:
            broad_group = 'all_customers'
        elif 'professional' in user_type:
            broad_group = 'all_professionals'

        now = timezone.now()

        # ── Trigger match — explicit list banao, fragile Q()-OR-chaining nahi ────
        # booking/search/ai_search/login → sirf exact screen pe
        # app_open → home ya login pe (app start hone pe bhi dikhe)
        # every_x_days → home pe hi dikhao (periodic reminder banner)
        allowed_triggers = {trigger}
        if trigger in ('home', 'login'):
            allowed_triggers.add('app_open')
        if trigger == 'home':
            allowed_triggers.add('every_x_days')

        # ── Audience match — yahan bhi explicit list, Q() empty-OR bug se bachne ke liye
        allowed_audiences = {'everyone', user_type}
        if broad_group:
            allowed_audiences.add(broad_group)

        banners = PromoBanner.objects.filter(
            is_active=True,
        ).filter(
            # start_date null ya past
            models.Q(start_date__isnull=True) | models.Q(start_date__lte=now)
        ).filter(
            # end_date null ya future
            models.Q(end_date__isnull=True) | models.Q(end_date__gte=now)
        ).filter(
            trigger__in=list(allowed_triggers),
        ).filter(
            target_audience__in=list(allowed_audiences),
        ).order_by('-priority')

        if not banners.exists():
            return Response({'active': False, 'banners': []})

        return Response({
            'active':  True,
            'banners': ContentTranslation.localize_rows(
                'promobanner', PromoBannerSerializer(banners, many=True).data,
                request.query_params.get('lang')),
        })


# ─── Subscription Plan Management ────────────────────────────────────────────

class AdminSubscriptionPlanView(APIView):
    """
    Admin: Subscription plans manage karo.
    GET    → sab plans
    POST   → new plan create
    PATCH  → plan update (price, duration, features)
    DELETE → plan delete
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        plans = SubscriptionPlan.objects.all()
        return Response(SubscriptionPlanSerializer(plans, many=True).data)

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        serializer = SubscriptionPlanSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

    def patch(self, request, plan_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            plan = SubscriptionPlan.objects.get(id=plan_id)
        except SubscriptionPlan.DoesNotExist:
            return Response({'error': 'Plan not found.'}, status=404)
        serializer = SubscriptionPlanSerializer(plan, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)

    def delete(self, request, plan_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            SubscriptionPlan.objects.get(id=plan_id).delete()
            return Response({'message': 'Plan deleted.'})
        except SubscriptionPlan.DoesNotExist:
            return Response({'error': 'Not found.'}, status=404)


class AdminPlanFeatureView(APIView):
    """
    Admin: Plan ki individual features edit karo (limits change karo).
    GET /api/admin-panel/plans/<plan_id>/features/
    PUT /api/admin-panel/plans/<plan_id>/features/<key>/
    Body: { "value": "10" }
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, plan_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        features = PlanFeature.objects.filter(plan_id=plan_id)
        from apps.subscriptions.serializers import PlanFeatureSerializer
        return Response(PlanFeatureSerializer(features, many=True).data)

    def put(self, request, plan_id, feature_key):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        new_value = request.data.get('value')
        if new_value is None:
            return Response({'error': 'value field required.'}, status=400)

        feature, created = PlanFeature.objects.get_or_create(
            plan_id=plan_id,
            key=feature_key,
            defaults={
                'value':        str(new_value),
                'feature_type': request.data.get('feature_type', 'int'),
                'label':        request.data.get('label', feature_key),
            }
        )
        if not created:
            feature.value = str(new_value)
            if 'feature_type' in request.data:
                feature.feature_type = request.data['feature_type']
            feature.save()

        from apps.subscriptions.serializers import PlanFeatureSerializer
        return Response(PlanFeatureSerializer(feature).data)


def _notify_report_resolution(report, was_banned, status_changed=True):
    """
    Report resolve hone ke baad parties ko notify karta hai — bilkul
    Instagram/Facebook/etc. jese bade apps ke pattern par:

    - Reporter: sirf ek GENERIC outcome milta hai — kabhi exact punishment,
      suspension duration, admin notes ya reported user ki koi private info
      nahi (privacy). Sirf tab jab status waqai change hua ho (baar baar
      PATCH par duplicate notification nahi).
    - Reported user: reporter ki identity aur report id KABHI expose nahi hoti.
        * Ban / restriction / warning jo ModerationAction ke through lagi hai,
          uski notification (reason ke saath) moderation service khud bhejti
          hai (apps.admin_panel.moderation_notifications) — yahan dobara
          nahi bheji jati, warna duplicate hoti.
        * Sirf legacy case: status 'action_taken' ho aur is report se koi
          ModerationAction linked na ho, tab purani generic warning jati hai.
        * 'dismissed' / 'reviewed' par reported user ko kuch nahi bataya jata.
    """
    if status_changed and report.status != 'pending':
        target_name = getattr(report.reported_user, 'name', 'the user') if report.reported_user else 'the reported user'
        reason_display = report.get_reason_display() if hasattr(report, 'get_reason_display') else 'your report'
        reporter_msg = {
            'action_taken': f"Your report regarding {target_name} ({reason_display}) has been reviewed and appropriate action has been taken.",
            'dismissed':    f"We've reviewed your report regarding {target_name} ({reason_display}) and didn't find a violation of our guidelines this time. Thanks for flagging it.",
            'reviewed':     f"We've reviewed your report regarding {target_name} ({reason_display}). Thanks for helping keep the community safe.",
        }.get(report.status, f"We've reviewed your report regarding {target_name}. Thanks for helping keep the community safe.")

        notify_user(
            report.reporter,
            title='Your Report Was Reviewed',
            message=reporter_msg,
            notif_type='report',
            data={'report_id': report.id, 'event': 'report_resolved', 'status': report.status},
        )

    if was_banned:
        # Reported user already got the "Account Permanently Suspended"
        # notification from the ModerationAction that recorded this ban.
        return

    if (status_changed and report.status == 'action_taken'
            and not report.moderation_actions.exists()):
        notify_user(
            report.reported_user,
            title='Community Guidelines Warning',
            message="Your account has received a warning for violating our community guidelines. Repeated violations may lead to suspension.",
            notif_type='report',
            data={'event': 'warning_issued'},   # no report_id: internal, never shown to the reported user
        )
    # 'reviewed' or 'dismissed' with no ban -> reported user is NOT notified.


# ─── User Reports (Trust & Safety) ────────────────────────────────────────────

class ReportUserView(APIView):
    """
    Koi bhi authenticated user (customer/professional) kisi dusre user ko
    report kar sakta hai. Admin-only nahi — end users submit karte hain.
    POST /api/admin-panel/reports/
    Body: { "reported_user": <id>, "reason": "spam", "description": "..." }
    """
    permission_classes = [IsAuthenticated]
    # ✅ Trust & Safety Part 9 (security pass) — see the matching
    # DEFAULT_THROTTLE_RATES comment in settings.py. Per-user, not global.
    throttle_scope = 'user_report_create'

    def post(self, request):
        serializer = CreateUserReportSerializer(
            data=request.data, context={'request': request})
        if serializer.is_valid():
            report = serializer.save(reporter=request.user)

            # Reporter ko turant confirmation — jaise Instagram/Facebook karte
            # hain: "we got it, it's under review". Reported user ko is stage
            # par kuch nahi bataya jata (reporter ki privacy/safety ke liye) —
            # unhe sirf tab pata chalta hai jab admin action leta hai (neeche
            # AdminReportActionView mein).
            target_name = getattr(report.reported_user, 'name', None) if report.reported_user else None
            about_target = f" regarding {target_name}" if target_name else ""
            notify_user(
                request.user,
                title='Report Submitted',
                message=f"Thanks — we've received your report{about_target} and our team will review it shortly.",
                notif_type='report',
                data={'report_id': report.id, 'event': 'report_submitted'},
            )

            # Admins get their own alert (this flow previously only notified
            # the reporter). After-commit + failure-isolated: a notification
            # problem can never fail the report submission itself.
            transaction.on_commit(
                lambda rid=report.id: moderation_notifications.notify_admins_of_new_report(rid))

            return Response(UserReportSerializer(report).data, status=201)
        return Response(serializer.errors, status=400)


class MyReportsView(APIView):
    """
    Trust & Safety Part 8: the reporting user's own "My Reports" screen —
    reports THEY submitted, newest first. Never another user's reports
    (filtered strictly by `reporter=request.user`), and never a report
    submitted against the current user by someone else.

    Uses `MyUserReportSerializer`, a deliberately narrow view — see that
    serializer's docstring for exactly what is (and is never) exposed.

    GET /api/admin-panel/reports/mine/
        ?status=pending|reviewed|action_taken|dismissed   (optional)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        reports = UserReport.objects.filter(reporter=request.user)

        status_filter = request.query_params.get('status')
        if status_filter:
            valid_statuses = dict(UserReport.STATUS_CHOICES)
            if status_filter not in valid_statuses:
                return Response(
                    {'error': f"status must be one of: {', '.join(valid_statuses)}."},
                    status=400)
            reports = reports.filter(status=status_filter)

        return Response(MyUserReportSerializer(reports, many=True).data)


class AdminReportedUsersView(APIView):
    """
    Admin: sab reports dekho, status se filter karo.
    GET /api/admin-panel/reports/                → all reports (newest first)
    GET /api/admin-panel/reports/?status=pending  → sirf pending
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        reports = UserReport.objects.select_related(
            'reporter', 'reported_user', 'reviewed_by',
            'related_booking__customer', 'related_booking__professional',
            'related_message__sender',
        ).prefetch_related('related_message__attachments').all()

        status_filter = request.query_params.get('status')
        if status_filter:
            reports = reports.filter(status=status_filter)

        return Response(UserReportSerializer(reports, many=True).data)


class AdminReportActionView(APIView):
    """
    Admin: ek report resolve karo — reviewed mark karo, dismiss karo, ya
    action_taken (aur chaho to reported user ko ban bhi kar do usi call mein).
    PATCH /api/admin-panel/reports/<report_id>/
    Body: {
        "status": "reviewed" | "dismissed" | "action_taken",
        "admin_note": "optional note",
        "ban_user": true   // optional — reported user ko ban bhi kardo
    }
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, report_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            report = UserReport.objects.select_related('reported_user').get(id=report_id)
        except UserReport.DoesNotExist:
            return Response({'error': 'Report not found.'}, status=404)

        new_status = request.data.get('status', report.status)
        valid_statuses = dict(UserReport.STATUS_CHOICES)
        if new_status not in valid_statuses:
            return Response({'error': 'Invalid status.'}, status=400)

        status_changed     = new_status != report.status
        report.status      = new_status
        report.admin_note   = request.data.get('admin_note', report.admin_note)
        report.reviewed_by  = request.user
        report.reviewed_at  = timezone.now()
        report.save()

        was_banned = False
        # Optional one-tap enforcement: ban the reported user right here.
        # Behaviour is unchanged (User.is_active=False + the 'ban' AdminLog),
        # but the ban is now ALSO recorded as a permanent-suspension
        # ModerationAction linked to this report, so the user has one
        # moderation history instead of a bare flag. All-or-nothing.
        if request.data.get('ban_user') and report.reported_user.is_active:
            with transaction.atomic():
                report.reported_user.is_active = False
                report.reported_user.save()
                record_legacy_report_ban(
                    admin=request.user, report=report, note=report.admin_note)
                AdminLog.objects.create(
                    admin=request.user, action='ban', target_user=report.reported_user,
                    note=f'Banned due to report #{report.id} ({report.get_reason_display()})')
            was_banned = True

        log_action = 'report_dismissed' if new_status == 'dismissed' else 'report_reviewed'
        AdminLog.objects.create(
            admin=request.user, action=log_action, target_user=report.reported_user,
            note=f'Report #{report.id} marked "{valid_statuses[new_status]}"')

        _notify_report_resolution(report, was_banned, status_changed=status_changed)

        return Response(UserReportSerializer(report).data)


# ─── Moderation Actions (Trust & Safety Part 4) ───────────────────────────────

def _apply_moderation_filters(qs, params):
    """
    Optional ?status=<active|scheduled|expired|reversed> and
    ?action_type=<warning|restrict_messaging|...> filters shared by the
    history endpoints. Returns (queryset, error_response_or_None).
    """
    now = timezone.now()

    status_filter = params.get('status')
    if status_filter:
        if status_filter not in MODERATION_STATUS_CHOICES:
            return qs, Response(
                {'error': f"status must be one of: {', '.join(MODERATION_STATUS_CHOICES)}."},
                status=400)
        if status_filter == 'reversed':
            qs = qs.filter(is_active=False)
        elif status_filter == 'scheduled':
            qs = qs.filter(is_active=True, starts_at__gt=now)
        elif status_filter == 'expired':
            qs = qs.filter(is_active=True, starts_at__lte=now, expires_at__lte=now)
        else:  # 'active' — mirrors enforcement._is_effectively_active
            qs = qs.filter(is_active=True, starts_at__lte=now).filter(
                Q(expires_at__isnull=True) | Q(expires_at__gt=now))

    type_filter = params.get('action_type')
    if type_filter:
        if type_filter not in dict(ModerationAction.ACTION_CHOICES):
            return qs, Response({'error': 'Invalid action_type.'}, status=400)
        qs = qs.filter(action_type=type_filter)

    return qs, None


def _moderation_queryset():
    return ModerationAction.objects.select_related(
        'target_user', 'performed_by', 'reversed_by', 'report')


class AdminModerationActionCreateView(APIView):
    """
    Admin: take a moderation action against a user.
    POST /api/admin-panel/moderation-actions/
    Body: {
        "target_user": <user id>,
        "action_type": "warning" | "restrict_messaging" | "restrict_booking"
                       | "suspend_temporary" | "suspend_permanent",
        "reason": "required text",
        "admin_note": "optional internal note",
        "report": <report id>,             // optional; must be about target_user
        "expires_at": "2026-10-01T12:00:00Z" // required for suspend_temporary,
                                              // forbidden for suspend_permanent
    }
    The acting admin, active state, start time and creation time are always
    set by the server; anything the client sends for them is ignored.
    This records the action only — enforcement is read from it by
    apps.admin_panel.enforcement; this endpoint changes no account flags.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        serializer = CreateModerationActionSerializer(
            data=request.data, context={'request': request})
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)
        data = serializer.validated_data

        try:
            action = create_moderation_action(
                admin=request.user,
                target_user=data['target_user'],
                action_type=data['action_type'],
                reason=data['reason'],
                admin_note=data.get('admin_note', ''),
                report=data.get('report'),
                expires_at=data.get('expires_at'),
            )
        except ModerationError as e:
            return Response({'error': e.message}, status=e.status_code)

        action = _moderation_queryset().get(pk=action.pk)
        return Response(ModerationActionSerializer(action).data, status=201)


class AdminUserModerationHistoryView(APIView):
    """
    Admin: full moderation history for one user, newest first — includes
    active, expired and reversed actions (nothing is ever deleted).
    GET /api/admin-panel/users/<user_id>/moderation-actions/
        ?status=active|scheduled|expired|reversed   (optional)
        &action_type=warning|restrict_messaging|... (optional)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        if not User.objects.filter(id=user_id).exists():
            return Response({'error': 'User not found.'}, status=404)

        qs = _moderation_queryset().filter(target_user_id=user_id)
        qs, error = _apply_moderation_filters(qs, request.query_params)
        if error:
            return error
        return Response(ModerationActionSerializer(qs, many=True).data)


class MyModerationStatusView(APIView):
    """
    Trust & Safety Part 8: the CURRENT user's own account-moderation status,
    for the "Account Moderation Status" screen. Always derived fresh from
    the database via `apps.admin_panel.enforcement` (the same read layer
    that governs actual enforcement) — never trusted from client-cached
    state, and never accepts any input.

    Only actions currently in force are listed (nothing reversed, expired,
    or not-yet-started) — this endpoint answers "what applies to me right
    now", not full history. `can_appeal` is precomputed per action from the
    user's own pending appeals, so the client never has to guess before
    submitting one.

    GET /api/admin-panel/moderation-status/mine/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        snapshot = enforcement.get_moderation_status(request.user)
        actions = snapshot.active_actions

        pending_appeal_action_ids = set(
            Appeal.objects.filter(
                user=request.user, status=Appeal.STATUS_PENDING,
                moderation_action__in=[a.pk for a in actions],
            ).values_list('moderation_action_id', flat=True)
        )

        serialized = MyModerationActionSerializer(
            actions, many=True,
            context={'pending_appeal_action_ids': pending_appeal_action_ids},
        ).data

        return Response({
            'is_suspended':               snapshot.is_suspended,
            'is_permanently_suspended':   snapshot.is_permanently_suspended,
            'is_temporarily_suspended':   snapshot.is_temporarily_suspended,
            'messaging_restricted':       snapshot.messaging_restricted,
            'booking_restricted':         snapshot.booking_restricted,
            'has_active_warning':         snapshot.has_active_warning,
            'actions':                    serialized,
        })


class AdminReportModerationActionsView(APIView):
    """
    Admin: every moderation action that was taken in response to one report.
    GET /api/admin-panel/reports/<report_id>/moderation-actions/
        ?status=...&action_type=...   (same optional filters as user history)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, report_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        if not UserReport.objects.filter(id=report_id).exists():
            return Response({'error': 'Report not found.'}, status=404)

        qs = _moderation_queryset().filter(report_id=report_id)
        qs, error = _apply_moderation_filters(qs, request.query_params)
        if error:
            return error
        return Response(ModerationActionSerializer(qs, many=True).data)


class AdminModerationActionReverseView(APIView):
    """
    Admin: reverse (deactivate) an action without deleting it — the record,
    its history, and who reversed it and why are all preserved.
    POST /api/admin-panel/moderation-actions/<action_id>/reverse/
    Body: { "reason": "required text" }
    404 if it doesn't exist; 409 if it was already reversed; 400 if it has
    already expired on its own (nothing left to reverse).
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, action_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        serializer = ReverseModerationActionSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)

        try:
            action = reverse_moderation_action(
                admin=request.user, action_id=action_id,
                reason=serializer.validated_data['reason'])
        except ModerationError as e:
            return Response({'error': e.message}, status=e.status_code)

        action = _moderation_queryset().get(pk=action.pk)
        return Response(ModerationActionSerializer(action).data)


# ─── Appeals (Trust & Safety Part 6) ──────────────────────────────────────────

_APPEAL_STATUSES = [c[0] for c in Appeal.STATUS_CHOICES]


def _appeal_status_filter(qs, params):
    """Optional ?status=pending|approved|rejected. Returns (qs, error_response|None)."""
    status_filter = params.get('status')
    if status_filter:
        if status_filter not in _APPEAL_STATUSES:
            return qs, Response(
                {'error': f"status must be one of: {', '.join(_APPEAL_STATUSES)}."}, status=400)
        qs = qs.filter(status=status_filter)
    return qs, None


def _admin_appeal_queryset():
    return Appeal.objects.select_related(
        'user', 'reviewed_by', 'report',
        'moderation_action', 'moderation_action__target_user',
        'moderation_action__performed_by', 'moderation_action__reversed_by',
        'moderation_action__report')


class AppealCreateView(APIView):
    """
    Affected user: appeal one of THEIR OWN moderation actions.
    POST /api/admin-panel/appeals/create/
    Body: {
        "moderation_action": <action id>,
        "reason": "required explanation",
        "evidence_url": "https://..."   // optional
    }
    Only those three fields are read. Status, reviewer, decision note,
    timestamps and the linked report are set by the server. An action that
    isn't yours and one that doesn't exist both return the same 400.
    409 if the action is no longer in force or already has a pending appeal.
    Submitting changes nothing about the action; only an admin decision does.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = AppealSubmitSerializer(data=request.data, context={'request': request})
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)
        data = serializer.validated_data

        try:
            appeal = submit_appeal(
                user=request.user,
                moderation_action_id=data['moderation_action'].pk,
                reason=data['reason'],
                evidence_url=data.get('evidence_url', ''),
            )
        except ModerationError as e:
            return Response({'error': e.message}, status=e.status_code)

        appeal = Appeal.objects.select_related('moderation_action').get(pk=appeal.pk)
        return Response(MyAppealSerializer(appeal).data, status=201)


class MyAppealsView(APIView):
    """
    Affected user: list THEIR OWN appeals, newest first. Never includes anyone
    else's, and never the internal decision note, reviewing admin, or report.
    GET /api/admin-panel/appeals/mine/?status=pending|approved|rejected (optional)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = Appeal.objects.filter(user=request.user).select_related('moderation_action')
        qs, error = _appeal_status_filter(qs, request.query_params)
        if error:
            return error
        return Response(MyAppealSerializer(qs, many=True).data)


class AdminAppealListView(APIView):
    """
    Admin: appeals review queue.
    GET /api/admin-panel/appeals/?status=pending|approved|rejected (optional)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        qs, error = _appeal_status_filter(_admin_appeal_queryset(), request.query_params)
        if error:
            return error
        return Response(AdminAppealSerializer(qs, many=True).data)


class AdminAppealDetailView(APIView):
    """Admin: one appeal in full, with the appealed action's details."""
    permission_classes = [IsAuthenticated]

    def get(self, request, appeal_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            appeal = _admin_appeal_queryset().get(pk=appeal_id)
        except Appeal.DoesNotExist:
            return Response({'error': 'Appeal not found.'}, status=404)
        return Response(AdminAppealSerializer(appeal).data)


class AdminAppealApproveView(APIView):
    """
    Admin: approve a pending appeal. This reverses the appealed moderation
    action through the existing reversal logic (history is kept).
    POST /api/admin-panel/appeals/<appeal_id>/approve/
    Body: { "decision_note": "optional internal note" }
    404 unknown appeal; 409 if it was already decided.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, appeal_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        serializer = AppealApproveSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)
        try:
            appeal = approve_appeal(
                admin=request.user, appeal_id=appeal_id,
                decision_note=serializer.validated_data.get('decision_note', ''))
        except ModerationError as e:
            return Response({'error': e.message}, status=e.status_code)
        return Response(AdminAppealSerializer(_admin_appeal_queryset().get(pk=appeal.pk)).data)


class AdminAppealRejectView(APIView):
    """
    Admin: reject a pending appeal. The moderation action is left untouched.
    POST /api/admin-panel/appeals/<appeal_id>/reject/
    Body: { "decision_note": "required internal note" }
    404 unknown appeal; 409 if it was already decided.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, appeal_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        serializer = AppealRejectSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)
        try:
            appeal = reject_appeal(
                admin=request.user, appeal_id=appeal_id,
                decision_note=serializer.validated_data['decision_note'])
        except ModerationError as e:
            return Response({'error': e.message}, status=e.status_code)
        return Response(AdminAppealSerializer(_admin_appeal_queryset().get(pk=appeal.pk)).data)


# ─── Admin Dashboard Stats ────────────────────────────────────────────────────

class AdminDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        from apps.ai_engine.models import SearchHistory
        from apps.payments.models import Payment
        from apps.profiles.models import Portfolio
        from datetime import date

        total_users         = User.objects.count()
        total_customers     = User.objects.filter(role='customer').count()
        total_professionals = User.objects.filter(role='professional').count()
        total_bookings      = Booking.objects.count()
        today_bookings      = Booking.objects.filter(created_at__date=date.today()).count()
        ai_today            = SearchHistory.objects.filter(created_at__date=date.today()).count()
        active_subs         = Subscription.objects.filter(status='active').count()
        active_banners      = PromoBanner.objects.filter(is_active=True).count()

        # Premium counts
        premium_subs          = Subscription.objects.filter(status='active').exclude(
            plan__billing='free').select_related('user', 'plan')
        premium_customers     = sum(1 for s in premium_subs if s.user.role == 'customer')
        premium_professionals = sum(1 for s in premium_subs if s.user.role == 'professional')

        # Pending portfolio verification
        pending_verification = Portfolio.objects.filter(status='pending').count()

        # ── Revenue (sum of completed payments) ─────────────────────────────
        total_revenue = Payment.objects.filter(status='completed').aggregate(
            total=models.Sum('amount'))['total'] or 0

        # ── Blocked users ────────────────────────────────────────────────────
        blocked_users = User.objects.filter(is_active=False).count()

        # ── Reported users ───────────────────────────────────────────────────
        # Distinct users who have at least one report still awaiting review.
        # (Reviewed / dismissed / action_taken reports don't count towards
        # the "needs attention" badge on this card.)
        reported_users = UserReport.objects.filter(
            status='pending').values('reported_user').distinct().count()
        total_reports          = UserReport.objects.count()
        pending_reports        = UserReport.objects.filter(status='pending').count()

        # ── Recent payments (last 5) ─────────────────────────────────────────
        recent_payments = [
            {
                'id':         p.id,
                'user_email': p.user.email,
                'user_name':  p.user.name,
                'amount':     str(p.amount),
                'currency':   p.currency,
                'status':     p.status,
                'created_at': p.created_at,
            }
            for p in Payment.objects.select_related('user').order_by('-created_at')[:5]
        ]

        # ── Latest registrations (last 5, any role) ──────────────────────────
        latest_registrations = [
            {
                'id':         u.id,
                'name':       u.name,
                'email':      u.email,
                'role':       u.role,
                'created_at': u.created_at,
            }
            for u in User.objects.order_by('-created_at')[:5]
        ]

        # ── Pending approvals (last 5 pending portfolio items) ───────────────
        pending_approvals = [
            {
                'id':               p.id,
                'professional_name': p.professional.name,
                'professional_email': p.professional.email,
                'title':            p.title,
                'created_at':       p.created_at,
            }
            for p in Portfolio.objects.filter(status='pending')
                .select_related('professional').order_by('-created_at')[:5]
        ]

        return Response({
            'total_users':           total_users,
            'total_customers':       total_customers,
            'total_professionals':   total_professionals,
            'premium_customers':     premium_customers,
            'premium_professionals': premium_professionals,
            'total_bookings':        total_bookings,
            'today_bookings':        today_bookings,
            'ai_searches_today':     ai_today,
            'active_subscriptions':  active_subs,
            'active_popup_ads':      active_banners,
            'pending_verification':  pending_verification,
            'total_revenue':         str(total_revenue),
            'blocked_users':         blocked_users,
            'reported_users':        reported_users,
            'total_reports':         total_reports,
            'pending_reports':       pending_reports,
            'recent_payments':       recent_payments,
            'latest_registrations':  latest_registrations,
            'pending_approvals':     pending_approvals,
        })


# ─── Admin Analytics Section ──────────────────────────────────────────────────

class AdminAnalyticsView(APIView):
    """
    Admin: full data feed for the Analytics section —
    Revenue Chart, User Growth, Daily/Monthly Bookings, Countries
    Distribution, Top Cities, Top Categories, AI Analytics, Platform
    Statistics.

    GET /api/admin-panel/analytics/?days=30   (days: 7 | 30 | 90, default 30)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        from datetime import date, timedelta
        from django.db.models import Count, Sum
        from django.db.models.functions import TruncDate, TruncMonth
        from apps.payments.models import Payment
        from apps.profiles.models import UserProfile
        from apps.ai_engine.models import SearchHistory
        from apps.search.models import Category
        from apps.reviews.models import Review
        from apps.profiles.models import Portfolio

        try:
            days = int(request.query_params.get('days', 30))
        except (TypeError, ValueError):
            days = 30
        days = max(7, min(days, 90))  # clamp to a sane range
        start_date = date.today() - timedelta(days=days - 1)

        def _fill_daily(rows, value_key, default=0):
            """Rows -> {date: value} then fill in every missing day with default."""
            by_day = {r['period']: r[value_key] for r in rows}
            return [
                {'period': str(start_date + timedelta(days=i)),
                 value_key: by_day.get(start_date + timedelta(days=i), default)}
                for i in range(days)
            ]

        # ── Revenue Chart (daily, completed payments only) ────────────────
        revenue_rows = (
            Payment.objects.filter(status='completed', created_at__date__gte=start_date)
            .annotate(period=TruncDate('created_at'))
            .values('period').annotate(amount=Sum('amount')).order_by('period')
        )
        revenue_by_day = {r['period']: r['amount'] for r in revenue_rows}
        revenue_chart = [
            {'period': str(start_date + timedelta(days=i)),
             'amount': float(revenue_by_day.get(start_date + timedelta(days=i)) or 0)}
            for i in range(days)
        ]

        # ── Daily Bookings (same range) ────────────────────────────────────
        booking_rows = (
            Booking.objects.filter(created_at__date__gte=start_date)
            .annotate(period=TruncDate('created_at'))
            .values('period').annotate(count=Count('id')).order_by('period')
        )
        daily_bookings = _fill_daily(booking_rows, 'count')

        # ── Monthly Bookings (fixed last-12-months window) ─────────────────
        twelve_months_ago = date.today().replace(day=1) - timedelta(days=365)
        monthly_booking_rows = (
            Booking.objects.filter(created_at__date__gte=twelve_months_ago)
            .annotate(period=TruncMonth('created_at'))
            .values('period').annotate(count=Count('id')).order_by('period')
        )
        monthly_bookings = [
            {'period': r['period'].strftime('%Y-%m'), 'count': r['count']}
            for r in monthly_booking_rows
        ]

        # ── User Growth (new signups per month, split by role) ─────────────
        growth_rows = (
            User.objects.filter(created_at__date__gte=twelve_months_ago)
            .annotate(period=TruncMonth('created_at'))
            .values('period', 'role').annotate(count=Count('id')).order_by('period')
        )
        growth_map = {}
        for r in growth_rows:
            key = r['period'].strftime('%Y-%m')
            growth_map.setdefault(key, {'period': key, 'customers': 0, 'professionals': 0})
            if r['role'] == 'customer':
                growth_map[key]['customers'] = r['count']
            elif r['role'] == 'professional':
                growth_map[key]['professionals'] = r['count']
        user_growth = [growth_map[k] for k in sorted(growth_map.keys())]

        # ── Countries Distribution (top 10, by user profile) ───────────────
        country_rows = list(
            UserProfile.objects.exclude(country='')
            .values('country').annotate(count=Count('id')).order_by('-count')[:10]
        )
        total_with_country = sum(r['count'] for r in country_rows) or 1
        countries_distribution = [
            {'country': r['country'], 'count': r['count'],
             'percentage': round(r['count'] * 100 / total_with_country, 1)}
            for r in country_rows
        ]

        # ── Top Cities (top 10, by user profile) ───────────────────────────
        city_rows = (
            UserProfile.objects.exclude(city='')
            .values('city').annotate(count=Count('id')).order_by('-count')[:10]
        )
        top_cities = [{'city': r['city'], 'count': r['count']} for r in city_rows]

        # ── Top Categories (top 10, ranked by booking demand) ───────────────
        category_rows = (
            Booking.objects
            .exclude(professional__professionalprofile__category__isnull=True)
            .values('professional__professionalprofile__category__name')
            .annotate(count=Count('id')).order_by('-count')[:10]
        )
        top_categories = [
            {'category': r['professional__professionalprofile__category__name'], 'count': r['count']}
            for r in category_rows
            if r['professional__professionalprofile__category__name']
        ]

        # ── AI Analytics ────────────────────────────────────────────────────
        ai_search_rows = (
            SearchHistory.objects.filter(created_at__date__gte=start_date)
            .annotate(period=TruncDate('created_at'))
            .values('period').annotate(count=Count('id')).order_by('period')
        )
        ai_searches_trend = _fill_daily(ai_search_rows, 'count')

        top_queries = list(
            SearchHistory.objects.filter(created_at__date__gte=start_date)
            .values('query').annotate(count=Count('id')).order_by('-count')[:10]
        )

        # Conversion = users who searched AND made a booking in the same
        # window, as a % of everyone who searched. Approximate but real —
        # there's no direct search->booking FK link in the schema yet.
        searched_user_ids = set(
            SearchHistory.objects.filter(created_at__date__gte=start_date)
            .values_list('user_id', flat=True))
        booked_user_ids = set(
            Booking.objects.filter(created_at__date__gte=start_date)
            .values_list('customer_id', flat=True))
        converted = len(searched_user_ids & booked_user_ids)
        ai_conversion_rate = (
            round(converted * 100 / len(searched_user_ids), 1) if searched_user_ids else 0
        )

        ai_analytics = {
            'searches_trend':    ai_searches_trend,
            'top_queries':       top_queries,
            'total_searches':    sum(x['count'] for x in ai_searches_trend),
            'conversion_rate':   ai_conversion_rate,
        }

        # ── Platform Statistics (snapshot, no time range) ───────────────────
        platform_statistics = {
            'total_bookings_all_time': Booking.objects.count(),
            'completed_bookings':      Booking.objects.filter(status='completed').count(),
            'cancelled_bookings':      Booking.objects.filter(status='cancelled').count(),
            'total_searches_all_time': SearchHistory.objects.count(),
            'active_subscriptions':    Subscription.objects.filter(status='active').count(),
            'active_popup_ads':        PromoBanner.objects.filter(is_active=True).count(),
            'total_categories':        Category.objects.count(),
            'total_portfolio_items':   Portfolio.objects.count(),
            'total_reviews':           Review.objects.count(),
        }

        return Response({
            'range_days':               days,
            'revenue_chart':            revenue_chart,
            'user_growth':              user_growth,
            'daily_bookings':           daily_bookings,
            'monthly_bookings':         monthly_bookings,
            'countries_distribution':   countries_distribution,
            'top_cities':               top_cities,
            'top_categories':           top_categories,
            'ai_analytics':             ai_analytics,
            'platform_statistics':      platform_statistics,
        })




# ─── Business Management: Categories & Subcategories ──────────────────────────

class AdminCategoryView(APIView):
    """
    GET    /api/admin-panel/categories/           → list (with counts)
    POST   /api/admin-panel/categories/            → create
    PATCH  /api/admin-panel/categories/<id>/       → edit / reorder / hide
    DELETE /api/admin-panel/categories/<id>/       → delete (blocked if in use)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        from apps.search.models import Category, SubCategory
        from apps.profiles.models import ProfessionalProfile

        categories = Category.objects.filter(parent__isnull=True).order_by('order', 'name')
        data = []
        for c in categories:
            prof_count = ProfessionalProfile.objects.filter(category=c).count()
            booking_count = Booking.objects.filter(
                professional__professionalprofile__category=c).count()
            data.append({
                'id': c.id, 'name': c.name, 'icon': c.icon, 'order': c.order,
                'is_featured': c.is_featured,
                'professional_count': prof_count,
                'booking_count': booking_count,
                'subcategory_count': SubCategory.objects.filter(category=c).count(),
            })
        return Response(ContentTranslation.attach_rows('category', data))

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        from apps.search.models import Category
        name = request.data.get('name', '').strip()
        if not name:
            return Response({'error': 'Name is required.'}, status=400)
        c = Category.objects.create(
            name=name, icon=request.data.get('icon', ''),
            order=request.data.get('order', 99),
            is_featured=bool(request.data.get('is_featured', False)))
        AdminLog.objects.create(admin=request.user, action='create_banner',
                                note=f'Created category "{name}"')
        return Response({'id': c.id, 'name': c.name}, status=201)

    def patch(self, request, category_id=None):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        from apps.search.models import Category
        try:
            c = Category.objects.get(id=category_id)
        except Category.DoesNotExist:
            return Response({'error': 'Category not found.'}, status=404)

        if 'name' in request.data:
            c.name = request.data['name']
        if 'icon' in request.data:
            c.icon = request.data['icon']
        if 'order' in request.data:
            c.order = request.data['order']
        if 'is_featured' in request.data:
            c.is_featured = bool(request.data['is_featured'])
        c.save()
        return Response({'id': c.id, 'name': c.name, 'order': c.order, 'is_featured': c.is_featured})

    def delete(self, request, category_id=None):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        from apps.search.models import Category
        from apps.profiles.models import ProfessionalProfile
        try:
            c = Category.objects.get(id=category_id)
        except Category.DoesNotExist:
            return Response({'error': 'Category not found.'}, status=404)

        if ProfessionalProfile.objects.filter(category=c).exists():
            return Response(
                {'error': 'Cannot delete — professionals are still assigned to this category.'},
                status=400)
        c.delete()
        return Response({'message': 'Category deleted.'})


class AdminSubCategoryView(APIView):
    """
    GET    /api/admin-panel/subcategories/?category=<id>
    POST   /api/admin-panel/subcategories/
    PATCH  /api/admin-panel/subcategories/<id>/
    DELETE /api/admin-panel/subcategories/<id>/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        from apps.search.models import SubCategory

        subs = SubCategory.objects.select_related('category').all()
        category_id = request.query_params.get('category')
        if category_id:
            subs = subs.filter(category_id=category_id)

        return Response(ContentTranslation.attach_rows('subcategory', [
            {'id': s.id, 'name': s.name, 'category_id': s.category_id,
             'category_name': s.category.name}
            for s in subs
        ]))

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        from apps.search.models import Category, SubCategory
        name = request.data.get('name', '').strip()
        category_id = request.data.get('category_id')
        if not name or not category_id:
            return Response({'error': 'name and category_id are required.'}, status=400)
        try:
            category = Category.objects.get(id=category_id)
        except Category.DoesNotExist:
            return Response({'error': 'Parent category not found.'}, status=404)

        s = SubCategory.objects.create(name=name, category=category)
        return Response({'id': s.id, 'name': s.name}, status=201)

    def patch(self, request, subcategory_id=None):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        from apps.search.models import SubCategory
        try:
            s = SubCategory.objects.get(id=subcategory_id)
        except SubCategory.DoesNotExist:
            return Response({'error': 'Subcategory not found.'}, status=404)
        if 'name' in request.data:
            s.name = request.data['name']
        s.save()
        return Response({'id': s.id, 'name': s.name})

    def delete(self, request, subcategory_id=None):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        from apps.search.models import SubCategory
        try:
            s = SubCategory.objects.get(id=subcategory_id)
        except SubCategory.DoesNotExist:
            return Response({'error': 'Subcategory not found.'}, status=404)
        s.delete()
        return Response({'message': 'Subcategory deleted.'})


# ─── Business Management: Payments ─────────────────────────────────────────────

class AdminPaymentView(APIView):
    """
    GET /api/admin-panel/payments/?status=completed&search=email
    List + filter all payments — read-only listing (no bulk-delete, ever;
    financial records only ever get exported, never destroyed).
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        from apps.payments.models import Payment

        payments = Payment.objects.select_related('user').all().order_by('-created_at')

        status_filter = request.query_params.get('status')
        if status_filter:
            payments = payments.filter(status=status_filter)

        search = request.query_params.get('search', '').strip()
        if search:
            payments = payments.filter(user__email__icontains=search)

        return Response([
            {'id': p.id, 'user_name': p.user.name, 'user_email': p.user.email,
             'amount': str(p.amount), 'currency': p.currency,
             'status': p.status, 'stripe_id': p.stripe_id,
             'created_at': p.created_at.strftime('%Y-%m-%d %H:%M')}
            for p in payments[:500]
        ])


class AdminPaymentRefundView(APIView):
    """
    PATCH /api/admin-panel/payments/<id>/refund/
    Marks a completed payment as refunded. Requires a reason note for the
    audit trail — refunds are money-moving and must never be silent.
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, payment_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        from apps.payments.models import Payment
        try:
            payment = Payment.objects.get(id=payment_id)
        except Payment.DoesNotExist:
            return Response({'error': 'Payment not found.'}, status=404)

        if payment.status != 'completed':
            return Response({'error': 'Only completed payments can be refunded.'}, status=400)

        reason = request.data.get('reason', '').strip()
        if not reason:
            return Response({'error': 'A reason is required to process a refund.'}, status=400)

        # Trigger gateway refund if captured via PayPal
        if payment.paypal_capture_id:
            try:
                from apps.payments.paypal import refund_capture
                refund_capture(payment.paypal_capture_id, payment.amount, payment.currency, note=reason)
            except Exception as exc:
                logger.warning("PayPal gateway refund warning: %s", exc)

        payment.status = 'refunded'
        payment.save()

        # Update booking payment status and reverse ledger if applicable
        if payment.booking:
            payment.booking.payment_status = 'refunded'
            payment.booking.save(update_fields=['payment_status'])

            try:
                from apps.payments.models import WalletTransaction
                if WalletTransaction.objects.filter(booking=payment.booking, transaction_type='credit').exists():
                    WalletTransaction.objects.create(
                        user=payment.booking.professional,
                        transaction_type='refund',
                        amount=payment.booking.total_price,
                        currency=payment.booking.currency,
                        status='completed',
                        payment=payment,
                        booking=payment.booking,
                        description=f"Refund adjustment for booking #{payment.booking.id}: {reason}"
                    )
            except Exception as exc:
                logger.warning("Failed to record refund transaction on ledger: %s", exc)

        AdminLog.objects.create(admin=request.user, action='reject', target_user=payment.user,
                                note=f'Refunded payment #{payment.id}: {reason}')
        return Response({'message': 'Payment refunded.', 'status': payment.status})


# ─── Business Management: Revenue ──────────────────────────────────────────────

class AdminRevenueView(APIView):
    """
    GET /api/admin-panel/revenue/?days=30
    Dedicated Revenue reporting page — summary cards + category breakdown.
    (The Analytics section's revenue_chart covers the trend line; this
    endpoint covers the "how is revenue composed" breakdown table.)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        from datetime import date, timedelta
        from django.db.models import Sum, Count
        from apps.payments.models import Payment

        try:
            days = int(request.query_params.get('days', 30))
        except (TypeError, ValueError):
            days = 30
        days = max(7, min(days, 365))
        start_date = date.today() - timedelta(days=days - 1)
        prev_start = start_date - timedelta(days=days)

        current_total = Payment.objects.filter(
            status='completed', created_at__date__gte=start_date
        ).aggregate(total=Sum('amount'))['total'] or 0
        previous_total = Payment.objects.filter(
            status='completed', created_at__date__gte=prev_start,
            created_at__date__lt=start_date
        ).aggregate(total=Sum('amount'))['total'] or 0

        change_pct = (
            round((float(current_total) - float(previous_total)) * 100 / float(previous_total), 1)
            if previous_total else 0
        )

        avg_transaction = Payment.objects.filter(
            status='completed', created_at__date__gte=start_date
        ).aggregate(avg=models.Avg('amount'))['avg'] or 0

        # Revenue-by-category: join payment.user -> booking -> professional's category
        category_rows = (
            Payment.objects.filter(status='completed', created_at__date__gte=start_date)
            .exclude(user__bookings_made__professional__professionalprofile__category__isnull=True)
            .values('user__bookings_made__professional__professionalprofile__category__name')
            .annotate(total=Sum('amount'), count=Count('id'))
            .order_by('-total')[:10]
        )
        by_category = [
            {'category': r['user__bookings_made__professional__professionalprofile__category__name'],
             'total': str(r['total']), 'count': r['count']}
            for r in category_rows
            if r['user__bookings_made__professional__professionalprofile__category__name']
        ]

        return Response({
            'range_days':          days,
            'total_revenue':       str(current_total),
            'previous_revenue':    str(previous_total),
            'change_percentage':   change_pct,
            'avg_transaction':     str(round(float(avg_transaction), 2)),
            'by_category':         by_category,
        })


# ─── Business Management: Subscriptions (active user subscriptions) ───────────

class AdminSubscriptionsView(APIView):
    """
    GET /api/admin-panel/subscriptions/?status=active
    Actual per-user subscription records — distinct from the Plan-definition
    CRUD at /admin-panel/plans/ (that manages the plan catalog; this manages
    who's subscribed to what).
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        subs = Subscription.objects.select_related('user', 'plan').all()

        status_filter = request.query_params.get('status')
        if status_filter:
            subs = subs.filter(status=status_filter)

        return Response([
            {'id': s.id, 'user_name': s.user.name, 'user_email': s.user.email,
             'plan_name': s.plan.name, 'billing': s.plan.billing,
             'price': str(s.plan.price), 'status': s.status,
             'start_date': str(s.start_date.date()) if s.start_date else None,
             'end_date': str(s.end_date.date()) if s.end_date else None}
            for s in subs[:500]
        ])


class AdminSubscriptionActionView(APIView):
    """
    PATCH /api/admin-panel/subscriptions/<id>/
    Body: { "action": "cancel" | "extend", "days": 30 }
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, subscription_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            sub = Subscription.objects.get(id=subscription_id)
        except Subscription.DoesNotExist:
            return Response({'error': 'Subscription not found.'}, status=404)

        action = request.data.get('action')
        if action == 'cancel':
            sub.status = 'cancelled'
            sub.save()
            AdminLog.objects.create(admin=request.user, action='reject', target_user=sub.user,
                                    note=f'Cancelled subscription #{sub.id} ({sub.plan.name})')
        elif action == 'extend':
            from datetime import timedelta
            extend_days = int(request.data.get('days', 30))
            base = sub.end_date if sub.end_date and sub.end_date > timezone.now() else timezone.now()
            sub.end_date = base + timedelta(days=extend_days)
            sub.status = 'active'
            sub.save()
            AdminLog.objects.create(admin=request.user, action='approve', target_user=sub.user,
                                    note=f'Extended subscription #{sub.id} by {extend_days} days')
        else:
            return Response({'error': "action must be 'cancel' or 'extend'."}, status=400)

        return Response({'id': sub.id, 'status': sub.status,
                         'end_date': str(sub.end_date.date()) if sub.end_date else None})


# ─── Business Management: Reviews ──────────────────────────────────────────────

class AdminReviewView(APIView):
    """
    GET    /api/admin-panel/reviews/?rating=1&search=name
    DELETE /api/admin-panel/reviews/<id>/    (moderation only — never edit)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        from apps.reviews.models import Review

        reviews = Review.objects.select_related('reviewer', 'professional').all()

        rating = request.query_params.get('rating')
        if rating:
            reviews = reviews.filter(rating=rating)

        search = request.query_params.get('search', '').strip()
        if search:
            reviews = reviews.filter(professional__name__icontains=search)

        return Response([
            {'id': r.id, 'reviewer_name': r.reviewer.name,
             'professional_name': r.professional.name,
             'rating': r.rating, 'comment': r.comment,
             'created_at': r.created_at.strftime('%Y-%m-%d')}
            for r in reviews.order_by('-created_at')[:500]
        ])

    def delete(self, request, review_id=None):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        from apps.reviews.models import Review
        reason = request.data.get('reason', '').strip()
        if not reason:
            return Response({'error': 'A reason is required to delete a review.'}, status=400)
        try:
            review = Review.objects.get(id=review_id)
        except Review.DoesNotExist:
            return Response({'error': 'Review not found.'}, status=404)

        AdminLog.objects.create(
            admin=request.user, action='delete', target_user=review.professional,
            note=f'Deleted review #{review.id} by {review.reviewer.email}: {reason}')
        review.delete()
        return Response({'message': 'Review deleted.'})


# ─── Business Management: Complaints ───────────────────────────────────────────

class AdminComplaintView(APIView):
    """
    GET /api/admin-panel/complaints/?status=open
    Service/booking-dispute complaints — Open → In Progress → Resolved
    workflow (distinct from Reported Users' Trust&Safety flow).
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        complaints = Complaint.objects.select_related(
            'complainant', 'against', 'assigned_to', 'booking').all()

        status_filter = request.query_params.get('status')
        if status_filter:
            complaints = complaints.filter(status=status_filter)

        category_filter = request.query_params.get('category')
        if category_filter:
            complaints = complaints.filter(category=category_filter)

        return Response(ComplaintSerializer(complaints, many=True).data)


class AdminComplaintActionView(APIView):
    """
    PATCH /api/admin-panel/complaints/<id>/
    Body: { "status": "in_progress"|"resolved"|"rejected", "resolution_note": "..." }
    or    { "assign_to_me": true }
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, complaint_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            complaint = Complaint.objects.get(id=complaint_id)
        except Complaint.DoesNotExist:
            return Response({'error': 'Complaint not found.'}, status=404)

        if request.data.get('assign_to_me'):
            complaint.assigned_to = request.user
            if complaint.status == 'open':
                complaint.status = 'in_progress'
            complaint.save()
            return Response(ComplaintSerializer(complaint).data)

        new_status = request.data.get('status')
        if new_status:
            valid = dict(Complaint.STATUS_CHOICES)
            if new_status not in valid:
                return Response({'error': 'Invalid status.'}, status=400)
            complaint.status = new_status
            complaint.resolution_note = request.data.get(
                'resolution_note', complaint.resolution_note)
            if new_status in ('resolved', 'rejected'):
                complaint.resolved_at = timezone.now()
            complaint.save()
            AdminLog.objects.create(
                admin=request.user, action='reject' if new_status == 'rejected' else 'approve',
                target_user=complaint.against,
                note=f'Complaint #{complaint.id} marked "{valid[new_status]}"')

        return Response(ComplaintSerializer(complaint).data)


# ─── Business Management: Reports (export hub) ─────────────────────────────────

class AdminReportsView(APIView):
    """
    GET /api/admin-panel/reports-hub/?type=revenue&days=30
    A lightweight report-data launcher — returns the raw rows for a chosen
    report type; the frontend turns this into a CSV/PDF download, same
    pattern already used by the Users/Professionals/Customers "Export"
    buttons (client-side generation, no extra backend file-storage needed).

    type: revenue | users | bookings | subscriptions
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        from datetime import date, timedelta
        report_type = request.query_params.get('type', 'revenue')
        try:
            days = int(request.query_params.get('days', 30))
        except (TypeError, ValueError):
            days = 30
        start_date = date.today() - timedelta(days=days - 1)

        if report_type == 'revenue':
            from apps.payments.models import Payment
            rows = Payment.objects.filter(
                status='completed', created_at__date__gte=start_date
            ).select_related('user').order_by('-created_at')
            data = [{'date': str(p.created_at.date()), 'user': p.user.email,
                     'amount': str(p.amount), 'currency': p.currency} for p in rows[:1000]]

        elif report_type == 'users':
            users = User.objects.filter(
                created_at__date__gte=start_date).exclude(role='admin')
            data = [{'name': u.name, 'email': u.email, 'role': u.role,
                     'joined': str(u.created_at.date())} for u in users[:1000]]

        elif report_type == 'bookings':
            rows = Booking.objects.filter(
                created_at__date__gte=start_date
            ).select_related('customer', 'professional')
            data = [{'date': str(b.date), 'customer': b.customer.email,
                     'professional': b.professional.email, 'status': b.status}
                    for b in rows[:1000]]

        elif report_type == 'subscriptions':
            subs = Subscription.objects.filter(
                start_date__date__gte=start_date).select_related('user', 'plan')
            data = [{'user': s.user.email, 'plan': s.plan.name, 'status': s.status,
                     'start_date': str(s.start_date.date())} for s in subs[:1000]]

        else:
            return Response({'error': 'Invalid report type.'}, status=400)

        return Response({'type': report_type, 'range_days': days, 'rows': data})


# ─── Content Management: Notifications (admin broadcast) ──────────────────────

def _audience_queryset(audience, specific_user_id=None):
    """Resolve an audience choice into an actual User queryset."""
    qs = User.objects.exclude(role='admin').filter(is_active=True)
    if audience == 'customers':
        return qs.filter(role='customer')
    if audience == 'professionals':
        return qs.filter(role='professional')
    if audience == 'specific':
        return qs.filter(id=specific_user_id) if specific_user_id else qs.none()
    return qs  # 'all'


class AdminNotificationView(APIView):
    """
    GET  /api/admin-panel/notifications/          → broadcast history
    POST /api/admin-panel/notifications/           → compose new broadcast
      Body: { "title", "message", "audience": "all"|"customers"|"professionals"|"specific",
              "specific_user_id": <id, if audience=specific>,
              "scheduled_at": "2026-07-10T10:00:00Z"  (optional — omit to send now) }
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        broadcasts = NotificationBroadcast.objects.select_related(
            'specific_user', 'created_by').all()
        status_filter = request.query_params.get('status')
        if status_filter:
            broadcasts = broadcasts.filter(status=status_filter)
        return Response(ContentTranslation.attach_rows(
            'notificationbroadcast', NotificationBroadcastSerializer(broadcasts, many=True).data))

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)

        title   = request.data.get('title', '').strip()
        message = request.data.get('message', '').strip()
        audience = request.data.get('audience', 'all')
        if not title or not message:
            return Response({'error': 'title and message are required.'}, status=400)
        if audience not in dict(NotificationBroadcast.AUDIENCE_CHOICES):
            return Response({'error': 'Invalid audience.'}, status=400)

        specific_user = None
        if audience == 'specific':
            specific_user_id = request.data.get('specific_user_id')
            try:
                specific_user = User.objects.get(id=specific_user_id)
            except (User.DoesNotExist, TypeError, ValueError):
                return Response({'error': 'specific_user_id is required and must be valid.'}, status=400)

        scheduled_at_raw = request.data.get('scheduled_at')
        broadcast = NotificationBroadcast.objects.create(
            title=title, message=message, audience=audience,
            specific_user=specific_user, created_by=request.user,
            scheduled_at=scheduled_at_raw or None,
            status='scheduled' if scheduled_at_raw else 'scheduled',
        )

        # Translations create ke saath hi (optional): "Send Now" turant dispatch hota
        # hai, to baad mein PUT karne tak intezar nahi ho sakta.
        _apply_inline_translations(
            'notificationbroadcast', broadcast.id, request.data.get('translations'))

        if not scheduled_at_raw:
            # "Send Now" — dispatch immediately, no cron needed.
            _dispatch_broadcast(broadcast)

        return Response(NotificationBroadcastSerializer(broadcast).data, status=201)


class AdminNotificationCancelView(APIView):
    """
    PATCH /api/admin-panel/notifications/<id>/cancel/
    Cancels a broadcast that hasn't been sent yet. Once sent, it's locked —
    a broadcast can't be un-sent, so this only works on 'scheduled' ones.
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, broadcast_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            broadcast = NotificationBroadcast.objects.get(id=broadcast_id)
        except NotificationBroadcast.DoesNotExist:
            return Response({'error': 'Broadcast not found.'}, status=404)

        if broadcast.status != 'scheduled':
            return Response({'error': 'Only scheduled (unsent) broadcasts can be cancelled.'}, status=400)

        broadcast.status = 'cancelled'
        broadcast.save()
        return Response(NotificationBroadcastSerializer(broadcast).data)


def _dispatch_broadcast(broadcast):
    """
    Fans a NotificationBroadcast out into individual Notification rows +
    real FCM push (via the existing notify_user helper), then marks the
    broadcast as sent. Used both by "Send Now" and by the
    `send_scheduled_broadcasts` management command.
    """
    users = _audience_queryset(
        broadcast.audience,
        broadcast.specific_user_id if broadcast.audience == 'specific' else None)

    translations = ContentTranslation.for_object('notificationbroadcast', broadcast.id)

    count = 0
    for user in users:
        try:
            tr = translations.get(normalize_lang(user.preferred_language) or '', {})
            notify_user(user, tr.get('title') or broadcast.title,
                        tr.get('message') or broadcast.message,
                        notif_type='general', push_kind='admin')
            count += 1
        except Exception:
            pass  # one bad user shouldn't fail the whole broadcast

    broadcast.status     = 'sent' if count else 'failed'
    broadcast.sent_at     = timezone.now()
    broadcast.sent_count = count
    broadcast.save()
    return count


# ─── Content Management: Languages ─────────────────────────────────────────────

class AdminLanguageView(APIView):
    """
    GET  /api/admin-panel/languages/            → list, with completion %
    POST /api/admin-panel/languages/             { name, code, is_rtl }
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        return Response(LanguageSerializer(Language.objects.all(), many=True).data)

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        name = request.data.get('name', '').strip()
        code = request.data.get('code', '').strip().lower()
        if not name or not code:
            return Response({'error': 'name and code are required.'}, status=400)
        if Language.objects.filter(code=code).exists():
            return Response({'error': f'Language code "{code}" already exists.'}, status=400)

        language = Language.objects.create(
            name=name, code=code, is_rtl=request.data.get('is_rtl', False),
            status='beta')  # new languages always start as beta, never active
        return Response(LanguageSerializer(language).data, status=201)


class AdminLanguageDetailView(APIView):
    """
    PATCH  /api/admin-panel/languages/<id>/    { status: active|beta|disabled }
    DELETE /api/admin-panel/languages/<id>/
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, language_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            language = Language.objects.get(id=language_id)
        except Language.DoesNotExist:
            return Response({'error': 'Language not found.'}, status=404)

        new_status = request.data.get('status')
        if new_status not in dict(Language.STATUS_CHOICES):
            return Response({'error': 'Invalid status.'}, status=400)

        if new_status == 'active':
            total = TranslationKey.objects.count()
            translated = TranslationString.objects.filter(
                language=language).exclude(text='').count()
            if total == 0 or translated < total:
                return Response({
                    'error': f'Cannot activate — only {translated}/{total} strings translated. '
                             f'A language must be 100% translated before going Active.',
                }, status=400)

        language.status = new_status
        language.save()
        return Response(LanguageSerializer(language).data)

    def delete(self, request, language_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            language = Language.objects.get(id=language_id)
        except Language.DoesNotExist:
            return Response({'error': 'Language not found.'}, status=404)
        language.delete()
        return Response({'message': 'Language deleted.'})


class AdminTranslationView(APIView):
    """
    Translation editor for one language — every TranslationKey paired with
    that language's current text (blank if not yet translated).

    GET   /api/admin-panel/languages/<id>/translations/
    PATCH /api/admin-panel/languages/<id>/translations/
      Body: { "translations": { "<key_id>": "translated text", ... } }
      (bulk upsert — only keys present in the payload are touched)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, language_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            language = Language.objects.get(id=language_id)
        except Language.DoesNotExist:
            return Response({'error': 'Language not found.'}, status=404)

        existing = {t.key_id: t.text for t in
                    TranslationString.objects.filter(language=language)}
        rows = [
            {'key_id': k.id, 'key': k.key, 'description': k.description,
             'text': existing.get(k.id, '')}
            for k in TranslationKey.objects.all()
        ]
        return Response({'language': LanguageSerializer(language).data, 'rows': rows})

    def patch(self, request, language_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            language = Language.objects.get(id=language_id)
        except Language.DoesNotExist:
            return Response({'error': 'Language not found.'}, status=404)

        updates = request.data.get('translations', {})
        if not isinstance(updates, dict):
            return Response({'error': 'translations must be an object of {key_id: text}.'}, status=400)

        saved = 0
        for key_id, text in updates.items():
            try:
                key = TranslationKey.objects.get(id=key_id)
            except (TranslationKey.DoesNotExist, ValueError):
                continue
            TranslationString.objects.update_or_create(
                language=language, key=key, defaults={'text': text})
            saved += 1

        return Response({'message': f'{saved} translation(s) saved.'})


class AdminTranslationKeyView(APIView):
    """
    Manage the master list of translatable keys (language-independent).
    GET  /api/admin-panel/translation-keys/
    POST /api/admin-panel/translation-keys/   { key, description }
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        keys = TranslationKey.objects.all()
        return Response([
            {'id': k.id, 'key': k.key, 'description': k.description} for k in keys
        ])

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        key = request.data.get('key', '').strip()
        if not key:
            return Response({'error': 'key is required.'}, status=400)
        if TranslationKey.objects.filter(key=key).exists():
            return Response({'error': 'This key already exists.'}, status=400)
        obj = TranslationKey.objects.create(
            key=key, description=request.data.get('description', ''))
        return Response({'id': obj.id, 'key': obj.key, 'description': obj.description}, status=201)


# ─── Content Management: Countries ─────────────────────────────────────────────

class AdminCountryView(APIView):
    """
    GET  /api/admin-panel/countries/          → list, with user/professional/city counts
    POST /api/admin-panel/countries/           { name, status }
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        return Response(CountrySerializer(Country.objects.all(), many=True).data)

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        name = request.data.get('name', '').strip()
        if not name:
            return Response({'error': 'name is required.'}, status=400)
        if Country.objects.filter(name__iexact=name).exists():
            return Response({'error': f'"{name}" already exists.'}, status=400)
        country = Country.objects.create(
            name=name, status=request.data.get('status', 'coming_soon'))
        return Response(CountrySerializer(country).data, status=201)


class AdminCountryDetailView(APIView):
    """
    PATCH  /api/admin-panel/countries/<id>/   { status }
    DELETE /api/admin-panel/countries/<id>/
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, country_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            country = Country.objects.get(id=country_id)
        except Country.DoesNotExist:
            return Response({'error': 'Country not found.'}, status=404)
        new_status = request.data.get('status')
        if new_status not in dict(Country.STATUS_CHOICES):
            return Response({'error': 'Invalid status.'}, status=400)
        country.status = new_status
        country.save()
        return Response(CountrySerializer(country).data)

    def delete(self, request, country_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            country = Country.objects.get(id=country_id)
        except Country.DoesNotExist:
            return Response({'error': 'Country not found.'}, status=404)
        country.delete()
        return Response({'message': 'Country deleted.'})


class AdminCountryMergeView(APIView):
    """
    Data-hygiene tool: rewrites every UserProfile.country typo/variant
    (e.g. "pakistan", "Pakistn") into the canonical Country.name — this is
    the single most valuable action on this page (see design spec).

    POST /api/admin-panel/countries/<id>/merge/
      Body: { "variants": ["pakistan", "Pakistn"] }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, country_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            country = Country.objects.get(id=country_id)
        except Country.DoesNotExist:
            return Response({'error': 'Country not found.'}, status=404)

        variants = request.data.get('variants', [])
        if not isinstance(variants, list) or not variants:
            return Response({'error': 'variants must be a non-empty list.'}, status=400)

        from apps.profiles.models import UserProfile
        updated = 0
        for variant in variants:
            updated += UserProfile.objects.filter(
                country__iexact=variant).update(country=country.name)

        return Response({'message': f'{updated} profile(s) normalized to "{country.name}".'})


# ─── Content Management: Cities ────────────────────────────────────────────────

class AdminCityView(APIView):
    """
    GET  /api/admin-panel/cities/?country=<id>
    POST /api/admin-panel/cities/    { name, country, status }
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        cities = City.objects.select_related('country').all()
        country_id = request.query_params.get('country')
        if country_id:
            cities = cities.filter(country_id=country_id)
        return Response(CitySerializer(cities, many=True).data)

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        name = request.data.get('name', '').strip()
        country_id = request.data.get('country')
        if not name or not country_id:
            return Response({'error': 'name and country are required.'}, status=400)
        try:
            country = Country.objects.get(id=country_id)
        except Country.DoesNotExist:
            return Response({'error': 'Country not found.'}, status=404)
        if City.objects.filter(name__iexact=name, country=country).exists():
            return Response({'error': f'"{name}" already exists in {country.name}.'}, status=400)
        city = City.objects.create(
            name=name, country=country, status=request.data.get('status', 'coming_soon'))
        return Response(CitySerializer(city).data, status=201)


class AdminCityDetailView(APIView):
    """
    PATCH  /api/admin-panel/cities/<id>/   { status }
    DELETE /api/admin-panel/cities/<id>/
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, city_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            city = City.objects.get(id=city_id)
        except City.DoesNotExist:
            return Response({'error': 'City not found.'}, status=404)
        new_status = request.data.get('status')
        if new_status not in dict(City.STATUS_CHOICES):
            return Response({'error': 'Invalid status.'}, status=400)
        city.status = new_status
        city.save()
        return Response(CitySerializer(city).data)

    def delete(self, request, city_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            city = City.objects.get(id=city_id)
        except City.DoesNotExist:
            return Response({'error': 'City not found.'}, status=404)
        city.delete()
        return Response({'message': 'City deleted.'})


class AdminCityMergeView(APIView):
    """Same data-hygiene pattern as AdminCountryMergeView, for city typos."""
    permission_classes = [IsAuthenticated]

    def post(self, request, city_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            city = City.objects.get(id=city_id)
        except City.DoesNotExist:
            return Response({'error': 'City not found.'}, status=404)

        variants = request.data.get('variants', [])
        if not isinstance(variants, list) or not variants:
            return Response({'error': 'variants must be a non-empty list.'}, status=400)

        from apps.profiles.models import UserProfile
        updated = 0
        for variant in variants:
            updated += UserProfile.objects.filter(
                city__iexact=variant).update(city=city.name)

        return Response({'message': f'{updated} profile(s) normalized to "{city.name}".'})


def _apply_inline_translations(label, object_id, payload):
    """
    Create-time translations, language *code* se keyed:
      { "ur": {"title": "..", "message": ".."}, "ar": {...} }
    Anjaan code / galat shape / khali text chupchap skip hota hai — main create
    kabhi isi wajah se fail nahi hota.
    """
    if not isinstance(payload, dict):
        return
    fields = TRANSLATABLE_FIELDS.get(label, ())
    languages = {l.code.lower(): l for l in Language.objects.all()}
    for code, values in payload.items():
        language = languages.get(normalize_lang(code) or '')
        if language is None or not isinstance(values, dict):
            continue
        for f in fields:
            text = str(values.get(f) or '').strip()
            if text:
                ContentTranslation.objects.update_or_create(
                    model_label=label, object_id=object_id,
                    language=language, field=f, defaults={'text': text})


# ─── Content Management: Announcements ─────────────────────────────────────────

def _push_announcement(announcement):
    """
    Announcement ki audience ko real FCM push bhejta hai.
    Background thread mein chalta hai taake admin ki request 94+ FCM calls
    ka intezar na kare. Sirf unhe jati hai jinka fcm_token DB mein hai.
    """
    log = logging.getLogger(__name__)
    try:
        qs = User.objects.exclude(role='admin').filter(
            is_active=True, fcm_token__isnull=False).exclude(fcm_token='')
        if announcement.audience == 'customers':
            qs = qs.filter(role='customer')
        elif announcement.audience == 'professionals':
            qs = qs.filter(role='professional')

        tokens = list(qs.values_list('fcm_token', 'preferred_language'))
        translations = ContentTranslation.for_object('announcement', announcement.id)
        ok = 0
        for token, pref_lang in tokens:
            lang = normalize_lang(pref_lang) or 'en'
            tr = translations.get(lang, {})
            title = tr.get('title') or announcement.title
            body = tr.get('message') or announcement.message
            if send_fcm_push(token, style_push_title('announcement', title, lang),
                             body, data={'type': 'announcement'}):
                ok += 1
        log.info('[FCM] announcement %s push: %s/%s sent',
                 announcement.id, ok, len(tokens))
    except Exception:
        log.exception('[FCM] announcement push failed')
    finally:
        close_old_connections()


class AdminAnnouncementView(APIView):
    """
    GET  /api/admin-panel/announcements/?active=true
    POST /api/admin-panel/announcements/
      { title, message, type, audience, start_date, end_date }
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        announcements = Announcement.objects.all()
        active_only = request.query_params.get('active')
        if active_only == 'true':
            announcements = announcements.filter(is_active=True)
        return Response(ContentTranslation.attach_rows(
            'announcement', AnnouncementSerializer(announcements, many=True).data))

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        title   = request.data.get('title', '').strip()
        message = request.data.get('message', '').strip()
        if not title or not message:
            return Response({'error': 'title and message are required.'}, status=400)
        announcement_type = request.data.get('type', 'info')
        if announcement_type not in dict(Announcement.TYPE_CHOICES):
            return Response({'error': 'Invalid type.'}, status=400)

        announcement = Announcement.objects.create(
            title=title, message=message, type=announcement_type,
            audience=request.data.get('audience', 'all'),
            start_date=request.data.get('start_date') or None,
            end_date=request.data.get('end_date') or None,
            created_by=request.user,
        )

        # Optional create-time translations: {"ur": {"title": .., "message": ..}, ...}
        # (push thread start hone se pehle save — taake push bhi receiver ki zabaan mein jaye)
        _apply_inline_translations(
            'announcement', announcement.id, request.data.get('translations'))

        # Push sirf tab jab announcement abhi se live ho (future start_date ho to skip)
        now = timezone.now()
        if announcement.is_active and (
                announcement.start_date is None or announcement.start_date <= now):
            threading.Thread(
                target=_push_announcement, args=(announcement,), daemon=True
            ).start()

        return Response(AnnouncementSerializer(announcement).data, status=201)


class AdminAnnouncementDetailView(APIView):
    """
    PATCH  /api/admin-panel/announcements/<id>/   { is_active, ... any field }
    DELETE /api/admin-panel/announcements/<id>/
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, announcement_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            announcement = Announcement.objects.get(id=announcement_id)
        except Announcement.DoesNotExist:
            return Response({'error': 'Announcement not found.'}, status=404)

        for field in ['title', 'message', 'type', 'audience', 'is_active', 'start_date', 'end_date']:
            if field in request.data:
                setattr(announcement, field, request.data[field])
        announcement.save()
        return Response(AnnouncementSerializer(announcement).data)

    def delete(self, request, announcement_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin only.'}, status=403)
        try:
            announcement = Announcement.objects.get(id=announcement_id)
        except Announcement.DoesNotExist:
            return Response({'error': 'Announcement not found.'}, status=404)
        announcement.delete()
        return Response({'message': 'Announcement deleted.'})


class ActiveAnnouncementView(APIView):
    """
    Public, no-auth endpoint the Flutter app calls from Guest/Customer/
    Professional home screens to fetch the announcements that should be
    showing right now — mirrors the exact same pattern as
    ActivePromoBannerView (audience + schedule window filtering), just for
    Announcement instead of PromoBanner.
    GET /api/admin-panel/announcements/active/?audience=customer
    audience: 'guest' (default) | 'customer' | 'professional'
      - 'guest'        → only audience='all' announcements
      - 'customer'     → audience in {'all', 'customers'}
      - 'professional' → audience in {'all', 'professionals'}
    """
    permission_classes = [AllowAny]

    def get(self, request):
        audience = request.query_params.get('audience', 'guest')
        now = timezone.now()

        allowed_audiences = {'all'}
        if audience == 'customer':
            allowed_audiences.add('customers')
        elif audience == 'professional':
            allowed_audiences.add('professionals')
        # 'guest' (or anything unrecognized) → stays {'all'} only

        announcements = Announcement.objects.filter(
            is_active=True,
            audience__in=list(allowed_audiences),
        ).filter(
            models.Q(start_date__isnull=True) | models.Q(start_date__lte=now)
        ).filter(
            models.Q(end_date__isnull=True) | models.Q(end_date__gte=now)
        ).order_by('-created_at')

        return Response({
            'active': announcements.exists(),
            'announcements': ContentTranslation.localize_rows(
                'announcement', AnnouncementSerializer(announcements, many=True).data,
                request.query_params.get('lang')),
        })


# ─── Content translations (generic admin endpoint) ───────────────────────────

def _translatable_model(label):
    """label → parent model class (search app lazy import — cycle se bachne ke liye)."""
    if label in ('category', 'subcategory'):
        from apps.search.models import Category, SubCategory
        return {'category': Category, 'subcategory': SubCategory}[label]
    return {'announcement': Announcement, 'promobanner': PromoBanner,
            'notificationbroadcast': NotificationBroadcast}.get(label)


class ContentTranslationAdminView(APIView):
    """
    PUT    /api/admin-panel/translations/<label>/<object_id>/<language_id>/
           { "title": "...", "message": "..." }
           Sirf bheje gaye fields touch hote hain; khali string us field ki
           translation hata deti hai (base text wapas dikhega).
    DELETE same URL → us language ki poori translation hat jati hai.
    label: 'announcement' | 'promobanner' | 'category' | 'subcategory' | 'notificationbroadcast'
    """
    permission_classes = [IsAuthenticated]

    def _resolve(self, request, label, object_id, language_id):
        if not _is_admin(request.user):
            return None, Response({'error': 'Admin only.'}, status=403)
        model = _translatable_model(label)
        if model is None or label not in TRANSLATABLE_FIELDS:
            return None, Response({'error': f'"{label}" is not translatable.'}, status=400)
        if not model.objects.filter(pk=object_id).exists():
            return None, Response({'error': 'Item not found.'}, status=404)
        try:
            return Language.objects.get(pk=language_id), None
        except Language.DoesNotExist:
            return None, Response({'error': 'Language not found.'}, status=404)

    def put(self, request, label, object_id, language_id):
        language, err = self._resolve(request, label, object_id, language_id)
        if err:
            return err
        with transaction.atomic():
            for f in TRANSLATABLE_FIELDS[label]:
                if f not in request.data:
                    continue
                text = str(request.data.get(f) or '').strip()
                lookup = dict(model_label=label, object_id=object_id,
                              language=language, field=f)
                if text:
                    ContentTranslation.objects.update_or_create(
                        defaults={'text': text}, **lookup)
                else:
                    ContentTranslation.objects.filter(**lookup).delete()
        row = ContentTranslation.attach_rows(label, [{'id': object_id}])[0]
        current = next(
            (t for t in row['translations'] if t['language'] == language.id),
            {'language': language.id, 'language_code': language.code})
        return Response(current)

    def delete(self, request, label, object_id, language_id):
        language, err = self._resolve(request, label, object_id, language_id)
        if err:
            return err
        ContentTranslation.objects.filter(
            model_label=label, object_id=object_id, language=language).delete()
        return Response({'message': 'Translation removed — base text will show instead.'})