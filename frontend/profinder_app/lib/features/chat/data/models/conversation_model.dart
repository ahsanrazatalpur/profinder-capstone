// lib/features/chat/data/models/conversation_model.dart
//
// Maps 1:1 onto apps/messaging/serializers.py -> ConversationSerializer.

import '../../domain/entities/conversation_entity.dart';
import '../../../../core/utils/app_helpers.dart';

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.otherUserId,
    required super.otherUserName,
    super.otherUserPhoto,
    required super.otherUserOnline,
    super.otherUserLastSeen,
    required super.lastMessage,
    super.lastMessageAt,
    super.lastMessageStatus,
    required super.unreadCount,
    required super.updatedAt,
    super.isPinned,
    super.isArchived,
    super.isMuted,
    super.draftText,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      otherUserId: json['other_user_id'] is int
          ? json['other_user_id'] as int
          : int.parse(json['other_user_id'].toString()),
      otherUserName: json['other_user_name']?.toString() ?? '',
      otherUserPhoto: AppHelpers.getFullImageUrl(json['other_user_photo']?.toString()).isEmpty
          ? null
          : AppHelpers.getFullImageUrl(json['other_user_photo']?.toString()),
      otherUserOnline: json['other_user_online'] == true,
      otherUserLastSeen:
          json['other_user_last_seen'] != null ? DateTime.parse(json['other_user_last_seen'].toString()).toLocal() : null,
      lastMessage: json['last_message']?.toString() ?? '',
      lastMessageAt: json['last_message_at'] != null ? DateTime.parse(json['last_message_at'].toString()).toLocal() : null,
      lastMessageStatus: json['last_message_status']?.toString(),
      unreadCount: json['unread_count'] is int ? json['unread_count'] as int : int.tryParse(json['unread_count'].toString()) ?? 0,
      updatedAt: DateTime.parse(json['updated_at'].toString()).toLocal(),
      isPinned: json['is_pinned'] == true,
      isArchived: json['is_archived'] == true,
      isMuted: json['is_muted'] == true,
      draftText: json['draft_text']?.toString() ?? '',
    );
  }
}