# PATH: backend/apps/messaging/realtime.py
#
# ✅ NEW — Shared broadcast helpers. Both the WebSocket consumer AND the
# REST views (e.g. sending an image message via multipart, which a plain
# WebSocket text frame can't carry) call these so every code path that
# creates/updates a message ends up notifying connected clients the same way.

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from apps.messaging.push import notify_new_message  # ✅ RESTORED — was never applied in the live project


def _group_name(conversation_id):
    return f'chat_{conversation_id}'


def broadcast_new_message(message):
    """Call after a Message (+ optional Attachment) has been saved."""
    from apps.messaging.serializers import MessageSerializer  # local import avoids circulars

    channel_layer = get_channel_layer()
    if channel_layer is not None:
        data = MessageSerializer(message).data
        async_to_sync(channel_layer.group_send)(
            _group_name(message.conversation_id),
            {'type': 'chat.message', 'message': data},
        )

    # Push notification to the receiver (covers background/terminated app
    # states that WebSocket alone can't reach). Mute/block checks happen
    # inside notify_new_message() itself.
    try:
        notify_new_message(message)
    except Exception:
        pass  # push failures must never break the message-send request


# ✅ NEW — Reactions
def broadcast_reaction(message):
    from apps.messaging.serializers import MessageSerializer

    channel_layer = get_channel_layer()
    if channel_layer is None:
        return

    data = MessageSerializer(message).data
    async_to_sync(channel_layer.group_send)(
        _group_name(message.conversation_id),
        {'type': 'chat.reaction', 'message': data},
    )


def broadcast_status_update(conversation_id, event, message_ids, actor_user_id):
    """
    event: 'delivered' or 'seen'
    Tells the SENDER's client (still connected in the room) that their
    messages just changed status, so it can update the little ticks live.
    """
    channel_layer = get_channel_layer()
    if channel_layer is None:
        return

    async_to_sync(channel_layer.group_send)(
        _group_name(conversation_id),
        {
            'type': 'chat.status',
            'event': event,
            'message_ids': list(message_ids),
            'actor_user_id': actor_user_id,
        },
    )


def broadcast_typing(conversation_id, user_id, is_typing):
    channel_layer = get_channel_layer()
    if channel_layer is None:
        return

    async_to_sync(channel_layer.group_send)(
        _group_name(conversation_id),
        {'type': 'chat.typing', 'user_id': user_id, 'is_typing': is_typing},
    )


def broadcast_presence(conversation_id, user_id, is_online, last_seen):
    channel_layer = get_channel_layer()
    if channel_layer is None:
        return

    async_to_sync(channel_layer.group_send)(
        _group_name(conversation_id),
        {
            'type': 'chat.presence',
            'user_id': user_id,
            'is_online': is_online,
            'last_seen': last_seen.isoformat() if last_seen else None,
        },
    )