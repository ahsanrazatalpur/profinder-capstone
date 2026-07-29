// lib/features/chat/data/models/message_model.dart
//
// Maps 1:1 onto apps/messaging/serializers.py -> MessageSerializer.

import '../../domain/entities/message_entity.dart';
import '../../domain/entities/message_status.dart';
import '../../../../core/utils/app_helpers.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.senderName,
    required super.text,
    super.imageUrl,
    super.localImagePath,
    super.audioUrl,
    super.audioDurationSeconds,
    super.localAudioPath,
    super.replyTo,
    required super.status,
    required super.createdAt,
    super.deliveredAt,
    super.readAt,
    super.isEdited,
    super.isDeleted,
    super.reactions,
    super.myReaction,
    super.tempId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final attachments = json['attachments'] as List<dynamic>? ?? [];
    Map<String, dynamic>? imageAttachment;
    Map<String, dynamic>? audioAttachment;
    for (final a in attachments) {
      final map = a as Map<String, dynamic>;
      if (map['file_type'] == 'audio' && audioAttachment == null) audioAttachment = map;
      if (map['file_type'] == 'image' && imageAttachment == null) imageAttachment = map;
    }

    final replyJson = json['reply_to'] as Map<String, dynamic>?;

    // reactions: {"❤️": 3, "👍": 1}
    final reactionsRaw = json['reactions'] as Map<String, dynamic>? ?? {};
    final reactions = reactionsRaw.map((k, v) => MapEntry(k, (v as num).toInt()));

    return MessageModel(
      id: json['id'].toString(),
      conversationId: json['conversation'] is int
          ? json['conversation'] as int
          : int.parse(json['conversation'].toString()),
      senderId: json['sender'] is int ? json['sender'] as int : int.parse(json['sender'].toString()),
      senderName: json['sender_name']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      imageUrl: imageAttachment != null ? AppHelpers.getFullImageUrl(imageAttachment['file_url']?.toString()) : null,
      audioUrl: audioAttachment != null ? AppHelpers.getFullImageUrl(audioAttachment['file_url']?.toString()) : null,
      audioDurationSeconds: audioAttachment != null ? (audioAttachment['duration_seconds'] as num?)?.toInt() : null,
      replyTo: replyJson == null
          ? null
          : ReplyPreviewEntity(
              id: replyJson['id'].toString(),
              senderName: replyJson['sender_name']?.toString() ?? '',
              text: replyJson['text']?.toString() ?? '',
              hasAttachment: replyJson['has_attachment'] == true,
            ),
      status: MessageStatusX.fromServerString(json['status']?.toString()),
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'].toString()).toLocal() : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'].toString()).toLocal() : null,
      isEdited: json['is_edited'] == true,
      isDeleted: json['is_deleted'] == true,
      reactions: reactions,
      myReaction: json['my_reaction']?.toString(),
    );
  }

  /// Builds the temporary, purely-local bubble shown the instant the user
  /// hits send — before the server has confirmed anything (optimistic UI).
  factory MessageModel.optimistic({
    required String tempId,
    required int conversationId,
    required int senderId,
    required String senderName,
    required String text,
    String? localImagePath,
    String? localAudioPath,
    int? audioDurationSeconds,
    ReplyPreviewEntity? replyTo,
  }) {
    return MessageModel(
      id: tempId,
      tempId: tempId,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      localImagePath: localImagePath,
      localAudioPath: localAudioPath,
      audioDurationSeconds: audioDurationSeconds,
      replyTo: replyTo,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );
  }
}