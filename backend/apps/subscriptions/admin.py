from django.utils import timezone
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


from django.utils.html import format_html
from django.contrib import messages

@admin.register(FeaturedListingCampaign)
class FeaturedListingCampaignAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'professional_display',
        'category',
        'package_display',
        'amount_display',
        'payment_status_display',
        'payment_reference_display',
        'start_date',
        'end_date',
        'running_status',
        'is_active',
    )
    list_filter = ('is_active', 'payment__status', 'category', 'package')
    search_fields = (
        'professional__user__name',
        'professional__user__email',
        'category__name',
        'payment__order_id',
        'payment__safepay_tracker',
    )
    readonly_fields = ('created_at', 'updated_at', 'payment_details')

    def professional_display(self, obj):
        user = obj.professional.user if obj.professional else None
        if not user:
            return "—"
        return f"{user.name or 'Pro'} ({user.email})"
    professional_display.short_description = "Professional"

    def package_display(self, obj):
        return obj.package.name if obj.package else f"{obj.duration_days} Days"
    package_display.short_description = "Package"

    def amount_display(self, obj):
        if obj.payment:
            return f"{obj.payment.currency} {obj.payment.amount}"
        if obj.package:
            return f"PKR {obj.package.price}"
        return "—"
    amount_display.short_description = "Amount"

    def payment_status_display(self, obj):
        status = obj.payment.status if obj.payment else 'no_payment'
        colors = {
            'completed': '#10B981',
            'pending': '#F59E0B',
            'processing': '#3B82F6',
            'failed': '#EF4444',
            'cancelled': '#6B7280',
        }
        color = colors.get(status, '#6B7280')
        return format_html(
            '<span style="color: white; background-color: {}; padding: 3px 8px; border-radius: 6px; font-weight: 600; font-size: 11px;">{}</span>',
            color,
            status.upper()
        )
    payment_status_display.short_description = "Payment Status"

    def payment_reference_display(self, obj):
        if not obj.payment:
            return "—"
        return obj.payment.order_id or obj.payment.safepay_tracker or str(obj.payment.id)
    payment_reference_display.short_description = "Safepay Ref"

    def running_status(self, obj):
        if obj.is_currently_running():
            return format_html('<span style="color: #059669; font-weight: bold;">● Active</span>')
        if obj.end_date and obj.end_date < timezone.now():
            return format_html('<span style="color: #DC2626;">● Expired</span>')
        if obj.payment and obj.payment.status != 'completed':
            return format_html('<span style="color: #D97706;">● Unpaid</span>')
        return format_html('<span style="color: #6B7280;">● Inactive</span>')
    running_status.short_description = "Live Status"

    def payment_details(self, obj):
        if not obj.payment:
            return "No payment record attached."
        p = obj.payment
        return format_html(
            "<b>Order ID:</b> {}<br/>"
            "<b>Safepay Tracker:</b> {}<br/>"
            "<b>Amount:</b> {} {}<br/>"
            "<b>Status:</b> {}<br/>"
            "<b>Environment:</b> {}",
            p.order_id or "—",
            p.safepay_tracker or "—",
            p.currency, p.amount,
            p.status,
            p.safepay_environment
        )
    payment_details.short_description = "Verified Safepay Details"

    def save_model(self, request, obj, form, change):
        # Admin security protection: cannot manually activate campaign without verified payment
        if obj.is_active and (not obj.payment or obj.payment.status != 'completed'):
            messages.error(
                request,
                "Security Enforcement: Featured Listing campaigns cannot be manually activated without a verified completed Safepay payment."
            )
            obj.is_active = False
        super().save_model(request, obj, form, change)


@admin.register(CampaignAuditLog)
class CampaignAuditLogAdmin(admin.ModelAdmin):
    list_display = ('campaign', 'action', 'previous_state', 'new_state', 'actor', 'created_at')
    list_filter = ('action', 'created_at')
    search_fields = ('campaign__professional__user__email', 'reason')
    readonly_fields = ('created_at',)
