# PATH: backend/apps/bookings/views.py
# apps/bookings/views.py

import logging
from datetime import date
from django.db.models import Q
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from apps.bookings.models import Booking
from apps.bookings.serializers import BookingSerializer
from apps.users.models import User
from apps.notifications.utils import notify_user
from apps.subscriptions.utils import check_booking_limit, get_booking_limit, get_bookings_this_month

logger = logging.getLogger(__name__)


def _notify(user, title, message, notif_type='general'):
    notify_user(user, title, message, notif_type=notif_type)


def _booking_detail(booking):
    time_str = booking.time.strftime('%I:%M %p') if booking.time else ''
    date_str = booking.date.strftime('%d %B %Y') if booking.date else ''
    return f"Booking #{booking.id} | {date_str} at {time_str}"


# ─── Customer Booking View ────────────────────────────────────────────────────

class BookingView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        bookings = Booking.objects.filter(
            customer=request.user
        ).select_related(
            'professional__professionalprofile__category',
            'professional__userprofile',
        ).order_by('-created_at')
        return Response(BookingSerializer(bookings, many=True).data)

    def post(self, request):
        professional_id = request.data.get('professional')

        if not professional_id:
            return Response({'error': 'professional field is required.'},
                            status=status.HTTP_400_BAD_REQUEST)

        try:
            professional = User.objects.get(id=professional_id, role='professional')
        except User.DoesNotExist:
            return Response({'error': f'Professional not found (id={professional_id}).'},
                            status=status.HTTP_404_NOT_FOUND)

        if request.user.id == professional.id:
            return Response({'error': 'You cannot book yourself.'},
                            status=status.HTTP_400_BAD_REQUEST)

        if Booking.objects.filter(
            customer=request.user,
            professional=professional,
            status='pending'
        ).exists():
            return Response(
                {'error': 'You already have a pending booking with this professional.'},
                status=status.HTTP_400_BAD_REQUEST)

        # ── Professional ka booking limit check (DB se, monthly) ─────────
        allowed, used, limit, sub_end_date = check_booking_limit(professional)

        if not allowed:
            return Response({
                'error':            'booking_limit_reached',
                'message':          (
                    f"This professional has reached their free plan limit "
                    f"({limit} bookings/month). They need to upgrade to Premium."
                ),
                'limit':            limit,
                'used_this_month':  used,
                'subscription_end': sub_end_date,
                'upgrade':          True,
            }, status=status.HTTP_403_FORBIDDEN)

        # ── Booking create ────────────────────────────────────────────────
        serializer = BookingSerializer(data=request.data)
        if serializer.is_valid():
            booking = serializer.save(
                customer=request.user,
                professional=professional,
                status='pending'
            )
            _notify(
                user=professional,
                title='New Booking Request 📅',
                message=(
                    f'{request.user.name} has booked you.\n'
                    f'{_booking_detail(booking)}'
                ),
            )
            return Response(BookingSerializer(booking).data,
                            status=status.HTTP_201_CREATED)

        return Response({'error': serializer.errors},
                        status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, booking_id):
        try:
            booking = Booking.objects.get(id=booking_id, customer=request.user)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found.'}, status=404)

        if booking.status != 'pending':
            return Response(
                {'error': f"Cannot cancel. Booking is already '{booking.status}'."},
                status=400)

        reason = request.data.get('cancel_reason', '').strip()
        booking.status        = 'cancelled'
        booking.cancel_reason = reason
        booking.cancelled_by  = 'customer'
        booking.save()

        detail      = _booking_detail(booking)
        reason_line = f'\nReason: {reason}' if reason else ''

        _notify(booking.professional,
                'Booking Cancelled by Customer ❌',
                f'{booking.customer.name} has cancelled their booking.\n{detail}{reason_line}')

        for admin in User.objects.filter(role='admin'):
            _notify(admin, 'Booking Cancelled ❌',
                    f'Customer: {booking.customer.name}\n'
                    f'Professional: {booking.professional.name}\n'
                    f'{detail}{reason_line}\nCancelled by: Customer')

        return Response(BookingSerializer(booking).data)


# ─── Professional Dashboard View ──────────────────────────────────────────────
# Ek single API call — poore Professional Home Dashboard ke liye zaroori
# saara data ek saath deta hai (header, earnings, stats, recent bookings).
# Multiple alag calls ki jagah ek call = fast load, kam network overhead.

class ProfessionalDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        # ── Lazy imports — circular-import se bachne ke liye ──────────────
        from apps.profiles.models import ProfessionalProfile
        from apps.reviews.models import Review
        from apps.notifications.models import Notification

        # ── Profile info (header ke liye) ─────────────────────────────────
        try:
            profile = ProfessionalProfile.objects.get(user=user)
            hourly_rate = float(profile.hourly_rate or 0)
            is_verified = profile.is_verified
            photo_url   = profile.photo_url.url if profile.photo_url else None
            avg_rating  = float(profile.average_rating or 0)
        except ProfessionalProfile.DoesNotExist:
            hourly_rate = 0
            is_verified = False
            photo_url   = None
            avg_rating  = 0.0

        # ── Bookings ────────────────────────────────────────────────────
        bookings = Booking.objects.filter(professional=user)
        today    = date.today()

        completed_qs = bookings.filter(status='completed')

        # NOTE: Booking model mein abhi tak koi per-job price field nahi hai,
        # is liye hum ProfessionalProfile.hourly_rate ko har completed booking
        # ki "value" maan kar earnings calculate kar rahe hain. Jab aap
        # Booking mein 'total_price' field add karenge, ye calculation
        # us field ko use karne lagegi (aur zyada accurate ho jayegi).
        today_earnings = completed_qs.filter(date=today).count() * hourly_rate
        month_earnings = completed_qs.filter(
            date__year=today.year, date__month=today.month
        ).count() * hourly_rate
        total_earnings = completed_qs.count() * hourly_rate

        stats = {
            'total_bookings':     bookings.count(),
            'pending_bookings':   bookings.filter(status='pending').count(),
            'accepted_bookings':  bookings.filter(status='accepted').count(),
            'completed_bookings': completed_qs.count(),
        }

        # ── Rating ──────────────────────────────────────────────────────
        total_reviews = Review.objects.filter(professional=user).count()

        # ── Notifications ───────────────────────────────────────────────
        unread_notifications = Notification.objects.filter(user=user, is_read=False).count()

        # ── Recent bookings (dashboard preview ke liye, max 5) ─────────
        recent = bookings.order_by('-created_at')[:5]

        return Response({
            'header': {
                'name':        user.name,
                'photo_url':   photo_url,
                'is_verified': is_verified,
            },
            'unread_notifications': unread_notifications,
            'earnings': {
                'today': today_earnings,
                'month': month_earnings,
                'total': total_earnings,
            },
            'stats': stats,
            'rating': {
                'average':       avg_rating,
                'total_reviews': total_reviews,
            },
            'recent_bookings': BookingSerializer(recent, many=True).data,
        })


# ─── Professional Booking View ────────────────────────────────────────────────

class ProfessionalBookingView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        bookings = Booking.objects.filter(
            professional=request.user).order_by('-created_at')

        # ✅ FIX: '?search=' query param pehle bilkul ignore ho raha tha —
        # Flutter naam se search karta tha lekin backend hamesha SAARI
        # bookings wapas bhej deta tha. Ab customer ke naam/email se filter hota hai.
        search = request.query_params.get('search', '').strip()
        if search:
            bookings = bookings.filter(
                Q(customer__name__icontains=search) |
                Q(customer__email__icontains=search)
            )

        # Plan info bhi saath bhejo — Flutter dialog dikhane ke liye
        limit        = get_booking_limit(request.user)
        used         = get_bookings_this_month(request.user)
        limit_reached = (limit > 0 and used >= limit)

        _, _, _, sub_end_date = check_booking_limit(request.user)

        return Response({
            'bookings':         BookingSerializer(bookings, many=True).data,
            'plan_info': {
                'booking_limit':   limit,       # 0 = unlimited
                'used_this_month': used,
                'limit_reached':   limit_reached,
                'subscription_end':sub_end_date,
                'remaining':       max(0, limit - used) if limit > 0 else None,
            }
        })

    def patch(self, request, booking_id):
        try:
            booking = Booking.objects.get(id=booking_id, professional=request.user)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found.'}, status=404)

        new_status = request.data.get('status')

        if booking.status != 'pending' and new_status in ['accepted', 'rejected']:
            return Response(
                {'error': f"Booking is already '{booking.status}'."},
                status=400)

        if new_status not in ['accepted', 'rejected', 'completed', 'cancelled']:
            return Response({'error': 'Invalid status.'}, status=400)

        # ✅ FIX: 'completed' ke liye koi state check nahi tha — professional
        # ek 'pending' ya 'rejected' booking ko bhi seedha 'completed' mark
        # kar sakta tha (API se direct), jo earnings/stats ko galat calculate
        # kar deta (ProfessionalDashboardView completed-status count pe based
        # hai). Ab sirf 'accepted' booking hi complete ho sakti hai.
        if new_status == 'completed' and booking.status != 'accepted':
            return Response(
                {'error': f"Cannot mark as completed. Booking must be 'accepted' first (currently '{booking.status}')."},
                status=400)

        if new_status == 'cancelled' and booking.status in ['completed', 'cancelled', 'rejected']:
            return Response(
                {'error': f"Cannot cancel. Booking is already '{booking.status}'."},
                status=400)

        reason = request.data.get('cancel_reason', '').strip()
        detail = _booking_detail(booking)

        booking.status = new_status
        if new_status == 'cancelled':
            booking.cancel_reason = reason
            booking.cancelled_by  = 'professional'
        booking.save()

        if new_status == 'accepted':
            _notify(booking.customer, 'Booking Accepted! ✅',
                    f'{booking.professional.name} has accepted your booking.\n{detail}')

        elif new_status == 'rejected':
            reason_line = f'\nReason: {reason}' if reason else ''
            _notify(booking.customer, 'Booking Rejected ❌',
                    f'{booking.professional.name} has rejected your booking.\n{detail}{reason_line}')

        elif new_status == 'completed':
            _notify(booking.customer, 'Service Completed! 🎉',
                    f'{booking.professional.name} has marked the service as completed.\n'
                    f'{detail}\nPlease leave a review!',
                    notif_type='review')

        elif new_status == 'cancelled':
            reason_line = f'\nReason: {reason}' if reason else ''
            _notify(booking.customer, 'Booking Cancelled by Professional ❌',
                    f'{booking.professional.name} has cancelled your booking.\n{detail}{reason_line}')
            for admin in User.objects.filter(role='admin'):
                _notify(admin, 'Booking Cancelled ❌',
                        f'Customer: {booking.customer.name}\n'
                        f'Professional: {booking.professional.name}\n'
                        f'{detail}{reason_line}\nCancelled by: Professional')

        return Response(BookingSerializer(booking).data)