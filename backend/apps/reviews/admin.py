# apps/reviews/admin.py
from django.contrib import admin
from django.utils import timezone
from apps.reviews.models import Review, ReviewPhoto, ReviewReply, ReviewHelpful, ReviewReport


class ReviewPhotoInline(admin.TabularInline):
    model = ReviewPhoto
    extra = 0


class ReviewReplyInline(admin.StackedInline):
    model = ReviewReply
    extra = 0


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display  = ('id', 'reviewer', 'professional', 'rating', 'is_verified_service', 'is_edited', 'is_hidden', 'created_at')
    list_filter   = ('rating', 'is_hidden', 'is_verified_service', 'is_edited')
    search_fields = ('reviewer__email', 'professional__email', 'comment')
    inlines       = [ReviewPhotoInline, ReviewReplyInline]
    actions       = ['hide_reviews', 'unhide_reviews']

    # ⚠️ Moderation rule: only genuine policy violations should ever be
    # hidden here — a review being negative is NOT a valid reason.
    def hide_reviews(self, request, queryset):
        queryset.update(is_hidden=True, hidden_at=timezone.now())
    hide_reviews.short_description = "Hide selected reviews (policy violation only)"

    def unhide_reviews(self, request, queryset):
        queryset.update(is_hidden=False, hidden_reason='', hidden_at=None)
    unhide_reviews.short_description = "Unhide selected reviews"


@admin.register(ReviewReport)
class ReviewReportAdmin(admin.ModelAdmin):
    list_display  = ('id', 'review', 'reporter', 'reason', 'status', 'created_at')
    list_filter   = ('reason', 'status')
    search_fields = ('reporter__email',)


admin.site.register(ReviewHelpful)