from django.contrib import admin

from apps.support.models import (
    HelpCategory, HelpCategoryTranslation, HelpArticle, HelpArticleTranslation,
    PolicyDocument, PolicyVersion, PolicyTranslation,
    SupportTicket, TicketMessage, TicketEvent,
)


class HelpCategoryTranslationInline(admin.TabularInline):
    model = HelpCategoryTranslation
    extra = 0


@admin.register(HelpCategory)
class HelpCategoryAdmin(admin.ModelAdmin):
    list_display = ('slug', 'audience', 'order', 'is_active')
    inlines = [HelpCategoryTranslationInline]


class HelpArticleTranslationInline(admin.StackedInline):
    model = HelpArticleTranslation
    extra = 0


@admin.register(HelpArticle)
class HelpArticleAdmin(admin.ModelAdmin):
    list_display = ('slug', 'category', 'audience', 'order', 'is_published')
    list_filter = ('category', 'audience', 'is_published')
    search_fields = ('slug', 'translations__title')
    inlines = [HelpArticleTranslationInline]


admin.site.register(PolicyDocument)


class PolicyTranslationInline(admin.StackedInline):
    model = PolicyTranslation
    extra = 0


@admin.register(PolicyVersion)
class PolicyVersionAdmin(admin.ModelAdmin):
    list_display = ('document', 'version_number', 'status', 'effective_date', 'published_at')
    list_filter = ('document', 'status')
    inlines = [PolicyTranslationInline]


class TicketMessageInline(admin.TabularInline):
    model = TicketMessage
    extra = 0


@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    list_display = ('reference', 'subject', 'category', 'status', 'priority', 'user', 'last_activity_at')
    list_filter = ('status', 'category', 'priority')
    search_fields = ('reference', 'subject', 'user__email', 'contact_email')
    readonly_fields = ('reference',)
    inlines = [TicketMessageInline]


admin.site.register(TicketEvent)
