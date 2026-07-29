# PATH: backend/apps/messaging/views.py

from django.utils import timezone
from django.db.models import Q, Prefetch
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from apps.messaging.models import (
    Conversation, Message, Attachment, UserPresence,
    Reaction, ConversationUserState, MessageDeletion, BlockedUser, UserReport,
)
from apps.messaging.serializers import (
    ConversationSerializer, MessageSerializer, UserPresenceSerializer,
    ReactionSerializer, ConversationUserStateSerializer,
    BlockedUserSerializer, UserReportSerializer, AttachmentSerializer,
)
from apps.messaging.realtime import broadcast_new_message, broadcast_status_update, broadcast_reaction
from apps.users.models import User


def _is_blocked_either_way(user_a_id, user_b_id):
    return BlockedUser.objects.filter(
        Q(blocker_id=user_a_id, blocked_id=user_b_id) | Q(blocker_id=user_b_id, blocked_id=user_a_id)
    ).exists()


class ConversationListView(APIView):
    """
    GET  /api/messaging/conversations/           — my conversations, newest first
         ?search=name    → filter by the other participant's name
         ?archived=true   → show ONLY archived conversations (default: hide archived)
    POST /api/messaging/conversations/            — start (or fetch existing) conversation
         body: {"other_user_id": <id>}
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        conversations = (
            Conversation.objects
            .filter(Q(customer=user) | Q(professional=user))
            .prefetch_related(
                Prefetch('messages', queryset=Message.objects.order_by('-created_at')),
                Prefetch('user_states', queryset=ConversationUserState.objects.filter(user=user), to_attr='_my_states'),
            )
            .select_related('customer', 'professional')
            .order_by('-updated_at')
        )

        search = request.query_params.get('search', '').strip()
        want_archived = request.query_params.get('archived', '').lower() == 'true'

        results = []
        for conv in conversations:
            msgs = list(conv.messages.all())
            conv._last_msg_cache = msgs[0] if msgs else None
            conv._my_state_cache = conv._my_states[0] if conv._my_states else None

            other = conv.professional if user.id == conv.customer_id else conv.customer
            if search and search.lower() not in (other.name or '').lower():
                continue

            is_archived = bool(conv._my_state_cache and conv._my_state_cache.is_archived)
            if is_archived != want_archived:
                continue

            results.append(conv)

        # ✅ Pinned conversations float to the top (still newest-first within each group)
        results.sort(key=lambda c: (
            not (c._my_state_cache and c._my_state_cache.is_pinned),
            -c.updated_at.timestamp(),
        ))

        serializer = ConversationSerializer(results, many=True, context={'request': request})
        return Response(serializer.data)

    def post(self, request):
        other_user_id = request.data.get('other_user_id')
        if not other_user_id:
            return Response({'error': 'other_user_id is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            other_user = User.objects.get(id=other_user_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        user = request.user

        if user.role == other_user.role:
            return Response(
                {'error': 'Conversations are only allowed between a customer and a professional.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if user.role == 'professional':
            customer, professional = other_user, user
        else:
            customer, professional = user, other_user

        conversation, _ = Conversation.objects.get_or_create(customer=customer, professional=professional)
        return Response(ConversationSerializer(conversation, context={'request': request}).data, status=status.HTTP_200_OK)


class MessageListView(APIView):
    """
    GET  /api/messaging/conversations/<id>/messages/   — thread, oldest first, paginated
         ?limit=30&before_id=123
         ?search=text     → only messages containing this text (in this conversation)
    POST /api/messaging/conversations/<id>/messages/   — send a message
         body (multipart or json): {"text": "...", "reply_to_id": <id>, "image": <file>}
         or for a voice note: {"audio": <file>, "duration_seconds": 12}
    """
    permission_classes = [IsAuthenticated]

    def _get_conversation(self, request, conversation_id):
        try:
            conv = Conversation.objects.get(id=conversation_id)
        except Conversation.DoesNotExist:
            return None
        if request.user.id not in (conv.customer_id, conv.professional_id):
            return None
        return conv

    def get(self, request, conversation_id):
        conv = self._get_conversation(request, conversation_id)
        if conv is None:
            return Response({'error': 'Conversation not found.'}, status=status.HTTP_404_NOT_FOUND)

        # ✅ "Delete for me" — never show messages this user hid, regardless
        # of pagination/search.
        hidden_ids = MessageDeletion.objects.filter(user=request.user, message__conversation=conv).values_list('message_id', flat=True)

        qs = conv.messages.exclude(id__in=hidden_ids).select_related('sender', 'reply_to') \
            .prefetch_related('attachments', 'reactions')

        search = request.query_params.get('search', '').strip()
        if search:
            # Simple in-conversation text search — good enough for a chat
            # thread's size; a global cross-conversation search would need
            # its own indexed endpoint if that's ever needed.
            results = qs.filter(text__icontains=search).order_by('created_at')
            return Response({'results': MessageSerializer(results, many=True, context={'request': request}).data, 'has_more': False})

        try:
            limit = int(request.query_params.get('limit', 30))
        except (TypeError, ValueError):
            limit = 30
        limit = max(1, min(limit, 100))

        before_id = request.query_params.get('before_id')
        if before_id:
            try:
                before_id = int(before_id)
            except (TypeError, ValueError):
                return Response({'error': 'before_id must be an integer.'}, status=status.HTTP_400_BAD_REQUEST)
            qs = qs.filter(id__lt=before_id)

        page = list(qs.order_by('-created_at')[:limit])
        page.reverse()

        has_more = conv.messages.exclude(id__in=hidden_ids).filter(id__lt=page[0].id).exists() if page else False

        return Response({
            'results': MessageSerializer(page, many=True, context={'request': request}).data,
            'has_more': has_more,
        })

    def post(self, request, conversation_id):
        conv = self._get_conversation(request, conversation_id)
        if conv is None:
            return Response({'error': 'Conversation not found.'}, status=status.HTTP_404_NOT_FOUND)

        other_id = conv.professional_id if request.user.id == conv.customer_id else conv.customer_id

        # ✅ NEW — Block check. Either side blocking the other stops new
        # messages (existing history stays visible).
        if _is_blocked_either_way(request.user.id, other_id):
            return Response({'error': 'You cannot message this user.'}, status=status.HTTP_403_FORBIDDEN)

        text  = (request.data.get('text') or '').strip()
        image = request.FILES.get('image')
        audio = request.FILES.get('audio')  # ✅ NEW — voice messages
        reply_to_id = request.data.get('reply_to_id')

        if not text and not image and not audio:
            return Response({'error': 'Message must have text, an image, or a voice note.'}, status=status.HTTP_400_BAD_REQUEST)

        reply_to = None
        if reply_to_id:
            reply_to = Message.objects.filter(id=reply_to_id, conversation=conv).first()
            if reply_to is None:
                return Response({'error': 'reply_to message not found in this conversation.'}, status=status.HTTP_400_BAD_REQUEST)

        message = Message.objects.create(
            conversation=conv,
            sender=request.user,
            text=text,
            reply_to=reply_to,
            status=Message.STATUS_SENT,
        )

        if image:
            Attachment.objects.create(message=message, file=image, file_type=Attachment.FILE_TYPE_IMAGE)
        elif audio:
            duration = request.data.get('duration_seconds')
            try:
                duration = int(duration) if duration is not None else None
            except (TypeError, ValueError):
                duration = None
            Attachment.objects.create(message=message, file=audio, file_type=Attachment.FILE_TYPE_AUDIO, duration_seconds=duration)

        conv.save(update_fields=['updated_at'])

        # ✅ NEW — sending a message clears any saved draft for this user
        ConversationUserState.objects.filter(conversation=conv, user=request.user).update(draft_text='')

        message = Message.objects.select_related('sender', 'reply_to').prefetch_related('attachments', 'reactions').get(id=message.id)
        broadcast_new_message(message)

        return Response(MessageSerializer(message, context={'request': request}).data, status=status.HTTP_201_CREATED)


class MessageDetailView(APIView):
    """
    PATCH  /api/messaging/messages/<id>/            — edit own message text
    DELETE /api/messaging/messages/<id>/            — delete for everyone (sender only)
    DELETE /api/messaging/messages/<id>/?for=me      — delete for me only (either participant)
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, message_id):
        try:
            message = Message.objects.get(id=message_id, sender=request.user)
        except Message.DoesNotExist:
            return Response({'error': 'Message not found.'}, status=status.HTTP_404_NOT_FOUND)
        if message.is_deleted:
            return Response({'error': 'Cannot edit a deleted message.'}, status=status.HTTP_400_BAD_REQUEST)

        new_text = (request.data.get('text') or '').strip()
        if not new_text:
            return Response({'error': 'text is required.'}, status=status.HTTP_400_BAD_REQUEST)

        message.text = new_text
        message.edited_at = timezone.now()
        message.save(update_fields=['text', 'edited_at'])
        return Response(MessageSerializer(message, context={'request': request}).data)

    def delete(self, request, message_id):
        delete_for_me_only = request.query_params.get('for') == 'me'

        try:
            message = Message.objects.get(id=message_id)
        except Message.DoesNotExist:
            return Response({'error': 'Message not found.'}, status=status.HTTP_404_NOT_FOUND)

        if message.conversation.customer_id != request.user.id and message.conversation.professional_id != request.user.id:
            return Response({'error': 'Message not found.'}, status=status.HTTP_404_NOT_FOUND)

        if delete_for_me_only:
            # ✅ NEW — any participant can hide it for just themselves
            MessageDeletion.objects.get_or_create(message=message, user=request.user)
            return Response({'message': 'Deleted for you.'})

        # "Delete for everyone" — sender only
        if message.sender_id != request.user.id:
            return Response({'error': 'Only the sender can delete for everyone.'}, status=status.HTTP_403_FORBIDDEN)

        message.deleted_at = timezone.now()
        message.text = ''
        message.save(update_fields=['deleted_at', 'text'])
        return Response({'message': 'Deleted for everyone.'})


# ✅ NEW — Reactions
class ReactionView(APIView):
    """
    POST /api/messaging/messages/<id>/reactions/   body: {"emoji": "❤️"}
    Toggle behavior: same emoji again removes it; a different emoji replaces it.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, message_id):
        try:
            message = Message.objects.get(id=message_id)
        except Message.DoesNotExist:
            return Response({'error': 'Message not found.'}, status=status.HTTP_404_NOT_FOUND)
        if request.user.id not in (message.conversation.customer_id, message.conversation.professional_id):
            return Response({'error': 'Message not found.'}, status=status.HTTP_404_NOT_FOUND)

        emoji = (request.data.get('emoji') or '').strip()
        if not emoji:
            return Response({'error': 'emoji is required.'}, status=status.HTTP_400_BAD_REQUEST)

        existing = Reaction.objects.filter(message=message, user=request.user).first()
        if existing and existing.emoji == emoji:
            existing.delete()
            action = 'removed'
        elif existing:
            existing.emoji = emoji
            existing.save(update_fields=['emoji'])
            action = 'updated'
        else:
            Reaction.objects.create(message=message, user=request.user, emoji=emoji)
            action = 'added'

        message.refresh_from_db()
        broadcast_reaction(message)
        return Response({'action': action, 'message': MessageSerializer(message, context={'request': request}).data})


# ✅ NEW — Pin / Archive / Mute / Draft
class ConversationStateView(APIView):
    """
    PATCH /api/messaging/conversations/<id>/state/
    body (any subset): {"is_pinned": true, "is_archived": false, "is_muted": true,
                         "muted_until": "2026-08-01T00:00:00Z", "draft_text": "..."}
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, conversation_id):
        conv = Conversation.objects.filter(
            Q(id=conversation_id) & (Q(customer=request.user) | Q(professional=request.user))
        ).first()
        if conv is None:
            return Response({'error': 'Conversation not found.'}, status=status.HTTP_404_NOT_FOUND)

        state, _ = ConversationUserState.objects.get_or_create(conversation=conv, user=request.user)
        serializer = ConversationUserStateSerializer(state, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ✅ NEW — Shared media gallery (images + voice notes in one conversation)
class MediaGalleryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, conversation_id):
        conv = Conversation.objects.filter(
            Q(id=conversation_id) & (Q(customer=request.user) | Q(professional=request.user))
        ).first()
        if conv is None:
            return Response({'error': 'Conversation not found.'}, status=status.HTTP_404_NOT_FOUND)

        hidden_ids = MessageDeletion.objects.filter(user=request.user, message__conversation=conv).values_list('message_id', flat=True)
        attachments = Attachment.objects.filter(
            message__conversation=conv, message__deleted_at__isnull=True
        ).exclude(message_id__in=hidden_ids).order_by('-created_at')
        return Response(AttachmentSerializer(attachments, many=True).data)


# ✅ NEW — Block / Unblock / list blocked users
class BlockUserView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        blocks = BlockedUser.objects.filter(blocker=request.user)
        return Response(BlockedUserSerializer(blocks, many=True).data)

    def post(self, request):
        blocked_id = request.data.get('user_id')
        if not blocked_id:
            return Response({'error': 'user_id is required.'}, status=status.HTTP_400_BAD_REQUEST)
        if str(blocked_id) == str(request.user.id):
            return Response({'error': 'You cannot block yourself.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            target = User.objects.get(id=blocked_id)
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

        BlockedUser.objects.get_or_create(blocker=request.user, blocked=target)
        return Response({'message': f'{target.name} blocked.'})

    def delete(self, request, user_id):
        BlockedUser.objects.filter(blocker=request.user, blocked_id=user_id).delete()
        return Response({'message': 'Unblocked.'})


# ✅ NEW — Report a user
class ReportUserView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        reported_id = request.data.get('reported')
        if not reported_id:
            return Response({'error': 'reported (user id) is required.'}, status=status.HTTP_400_BAD_REQUEST)

        serializer = UserReportSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(reporter=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class MarkDeliveredView(APIView):
    """
    POST /api/messaging/conversations/<id>/mark-delivered/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, conversation_id):
        conv = Conversation.objects.filter(
            Q(id=conversation_id) & (Q(customer=request.user) | Q(professional=request.user))
        ).first()
        if conv is None:
            return Response({'error': 'Conversation not found.'}, status=status.HTTP_404_NOT_FOUND)

        pending_qs = conv.messages.filter(status=Message.STATUS_SENT).exclude(sender=request.user)
        ids = list(pending_qs.values_list('id', flat=True))
        updated = pending_qs.update(
            status=Message.STATUS_DELIVERED,
            delivered_at=timezone.now(),
        )

        if updated:
            broadcast_status_update(conv.id, 'delivered', ids, request.user.id)

        return Response({'updated': updated})


class MarkSeenView(APIView):
    """
    POST /api/messaging/conversations/<id>/mark-seen/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, conversation_id):
        conv = Conversation.objects.filter(
            Q(id=conversation_id) & (Q(customer=request.user) | Q(professional=request.user))
        ).first()
        if conv is None:
            return Response({'error': 'Conversation not found.'}, status=status.HTTP_404_NOT_FOUND)

        now = timezone.now()
        pending_qs = conv.messages.filter(read_at__isnull=True).exclude(sender=request.user)
        ids = list(pending_qs.values_list('id', flat=True))
        updated = pending_qs.update(
            status=Message.STATUS_SEEN,
            read_at=now,
            delivered_at=now,
        )

        if updated:
            broadcast_status_update(conv.id, 'seen', ids, request.user.id)

        return Response({'updated': updated})


class PresenceView(APIView):
    """
    GET  /api/messaging/presence/<user_id>/
    POST /api/messaging/presence/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id):
        presence = UserPresence.objects.filter(user_id=user_id).first()
        if presence is None:
            return Response({'is_online': False, 'last_seen': None})
        return Response(UserPresenceSerializer(presence).data)

    def post(self, request):
        is_online = bool(request.data.get('is_online', True))
        presence, _ = UserPresence.objects.get_or_create(user=request.user)
        presence.is_online = is_online
        presence.save(update_fields=['is_online', 'last_seen'])
        return Response(UserPresenceSerializer(presence).data)