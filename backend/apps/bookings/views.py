# apps/bookings/views.py

import logging
from datetime import date
from django.db import transaction
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
# ✅ Trust & Safety Part 9 (security pass) — same gap as messaging (see the
# matching comment in apps/messaging/views.py): enforcement.py existed and
# was unit-tested since Part 3, but a booking restriction / suspension was
# never actually checked when a booking gets created, only in the Flutter
# UI. `can_create_bookings` re-derives the answer from the DB on every call.
from apps.admin_panel.enforcement import can_create_bookings

logger = logging.getLogger(__name__)


def _notify(user, title, message, notif_type='general'):
    notify_user(user, title, message, notif_type=notif_type)


def _booking_detail(booking):
    time_str = booking.time.strftime('%I:%M %p') if booking.time else ''
    date_str = booking.date.strftime('%d %B %Y') if booking.date else ''
    if date_str and time_str:
        return f"Scheduled for {date_str} at {time_str}"
    elif date_str:
        return f"Scheduled for {date_str}"
    return "Scheduled service"


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

        # ✅ Trust & Safety Part 9 — server-side enforcement (see import
        # comment above). A booking restriction or any active suspension on
        # the CUSTOMER blocks creating a NEW booking; existing bookings are
        # untouched.
        if not can_create_bookings(request.user):
            return Response(
                {'error': 'Your ability to create bookings has been restricted.', 'code': 'booking_restricted'},
                status=status.HTTP_403_FORBIDDEN)

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
            # Server-side authoritative pricing snapshot from professional's rate
            from apps.profiles.models import ProfessionalProfile
            hourly_rate = 0.00
            try:
                prof_profile = ProfessionalProfile.objects.get(user=professional)
                if not getattr(prof_profile, 'is_available', True):
                    return Response(
                        {'error': 'This professional is currently marked as unavailable for new bookings.'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                if prof_profile.hourly_rate:
                    hourly_rate = prof_profile.hourly_rate
            except ProfessionalProfile.DoesNotExist:
                pass

            target_date = serializer.validated_data.get('date')
            target_time = serializer.validated_data.get('time')

            with transaction.atomic():
                # Prevent overlapping/double bookings for the exact same professional time slot
                slot_conflict = Booking.objects.filter(
                    professional=professional,
                    date=target_date,
                    time=target_time,
                    status__in=['pending', 'accepted']
                ).exists()

                if slot_conflict:
                    return Response(
                        {'error': 'This time slot is already reserved or pending with the professional. Please choose a different time.'},
                        status=status.HTTP_409_CONFLICT
                    )

                from apps.payments.exchange import resolve_currency_for_user
                up = getattr(professional, 'userprofile', None)
                curr, _ = resolve_currency_for_user(
                    country=getattr(up, 'country', None),
                    city=getattr(up, 'city', None)
                )

                booking = serializer.save(
                    customer=request.user,
                    professional=professional,
                    status='pending',
                    total_price=hourly_rate,
                    currency=curr,
                    payment_status='unpaid',
                )

            _notify(
                user=professional,
                title='New Service Inquiry 📩',
                message=(
                    f'{request.user.name} has sent you a service inquiry.\n'
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

        new_status = request.data.get('status', 'cancelled')

        # Allow customer to confirm/mark job as completed once accepted
        if new_status == 'completed':
            if booking.status != 'accepted':
                return Response(
                    {'error': f"Cannot mark as completed. Booking must be 'accepted' first (currently '{booking.status}')."},
                    status=400)
            booking.status = 'completed'
            booking.save()

            detail = _booking_detail(booking)
            _notify(booking.professional,
                    'Inquiry Completed & Confirmed! 🎉',
                    f'{booking.customer.name} has confirmed that your service inquiry is completed.\n{detail}',
                    notif_type='booking')
            return Response(BookingSerializer(booking).data)

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
            if not photo_url and hasattr(user, 'userprofile') and user.userprofile.photo_url:
                try:
                    photo_url = user.userprofile.photo_url.url
                except Exception:
                    pass
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

        today_earnings = 0.0
        month_earnings = 0.0
        total_earnings = 0.0

        stats = {
            'total_bookings':     bookings.count(),
            'pending_bookings':   bookings.filter(status='pending').count(),
            'accepted_bookings':  bookings.filter(status='accepted').count(),
            'completed_bookings': completed_qs.count(),
            'total_inquiries':     bookings.count(),
            'pending_inquiries':   bookings.filter(status='pending').count(),
            'accepted_inquiries':  bookings.filter(status='accepted').count(),
            'completed_inquiries': completed_qs.count(),
        }

        # ── Rating ──────────────────────────────────────────────────────
        total_reviews = Review.objects.filter(professional=user).count()

        # ── Notifications ───────────────────────────────────────────────
        unread_notifications = Notification.objects.filter(user=user, is_read=False).count()

        # ── Recent bookings (dashboard preview ke liye, max 5) ─────────
        recent = bookings.order_by('-created_at')[:5]

        from apps.payments.exchange import resolve_currency_for_user
        up = getattr(user, 'userprofile', None)
        curr, sym = resolve_currency_for_user(
            country=getattr(up, 'country', None),
            city=getattr(up, 'city', None)
        )

        return Response({
            'header': {
                'name':        user.name,
                'photo_url':   photo_url,
                'is_verified': is_verified,
            },
            'unread_notifications': unread_notifications,
            'currency': curr,
            'currency_symbol': sym,
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

        from django.db import transaction

        if new_status == 'accepted':
            # Concurrency & Overlap Protection (Atomic Transaction + Row Locking)
            with transaction.atomic():
                locked_booking = Booking.objects.select_for_update().get(id=booking.id)
                overlap = Booking.objects.filter(
                    professional=locked_booking.professional,
                    date=locked_booking.date,
                    time=locked_booking.time,
                    status__in=['accepted', 'confirmed']
                ).exclude(id=locked_booking.id).exists()
                if overlap:
                    return Response({
                        'error': f'A confirmed booking already exists for {locked_booking.date} at {locked_booking.time}. Please propose an alternative time.'
                    }, status=status.HTTP_409_CONFLICT)

                locked_booking.status = 'accepted'
                locked_booking.save()
                booking = locked_booking

            _notify(booking.customer, 'Inquiry Accepted!',
                    f'{booking.professional.name} has accepted your service inquiry.\n{detail}')

        elif new_status == 'rejected':
            booking.status = 'rejected'
            booking.save()
            reason_line = f'\nReason: {reason}' if reason else ''
            _notify(booking.customer, 'Booking Rejected',
                    f'{booking.professional.name} has rejected your booking.\n{detail}{reason_line}')

        elif new_status == 'completed':
            booking.status = 'completed'
            booking.completion_marked_by_pro = True
            booking.save()
            # Direct Settlement Model: ProFinder charges 0% commission.
            # Customers settle directly with professionals (Cash, Raast, Direct Bank Transfer).
            _notify(booking.customer, 'Service Completed!',
                    f'{booking.professional.name} has marked the service as completed.\n'
                    f'{detail}\nPlease confirm completion and leave a review!',
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

# ─── Suggest New Time View (Replaces Local SharedPreferences) ────────────────
class BookingSuggestTimeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id):
        user = request.user
        try:
            booking = Booking.objects.get(id=booking_id)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found.'}, status=404)

        if user != booking.professional and user != booking.customer:
            return Response({'error': 'You are not authorized for this booking.'}, status=403)

        suggested_date = request.data.get('suggested_date')
        suggested_time = request.data.get('suggested_time')
        reason = request.data.get('reason', '').strip()

        if not suggested_date or not suggested_time:
            return Response({'error': 'suggested_date and suggested_time are required.'}, status=400)

        suggested_by = 'professional' if user == booking.professional else 'customer'
        recipient = booking.customer if suggested_by == 'professional' else booking.professional

        booking.suggested_date = suggested_date
        booking.suggested_time = suggested_time
        booking.suggested_by = suggested_by
        booking.rescheduled_reason = reason
        booking.save()

        # Notify other party
        _notify(
            recipient,
            'New Service Time Proposed ⏰',
            f"{user.name or 'The other party'} has proposed a new time for your booking: {suggested_date} at {suggested_time}."
            + (f" Reason: {reason}" if reason else ""),
            notif_type='booking'
        )

        return Response(BookingSerializer(booking).data)


# ─── Respond to Suggested Time View ──────────────────────────────────────────
class BookingRespondSuggestionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id):
        user = request.user
        try:
            booking = Booking.objects.get(id=booking_id)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found.'}, status=404)

        if user != booking.professional and user != booking.customer:
            return Response({'error': 'You are not authorized for this booking.'}, status=403)

        action = request.data.get('action') # 'accept' | 'decline'
        if action not in ['accept', 'decline']:
            return Response({'error': "action must be 'accept' or 'decline'."}, status=400)

        proposer = booking.professional if booking.suggested_by == 'professional' else booking.customer

        if action == 'accept':
            if not booking.suggested_date or not booking.suggested_time:
                return Response({'error': 'No suggested time exists on this booking.'}, status=400)
            from django.db import transaction
            with transaction.atomic():
                locked_booking = Booking.objects.select_for_update().get(id=booking.id)
                overlap = Booking.objects.filter(
                    professional=locked_booking.professional,
                    date=locked_booking.suggested_date,
                    time=locked_booking.suggested_time,
                    status__in=['accepted', 'confirmed']
                ).exclude(id=locked_booking.id).exists()
                if overlap:
                    return Response({
                        'error': 'This time slot is no longer available as another booking was confirmed. Please select another slot.'
                    }, status=status.HTTP_409_CONFLICT)

                locked_booking.date = locked_booking.suggested_date
                locked_booking.time = locked_booking.suggested_time
                locked_booking.suggested_date = None
                locked_booking.suggested_time = None
                locked_booking.suggested_by = ''
                locked_booking.rescheduled_reason = ''
                locked_booking.status = 'accepted'
                locked_booking.save()
                booking = locked_booking

            _notify(
                proposer,
                'Proposed Time Accepted! ✅',
                f"{user.name or 'Customer'} has accepted your proposed booking time. The appointment is scheduled for {booking.date} at {booking.time}.",
                notif_type='booking'
            )
            return Response({'message': 'Time accepted successfully.', 'booking': BookingSerializer(booking).data})
        else:
            booking.suggested_date = None
            booking.suggested_time = None
            booking.suggested_by = ''
            booking.rescheduled_reason = ''
            booking.save()

            _notify(
                proposer,
                'Proposed Time Declined ❌',
                f"{user.name or 'Customer'} has declined the proposed new time. The previous schedule remains active.",
                notif_type='booking'
            )
            return Response({'message': 'Time suggestion declined.', 'booking': BookingSerializer(booking).data})


# ─── Customer Job Completion Confirmation View ───────────────────────────────
class BookingConfirmCompletionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id):
        user = request.user
        try:
            booking = Booking.objects.get(id=booking_id, customer=user)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found or you are not the customer.'}, status=404)

        if booking.status == 'completed' and booking.completion_confirmed_by_customer:
            return Response({'message': 'Booking is already confirmed complete.', 'booking': BookingSerializer(booking).data})

        from django.utils import timezone
        booking.status = 'completed'
        booking.completion_marked_by_pro = True
        booking.completion_confirmed_by_customer = True
        booking.completion_date = timezone.now()
        booking.save()

        _notify(
            booking.professional,
            'Job Completion Confirmed! 🎉',
            f"{user.name or 'Customer'} has confirmed that your service is completed. Thank you for your work!",
            notif_type='booking'
        )

        return Response({
            'message': 'Job completion confirmed successfully! Please share a review for this professional.',
            'booking': BookingSerializer(booking).data,
            'prompt_review': True,
            'professional_id': booking.professional.id,
            'professional_name': booking.professional.name,
        })
