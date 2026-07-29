// lib/features/chat/domain/entities/message_entity.dart
//
// Pure domain object — no JSON, no Dio, no Flutter. Just the shape of a
// chat message as the rest of the app should think about it.

import 'message_status.dart';

/// Lightweight quote of the message being replied to. Matches
/// ReplyPreviewSerializer on the backend — deliberately thin.
class ReplyPreviewEntity {
  final String id;
  final String senderName;
  final String text;
  final bool hasAttachment;

  const ReplyPreviewEntity({
    required this.id,
    required this.senderName,
    required this.text,
    required this.hasAttachment,
  });
}

class MessageEntity {
  /// Server id (stringified) for a persisted message, or a local
  /// `temp_<uuid>` id for an optimistic message not yet acknowledged.
  final String id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String text;
  final String? imageUrl;      // full URL, already resolved
  final String? localImagePath; // set only while an optimistic image upload is in flight
  // ✅ NEW — voice messages reuse the same optimistic-upload pattern as images
  final String? audioUrl;
  final int? audioDurationSeconds;
  final String? localAudioPath;
  final ReplyPreviewEntity? replyTo;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final bool isEdited;
  final bool isDeleted;

  // ✅ NEW — reactions grouped by emoji (e.g. {"❤️": 3, "👍": 1}) and
  // which one (if any) the CURRENT user picked, for highlighting.
  final Map<String, int> reactions;
  final String? myReaction;

  /// Only meaningful for optimistic messages — lets the provider find and
  /// replace this exact bubble once the server responds or the socket
  /// echoes it back with the same temp_id.
  final String? tempId;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    this.localImagePath,
    this.audioUrl,
    this.audioDurationSeconds,
    this.localAudioPath,
    this.replyTo,
    required this.status,
    required this.createdAt,
    this.deliveredAt,
    this.readAt,
    this.isEdited = false,
    this.isDeleted = false,
    this.reactions = const {},
    this.myReaction,
    this.tempId,
  });

  bool get hasImage => (imageUrl != null && imageUrl!.isNotEmpty) || localImagePath != null;
  bool get hasAudio => (audioUrl != null && audioUrl!.isNotEmpty) || localAudioPath != null;
  bool get hasReactions => reactions.isNotEmpty;

  MessageEntity copyWith({
    String? id,
    String? text,
    String? imageUrl,
    String? localImagePath,
    String? audioUrl,
    int? audioDurationSeconds,
    String? localAudioPath,
    MessageStatus? status,
    DateTime? deliveredAt,
    DateTime? readAt,
    bool? isEdited,
    bool? isDeleted,
    Map<String, int>? reactions,
    String? Function()? myReaction, // wrapped so we can explicitly set it back to null
  }) {
    return MessageEntity(
      id: id ?? this.id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      replyTo: replyTo,
      status: status ?? this.status,
      createdAt: createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      reactions: reactions ?? this.reactions,
      myReaction: myReaction != null ? myReaction() : this.myReaction,
      tempId: tempId,
    );
  }
}