# PATH: backend/apps/messaging/push.py
#
# ✅ Chat-specific push notification building — kept separate from the
# generic apps/notifications/utils.py so messaging-domain logic (who's
# the recipient, unread badge count, mute status, message preview format)
# doesn't leak into the shared/generic notification helper.
#
# ⚠️ This file existed in an earlier round but was never actually applied
# to the live project — recreated here as part of the final integration.

from django.db.models import Q
from django.utils import timezone
from apps.notifications.utils import send_fcm_push
from apps.messaging.models import Message, ConversationUserState


def get_unread_message_count(user):
    """
    Total unread messages across ALL of this user's conversations
    (as customer OR professional), excluding messages they sent
    themselves. Used for the app badge count.
    """
    return Message.objects.filter(
        Q(conversation__customer=user) | Q(conversation__professional=user),
        read_at__isnull=True,
    ).exclude(sender=user).count()


def _preview_text(message):
    if message.is_deleted:
        return 'This message was deleted'
    if message.text:
        return message.text[:100]
    if message.attachments.filter(file_type='audio').exists():
        return '🎤 Voice message'
    if message.attachments.exists():
        return '📷 Photo'
    return 'New message'


def _sender_photo_url(sender):
    try:
        if hasattr(sender, 'professionalprofile') and sender.professionalprofile.photo_url:
            return sender.professionalprofile.photo_url.url
        if hasattr(sender, 'userprofile') and sender.userprofile.photo_url:
            return sender.userprofile.photo_url.url
    except Exception:
        pass
    return ''


def _is_sender_the_customer(message):
    return message.sender_id == message.conversation.customer_id


def _recipient_has_muted(conversation, recipient):
    # ✅ NEW — respects the "Mute conversation" feature
    state = ConversationUserState.objects.filter(conversation=conversation, user=recipient).first()
    if not state or not state.is_muted:
        return False
    if state.muted_until is None:
        return True
    return timezone.now() < state.muted_until


def notify_new_message(message):
    """
    Call this right after a Message is created (both the WebSocket
    consumer and the REST endpoint go through realtime.py's
    broadcast_new_message(), which is the single choke point that calls
    this — so every send path is covered automatically).

    "Notify only the receiver" — we explicitly resolve the OTHER
    participant; the sender never gets pinged for their own message.
    Blocked senders never reach this point at all (MessageListView.post
    rejects the send before a Message row is even created).
    """
    conversation = message.conversation
    sender = message.sender
    recipient = conversation.professional if _is_sender_the_customer(message) else conversation.customer

    if _recipient_has_muted(conversation, recipient):
        return False

    fcm_token = getattr(recipient, 'fcm_token', None)
    if not fcm_token:
        return False

    badge = get_unread_message_count(recipient)

    return send_fcm_push(
        fcm_token=fcm_token,
        title=sender.name,
        body=_preview_text(message),
        data={
            'type':             'chat_message',
            'conversation_id':  conversation.id,
            'message_id':       message.id,
            'sender_id':        sender.id,
            'sender_name':      sender.name,
            'sender_photo':     _sender_photo_url(sender),
            'timestamp':        message.created_at.isoformat(),
        },
        badge=badge,
        channel_id='profinder_chat_channel',
    )