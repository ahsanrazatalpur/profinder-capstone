from django.contrib import admin
from apps.ai_engine.models import AIRecommendation, SearchHistory, LocalizedText

admin.site.register(AIRecommendation)
admin.site.register(SearchHistory)


@admin.register(LocalizedText)
class LocalizedTextAdmin(admin.ModelAdmin):
    """
    Optional manual override. Edit 'translated' and set status = Manual:
    that row then beats every automatic translation and is never overwritten.
    Delete a row to force a fresh automatic translation.
    """
    list_display = ('source', 'translated', 'lang', 'kind', 'status', 'updated_at')
    list_filter = ('lang', 'kind', 'status')
    search_fields = ('source', 'translated')
    readonly_fields = ('source_key', 'created_at', 'updated_at')

    def save_model(self, request, obj, form, change):
        if change and 'translated' in form.changed_data:
            obj.status = LocalizedText.STATUS_MANUAL      # a human edit = approved
        super().save_model(request, obj, form, change)