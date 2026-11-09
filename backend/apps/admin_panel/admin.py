from django.contrib import admin
from apps.admin_panel.models import (
    AdminLog, PromoBanner, UserReport, Complaint, NotificationBroadcast,
    Language, TranslationKey, TranslationString,
    Country, City, Announcement, DisplayAdCampaign,
)

admin.site.register(AdminLog)
@admin.register(PromoBanner)
class PromoBannerAdmin(admin.ModelAdmin):
    list_display  = ('title', 'trigger', 'target_audience', 'is_active', 'start_date', 'end_date')
    list_filter   = ('is_active', 'trigger', 'target_audience')
    search_fields = ('title',)


@admin.register(UserReport)
class UserReportAdmin(admin.ModelAdmin):
    list_display  = ('id', 'reporter', 'reported_user', 'reason', 'status', 'created_at')
    list_filter   = ('status', 'reason')
    search_fields = ('reporter__email', 'reported_user__email', 'description')

@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display  = ('id', 'complainant', 'against', 'category', 'status', 'created_at')
    list_filter   = ('status', 'category')
    search_fields = ('complainant__email', 'against__email', 'description')


@admin.register(NotificationBroadcast)
class NotificationBroadcastAdmin(admin.ModelAdmin):
    list_display  = ('title', 'audience', 'status', 'sent_count', 'scheduled_at', 'sent_at')
    list_filter   = ('audience', 'status')
    search_fields = ('title', 'message')


@admin.register(Language)
class LanguageAdmin(admin.ModelAdmin):
    list_display  = ('name', 'code', 'status', 'is_rtl', 'created_at')
    list_filter   = ('status', 'is_rtl')


@admin.register(TranslationKey)
class TranslationKeyAdmin(admin.ModelAdmin):
    list_display  = ('key', 'description')
    search_fields = ('key', 'description')


@admin.register(Country)
class CountryAdmin(admin.ModelAdmin):
    list_display  = ('name', 'status', 'created_at')
    list_filter   = ('status',)


@admin.register(City)
class CityAdmin(admin.ModelAdmin):
    list_display  = ('name', 'country', 'status', 'created_at')
    list_filter   = ('status', 'country')


@admin.register(Announcement)
class AnnouncementAdmin(admin.ModelAdmin):
    list_display  = ('title', 'type', 'audience', 'is_active', 'created_at')
    list_filter   = ('type', 'audience', 'is_active')


@admin.register(DisplayAdCampaign)
class DisplayAdCampaignAdmin(admin.ModelAdmin):
    list_display = ('title', 'advertiser_name', 'placement_slot', 'is_approved', 'is_active', 'start_datetime', 'end_datetime', 'raw_impressions_count', 'raw_clicks_count')
    list_filter = ('placement_slot', 'is_approved', 'is_active')
    search_fields = ('title', 'advertiser_name', 'contact_phone_or_whatsapp', 'contact_email')
    readonly_fields = ('raw_impressions_count', 'unique_impressions_count', 'raw_clicks_count', 'unique_clicks_count', 'created_at', 'updated_at')

