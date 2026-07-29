# PATH: backend/apps/messaging/admin.py

from django.contrib import admin
from apps.messaging.models import (
    Conversation, Message, Attachment, UserPresence,
    Reaction, ConversationUserState, MessageDeletion, BlockedUser, UserReport,
)

admin.site.register(Conversation)
admin.site.register(Message)
admin.site.register(Attachment)
admin.site.register(UserPresence)
admin.site.register(Reaction)              # ✅ NEW
admin.site.register(ConversationUserState) # ✅ NEW
admin.site.register(MessageDeletion)       # ✅ NEW
admin.site.register(BlockedUser)           # ✅ NEW


@admin.register(UserReport)
class UserReportAdmin(admin.ModelAdmin):
    # ✅ NEW — a bit of care here since this is the one moderation queue
    # an admin will actually work from day to day.
    list_display  = ('reporter', 'reported', 'reason', 'is_reviewed', 'created_at')
    list_filter   = ('reason', 'is_reviewed')
    search_fields = ('reporter__email', 'reported__email', 'details')