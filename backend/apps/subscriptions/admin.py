from django.contrib import admin
from apps.subscriptions.models import (
    SubscriptionPlan,
    PlanFeature,
    Subscription,
    FeaturedPromotionPackage,
    FeaturedListingCampaign,
    CampaignAuditLog,
)


class PlanFeatureInline(admin.TabularInline):
    model = PlanFeature
    extra = 1


@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'plan_type', 'billing', 'price', 'currency', 'duration_days', 'is_active')
    list_filter = ('plan_type', 'billing', 'is_active')
    search_fields = ('name',)
    inlines = [PlanFeatureInline]


@admin.register(PlanFeature)
class PlanFeatureAdmin(admin.ModelAdmin):
    list_display = ('plan', 'key', 'value', 'feature_type', 'label')
    list_filter = ('feature_type', 'plan')
    search_fields = ('key', 'label')


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ('user', 'plan', 'status', 'start_date', 'end_date', 'created_at')
    list_filter = ('status', 'plan')
    search_fields = ('user__email',)
    readonly_fields = ('created_at',)


@admin.register(FeaturedPromotionPackage)
class FeaturedPromotionPackageAdmin(admin.ModelAdmin):
    list_display = ('name', 'duration_days', 'price', 'currency', 'is_active')
    list_filter = ('is_active',)
    search_fields = ('name',)


@admin.register(FeaturedListingCampaign)
class FeaturedListingCampaignAdmin(admin.ModelAdmin):
    list_display = ('id', 'professional', 'category', 'package', 'duration_days', 'start_date', 'end_date', 'is_active')
    list_filter = ('is_active', 'category')
    search_fields = ('professional__user__email', 'category__name')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(CampaignAuditLog)
class CampaignAuditLogAdmin(admin.ModelAdmin):
    list_display = ('campaign', 'action', 'previous_state', 'new_state', 'actor', 'created_at')
    list_filter = ('action', 'created_at')
    search_fields = ('campaign__professional__user__email', 'reason')
    readonly_fields = ('created_at',)
