// lib/features/trust_safety/services/user_trust_safety_service.dart
//
// Thin, typed wrapper around the USER-facing Trust & Safety endpoints
// (Part 8). Reuses the app-wide [ApiService] (JWT + refresh handling),
// mirroring the pattern already used by
// features/admin/services/trust_safety_service.dart — but this one only
// ever touches the "my own" endpoints; it has no admin capability at all.
//
// Endpoints consumed:
//   GET  /admin-panel/reports/mine/              → my own submitted reports
//   GET  /admin-panel/moderation-status/mine/    → my live account status
//   GET  /admin-panel/appeals/mine/              → my own appeals
//   POST /admin-panel/appeals/create/            → appeal one of my own
//                                                   moderation actions

import 'package:dio/dio.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/user_ts_models.dart';

/// A failed user Trust & Safety request, with the backend's message when it
/// sent one. Kept separate from the admin feature's `TsApiException` so this
/// feature has no dependency on admin-only code.
class UserTsApiException implements Exception {
  final String? message;
  final int? statusCode;
  final Map<String, String> fieldErrors;
  final bool isNetwork;

  const UserTsApiException({
    this.message,
    this.statusCode,
    this.fieldErrors = const {},
    this.isNetwork = false,
  });

  bool get isConflict => statusCode == 409; // e.g. duplicate pending appeal
  bool get isNotFound => statusCode == 404;
  bool get isBadRequest => statusCode == 400;

  factory UserTsApiException.fromDio(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    String? msg;
    final fields = <String, String>{};

    if (data is Map) {
      final direct = data['error'] ?? data['detail'] ?? data['message'];
      if (direct != null) msg = direct.toString();
      data.forEach((k, v) {
        final key = k.toString();
        if (key == 'error' || key == 'detail' || key == 'message') return;
        fields[key] = v is List ? v.map((x) => x.toString()).join(' ') : v.toString();
      });
      if (msg == null && fields.isNotEmpty) msg = fields.values.first;
    }

    final network = e.response == null &&
        (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout);

    return UserTsApiException(
      message: msg,
      statusCode: code,
      fieldErrors: fields,
      isNetwork: network,
    );
  }

  @override
  String toString() => 'UserTsApiException($statusCode, $message)';
}

class UserTrustSafetyService {
  UserTrustSafetyService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw UserTsApiException.fromDio(e);
    }
  }

  List<Map<String, dynamic>> _rows(dynamic data) {
    if (data is! List) return const [];
    return data.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  // ── My Reports ──────────────────────────────────────────────────────────

  /// Reports the CURRENT user submitted, newest first. Never another
  /// user's reports, and never a report submitted against them.
  Future<List<MyReport>> fetchMyReports({String? status}) => _guard(() async {
        final qs = (status != null && status.isNotEmpty) ? '?status=$status' : '';
        final r = await _api.get('${AppConstants.myReports}$qs');
        return _rows(r.data).map(MyReport.fromJson).toList();
      });

  // ── My Account Moderation Status ────────────────────────────────────────

  /// Always a fresh server read — never derived from cached/local state.
  Future<MyModerationStatus> fetchMyModerationStatus() => _guard(() async {
        final r = await _api.get(AppConstants.myModerationStatus);
        return MyModerationStatus.fromJson(Map<String, dynamic>.from(r.data as Map));
      });

  // ── My Appeals ───────────────────────────────────────────────────────────

  Future<List<MyAppeal>> fetchMyAppeals({String? status}) => _guard(() async {
        final qs = (status != null && status.isNotEmpty) ? '?status=$status' : '';
        final r = await _api.get('${AppConstants.myAppeals}$qs');
        return _rows(r.data).map(MyAppeal.fromJson).toList();
      });

  /// Appeal one of the CURRENT user's own moderation actions. The server
  /// itself rejects (409) an action that isn't theirs, isn't currently in
  /// force, or already has a pending appeal — this is the single source of
  /// truth for duplicate-prevention, not client state.
  Future<MyAppeal> submitAppeal({
    required int moderationActionId,
    required String reason,
    String? evidenceUrl,
  }) =>
      _guard(() async {
        final body = <String, dynamic>{
          'moderation_action': moderationActionId,
          'reason': reason.trim(),
        };
        final ev = evidenceUrl?.trim() ?? '';
        if (ev.isNotEmpty) body['evidence_url'] = ev;
        final r = await _api.post(AppConstants.appealCreate, body);
        return MyAppeal.fromJson(Map<String, dynamic>.from(r.data as Map));
      });
}