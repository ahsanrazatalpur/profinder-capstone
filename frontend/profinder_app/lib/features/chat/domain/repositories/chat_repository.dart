// lib/features/chat/domain/repositories/chat_repository.dart
//
// The contract. `presentation` only ever talks to this interface — it has
// no idea whether messages arrive over REST or WebSocket underneath.

import 'dart:io';
import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';

/// Base type for anything the live WebSocket connection can push at us.
/// Modeled as a small sealed-style hierarchy instead of a generic
/// Map<String,dynamic> so the provider gets exhaustive-switch safety.
abstract class ChatSocketEvent {
  const ChatSocketEvent();
}

class NewMessageSocketEvent extends ChatSocketEvent {
  final MessageEntity message;
  final String? tempId; // present when this is the echo of our own optimistic send
  const NewMessageSocketEvent(this.message, {this.tempId});
}

class TypingSocketEvent extends ChatSocketEvent {
  final int userId;
  final bool isTyping;
  const TypingSocketEvent(this.userId, this.isTyping);
}

class StatusUpdateSocketEvent extends ChatSocketEvent {
  final String event; // 'delivered' | 'seen'
  final List<String> messageIds;
  final int actorUserId;
  const StatusUpdateSocketEvent(this.event, this.messageIds, this.actorUserId);
}

class PresenceSocketEvent extends ChatSocketEvent {
  final int userId;
  final bool isOnline;
  final DateTime? lastSeen;
  const PresenceSocketEvent(this.userId, this.isOnline, this.lastSeen);
}

// ✅ NEW — a reaction was added/changed/removed on a message
class ReactionSocketEvent extends ChatSocketEvent {
  final MessageEntity message; // full updated message, including new reactions map
  const ReactionSocketEvent(this.message);
}

class SocketErrorEvent extends ChatSocketEvent {
  final String message;
  const SocketErrorEvent(this.message);
}

// ✅ NEW — small supporting entities, co-located here since they're only
// ever produced/consumed through the repository (not worth a separate file each).
class MediaAttachmentEntity {
  final String id;
  final String fileUrl;
  final String fileType; // 'image' | 'audio'
  final int? durationSeconds;
  final DateTime createdAt;
  const MediaAttachmentEntity({
    required this.id,
    required this.fileUrl,
    required this.fileType,
    this.durationSeconds,
    required this.createdAt,
  });
}

class BlockedUserEntity {
  final int id;
  final int blockedUserId;
  final String blockedUserName;
  final DateTime createdAt;
  const BlockedUserEntity({
    required this.id,
    required this.blockedUserId,
    required this.blockedUserName,
    required this.createdAt,
  });
}

abstract class ChatRepository {
  // ── Conversations ───────────────────────────────────────────────────
  Future<List<ConversationEntity>> getConversations({String? search, bool archived = false});
  Future<ConversationEntity> startConversation(int otherUserId);

  // ✅ NEW — pin / archive / mute / draft (all one PATCH under the hood)
  Future<void> setPinned(int conversationId, bool value);
  Future<void> setArchived(int conversationId, bool value);
  Future<void> setMuted(int conversationId, bool value, {DateTime? until});
  Future<void> saveDraft(int conversationId, String text);

  // ── Messages (REST) ─────────────────────────────────────────────────
  /// [beforeId] = null fetches the newest page. Pass the oldest currently
  /// loaded message id to page further back in history.
  /// Returns a record so callers get `hasMore` without a wrapper class.
  Future<({List<MessageEntity> messages, bool hasMore})> getMessages(
    int conversationId, {
    String? beforeId,
    int limit = 30,
  });

  Future<MessageEntity> sendMessage(
    int conversationId, {
    String? text,
    String? replyToId,
    File? image,
  });

  // ✅ NEW — voice notes reuse the same upload flow with a distinct field
  Future<MessageEntity> sendVoiceMessage(
    int conversationId, {
    required File audio,
    required int durationSeconds,
    String? replyToId,
  });

  Future<MessageEntity> editMessage(String messageId, String newText);

  /// forEveryone=true (default) soft-deletes for both sides (sender only).
  /// forEveryone=false hides it just for the caller ("delete for me").
  Future<void> deleteMessage(String messageId, {bool forEveryone = true});

  Future<void> markDelivered(int conversationId);
  Future<void> markSeen(int conversationId);

  // ✅ NEW — reactions. Passing the SAME emoji again removes it (toggle).
  Future<MessageEntity> toggleReaction(String messageId, String emoji);

  // ✅ NEW — search text within one conversation's history
  Future<List<MessageEntity>> searchMessages(int conversationId, String query);

  // ✅ NEW — shared media gallery for a conversation
  Future<List<MediaAttachmentEntity>> getMedia(int conversationId);

  // ✅ NEW — block / report
  Future<List<BlockedUserEntity>> getBlockedUsers();
  Future<void> blockUser(int userId);
  Future<void> unblockUser(int userId);
  Future<void> reportUser(int userId, String reason, String details, {String? messageId});

  // ── Realtime (WebSocket) ─────────────────────────────────────────────
  Stream<ChatSocketEvent> connectSocket(int conversationId);
  void sendTyping(bool isTyping);
  void sendSocketMessage({required String text, String? replyToId, required String tempId});
  void disconnectSocket();
}