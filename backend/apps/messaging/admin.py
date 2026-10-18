# PATH: backend/apps/messaging/admin.py

from django.contrib import admin
from apps.messaging.models import (
    Conversation, Message, Attachment, UserPresence,
    Reaction, ConversationUserState, MessageDeletion, BlockedUser, UserReport,
)
from apps.notifications.utils import notify_user

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
    list_display  = ('reporter', 'reported', 'reason', 'is_reviewed', 'action_taken', 'created_at')
    list_filter   = ('reason', 'is_reviewed', 'action_taken')
    search_fields = ('reporter__email', 'reported__email', 'details')

    def save_model(self, request, obj, form, change):
        # Pehle purani state nikal lo (DB se), taake pata chale ke admin ne
        # ABHI is_reviewed/action_taken flip kiya hai ya pehle se set tha —
        # warna save() dobara call hone par baar baar notification chali
        # jayegi.
        was_reviewed = False
        was_action_taken = False
        if change and obj.pk:
            prev = UserReport.objects.filter(pk=obj.pk).values(
                'is_reviewed', 'action_taken').first()
            if prev:
                was_reviewed = prev['is_reviewed']
                was_action_taken = prev['action_taken']

        super().save_model(request, obj, form, change)

        just_reviewed = obj.is_reviewed and not was_reviewed
        just_actioned = obj.action_taken and not was_action_taken

        if just_reviewed:
            # Reporter ko hamesha batao ke unki report dekhi ja chuki hai —
            # result reveal kiye bina.
            target_name = getattr(obj.reported, 'name', None) if getattr(obj, 'reported', None) else None
            about_target = f" regarding {target_name}" if target_name else ""
            notify_user(
                obj.reporter,
                title='Your Report Was Reviewed',
                message=f"We've reviewed your report{about_target}. Thanks for helping keep the community safe.",
                notif_type='report',
                data={'report_id': obj.id, 'event': 'report_resolved'},
            )

        if just_actioned:
            # Sirf tab reported user ko warning jaye jab admin ne waqai
            # violation confirm ki ho — dismissed/reviewed-only reports par
            # unhe kabhi kuch nahi bataya jata.
            notify_user(
                obj.reported,
                title='Community Guidelines Warning',
                message="Your account has received a warning for violating our community guidelines. Repeated violations may lead to suspension.",
                notif_type='report',
                data={'report_id': obj.id, 'event': 'warning_issued'},
            )