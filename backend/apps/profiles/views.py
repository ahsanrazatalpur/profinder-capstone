# PATH: backend/apps/profiles/views.py
# apps/profiles/views.py

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAdminUser
from django.utils import timezone
from apps.profiles.models import UserProfile, ProfessionalProfile, Portfolio, Certificate, GalleryImage, ProfileView
from apps.profiles.serializers import (
    UserProfileSerializer,
    ProfessionalProfileSerializer,
    PortfolioSerializer,
    CertificateSerializer,
    GalleryImageSerializer,
)
from django.db.models import Q, Avg


class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        return Response(UserProfileSerializer(profile).data)

    def patch(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        photo = request.FILES.get('photo')
        if photo:
            profile.photo_url = photo
            profile.save(update_fields=['photo_url'])
        serializer = UserProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            profile.refresh_from_db()
            return Response(UserProfileSerializer(profile).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request):
        return self.patch(request)


class ProfessionalProfileView(APIView):

    def get_permissions(self):
        if self.kwargs.get('user_id'):
            return [AllowAny()]
        return [IsAuthenticated()]

    def get(self, request, user_id=None):
        if user_id:
            try:
                profile = ProfessionalProfile.objects.get(user_id=user_id)
                data = ProfessionalProfileSerializer(profile).data
                data['name']          = profile.user.name
                data['email']         = profile.user.email
                data['category_name'] = profile.category.name if profile.category else ''
                data['user_id']       = profile.user.id   # ✅ FIX: User.id explicitly bhejo
                try:
                    data['city'] = profile.user.userprofile.city
                except Exception:
                    data['city'] = ''

                # ✅ NEW — log this view for Analytics (skip if professional
                # is viewing their own profile via this route)
                viewer = request.user if request.user.is_authenticated else None
                if viewer is None or viewer.id != profile.user_id:
                    ProfileView.objects.create(professional=profile.user, viewer=viewer)

                return Response(data)
            except ProfessionalProfile.DoesNotExist:
                return Response({'error': 'Profile not found'}, status=status.HTTP_404_NOT_FOUND)

        profile, _ = ProfessionalProfile.objects.get_or_create(user=request.user)
        data = ProfessionalProfileSerializer(profile).data
        data['category_name'] = profile.category.name if profile.category else ''
        data['user_id']       = profile.user.id   # ✅ FIX: apne profile mein bhi
        return Response(data)

    def patch(self, request, user_id=None):
        profile, _ = ProfessionalProfile.objects.get_or_create(user=request.user)
        photo = request.FILES.get('photo')
        if photo:
            profile.photo_url = photo
            profile.save(update_fields=['photo_url'])
        serializer = ProfessionalProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            profile.refresh_from_db()
            return Response(ProfessionalProfileSerializer(profile).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def put(self, request, user_id=None):
        return self.patch(request)


class PortfolioView(APIView):

    def get_permissions(self):
        if self.kwargs.get('user_id'):
            return [AllowAny()]
        return [IsAuthenticated()]

    def get(self, request, user_id=None, portfolio_id=None):
        if user_id:
            # Public — sirf approved portfolio dikhao
            portfolio = Portfolio.objects.filter(
                professional_id=user_id,
                status=Portfolio.APPROVED
            )
        else:
            # Professional apna sab kuch dekh sakta hai (pending bhi)
            portfolio = Portfolio.objects.filter(professional=request.user)
        return Response(PortfolioSerializer(portfolio, many=True).data)

    def post(self, request, **kwargs):
        serializer = PortfolioSerializer(data=request.data)
        if serializer.is_valid():
            portfolio_item = serializer.save(professional=request.user)
            image = request.FILES.get('image')
            if image:
                portfolio_item.image_url = image
                portfolio_item.save(update_fields=['image_url'])
                portfolio_item.refresh_from_db()
                return Response(PortfolioSerializer(portfolio_item).data, status=status.HTTP_201_CREATED)
            return Response(PortfolioSerializer(portfolio_item).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, portfolio_id=None, **kwargs):
        try:
            item = Portfolio.objects.get(id=portfolio_id, professional=request.user)
            item.delete()
            return Response({'message': 'Deleted successfully'})
        except Portfolio.DoesNotExist:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)


# ── ADMIN — Portfolio Approval ─────────────────────────────────────────────────
class AdminPortfolioView(APIView):
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request):
        status_filter = request.query_params.get('status', 'pending')
        portfolios = Portfolio.objects.filter(status=status_filter).select_related('professional')
        data = []
        for p in portfolios:
            d = PortfolioSerializer(p).data
            d['professional_name']  = p.professional.name
            d['professional_email'] = p.professional.email
            d['professional_id']    = p.professional.id
            data.append(d)
        return Response(data)

    def patch(self, request, portfolio_id=None):
        try:
            portfolio = Portfolio.objects.get(id=portfolio_id)
        except Portfolio.DoesNotExist:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)

        new_status = request.data.get('status')
        admin_note = request.data.get('admin_note', '')

        if new_status not in [Portfolio.APPROVED, Portfolio.REJECTED]:
            return Response({'error': 'Status must be approved or rejected'}, status=status.HTTP_400_BAD_REQUEST)

        portfolio.status      = new_status
        portfolio.admin_note  = admin_note
        portfolio.reviewed_at = timezone.now()
        portfolio.save()

        if new_status == Portfolio.APPROVED:
            try:
                pro_profile = ProfessionalProfile.objects.get(user=portfolio.professional)
                pro_profile.update_verification()
            except ProfessionalProfile.DoesNotExist:
                pass

        return Response({
            'message': f'Portfolio {new_status}',
            'portfolio': PortfolioSerializer(portfolio).data
        })


# ✅ NEW — Certificates (professional-managed, no admin approval needed)
class CertificateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id=None, certificate_id=None):
        if user_id:
            # Public — anyone viewing this professional's profile can see certs
            certs = Certificate.objects.filter(professional_id=user_id)
        else:
            certs = Certificate.objects.filter(professional=request.user)
        return Response(CertificateSerializer(certs, many=True).data)

    def post(self, request, **kwargs):
        serializer = CertificateSerializer(data=request.data)
        if serializer.is_valid():
            cert = serializer.save(professional=request.user)
            return Response(CertificateSerializer(cert).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, certificate_id=None, **kwargs):
        try:
            item = Certificate.objects.get(id=certificate_id, professional=request.user)
            item.delete()
            return Response({'message': 'Deleted successfully'})
        except Certificate.DoesNotExist:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)


# ✅ NEW — Gallery (simple photo grid, no title/description/approval)
class GalleryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id=None, image_id=None):
        if user_id:
            images = GalleryImage.objects.filter(professional_id=user_id)
        else:
            images = GalleryImage.objects.filter(professional=request.user)
        return Response(GalleryImageSerializer(images, many=True).data)

    def post(self, request, **kwargs):
        serializer = GalleryImageSerializer(data=request.data)
        if serializer.is_valid():
            img = serializer.save(professional=request.user)
            return Response(GalleryImageSerializer(img).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, image_id=None, **kwargs):
        try:
            item = GalleryImage.objects.get(id=image_id, professional=request.user)
            item.delete()
            return Response({'message': 'Deleted successfully'})
        except GalleryImage.DoesNotExist:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)


# ✅ NEW — Analytics: Profile Views, Visitors, Performance Score,
# Acceptance Rate, Response Rate — for the Professional Dashboard's
# Analytics tab/card.
class ProfessionalAnalyticsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Local imports to avoid circular-import issues between apps
        from apps.bookings.models import Booking
        from apps.reviews.models import Review
        from django.utils import timezone
        from datetime import timedelta

        professional = request.user
        now = timezone.now()
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

        views_qs = ProfileView.objects.filter(professional=professional)
        total_views = views_qs.count()
        month_views = views_qs.filter(created_at__gte=month_start).count()
        visitors = views_qs.exclude(viewer=None).values('viewer').distinct().count()

        bookings = Booking.objects.filter(professional=professional)
        total_bookings = bookings.count()
        decided = bookings.filter(status__in=['accepted', 'rejected', 'completed'])
        accepted = bookings.filter(status__in=['accepted', 'completed'])
        responded = bookings.exclude(status='pending')

        acceptance_rate = round((accepted.count() / decided.count()) * 100, 1) if decided.count() else 0
        response_rate   = round((responded.count() / total_bookings) * 100, 1) if total_bookings else 0

        avg_rating = Review.objects.filter(professional=professional).aggregate(
            avg=Avg('rating'))['avg'] or 0

        # Weighted composite score out of 100
        performance_score = round(
            (float(avg_rating) / 5 * 100) * 0.4 +
            acceptance_rate * 0.3 +
            response_rate * 0.3,
            1
        )

        return Response({
            'profile_views':      total_views,
            'profile_views_month': month_views,
            'visitors':           visitors,
            'acceptance_rate':    acceptance_rate,
            'response_rate':      response_rate,
            'average_rating':     round(float(avg_rating), 1),
            'performance_score':  performance_score,
        })

class ProfessionalDashboardView(APIView):
    """
    Aggregated dashboard stats for professional home screen.
    GET /api/profiles/professional/dashboard/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from apps.bookings.models import Booking
        from django.utils import timezone
        from django.db.models import Count, Q

        user = request.user
        if user.role != 'professional':
            return Response({'error': 'Not a professional'}, status=403)

        try:
            prof = user.professionalprofile
            hourly_rate = float(prof.hourly_rate or 0)
        except Exception:
            return Response({'error': 'Profile not found'}, status=404)

        today      = timezone.now().date()
        month_start = today.replace(day=1)

        bookings = Booking.objects.filter(professional=user)

        total_bookings     = bookings.count()
        pending_bookings   = bookings.filter(status='pending').count()
        accepted_bookings  = bookings.filter(status='accepted').count()
        completed_bookings = bookings.filter(status='completed').count()
        cancelled_bookings = bookings.filter(status='cancelled').count()

        # Earnings estimate — completed bookings x hourly_rate
        today_completed   = bookings.filter(status='completed', date=today).count()
        month_completed   = bookings.filter(status='completed', date__gte=month_start).count()

        today_earnings = round(today_completed   * hourly_rate, 2)
        month_earnings = round(month_completed   * hourly_rate, 2)
        total_earnings = round(completed_bookings * hourly_rate, 2)

        # Recent bookings (last 5)
        recent = bookings.select_related('customer', 'customer__userprofile') \
                         .order_by('-created_at')[:5]
        recent_list = []
        for b in recent:
            try:
                recent_list.append({
                    'id':           b.id,
                    'customer_name': b.customer.name,
                    'date':         str(b.date),
                    'time':         str(b.time),
                    'status':       b.status,
                    'total_price':  hourly_rate,
                })
            except Exception:
                pass

        return Response({
            'today_earnings':    today_earnings,
            'month_earnings':    month_earnings,
            'total_earnings':    total_earnings,
            'total_bookings':    total_bookings,
            'pending_bookings':  pending_bookings,
            'accepted_bookings': accepted_bookings,
            'completed_bookings':completed_bookings,
            'cancelled_bookings':cancelled_bookings,
            'average_rating':    float(prof.average_rating or 0),
            'hourly_rate':       hourly_rate,
            'is_verified':       prof.is_verified,
            'recent_bookings':   recent_list,
        })