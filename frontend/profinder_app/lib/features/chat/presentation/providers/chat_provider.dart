// lib/features/chat/presentation/providers/chat_provider.dart
//
// The engine behind ChatScreen. Owns:
//  - the message list (ascending, oldest -> newest) + pagination
//  - optimistic send (text goes over WebSocket when connected, falls back
//    to REST; images always go over REST since consumers.py only accepts
//    text frames)
//  - live typing indicator (with auto-clear timeout, since a "stopped
//    typing" event can be lost if the other side's app is killed)
//  - online/last-seen presence
//  - reply-to state for the input bar

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/message_status.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/models/message_model.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repo;
  final int conversationId;
  final int currentUserId;
  int? _otherUserId; // ✅ NEW — for the "Block user" menu action

  // ✅ NEW — block/unblock visibility. `isBlockedByMe` drives the "You
  // blocked X" banner + swaps the menu action to "Unblock". `canMessage`
  // covers BOTH directions (mine or theirs) and gates the input bar —
  // it never reveals which side did the blocking if it was the other user.
  bool isBlockedByMe = false;
  bool canMessage = true;

  ChatProvider({
    required this.conversationId,
    required this.currentUserId,
    ChatRepository? repo,
    ConversationEntity? initialSnapshot,
  }) : _repo = repo ?? ChatRepositoryImpl() {
    if (initialSnapshot != null) {
      otherUserOnline = initialSnapshot.otherUserOnline;
      otherUserLastSeen = initialSnapshot.otherUserLastSeen;
      initialDraftText = initialSnapshot.draftText;
      _otherUserId = initialSnapshot.otherUserId; // ✅ NEW
      isBlockedByMe = initialSnapshot.isBlockedByMe;
      canMessage = initialSnapshot.canMessage;
    }
  }

  // ✅ NEW
  Future<void> blockOtherUser() async {
    if (_otherUserId == null) return;
    await _repo.blockUser(_otherUserId!);
    isBlockedByMe = true;
    canMessage = false;
    notifyListeners();
  }

  // ✅ NEW — Instagram-style unblock, straight from the chat itself.
  Future<void> unblockOtherUser() async {
    if (_otherUserId == null) return;
    await _repo.unblockUser(_otherUserId!);
    isBlockedByMe = false;
    // Optimistic: if the other side had *also* blocked me independently,
    // the next send attempt will still 403 with code 'blocked' and
    // _handleBlockedError below will flip this back and show the banner.
    canMessage = true;
    notifyListeners();
  }

  // ✅ NEW — central place any send path calls on a blocked-send failure,
  // so the input locks immediately without needing to reopen the chat.
  void _handleBlockedError(Object error) {
    final msg = error.toString();
    if (msg.contains('"code":"blocked"') || msg.contains("'code': 'blocked'") || msg.contains('code: blocked')) {
      canMessage = false;
      notifyListeners();
    }
  }

  // ✅ NEW — pre-fills the input bar when the screen first opens
  String initialDraftText = '';

  // ── State ────────────────────────────────────────────────────────────
  final List<MessageEntity> _messages = []; // ascending: oldest first
  List<MessageEntity> get messages => List.unmodifiable(_messages);

  bool isLoadingInitial = true;
  bool isLoadingMore = false;
  bool hasMoreHistory = true;
  String? loadError;

  bool otherUserTyping = false;
  bool otherUserOnline = false;
  DateTime? otherUserLastSeen;

  MessageEntity? replyingTo;

  StreamSubscription<ChatSocketEvent>? _socketSub;
  Timer? _typingClearTimer;
  Timer? _typingDebounce;
  Timer? _draftDebounce;  // ✅ NEW
  bool _iAmTyping = false;

  // ── Lifecycle ────────────────────────────────────────────────────────
  Future<void> init() async {
    await loadInitialMessages();
    _connectSocket();
    // Fire-and-forget: tell the server we've now seen/received everything
    // currently in this conversation.
    unawaited(_repo.markDelivered(conversationId));
    unawaited(markSeen());
  }

  void _connectSocket() {
    _socketSub = _repo.connectSocket(conversationId).listen(_handleSocketEvent);
  }

  @override
  void dispose() {
    _typingClearTimer?.cancel();
    _typingDebounce?.cancel();
    _draftDebounce?.cancel();
    _socketSub?.cancel();
    _repo.disconnectSocket();
    super.dispose();
  }

  // ── Loading & pagination ─────────────────────────────────────────────
  Future<void> loadInitialMessages() async {
    isLoadingInitial = true;
    loadError = null;
    notifyListeners();

    try {
      final page = await _repo.getMessages(conversationId, limit: 30);
      _messages
        ..clear()
        ..addAll(page.messages);
      hasMoreHistory = page.hasMore;
    } catch (_) {
      loadError = 'Could not load messages';
    }

    isLoadingInitial = false;
    notifyListeners();
  }

  /// Called when the user scrolls to the top of the history.
  Future<void> loadMoreHistory() async {
    if (isLoadingMore || !hasMoreHistory || _messages.isEmpty) return;

    // The oldest loaded message must be a real (numeric) server id — an
    // optimistic temp message can never be the oldest since new messages
    // are always appended at the bottom.
    final oldest = _messages.first;

    isLoadingMore = true;
    notifyListeners();

    try {
      final page = await _repo.getMessages(conversationId, beforeId: oldest.id, limit: 30);
      _messages.insertAll(0, page.messages);
      hasMoreHistory = page.hasMore;
    } catch (_) {
      // Silently keep hasMoreHistory as-is — user can just try scrolling again.
    }

    isLoadingMore = false;
    notifyListeners();
  }

  // ── Sending (optimistic UI) ──────────────────────────────────────────
  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !canMessage) return;

    final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';
    final replyPreview = replyingTo == null
        ? null
        : ReplyPreviewEntity(
            id: replyingTo!.id,
            senderName: replyingTo!.senderName,
            text: replyingTo!.text,
            hasAttachment: replyingTo!.hasImage,
          );
    final replyToId = replyingTo?.id;
    clearReply();

    final optimistic = MessageModel.optimistic(
      tempId: tempId,
      conversationId: conversationId,
      senderId: currentUserId,
      senderName: 'You',
      text: trimmed,
      replyTo: replyPreview,
    );
    _messages.add(optimistic);
    notifyListeners();

    // Prefer the live socket (instant, and the recipient gets it via the
    // same group_send) — but only for text; fall back to REST if the
    // socket isn't connected, or if it doesn't ack in time.
    if (_socketSub != null) {
      _repo.sendSocketMessage(text: trimmed, replyToId: replyToId, tempId: tempId);
      _scheduleAckTimeout(tempId, () => _sendViaRest(tempId, trimmed, replyToId));
    } else {
      await _sendViaRest(tempId, trimmed, replyToId);
    }
  }

  Future<void> sendImage(File image, {String? caption}) async {
    if (!canMessage) return;
    final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';
    final replyToId = replyingTo?.id;
    clearReply();

    final optimistic = MessageModel.optimistic(
      tempId: tempId,
      conversationId: conversationId,
      senderId: currentUserId,
      senderName: 'You',
      text: caption ?? '',
      localImagePath: image.path,
    );
    _messages.add(optimistic);
    notifyListeners();

    try {
      final sent = await _repo.sendMessage(conversationId, text: caption, replyToId: replyToId, image: image);
      _replaceOptimistic(tempId, sent);
    } catch (e) {
      _markFailed(tempId);
      _handleBlockedError(e);
    }
  }

  // ✅ NEW — voice messages, same optimistic pattern as sendImage
  Future<void> sendVoice(File audio, int durationSeconds) async {
    if (!canMessage) return;
    final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';
    final replyToId = replyingTo?.id;
    clearReply();

    final optimistic = MessageModel.optimistic(
      tempId: tempId,
      conversationId: conversationId,
      senderId: currentUserId,
      senderName: 'You',
      text: '',
      localAudioPath: audio.path,
      audioDurationSeconds: durationSeconds,
    );
    _messages.add(optimistic);
    notifyListeners();

    try {
      final sent = await _repo.sendVoiceMessage(
        conversationId,
        audio: audio,
        durationSeconds: durationSeconds,
        replyToId: replyToId,
      );
      _replaceOptimistic(tempId, sent);
    } catch (e) {
      _markFailed(tempId);
      _handleBlockedError(e);
    }
  }

  Future<void> _sendViaRest(String tempId, String text, String? replyToId) async {
    try {
      final sent = await _repo.sendMessage(conversationId, text: text, replyToId: replyToId);
      _replaceOptimistic(tempId, sent);
    } catch (e) {
      _markFailed(tempId);
      _handleBlockedError(e);
    }
  }

  /// If the socket hasn't echoed our own message back within this window,
  /// assume it's lost (dropped frame, server hiccup) and fall back to REST
  /// rather than leaving the bubble stuck on "sending" forever.
  void _scheduleAckTimeout(String tempId, Future<void> Function() fallback) {
    Timer(const Duration(seconds: 6), () {
      final stillPending = _messages.any((m) => m.tempId == tempId && m.status == MessageStatus.sending);
      if (stillPending) fallback();
    });
  }

  Future<void> retry(MessageEntity failedMessage) async {
    if (failedMessage.status != MessageStatus.failed) return;
    final idx = _messages.indexWhere((m) => m.id == failedMessage.id);
    if (idx == -1) return;

    _messages[idx] = failedMessage.copyWith(status: MessageStatus.sending);
    notifyListeners();

    if (failedMessage.localImagePath != null) {
      try {
        final sent = await _repo.sendMessage(
          conversationId,
          text: failedMessage.text,
          image: File(failedMessage.localImagePath!),
        );
        _replaceOptimistic(failedMessage.id, sent);
      } catch (_) {
        _markFailed(failedMessage.id);
      }
    } else if (failedMessage.localAudioPath != null) {
      // ✅ NEW — voice message retry
      try {
        final sent = await _repo.sendVoiceMessage(
          conversationId,
          audio: File(failedMessage.localAudioPath!),
          durationSeconds: failedMessage.audioDurationSeconds ?? 0,
        );
        _replaceOptimistic(failedMessage.id, sent);
      } catch (_) {
        _markFailed(failedMessage.id);
      }
    } else {
      await _sendViaRest(failedMessage.id, failedMessage.text, failedMessage.replyTo?.id);
    }
  }

  void _replaceOptimistic(String tempId, MessageEntity real) {
    final idx = _messages.indexWhere((m) => m.id == tempId || m.tempId == tempId);
    if (idx == -1) {
      _messages.add(real);
    } else {
      _messages[idx] = real;
    }
    notifyListeners();
  }

  void _markFailed(String tempId) {
    final idx = _messages.indexWhere((m) => m.id == tempId || m.tempId == tempId);
    if (idx == -1) return;
    _messages[idx] = _messages[idx].copyWith(status: MessageStatus.failed);
    notifyListeners();
  }

  // ── Reply state ──────────────────────────────────────────────────────
  void setReplyTo(MessageEntity message) {
    replyingTo = message;
    notifyListeners();
  }

  void clearReply() {
    replyingTo = null;
    notifyListeners();
  }

  // ── Edit / delete ────────────────────────────────────────────────────
  Future<void> editMessage(String messageId, String newText) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    try {
      final updated = await _repo.editMessage(messageId, newText);
      _messages[idx] = updated;
      notifyListeners();
    } catch (_) {
      // leave the bubble as-is; caller's UI can show a snackbar
    }
  }

  // ✅ CHANGED — supports both "delete for everyone" (soft-deletes, bubble
  // stays visible as "This message was deleted") and "delete for me"
  // (vanishes from THIS user's list only — the other side still sees it).
  Future<void> deleteMessage(String messageId, {bool forEveryone = true}) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    try {
      await _repo.deleteMessage(messageId, forEveryone: forEveryone);
      if (forEveryone) {
        _messages[idx] = _messages[idx].copyWith(isDeleted: true, text: '');
      } else {
        _messages.removeAt(idx);
      }
      notifyListeners();
    } catch (_) {
      // no-op — message stays visible; user can retry
    }
  }

  // ✅ NEW — reactions. Optimistic with rollback so tapping an emoji feels
  // instant even before the server round-trip completes.
  Future<void> toggleReaction(String messageId, String emoji) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final before = _messages[idx];

    final newReactions = Map<String, int>.from(before.reactions);
    final wasMine = before.myReaction == emoji;
    if (wasMine) {
      newReactions[emoji] = (newReactions[emoji] ?? 1) - 1;
      if (newReactions[emoji]! <= 0) newReactions.remove(emoji);
    } else {
      if (before.myReaction != null) {
        final old = before.myReaction!;
        newReactions[old] = (newReactions[old] ?? 1) - 1;
        if (newReactions[old]! <= 0) newReactions.remove(old);
      }
      newReactions[emoji] = (newReactions[emoji] ?? 0) + 1;
    }

    _messages[idx] = before.copyWith(
      reactions: newReactions,
      myReaction: () => wasMine ? null : emoji,
    );
    notifyListeners();

    try {
      final updated = await _repo.toggleReaction(messageId, emoji);
      final freshIdx = _messages.indexWhere((m) => m.id == messageId);
      if (freshIdx != -1) {
        _messages[freshIdx] = updated;
        notifyListeners();
      }
    } catch (_) {
      final freshIdx = _messages.indexWhere((m) => m.id == messageId);
      if (freshIdx != -1) {
        _messages[freshIdx] = before; // rollback
        notifyListeners();
      }
    }
  }

  // ✅ NEW — in-conversation search. Returns results for the caller (e.g.
  // ChatScreen) to show as an overlay; doesn't touch the main list.
  Future<List<MessageEntity>> searchInChat(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      return await _repo.searchMessages(conversationId, query.trim());
    } catch (_) {
      return [];
    }
  }

  // ── Typing (outgoing, debounced so we don't spam a frame per keystroke) ──
  void onComposerChanged(String text) {
    final typing = text.trim().isNotEmpty;
    if (typing != _iAmTyping) {
      _iAmTyping = typing;
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(milliseconds: 150), () {
        _repo.sendTyping(_iAmTyping);
      });
    }

    // ✅ NEW — draft auto-save. Debounced longer than the typing signal
    // (1.5s of no keystrokes) since this hits the DB, not just a socket
    // broadcast — no need to save on every character.
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 1500), () {
      unawaited(_repo.saveDraft(conversationId, text));
    });
  }

  void stopTypingOnSend() {
    _draftDebounce?.cancel();  // ✅ NEW — backend clears the draft on send; don't let a stale debounced save overwrite that
    if (!_iAmTyping) return;
    _iAmTyping = false;
    _typingDebounce?.cancel();
    _repo.sendTyping(false);
  }

  // ── Mark seen (call when the screen is actually in foreground) ───────
  Future<void> markSeen() async {
    try {
      await _repo.markSeen(conversationId);
      // Optimistically reflect it locally too, so ticks update instantly
      // even before any socket echo comes back.
      for (var i = 0; i < _messages.length; i++) {
        final m = _messages[i];
        if (m.senderId != currentUserId && m.status != MessageStatus.seen) {
          _messages[i] = m.copyWith(status: MessageStatus.seen);
        }
      }
      notifyListeners();
    } catch (_) {
      // best-effort
    }
  }

  // ── Incoming socket events ───────────────────────────────────────────
  void _handleSocketEvent(ChatSocketEvent event) {
    if (event is NewMessageSocketEvent) {
      if (event.tempId != null) {
        _replaceOptimistic(event.tempId!, event.message);
      } else if (!_messages.any((m) => m.id == event.message.id)) {
        _messages.add(event.message);
        notifyListeners();
        // A new incoming message while the screen is open -> immediately
        // tell the sender we've seen it.
        if (event.message.senderId != currentUserId) {
          unawaited(markSeen());
        }
      }
    } else if (event is TypingSocketEvent) {
      otherUserTyping = event.isTyping;
      _typingClearTimer?.cancel();
      if (event.isTyping) {
        // Safety net: auto-clear after 8s in case a "stopped typing"
        // frame never arrives (app backgrounded, connection dropped).
        _typingClearTimer = Timer(const Duration(seconds: 8), () {
          otherUserTyping = false;
          notifyListeners();
        });
      }
      notifyListeners();
    } else if (event is StatusUpdateSocketEvent) {
      final newStatus = event.event == 'seen' ? MessageStatus.seen : MessageStatus.delivered;
      for (var i = 0; i < _messages.length; i++) {
        final m = _messages[i];
        if (event.messageIds.contains(m.id) && newStatus.rank > m.status.rank) {
          _messages[i] = m.copyWith(status: newStatus);
        }
      }
      notifyListeners();
    } else if (event is PresenceSocketEvent) {
      otherUserOnline = event.isOnline;
      otherUserLastSeen = event.lastSeen ?? otherUserLastSeen;
      notifyListeners();
    } else if (event is ReactionSocketEvent) {
      // ✅ NEW
      final idx = _messages.indexWhere((m) => m.id == event.message.id);
      if (idx != -1) {
        _messages[idx] = event.message;
        notifyListeners();
      }
    } else if (event is SocketErrorEvent) {
      // Non-fatal — REST fallback paths already cover sending/marking.
      debugPrint('Chat socket error: ${event.message}');
    }
  }

  /// Snapshot handed back to the conversation list when this screen pops,
  /// so the list tile updates instantly without a re-fetch.
  ConversationEntity? snapshotForList(ConversationEntity base) {
    if (_messages.isEmpty) return null;
    final last = _messages.last;
    final preview = last.isDeleted
        ? 'This message was deleted'
        : (last.text.isNotEmpty ? last.text : (last.hasAudio ? '🎤 Voice message' : (last.hasImage ? '📷 Photo' : '')));
    return base.copyWith(
      lastMessage: preview,
      lastMessageAt: last.createdAt,
      lastMessageStatus: last.status.name,
      unreadCount: 0,
      updatedAt: DateTime.now(),
      isBlockedByMe: isBlockedByMe,
      canMessage: canMessage,
    );
  }
}