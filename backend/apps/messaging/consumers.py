# PATH: backend/apps/messaging/consumers.py

import json
from django.utils import timezone
from django.db.models import Q
from django.contrib.auth.models import AnonymousUser
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from channels.db import database_sync_to_async

from apps.messaging.models import Conversation, Message, UserPresence
from apps.messaging.serializers import MessageSerializer


class ChatConsumer(AsyncJsonWebsocketConsumer):
    """
    One instance of this class = one connected client inside ONE
    conversation room. Route: ws/chat/<conversation_id>/?token=<jwt>
    """

    async def connect(self):
        self.user = self.scope['user']
        self.conversation_id = self.scope['url_route']['kwargs']['conversation_id']
        self.group_name = f'chat_{self.conversation_id}'

        # ✅ Security check 1 — must be logged in
        if isinstance(self.user, AnonymousUser) or not self.user.is_authenticated:
            await self.close(code=4001)  # 4xxx = custom app-level close codes
            return

        # ✅ Security check 2 — must actually be a participant of this
        # conversation (not just any logged-in user)
        is_member = await self._is_conversation_member()
        if not is_member:
            await self.close(code=4003)
            return

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

        # Mark online + tell the other participant
        await self._set_presence(is_online=True)
        await self.channel_layer.group_send(self.group_name, {
            'type': 'chat.presence',
            'user_id': self.user.id,
            'is_online': True,
            'last_seen': None,
        })

    async def disconnect(self, close_code):
        # If connect() rejected early, these attrs may not exist yet
        if not hasattr(self, 'group_name'):
            return

        await self.channel_layer.group_discard(self.group_name, self.channel_name)

        if getattr(self, 'user', None) and self.user.is_authenticated:
            last_seen = await self._set_presence(is_online=False)
            await self.channel_layer.group_send(self.group_name, {
                'type': 'chat.presence',
                'user_id': self.user.id,
                'is_online': False,
                'last_seen': last_seen.isoformat() if last_seen else None,
            })

    # ── Incoming messages from the client ──────────────────────────────
    async def receive_json(self, content, **kwargs):
        action = content.get('action')

        if action == 'send_message':
            await self._handle_send_message(content)
        elif action == 'typing':
            await self._handle_typing(content)
        elif action == 'mark_delivered':
            await self._handle_mark_delivered()
        elif action == 'mark_seen':
            await self._handle_mark_seen()
        else:
            await self.send_json({'error': f'Unknown action: {action}'})

    async def _handle_send_message(self, content):
        text = (content.get('text') or '').strip()
        reply_to_id = content.get('reply_to_id')
        temp_id = content.get('temp_id')  # client's local optimistic-UI id, echoed back for reconciliation

        if not text:
            await self.send_json({'error': 'text is required for send_message over WebSocket. Use the REST endpoint for images.'})
            return

        message = await self._create_message(text, reply_to_id)
        data = await self._serialize_message(message)
        if temp_id is not None:
            data['temp_id'] = temp_id

        await self.channel_layer.group_send(self.group_name, {
            'type': 'chat.message',
            'message': data,
        })

    async def _handle_typing(self, content):
        is_typing = bool(content.get('is_typing', True))
        await self.channel_layer.group_send(self.group_name, {
            'type': 'chat.typing',
            'user_id': self.user.id,
            'is_typing': is_typing,
        })

    async def _handle_mark_delivered(self):
        updated_ids = await self._mark_delivered()
        if updated_ids:
            await self.channel_layer.group_send(self.group_name, {
                'type': 'chat.status',
                'event': 'delivered',
                'message_ids': updated_ids,
                'actor_user_id': self.user.id,
            })

    async def _handle_mark_seen(self):
        updated_ids = await self._mark_seen()
        if updated_ids:
            await self.channel_layer.group_send(self.group_name, {
                'type': 'chat.status',
                'event': 'seen',
                'message_ids': updated_ids,
                'actor_user_id': self.user.id,
            })

    # ── Group event handlers — these fan back OUT to this client's socket ──
    # (method name must match the "type" string, with dots turned to underscores)
    async def chat_message(self, event):
        await self.send_json({'type': 'new_message', 'message': event['message']})

    async def chat_typing(self, event):
        if event['user_id'] == self.user.id:
            return  # don't echo my own typing back to myself
        await self.send_json({'type': 'typing', 'user_id': event['user_id'], 'is_typing': event['is_typing']})

    async def chat_status(self, event):
        await self.send_json({
            'type': 'status_update',
            'event': event['event'],
            'message_ids': event['message_ids'],
            'actor_user_id': event['actor_user_id'],
        })

    async def chat_presence(self, event):
        if event['user_id'] == self.user.id:
            return
        await self.send_json({
            'type': 'presence',
            'user_id': event['user_id'],
            'is_online': event['is_online'],
            'last_seen': event['last_seen'],
        })

    # ✅ NEW — forwards a reaction add/remove/change to everyone in the room
    async def chat_reaction(self, event):
        await self.send_json({'type': 'reaction_update', 'message': event['message']})

    # ── DB access (sync ORM wrapped for async consumer) ─────────────────
    @database_sync_to_async
    def _is_conversation_member(self):
        return Conversation.objects.filter(
            Q(id=self.conversation_id) & (Q(customer_id=self.user.id) | Q(professional_id=self.user.id))
        ).exists()

    @database_sync_to_async
    def _create_message(self, text, reply_to_id):
        reply_to = None
        if reply_to_id:
            reply_to = Message.objects.filter(id=reply_to_id, conversation_id=self.conversation_id).first()
        message = Message.objects.create(
            conversation_id=self.conversation_id,
            sender=self.user,
            text=text,
            reply_to=reply_to,
            status=Message.STATUS_SENT,
        )
        Conversation.objects.filter(id=self.conversation_id).update(updated_at=timezone.now())
        return message

    @database_sync_to_async
    def _serialize_message(self, message):
        message = Message.objects.select_related('sender', 'reply_to').prefetch_related('attachments').get(id=message.id)
        return MessageSerializer(message).data

    @database_sync_to_async
    def _mark_delivered(self):
        qs = Message.objects.filter(conversation_id=self.conversation_id, status=Message.STATUS_SENT).exclude(sender=self.user)
        ids = list(qs.values_list('id', flat=True))
        qs.update(status=Message.STATUS_DELIVERED, delivered_at=timezone.now())
        return ids

    @database_sync_to_async
    def _mark_seen(self):
        qs = Message.objects.filter(conversation_id=self.conversation_id, read_at__isnull=True).exclude(sender=self.user)
        ids = list(qs.values_list('id', flat=True))
        now = timezone.now()
        qs.update(status=Message.STATUS_SEEN, read_at=now, delivered_at=now)
        return ids

    @database_sync_to_async
    def _set_presence(self, is_online):
        presence, _ = UserPresence.objects.get_or_create(user=self.user)
        presence.is_online = is_online
        presence.save(update_fields=['is_online', 'last_seen'])
        return presence.last_seen