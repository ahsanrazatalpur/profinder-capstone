# apps/admin_panel/serializers.py

from rest_framework import serializers
from apps.admin_panel.models import (
    AdminLog, PromoBanner, UserReport, Complaint, NotificationBroadcast,
    Language, TranslationKey, TranslationString,
    Country, City, Announcement,
)


class AdminLogSerializer(serializers.ModelSerializer):
    admin_email       = serializers.EmailField(source='admin.email',       read_only=True)
    admin_name        = serializers.CharField(source='admin.name',         read_only=True)
    target_user_email = serializers.SerializerMethodField()
    target_user_name  = serializers.SerializerMethodField()

    class Meta:
        model  = AdminLog
        fields = [
            'id', 'action', 'note', 'created_at',
            'admin_email', 'admin_name',
            'target_user_email', 'target_user_name',
        ]

    def get_target_user_email(self, obj):
        return obj.target_user.email if obj.target_user else None

    def get_target_user_name(self, obj):
        return obj.target_user.name if obj.target_user else None


class PromoBannerSerializer(serializers.ModelSerializer):
    is_currently_active = serializers.SerializerMethodField()

    class Meta:
        model  = PromoBanner
        fields = [
            'id', 'title', 'description', 'image_url',
            'button_text', 'button_link_type', 'button_link_value',
            'target_audience', 'trigger', 'trigger_x_days',
            'is_active', 'priority', 'start_date', 'end_date',
            'is_currently_active', 'created_at', 'updated_at',
        ]

    def get_is_currently_active(self, obj):
        return obj.is_currently_active()


class UserReportSerializer(serializers.ModelSerializer):
    """
    Admin-facing view of a report — full context: kisne kisko report kiya,
    kyun, aur ab tak kya action liya gaya.
    """
    reporter_name        = serializers.CharField(source='reporter.name',  read_only=True)
    reporter_email       = serializers.EmailField(source='reporter.email', read_only=True)
    reported_user_name   = serializers.CharField(source='reported_user.name',  read_only=True)
    reported_user_email  = serializers.EmailField(source='reported_user.email', read_only=True)
    reported_user_role   = serializers.CharField(source='reported_user.role',   read_only=True)
    reported_user_active = serializers.BooleanField(source='reported_user.is_active', read_only=True)
    reviewed_by_email    = serializers.SerializerMethodField()
    reason_display        = serializers.CharField(source='get_reason_display', read_only=True)
    status_display        = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model  = UserReport
        fields = [
            'id', 'reason', 'reason_display', 'description',
            'status', 'status_display', 'admin_note',
            'created_at', 'reviewed_at',
            'reporter_name', 'reporter_email',
            'reported_user', 'reported_user_name', 'reported_user_email',
            'reported_user_role', 'reported_user_active',
            'reviewed_by_email',
        ]

    def get_reviewed_by_email(self, obj):
        return obj.reviewed_by.email if obj.reviewed_by else None


class CreateUserReportSerializer(serializers.ModelSerializer):
    """
    Ye serializer regular users (customer/professional) use karte hain jab
    woh kisi user ko report karte hain.
    POST /api/admin-panel/reports/
    """
    class Meta:
        model  = UserReport
        fields = ['reported_user', 'reason', 'description']

    def validate_reported_user(self, value):
        request = self.context.get('request')
        if request and value == request.user:
            raise serializers.ValidationError("You can't report yourself.")
        return value


class ComplaintSerializer(serializers.ModelSerializer):
    complainant_name  = serializers.CharField(source='complainant.name',  read_only=True)
    complainant_email = serializers.EmailField(source='complainant.email', read_only=True)
    against_name       = serializers.CharField(source='against.name',  read_only=True)
    against_email      = serializers.EmailField(source='against.email', read_only=True)
    assigned_to_name    = serializers.SerializerMethodField()
    category_display     = serializers.CharField(source='get_category_display', read_only=True)
    status_display        = serializers.CharField(source='get_status_display', read_only=True)
    booking_date          = serializers.SerializerMethodField()

    class Meta:
        model  = Complaint
        fields = [
            'id', 'category', 'category_display', 'description',
            'status', 'status_display', 'resolution_note',
            'created_at', 'resolved_at',
            'complainant_name', 'complainant_email',
            'against', 'against_name', 'against_email',
            'assigned_to_name', 'booking', 'booking_date',
        ]

    def get_assigned_to_name(self, obj):
        return obj.assigned_to.name if obj.assigned_to else None

    def get_booking_date(self, obj):
        return str(obj.booking.date) if obj.booking else None


class NotificationBroadcastSerializer(serializers.ModelSerializer):
    audience_display     = serializers.CharField(source='get_audience_display', read_only=True)
    status_display       = serializers.CharField(source='get_status_display', read_only=True)
    specific_user_name   = serializers.CharField(source='specific_user.name', read_only=True, default=None)
    created_by_name       = serializers.CharField(source='created_by.name', read_only=True, default=None)
    open_rate            = serializers.SerializerMethodField()

    class Meta:
        model  = NotificationBroadcast
        fields = [
            'id', 'title', 'message', 'audience', 'audience_display',
            'specific_user', 'specific_user_name',
            'status', 'status_display', 'scheduled_at', 'sent_at',
            'sent_count', 'opened_count', 'open_rate',
            'created_by_name', 'created_at',
        ]

    def get_open_rate(self, obj):
        if not obj.sent_count:
            return 0
        return round(obj.opened_count * 100 / obj.sent_count, 1)


class LanguageSerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    completion_percentage = serializers.SerializerMethodField()

    class Meta:
        model  = Language
        fields = ['id', 'name', 'code', 'is_rtl', 'status', 'status_display',
                   'completion_percentage', 'created_at']

    def get_completion_percentage(self, obj):
        total = TranslationKey.objects.count()
        if total == 0:
            return 0
        translated = TranslationString.objects.filter(
            language=obj).exclude(text='').count()
        return round(translated * 100 / total, 1)


class CountrySerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    user_count       = serializers.SerializerMethodField()
    professional_count = serializers.SerializerMethodField()
    city_count       = serializers.SerializerMethodField()

    class Meta:
        model  = Country
        fields = ['id', 'name', 'status', 'status_display', 'user_count',
                   'professional_count', 'city_count', 'created_at']

    def get_user_count(self, obj):
        from apps.profiles.models import UserProfile
        return UserProfile.objects.filter(country__iexact=obj.name).count()

    def get_professional_count(self, obj):
        from apps.profiles.models import UserProfile
        return UserProfile.objects.filter(
            country__iexact=obj.name, user__role='professional').count()

    def get_city_count(self, obj):
        return obj.cities.count()


class CitySerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    country_name   = serializers.CharField(source='country.name', read_only=True)
    user_count       = serializers.SerializerMethodField()
    professional_count = serializers.SerializerMethodField()

    class Meta:
        model  = City
        fields = ['id', 'name', 'country', 'country_name', 'status', 'status_display',
                   'user_count', 'professional_count', 'created_at']

    def get_user_count(self, obj):
        from apps.profiles.models import UserProfile
        return UserProfile.objects.filter(city__iexact=obj.name).count()

    def get_professional_count(self, obj):
        from apps.profiles.models import UserProfile
        return UserProfile.objects.filter(
            city__iexact=obj.name, user__role='professional').count()


class AnnouncementSerializer(serializers.ModelSerializer):
    type_display     = serializers.CharField(source='get_type_display', read_only=True)
    audience_display = serializers.CharField(source='get_audience_display', read_only=True)
    created_by_name  = serializers.CharField(source='created_by.name', read_only=True, default=None)

    class Meta:
        model  = Announcement
        fields = ['id', 'title', 'message', 'type', 'type_display',
                   'audience', 'audience_display', 'is_active',
                   'start_date', 'end_date', 'created_by_name', 'created_at']