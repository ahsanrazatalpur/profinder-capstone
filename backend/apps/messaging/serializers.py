# PATH: backend/apps/messaging/serializers.py

from rest_framework import serializers
from apps.messaging.models import (
    Conversation, Message, Attachment, UserPresence,
    Reaction, ConversationUserState, BlockedUser, UserReport,
)


class AttachmentSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()

    class Meta:
        model  = Attachment
        fields = ['id', 'file_url', 'file_type', 'duration_seconds', 'created_at']

    def get_file_url(self, obj):
        return obj.file.url if obj.file else None


class ReplyPreviewSerializer(serializers.ModelSerializer):
    """
    Lightweight preview of a replied-to message — just enough to render
    the little quote-box above a reply, not the full message payload.
    """
    sender_name = serializers.CharField(source='sender.name', read_only=True)
    has_attachment = serializers.SerializerMethodField()

    class Meta:
        model  = Message
        fields = ['id', 'sender_name', 'text', 'has_attachment']

    def get_has_attachment(self, obj):
        return obj.attachments.exists()


class MessageSerializer(serializers.ModelSerializer):
    sender_name    = serializers.CharField(source='sender.name', read_only=True)
    attachments    = AttachmentSerializer(many=True, read_only=True)
    reply_to       = ReplyPreviewSerializer(read_only=True)
    reply_to_id    = serializers.PrimaryKeyRelatedField(
        queryset=Message.objects.all(), source='reply_to', write_only=True, required=False, allow_null=True
    )
    is_edited  = serializers.BooleanField(read_only=True)
    is_deleted = serializers.BooleanField(read_only=True)

    # ✅ NEW — reactions grouped by emoji, e.g. {"❤️": 3, "👍": 1}, plus
    # which emoji (if any) the REQUESTING user picked, so the UI can
    # highlight their own reaction.
    reactions     = serializers.SerializerMethodField()
    my_reaction   = serializers.SerializerMethodField()

    class Meta:
        model  = Message
        fields = [
            'id', 'conversation', 'sender', 'sender_name', 'text',
            'reply_to', 'reply_to_id', 'attachments',
            'status', 'created_at', 'delivered_at', 'read_at', 'edited_at', 'deleted_at',
            'is_edited', 'is_deleted', 'reactions', 'my_reaction',
        ]
        read_only_fields = ['sender', 'sender_name', 'status', 'created_at',
                             'delivered_at', 'read_at', 'edited_at', 'deleted_at']

    def get_reactions(self, obj):
        counts = {}
        for r in obj.reactions.all():
            counts[r.emoji] = counts.get(r.emoji, 0) + 1
        return counts

    def get_my_reaction(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        mine = next((r for r in obj.reactions.all() if r.user_id == request.user.id), None)
        return mine.emoji if mine else None

    def validate_text(self, value):
        return value.strip()

    def validate_reply_to(self, value):
        # A reply must point to a message in the SAME conversation —
        # enforced fully in the view (where conversation is known); here
        # we just guard against obviously deleted messages.
        if value and value.is_deleted:
            raise serializers.ValidationError("Cannot reply to a deleted message.")
        return value


class ConversationSerializer(serializers.ModelSerializer):
    """
    Used for the conversation LIST — includes the other participant's info
    (name/photo/online status), a preview of the last message, unread
    count, and now this user's own pin/archive/mute/draft state.
    """
    other_user_id       = serializers.SerializerMethodField()
    other_user_name     = serializers.SerializerMethodField()
    other_user_photo    = serializers.SerializerMethodField()
    other_user_online   = serializers.SerializerMethodField()
    other_user_last_seen = serializers.SerializerMethodField()
    last_message         = serializers.SerializerMethodField()
    last_message_at       = serializers.SerializerMethodField()
    last_message_status   = serializers.SerializerMethodField()
    unread_count         = serializers.SerializerMethodField()

    # ✅ NEW — per-user state
    is_pinned    = serializers.SerializerMethodField()
    is_archived  = serializers.SerializerMethodField()
    is_muted     = serializers.SerializerMethodField()
    draft_text   = serializers.SerializerMethodField()

    class Meta:
        model  = Conversation
        fields = ['id', 'other_user_id', 'other_user_name', 'other_user_photo',
                  'other_user_online', 'other_user_last_seen',
                  'last_message', 'last_message_at', 'last_message_status',
                  'unread_count', 'updated_at',
                  'is_pinned', 'is_archived', 'is_muted', 'draft_text']

    def _other_user(self, obj):
        request_user = self.context['request'].user
        return obj.professional if request_user.id == obj.customer_id else obj.customer

    def _last_message(self, obj):
        # Prefetched in the view as `_last_msg_cache` where possible;
        # falls back to a query here for safety.
        return getattr(obj, '_last_msg_cache', None) or obj.messages.order_by('-created_at').first()

    def _my_state(self, obj):
        # Prefetched in the view as `_my_state_cache`; falls back to a
        # query for safety (e.g. serializer used outside that view).
        if hasattr(obj, '_my_state_cache'):
            return obj._my_state_cache
        request_user = self.context['request'].user
        return ConversationUserState.objects.filter(conversation=obj, user=request_user).first()

    def get_other_user_id(self, obj):
        return self._other_user(obj).id

    def get_other_user_name(self, obj):
        return self._other_user(obj).name

    def get_other_user_photo(self, obj):
        other = self._other_user(obj)
        try:
            if hasattr(other, 'professionalprofile') and other.professionalprofile.photo_url:
                return other.professionalprofile.photo_url.url
            if hasattr(other, 'userprofile') and other.userprofile.photo_url:
                return other.userprofile.photo_url.url
        except Exception:
            pass
        return None

    def get_other_user_online(self, obj):
        other = self._other_user(obj)
        return getattr(other, 'presence', None) and other.presence.is_online

    def get_other_user_last_seen(self, obj):
        other = self._other_user(obj)
        presence = getattr(other, 'presence', None)
        return presence.last_seen.isoformat() if presence else None

    def get_last_message(self, obj):
        last = self._last_message(obj)
        if not last:
            return ''
        if last.is_deleted:
            return 'This message was deleted'
        if last.text:
            return last.text
        if last.attachments.filter(file_type='audio').exists():
            return '🎤 Voice message'
        return '📷 Photo' if last.attachments.exists() else ''

    def get_last_message_at(self, obj):
        last = self._last_message(obj)
        return last.created_at.isoformat() if last else None

    def get_last_message_status(self, obj):
        last = self._last_message(obj)
        return last.status if last else None

    def get_unread_count(self, obj):
        request_user = self.context['request'].user
        return obj.messages.filter(read_at__isnull=True).exclude(sender=request_user).count()

    def get_is_pinned(self, obj):
        state = self._my_state(obj)
        return bool(state and state.is_pinned)

    def get_is_archived(self, obj):
        state = self._my_state(obj)
        return bool(state and state.is_archived)

    def get_is_muted(self, obj):
        state = self._my_state(obj)
        return bool(state and state.is_currently_muted)

    def get_draft_text(self, obj):
        state = self._my_state(obj)
        return state.draft_text if state else ''


class UserPresenceSerializer(serializers.ModelSerializer):
    class Meta:
        model  = UserPresence
        fields = ['is_online', 'last_seen']


# ✅ NEW — Reactions
class ReactionSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Reaction
        fields = ['id', 'message', 'user', 'emoji', 'created_at']
        read_only_fields = ['user', 'created_at']

    def validate_emoji(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError("emoji is required.")
        return value


# ✅ NEW — Pin / Archive / Mute / Draft (partial updates only — see view)
class ConversationUserStateSerializer(serializers.ModelSerializer):
    class Meta:
        model  = ConversationUserState
        fields = ['is_pinned', 'is_archived', 'is_muted', 'muted_until', 'draft_text']


# ✅ NEW — Block / Report
class BlockedUserSerializer(serializers.ModelSerializer):
    blocked_name = serializers.CharField(source='blocked.name', read_only=True)

    class Meta:
        model  = BlockedUser
        fields = ['id', 'blocked', 'blocked_name', 'created_at']
        read_only_fields = ['created_at']


class UserReportSerializer(serializers.ModelSerializer):
    class Meta:
        model  = UserReport
        fields = ['id', 'reported', 'reason', 'details', 'message', 'created_at']
        read_only_fields = ['created_at']

    def validate_details(self, value):
        return value.strip()