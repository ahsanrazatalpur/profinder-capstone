// lib/features/chat/domain/entities/conversation_entity.dart

class ConversationEntity {
  final int id;
  final int otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final bool otherUserOnline;
  final DateTime? otherUserLastSeen;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageStatus; // 'sent' | 'delivered' | 'seen' | null
  final int unreadCount;
  final DateTime updatedAt;

  // ✅ NEW — per-user chat management state
  final bool isPinned;
  final bool isArchived;
  final bool isMuted;
  final String draftText;

  // ✅ NEW — block visibility. `isBlockedByMe` is safe to show explicitly
  // ("You blocked X"); `canMessage` covers both directions but never
  // reveals whether it was the OTHER user who blocked me.
  final bool isBlockedByMe;
  final bool canMessage;

  const ConversationEntity({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    required this.otherUserOnline,
    this.otherUserLastSeen,
    required this.lastMessage,
    this.lastMessageAt,
    this.lastMessageStatus,
    required this.unreadCount,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.isMuted = false,
    this.draftText = '',
    this.isBlockedByMe = false,
    this.canMessage = true,
  });

  bool get hasDraft => draftText.isNotEmpty;

  ConversationEntity copyWith({
    bool? otherUserOnline,
    DateTime? otherUserLastSeen,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageStatus,
    int? unreadCount,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
    bool? isMuted,
    String? draftText,
    bool? isBlockedByMe,
    bool? canMessage,
  }) {
    return ConversationEntity(
      id: id,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserPhoto: otherUserPhoto,
      otherUserOnline: otherUserOnline ?? this.otherUserOnline,
      otherUserLastSeen: otherUserLastSeen ?? this.otherUserLastSeen,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageStatus: lastMessageStatus ?? this.lastMessageStatus,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      draftText: draftText ?? this.draftText,
      isBlockedByMe: isBlockedByMe ?? this.isBlockedByMe,
      canMessage: canMessage ?? this.canMessage,
    );
  }
}