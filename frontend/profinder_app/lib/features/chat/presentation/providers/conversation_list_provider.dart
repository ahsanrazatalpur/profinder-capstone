// PATH: lib/features/chat/presentation/providers/conversation_list_provider.dart
// lib/features/chat/presentation/providers/conversation_list_provider.dart

import 'package:flutter/material.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/repositories/chat_repository_impl.dart';

class ConversationListProvider extends ChangeNotifier {
  final ChatRepository _repo;
  ConversationListProvider({ChatRepository? repo}) : _repo = repo ?? ChatRepositoryImpl();

  bool _isLoading = false;
  String? _error;
  List<ConversationEntity> _conversations = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ConversationEntity> get conversations => _conversations;

  /// ✅ NEW — sum of unread messages across every conversation. Used to
  /// show a badge on the "Messages" bottom-nav icon (both Customer and
  /// Professional sides) without a separate network call.
  int get totalUnreadCount => _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _repo.getConversations();
    } catch (e) {
      _error = 'Could not load conversations';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => load();

  /// Called when the chat screen for [conversationId] closes, so the list
  /// reflects the latest message/unread-count immediately without a
  /// network round trip.
  void patchFromChat(ConversationEntity updated) {
    final idx = _conversations.indexWhere((c) => c.id == updated.id);
    if (idx == -1) {
      _conversations = [updated, ..._conversations];
    } else {
      _conversations = List.of(_conversations)..[idx] = updated;
    }
    _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  Future<ConversationEntity> startConversation(int otherUserId) async {
    final conv = await _repo.startConversation(otherUserId);
    patchFromChat(conv);
    return conv;
  }

  /// Flips [conv.isMuted] — calls the same PATCH the repo already exposes
  /// for pin/archive/mute, then patches the local list so the bell icon
  /// updates immediately without a full reload.
  Future<void> toggleMute(ConversationEntity conv) async {
    final newValue = !conv.isMuted;
    await _repo.setMuted(conv.id, newValue);
    patchFromChat(conv.copyWith(isMuted: newValue));
  }
}