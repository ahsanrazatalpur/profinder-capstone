# apps/reviews/serializers.py
from rest_framework import serializers
from apps.reviews.models import Review, ReviewPhoto, ReviewReply, ReviewReport


class ReviewPhotoSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model  = ReviewPhoto
        fields = ['id', 'image']

    def get_image(self, obj):
        try:
            return obj.image.url if obj.image else None
        except Exception:
            return None


class ReviewReplySerializer(serializers.ModelSerializer):
    professional_name  = serializers.CharField(source='review.professional.name', read_only=True)
    professional_photo = serializers.SerializerMethodField()

    class Meta:
        model  = ReviewReply
        fields = ['id', 'text', 'created_at', 'updated_at', 'professional_name', 'professional_photo']

    def get_professional_photo(self, obj):
        try:
            prof = obj.review.professional.professionalprofile
            return prof.photo_url.url if prof.photo_url else None
        except Exception:
            return None


class ReviewSerializer(serializers.ModelSerializer):
    reviewer_name     = serializers.CharField(source='reviewer.name', read_only=True)
    reviewer_photo    = serializers.SerializerMethodField()
    professional_name  = serializers.CharField(source='professional.name', read_only=True)
    professional_photo = serializers.SerializerMethodField()
    photos            = ReviewPhotoSerializer(many=True, read_only=True)
    reply             = ReviewReplySerializer(read_only=True)
    helpful_count     = serializers.SerializerMethodField()
    is_helpful_by_me  = serializers.SerializerMethodField()
    is_owner          = serializers.SerializerMethodField()
    is_professional_viewer = serializers.SerializerMethodField()

    class Meta:
        model  = Review
        fields = [
            'id', 'reviewer', 'reviewer_name', 'reviewer_photo',
            'professional', 'professional_name', 'professional_photo',
            'rating', 'comment', 'created_at',
            'is_verified_service', 'is_edited', 'edited_at',
            'photos', 'reply', 'helpful_count', 'is_helpful_by_me', 'is_owner',
            'is_professional_viewer',
        ]
        read_only_fields = [
            'reviewer', 'reviewer_name', 'professional', 'created_at',
            'is_verified_service', 'is_edited', 'edited_at',
        ]

    def get_reviewer_photo(self, obj):
        try:
            profile = obj.reviewer.userprofile
            return profile.photo_url.url if profile.photo_url else None
        except Exception:
            return None

    def get_professional_photo(self, obj):
        try:
            prof = obj.professional.professionalprofile
            return prof.photo_url.url if prof.photo_url else None
        except Exception:
            return None

    def get_helpful_count(self, obj):
        # Prefer the annotated value (set by the list view) to avoid N+1 queries
        if hasattr(obj, 'helpful_total'):
            return obj.helpful_total
        return obj.helpful_votes.count()

    def get_is_helpful_by_me(self, obj):
        request = self.context.get('request')
        if not request or not request.user or not request.user.is_authenticated:
            return False
        return obj.helpful_votes.filter(user=request.user).exists()

    def get_is_owner(self, obj):
        request = self.context.get('request')
        if not request or not request.user or not request.user.is_authenticated:
            return False
        return obj.reviewer_id == request.user.id

    def get_is_professional_viewer(self, obj):
        request = self.context.get('request')
        if not request or not request.user or not request.user.is_authenticated:
            return False
        return obj.professional_id == request.user.id

    def validate_rating(self, value):
        if value < 1 or value > 5:
            raise serializers.ValidationError(
                "Rating must be between 1 and 5.")
        return value

    def validate_comment(self, value):
        value = value.strip()
        if len(value) > 1000:
            raise serializers.ValidationError(
                "Comment cannot exceed 1000 characters.")
        return value


class ReviewReportSerializer(serializers.ModelSerializer):
    class Meta:
        model  = ReviewReport
        fields = ['id', 'review', 'reason', 'note', 'status', 'created_at']
        read_only_fields = ['id', 'status', 'created_at']

    def validate_reason(self, value):
        valid = dict(ReviewReport.REASON_CHOICES)
        if value not in valid:
            raise serializers.ValidationError("Invalid report reason.")
        return value