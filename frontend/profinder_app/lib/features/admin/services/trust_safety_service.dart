// lib/features/admin/services/trust_safety_service.dart
//
// Thin, typed wrapper around the admin Trust & Safety endpoints (Parts 4–6).
// It reuses the app-wide [ApiService] (JWT + refresh handling) and adds
// nothing on the wire beyond what the backend already documents.
//
// Endpoints consumed:
//   GET   /admin-panel/reports/                         → reports (admin)
//   PATCH /admin-panel/reports/<id>/                    → review / dismiss / action_taken
//   GET   /admin-panel/users/<id>/moderation-actions/   → moderation history
//   POST  /admin-panel/moderation-actions/              → take an action
//   POST  /admin-panel/moderation-actions/<id>/reverse/ → reverse an action
//   GET   /admin-panel/appeals/                         → appeals queue
//   POST  /admin-panel/appeals/<id>/approve/            → approve
//   POST  /admin-panel/appeals/<id>/reject/             → reject
//
// The legacy `ban_user` flag on the report PATCH is intentionally never sent.

import 'package:dio/dio.dart';
import '../../../services/api_service.dart';
import '../models/ts_models.dart';

/// A failed Trust & Safety request, with the backend's message when it sent one.
class TsApiException implements Exception {
  /// Backend-provided message (English, server side) or null when generic.
  final String? message;
  final int? statusCode;
  final Map<String, String> fieldErrors;
  final bool isNetwork;

  const TsApiException({
    this.message,
    this.statusCode,
    this.fieldErrors = const {},
    this.isNetwork = false,
  });

  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  factory TsApiException.fromDio(DioException e) {
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

    return TsApiException(
      message: msg,
      statusCode: code,
      fieldErrors: fields,
      isNetwork: network,
    );
  }

  @override
  String toString() => 'TsApiException($statusCode, $message)';
}

class TrustSafetyService {
  TrustSafetyService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;
  static const String _base = '/admin-panel';

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw TsApiException.fromDio(e);
    }
  }

  List<Map<String, dynamic>> _rows(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  Future<List<TsReport>> fetchReports() => _guard(() async {
        final r = await _api.get('$_base/reports/');
        return _rows(r.data).map(TsReport.fromJson).toList();
      });

  /// Review / dismiss / mark action taken. Never sends `ban_user`.
  /// Omitting [adminNote] leaves the existing internal note untouched.
  Future<TsReport> updateReport(
    int reportId, {
    required String status,
    String? adminNote,
  }) =>
      _guard(() async {
        final body = <String, dynamic>{'status': status};
        if (adminNote != null) body['admin_note'] = adminNote;
        final r = await _api.patch('$_base/reports/$reportId/', body);
        return TsReport.fromJson(Map<String, dynamic>.from(r.data as Map));
      });

  // ── Moderation actions ────────────────────────────────────────────────────

  Future<List<ModerationAction>> fetchUserHistory(int userId) => _guard(() async {
        final r = await _api.get('$_base/users/$userId/moderation-actions/');
        return _rows(r.data).map(ModerationAction.fromJson).toList();
      });

  Future<ModerationAction> createAction({
    required int targetUserId,
    required String actionType,
    required String reason,
    String? adminNote,
    int? reportId,
    DateTime? expiresAt,
  }) =>
      _guard(() async {
        final body = <String, dynamic>{
          'target_user': targetUserId,
          'action_type': actionType,
          'reason': reason.trim(),
        };
        final note = adminNote?.trim() ?? '';
        if (note.isNotEmpty) body['admin_note'] = note;
        if (reportId != null) body['report'] = reportId;
        if (expiresAt != null) {
          body['expires_at'] = expiresAt.toUtc().toIso8601String();
        }
        final r = await _api.post('$_base/moderation-actions/', body);
        return ModerationAction.fromJson(Map<String, dynamic>.from(r.data as Map));
      });

  Future<ModerationAction> reverseAction(int actionId, String reason) =>
      _guard(() async {
        final r = await _api.post(
          '$_base/moderation-actions/$actionId/reverse/',
          {'reason': reason.trim()},
        );
        return ModerationAction.fromJson(Map<String, dynamic>.from(r.data as Map));
      });

  // ── Appeals ───────────────────────────────────────────────────────────────

  Future<List<TsAppeal>> fetchAppeals() => _guard(() async {
        final r = await _api.get('$_base/appeals/');
        return _rows(r.data).map(TsAppeal.fromJson).toList();
      });

  Future<TsAppeal> approveAppeal(int appealId, {String? decisionNote}) =>
      _guard(() async {
        final body = <String, dynamic>{};
        final note = decisionNote?.trim() ?? '';
        if (note.isNotEmpty) body['decision_note'] = note;
        final r = await _api.post('$_base/appeals/$appealId/approve/', body);
        return TsAppeal.fromJson(Map<String, dynamic>.from(r.data as Map));
      });

  Future<TsAppeal> rejectAppeal(int appealId, {required String decisionNote}) =>
      _guard(() async {
        final r = await _api.post(
          '$_base/appeals/$appealId/reject/',
          {'decision_note': decisionNote.trim()},
        );
        return TsAppeal.fromJson(Map<String, dynamic>.from(r.data as Map));
      });
}