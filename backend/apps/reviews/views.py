# apps/reviews/views.py
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.db.models import Avg, Count
from django.utils import timezone

from apps.reviews.models import Review, ReviewPhoto, ReviewReply, ReviewHelpful, ReviewReport
from apps.reviews.serializers import ReviewSerializer, ReviewReplySerializer
from apps.profiles.models import ProfessionalProfile
from apps.users.models import User
from apps.bookings.models import Booking

PAGE_SIZE = 10
MAX_PHOTOS_PER_REVIEW = 5


def _recompute_average(professional_id):
    avg = Review.objects.filter(
        professional_id=professional_id, is_hidden=False
    ).aggregate(Avg('rating'))['rating__avg']
    ProfessionalProfile.objects.filter(
        user_id=professional_id
    ).update(average_rating=round(avg or 0, 2))


class ReviewView(APIView):
    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAuthenticated()]
        return [AllowAny()]

    def get(self, request, professional_id):
        base_qs = Review.objects.filter(professional_id=professional_id, is_hidden=False)

        # ── Rating summary — always computed on the FULL unfiltered set,
        # so the distribution bars stay stable while the user filters ──
        total = base_qs.count()
        dist_counts = {str(i): base_qs.filter(rating=i).count() for i in range(1, 6)}
        dist_percent = {
            k: (round(v * 100 / total) if total else 0) for k, v in dist_counts.items()
        }
        avg = base_qs.aggregate(Avg('rating'))['rating__avg'] or 0

        qs = base_qs

        # ── Filter by star rating ──
        rating_filter = request.query_params.get('rating')
        if rating_filter and rating_filter not in ('all', ''):
            try:
                qs = qs.filter(rating=int(rating_filter))
            except ValueError:
                pass

        if request.query_params.get('with_photos') == 'true':
            qs = qs.filter(photos__isnull=False).distinct()

        # ── Sort ──
        qs = qs.annotate(helpful_total=Count('helpful_votes', distinct=True))
        sort = request.query_params.get('sort', 'relevant')
        if sort == 'newest':
            qs = qs.order_by('-created_at')
        elif sort == 'highest':
            qs = qs.order_by('-rating', '-created_at')
        elif sort == 'lowest':
            qs = qs.order_by('rating', '-created_at')
        elif sort == 'helpful':
            qs = qs.order_by('-helpful_total', '-created_at')
        else:  # 'relevant' default — most-helpful-first reads as most-relevant
            qs = qs.order_by('-helpful_total', '-created_at')

        # ── Pagination ──
        try:
            page = max(1, int(request.query_params.get('page', 1)))
        except ValueError:
            page = 1
        try:
            page_size = min(100, max(1, int(request.query_params.get('page_size', PAGE_SIZE))))
        except ValueError:
            page_size = PAGE_SIZE
        start, end = (page - 1) * page_size, page * page_size

        filtered_total = qs.count()
        page_qs = qs[start:end]
        has_more = filtered_total > end

        serializer = ReviewSerializer(page_qs, many=True, context={'request': request})

        return Response({
            'summary': {
                'average_rating': round(avg, 1),
                'total_reviews': total,
                'distribution_percent': dist_percent,
                'distribution_counts': dist_counts,
            },
            'results': serializer.data,
            'page': page,
            'has_more': has_more,
        })

    def post(self, request, professional_id):
        # Professional exists check karo
        try:
            professional = User.objects.get(id=professional_id, role='professional')
        except User.DoesNotExist:
            return Response(
                {"error": "Professional not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        # Khud ko review nahi de sakta
        if request.user.id == professional.id:
            return Response(
                {"error": "You cannot review yourself."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Duplicate review check
        if Review.objects.filter(reviewer=request.user, professional=professional).exists():
            return Response(
                {"error": "You have already reviewed this professional."},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = ReviewSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            # ✅ Verified Service badge — true if there was a completed
            # booking between this customer and this professional.
            # ⚠️ TEMP TESTING: also counts 'accepted' bookings, since
            # payment (and the usual completion trigger) isn't wired up
            # yet. Remove 'accepted' from status__in once payment is live.
            is_verified = Booking.objects.filter(
                customer=request.user, professional=professional,
                status__in=['accepted', 'completed'],
            ).exists()

            review = serializer.save(
                reviewer=request.user,
                professional=professional,
                is_verified_service=is_verified,
            )

            # ✅ Optional photos — multipart field name: photos
            photos = request.FILES.getlist('photos')
            for f in photos[:MAX_PHOTOS_PER_REVIEW]:
                ReviewPhoto.objects.create(review=review, image=f)

            _recompute_average(professional_id)

            out = ReviewSerializer(review, context={'request': request})
            return Response(out.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ReviewDetailView(APIView):
    """Owner-only edit / delete of a single review."""
    permission_classes = [IsAuthenticated]

    def patch(self, request, review_id):
        try:
            review = Review.objects.get(id=review_id)
        except Review.DoesNotExist:
            return Response({"error": "Review not found."}, status=status.HTTP_404_NOT_FOUND)

        if review.reviewer_id != request.user.id:
            return Response({"error": "You can only edit your own review."}, status=status.HTTP_403_FORBIDDEN)

        # Only rating/comment are editable — never reviewer/professional
        allowed = {k: v for k, v in request.data.items() if k in ('rating', 'comment')}
        serializer = ReviewSerializer(review, data=allowed, partial=True, context={'request': request})
        if serializer.is_valid():
            serializer.save(is_edited=True, edited_at=timezone.now())
            _recompute_average(review.professional_id)
            return Response(ReviewSerializer(review, context={'request': request}).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, review_id):
        try:
            review = Review.objects.get(id=review_id)
        except Review.DoesNotExist:
            return Response({"error": "Review not found."}, status=status.HTTP_404_NOT_FOUND)

        if review.reviewer_id != request.user.id:
            return Response({"error": "You can only delete your own review."}, status=status.HTTP_403_FORBIDDEN)

        professional_id = review.professional_id
        review.delete()
        _recompute_average(professional_id)
        return Response(status=status.HTTP_204_NO_CONTENT)


class ReviewHelpfulView(APIView):
    """Toggle 'Helpful' on a review — one vote per user, tapping again un-marks it."""
    permission_classes = [IsAuthenticated]

    def post(self, request, review_id):
        try:
            review = Review.objects.get(id=review_id)
        except Review.DoesNotExist:
            return Response({"error": "Review not found."}, status=status.HTTP_404_NOT_FOUND)

        vote, created = ReviewHelpful.objects.get_or_create(review=review, user=request.user)
        if not created:
            vote.delete()
            marked = False
        else:
            marked = True

        return Response({
            'is_helpful_by_me': marked,
            'helpful_count': review.helpful_votes.count(),
        })


class ReviewReplyView(APIView):
    """Professional replies to a review they received. One reply per review."""
    permission_classes = [IsAuthenticated]

    def post(self, request, review_id):
        try:
            review = Review.objects.get(id=review_id)
        except Review.DoesNotExist:
            return Response({"error": "Review not found."}, status=status.HTTP_404_NOT_FOUND)

        # Professional CANNOT delete/edit/hide reviews — replying is all they get
        if review.professional_id != request.user.id:
            return Response({"error": "Only the reviewed professional can reply."}, status=status.HTTP_403_FORBIDDEN)

        text = (request.data.get('text') or '').strip()
        if not text:
            return Response({"error": "Reply text is required."}, status=status.HTTP_400_BAD_REQUEST)
        if len(text) > 1000:
            return Response({"error": "Reply cannot exceed 1000 characters."}, status=status.HTTP_400_BAD_REQUEST)

        reply, _ = ReviewReply.objects.update_or_create(review=review, defaults={'text': text})
        return Response(ReviewReplySerializer(reply).data, status=status.HTTP_201_CREATED)


class ReviewReportView(APIView):
    """Flags a review for Admin moderation. Never deletes/hides immediately."""
    permission_classes = [IsAuthenticated]

    def post(self, request, review_id):
        try:
            review = Review.objects.get(id=review_id)
        except Review.DoesNotExist:
            return Response({"error": "Review not found."}, status=status.HTTP_404_NOT_FOUND)

        reason = request.data.get('reason')
        valid_reasons = dict(ReviewReport.REASON_CHOICES)
        if reason not in valid_reasons:
            return Response({"error": "Invalid report reason."}, status=status.HTTP_400_BAD_REQUEST)

        if ReviewReport.objects.filter(review=review, reporter=request.user).exists():
            return Response({"error": "You have already reported this review."}, status=status.HTTP_400_BAD_REQUEST)

        ReviewReport.objects.create(
            review=review,
            reporter=request.user,
            reason=reason,
            note=(request.data.get('note') or '').strip(),
        )
        return Response({"message": "Thanks — our team will review this."}, status=status.HTTP_201_CREATED)


class MyReviewsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != 'professional':
            return Response({'error': 'Not a professional'}, status=status.HTTP_403_FORBIDDEN)
        # Professional dashboard sees everything, including any Admin-hidden
        # ones (so they understand their own standing) — public view does not.
        reviews = Review.objects.filter(professional=request.user).order_by('-created_at')
        return Response(ReviewSerializer(reviews, many=True, context={'request': request}).data)


class MyGivenReviewsView(APIView):
    """The reviews *I* (a customer) have written, across every professional.

    Added so the Flutter 'My Reviews' screen no longer has to loop over
    every booked professional and filter client-side just to find its own
    reviews — a single call now.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        reviews = Review.objects.filter(reviewer=request.user).order_by('-created_at')
        return Response(ReviewSerializer(reviews, many=True, context={'request': request}).data)