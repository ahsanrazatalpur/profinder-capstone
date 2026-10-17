// lib/features/support/services/support_admin_service.dart
//
// Admin ticket inbox calls.

import 'package:dio/dio.dart';

import '../../../core/network/api_service.dart';
import '../../admin/models/support_admin_models.dart';
import 'support_service.dart';

abstract class SupportAdminDataSource {
  Future<SupportResult<AdminTicketCounts>> getCounts();

  Future<SupportResult<AdminTicketPage>> getTickets({
    String? status,
    String? assigned,
    bool needsReply = false,
    String? query,
    int offset = 0,
    int limit = 30,
  });

  Future<SupportResult<AdminTicketDetail>> getTicket(int id);

  Future<SupportResult<AdminTicketDetail>> reply(
    int id,
    String body, {
    required bool internal,
  });

  Future<SupportResult<AdminTicketDetail>> update(
    int id, {
    String? status,
    String? priority,
    String? assignee,
  });
}

class SupportAdminService implements SupportAdminDataSource {
  final ApiService _api = ApiService();

  static const _base = '/support/admin/tickets/';

  @override
  Future<SupportResult<AdminTicketCounts>> getCounts() =>
      _run(() => _api.get('${_base}summary/'), AdminTicketCounts.fromJson);

  @override
  Future<SupportResult<AdminTicketPage>> getTickets({
    String? status,
    String? assigned,
    bool needsReply = false,
    String? query,
    int offset = 0,
    int limit = 30,
  }) {
    final params = <String, String>{
      'status': ?status,
      'assigned': ?assigned,
      if (needsReply) 'needs_reply': '1',
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      'offset': '$offset',
      'limit': '$limit',
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return _run(() => _api.get('$_base?$qs'), AdminTicketPage.fromJson);
  }

  @override
  Future<SupportResult<AdminTicketDetail>> getTicket(int id) =>
      _run(() => _api.get('$_base$id/'), AdminTicketDetail.fromJson);

  @override
  Future<SupportResult<AdminTicketDetail>> reply(
    int id,
    String body, {
    required bool internal,
  }) => _run(
    () => _api.post('$_base$id/reply/', {'body': body, 'internal': internal}),
    AdminTicketDetail.fromJson,
  );

  @override
  Future<SupportResult<AdminTicketDetail>> update(
    int id, {
    String? status,
    String? priority,
    String? assignee,
  }) {
    final data = <String, dynamic>{
      'status': ?status,
      'priority': ?priority,
      if (assignee == 'me') 'assigned_to': 'me',
      if (assignee == 'none') 'assigned_to': null,
    };
    return _run(
      () => _api.patch('$_base$id/', data),
      AdminTicketDetail.fromJson,
    );
  }

  Future<SupportResult<T>> _run<T>(
    Future<Response> Function() call,
    T Function(Map<String, dynamic> body) parse,
  ) async {
    try {
      final response = await call();
      final body = response.data;
      if (body is! Map) return const SupportResult.fail(SupportFailure.other);
      return SupportResult.ok(parse(Map<String, dynamic>.from(body)));
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 400:
          return const SupportResult.fail(SupportFailure.invalid);
        case 401:
        case 403:
          return const SupportResult.fail(SupportFailure.unauthorized);
        case 404:
          return const SupportResult.fail(SupportFailure.notFound);
        case 409:
          return const SupportResult.fail(SupportFailure.conflict);
        case 429:
          return const SupportResult.fail(SupportFailure.rateLimited);
      }
      final offline =
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      return SupportResult.fail(
        offline ? SupportFailure.network : SupportFailure.other,
      );
    } catch (_) {
      return const SupportResult.fail(SupportFailure.other);
    }
  }
}
