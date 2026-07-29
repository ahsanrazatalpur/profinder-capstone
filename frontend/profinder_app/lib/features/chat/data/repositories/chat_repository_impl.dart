// lib/features/chat/data/repositories/chat_repository_impl.dart

import 'dart:async';
import 'dart:io';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../datasources/chat_socket_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remote;
  final ChatSocketDataSource _socket;

  ChatRepositoryImpl({ChatRemoteDataSource? remote, ChatSocketDataSource? socket})
      : _remote = remote ?? ChatRemoteDataSource(),
        _socket = socket ?? ChatSocketDataSource();

  @override
  Future<List<ConversationEntity>> getConversations({String? search, bool archived = false}) =>
      _remote.getConversations(search: search, archived: archived);

  @override
  Future<ConversationEntity> startConversation(int otherUserId) => _remote.startConversation(otherUserId);

  // ✅ NEW — pin / archive / mute / draft
  @override
  Future<void> setPinned(int conversationId, bool value) => _remote.setPinned(conversationId, value);

  @override
  Future<void> setArchived(int conversationId, bool value) => _remote.setArchived(conversationId, value);

  @override
  Future<void> setMuted(int conversationId, bool value, {DateTime? until}) =>
      _remote.setMuted(conversationId, value, until: until);

  @override
  Future<void> saveDraft(int conversationId, String text) => _remote.saveDraft(conversationId, text);

  @override
  Future<({List<MessageEntity> messages, bool hasMore})> getMessages(
    int conversationId, {
    String? beforeId,
    int limit = 30,
  }) async {
    final page = await _remote.getMessages(conversationId, beforeId: beforeId, limit: limit);
    return (messages: page.messages, hasMore: page.hasMore);
  }

  @override
  Future<MessageEntity> sendMessage(int conversationId, {String? text, String? replyToId, File? image}) {
    return _remote.sendMessage(conversationId, text: text, replyToId: replyToId, image: image);
  }

  // ✅ NEW — voice messages
  @override
  Future<MessageEntity> sendVoiceMessage(
    int conversationId, {
    required File audio,
    required int durationSeconds,
    String? replyToId,
  }) {
    return _remote.sendVoiceMessage(conversationId, audio: audio, durationSeconds: durationSeconds, replyToId: replyToId);
  }

  @override
  Future<MessageEntity> editMessage(String messageId, String newText) => _remote.editMessage(messageId, newText);

  @override
  Future<void> deleteMessage(String messageId, {bool forEveryone = true}) =>
      _remote.deleteMessage(messageId, forEveryone: forEveryone);

  @override
  Future<void> markDelivered(int conversationId) => _remote.markDelivered(conversationId);

  @override
  Future<void> markSeen(int conversationId) => _remote.markSeen(conversationId);

  // ✅ NEW — reactions
  @override
  Future<MessageEntity> toggleReaction(String messageId, String emoji) => _remote.toggleReaction(messageId, emoji);

  // ✅ NEW — search
  @override
  Future<List<MessageEntity>> searchMessages(int conversationId, String query) =>
      _remote.searchMessages(conversationId, query);

  // ✅ NEW — media gallery
  @override
  Future<List<MediaAttachmentEntity>> getMedia(int conversationId) => _remote.getMedia(conversationId);

  // ✅ NEW — block / report
  @override
  Future<List<BlockedUserEntity>> getBlockedUsers() => _remote.getBlockedUsers();

  @override
  Future<void> blockUser(int userId) => _remote.blockUser(userId);

  @override
  Future<void> unblockUser(int userId) => _remote.unblockUser(userId);

  @override
  Future<void> reportUser(int userId, String reason, String details, {String? messageId}) =>
      _remote.reportUser(userId, reason, details, messageId: messageId);

  @override
  Stream<ChatSocketEvent> connectSocket(int conversationId) {
    // connect() is async but the interface wants a Stream synchronously —
    // bridge with a StreamController that forwards once the real socket
    // stream is ready. Keeps ChatProvider's call site a plain `.listen(...)`.
    late final _ForwardingStream forwarder;
    forwarder = _ForwardingStream();
    _socket.connect(conversationId).then((stream) => forwarder.attach(stream));
    return forwarder.stream;
  }

  @override
  void sendTyping(bool isTyping) => _socket.sendTyping(isTyping);

  @override
  void sendSocketMessage({required String text, String? replyToId, required String tempId}) {
    _socket.sendMessage(text: text, replyToId: replyToId, tempId: tempId);
  }

  @override
  void disconnectSocket() => _socket.disconnect();

  // Note: mark-delivered/mark-seen are only exposed over REST in this
  // repository (see markDelivered/markSeen above). The consumer *can*
  // also handle those as socket actions, but the REST views already call
  // broadcast_status_update() (apps/messaging/realtime.py), so calling
  // REST once has the same real-time effect without a second code path.
}

/// Tiny helper: exposes a Stream immediately, then forwards every event
/// from the "real" stream once it resolves. Lets connectSocket() have a
/// synchronous signature despite the underlying connect being async.
class _ForwardingStream {
  final _controller = StreamController<ChatSocketEvent>.broadcast();
  Stream<ChatSocketEvent> get stream => _controller.stream;

  void attach(Stream<ChatSocketEvent> source) {
    source.listen(
      _controller.add,
      onError: _controller.addError,
      onDone: _controller.close,
    );
  }
}