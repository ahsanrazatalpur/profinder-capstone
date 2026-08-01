// lib/features/chat/data/datasources/chat_remote_data_source.dart
//
// Everything here is a thin, honest wrapper around ApiService (Dio) +
// AppConstants endpoints. No business logic — that lives in the
// repository. If the backend contract changes, this is the only file
// that needs to change.

import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/api_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../../domain/repositories/chat_repository.dart' show MediaAttachmentEntity, BlockedUserEntity;

class ChatRemoteDataSource {
  final ApiService _api;
  ChatRemoteDataSource({ApiService? api}) : _api = api ?? ApiService();

  Future<List<ConversationModel>> getConversations({String? search, bool archived = false}) async {
    final endpoint = search != null && search.isNotEmpty
        ? AppConstants.conversationSearch(search)
        : (archived ? AppConstants.archivedConversations() : AppConstants.conversations);
    final res = await _api.get(endpoint);
    final list = res.data is List ? res.data as List : <dynamic>[];
    return list.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ConversationModel> startConversation(int otherUserId) async {
    final res = await _api.post(AppConstants.conversations, {'other_user_id': otherUserId});
    return ConversationModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ✅ NEW — pin / archive / mute / draft, all through one PATCH
  Future<void> setPinned(int conversationId, bool value) async {
    await _api.patch(AppConstants.conversationState(conversationId), {'is_pinned': value});
  }

  Future<void> setArchived(int conversationId, bool value) async {
    await _api.patch(AppConstants.conversationState(conversationId), {'is_archived': value});
  }

  Future<void> setMuted(int conversationId, bool value, {DateTime? until}) async {
    await _api.patch(AppConstants.conversationState(conversationId), {
      'is_muted': value,
      if (until != null) 'muted_until': until.toUtc().toIso8601String(),
    });
  }

  Future<void> saveDraft(int conversationId, String text) async {
    await _api.patch(AppConstants.conversationState(conversationId), {'draft_text': text});
  }

  /// Returns (messages, hasMore) for one page, oldest-to-newest.
  Future<({List<MessageModel> messages, bool hasMore})> getMessages(
    int conversationId, {
    String? beforeId,
    int limit = 30,
  }) async {
    final res = await _api.get(
      AppConstants.conversationMessagesPage(conversationId, beforeId: beforeId, limit: limit),
    );
    final data = res.data as Map<String, dynamic>;
    final results = (data['results'] as List? ?? [])
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (messages: results, hasMore: data['has_more'] == true);
  }

  Future<MessageModel> sendMessage(
    int conversationId, {
    String? text,
    String? replyToId,
    File? image,
  }) async {
    final endpoint = AppConstants.conversationMessages(conversationId);

    if (image != null) {
      // 🐛 FIX: MultipartFile.fromFile() reads through dart:io, which is a
      // non-functional stub on Flutter Web — it throws the moment it tries
      // to open/stream the picked file, crashing right when "Send" is
      // tapped. XFile.readAsBytes() is cross-platform-safe (handles the
      // `blob:` URL image_picker hands back on web, and a real path on
      // Android/iOS), so we upload bytes instead of streaming from disk.
      final bytes = await XFile(image.path).readAsBytes();
      final formData = FormData.fromMap({
        if (text != null && text.isNotEmpty) 'text': text,
        if (replyToId != null) 'reply_to_id': replyToId,
        'image': MultipartFile.fromBytes(bytes, filename: 'chat_image.jpg'),
      });
      final res = await _api.postForm(endpoint, formData);
      return MessageModel.fromJson(res.data as Map<String, dynamic>);
    }

    final res = await _api.post(endpoint, {
      'text': text ?? '',
      if (replyToId != null) 'reply_to_id': replyToId,
    });
    return MessageModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ✅ NEW — voice message upload (same endpoint, 'audio' field instead of 'image')
  Future<MessageModel> sendVoiceMessage(
    int conversationId, {
    required File audio,
    required int durationSeconds,
    String? replyToId,
  }) async {
    final bytes = await XFile(audio.path).readAsBytes();
    final formData = FormData.fromMap({
      if (replyToId != null) 'reply_to_id': replyToId,
      'duration_seconds': durationSeconds,
      'audio': MultipartFile.fromBytes(bytes, filename: 'chat_audio.m4a'),
    });
    final res = await _api.postForm(AppConstants.conversationMessages(conversationId), formData);
    return MessageModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MessageModel> editMessage(String messageId, String newText) async {
    final res = await _api.patch(AppConstants.messageDetail(messageId), {'text': newText});
    return MessageModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteMessage(String messageId, {bool forEveryone = true}) async {
    final endpoint = forEveryone ? AppConstants.messageDetail(messageId) : AppConstants.deleteForMe(messageId);
    await _api.delete(endpoint);
  }

  Future<void> markDelivered(int conversationId) async {
    await _api.post(AppConstants.markDelivered(conversationId), const {});
  }

  Future<void> markSeen(int conversationId) async {
    await _api.post(AppConstants.markSeen(conversationId), const {});
  }

  // ✅ NEW — reactions
  Future<MessageModel> toggleReaction(String messageId, String emoji) async {
    final res = await _api.post(AppConstants.messageReactions(messageId), {'emoji': emoji});
    final data = res.data as Map<String, dynamic>;
    return MessageModel.fromJson(data['message'] as Map<String, dynamic>);
  }

  // ✅ NEW — in-conversation text search
  Future<List<MessageModel>> searchMessages(int conversationId, String query) async {
    final res = await _api.get(AppConstants.messageSearch(conversationId, query));
    final data = res.data as Map<String, dynamic>;
    return (data['results'] as List? ?? []).map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ✅ NEW — shared media gallery
  Future<List<MediaAttachmentEntity>> getMedia(int conversationId) async {
    final res = await _api.get(AppConstants.conversationMedia(conversationId));
    final list = res.data is List ? res.data as List : <dynamic>[];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return MediaAttachmentEntity(
        id: m['id'].toString(),
        fileUrl: m['file_url']?.toString() ?? '',
        fileType: m['file_type']?.toString() ?? 'image',
        durationSeconds: (m['duration_seconds'] as num?)?.toInt(),
        createdAt: DateTime.parse(m['created_at'].toString()).toLocal(),
      );
    }).toList();
  }

  // ✅ NEW — block / report
  Future<List<BlockedUserEntity>> getBlockedUsers() async {
    final res = await _api.get(AppConstants.blockedUsers);
    final list = res.data is List ? res.data as List : <dynamic>[];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return BlockedUserEntity(
        id: m['id'] is int ? m['id'] as int : int.parse(m['id'].toString()),
        blockedUserId: m['blocked'] is int ? m['blocked'] as int : int.parse(m['blocked'].toString()),
        blockedUserName: m['blocked_name']?.toString() ?? '',
        createdAt: DateTime.parse(m['created_at'].toString()).toLocal(),
      );
    }).toList();
  }

  Future<void> blockUser(int userId) async {
    await _api.post(AppConstants.blockedUsers, {'user_id': userId});
  }

  Future<void> unblockUser(int userId) async {
    await _api.delete(AppConstants.unblockUser(userId));
  }

  Future<void> reportUser(int userId, String reason, String details, {String? messageId}) async {
    // 🐛 FIX: field names now match apps.admin_panel's CreateUserReportSerializer
    // ({reported_user, reason, description}), not messaging's UserReport
    // ({reported, reason, details, message}) — see AppConstants.reportUser.
    // That serializer has no message-link field, so `messageId` (still
    // accepted for API compatibility with call sites) isn't sent.
    await _api.post(AppConstants.reportUser, {
      'reported_user': userId,
      'reason': reason,
      'description': details,
    });
  }
}