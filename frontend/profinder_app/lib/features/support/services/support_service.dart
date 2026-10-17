// lib/features/support/services/support_service.dart
//
// Help & Support network calls. Never throws: callers get a SupportResult and
// decide what to show.
//   * Help Center + Privacy Policy: public (no login).
//   * Tickets: login required (JWT is attached by ApiService).
//   * Guest contact: public.

import 'package:dio/dio.dart';

import '../../../core/network/api_service.dart';
import '../models/help_models.dart';
import '../models/policy_document.dart';
import '../models/ticket_models.dart';

enum SupportFailure {
  notFound,
  network,
  other,
  invalid, // 400: the server rejected the input
  unauthorized, // 401: not signed in / session expired
  conflict, // 409: e.g. replying to a closed ticket
  rateLimited, // 429: throttled or too many open tickets
}

class SupportResult<T> {
  final T? data;
  final SupportFailure? failure;

  const SupportResult.ok(T this.data) : failure = null;
  const SupportResult.fail(SupportFailure this.failure) : data = null;

  bool get isOk => data != null;
}

/// What the Help Center screens need. SupportService is the real
/// implementation; widget tests pass a fake so no network/Dio is touched.
abstract class HelpDataSource {
  Future<SupportResult<List<HelpCategory>>> getHelpCategories({
    required String lang,
    String? audience,
  });

  Future<SupportResult<List<HelpArticleSummary>>> getHelpArticles({
    required String lang,
    String? audience,
    String? category,
    String? query,
  });

  Future<SupportResult<HelpArticle>> getHelpArticle({
    required String slug,
    required String lang,
    String? audience,
  });
}

/// What the ticket screens need (same testing idea as HelpDataSource).
abstract class TicketDataSource {
  Future<SupportResult<List<SupportTicketSummary>>> getTickets();

  Future<SupportResult<SupportTicketDetail>> getTicket(int id);

  Future<SupportResult<SupportTicketDetail>> createTicket({
    required String subject,
    required String body,
    required String category,
    String? platform,
    String? appLanguage,
  });

  Future<SupportResult<SupportTicketDetail>> replyToTicket(int id, String body);

  Future<SupportResult<SupportTicketDetail>> closeTicket(int id);

  Future<SupportResult<GuestReceipt>> sendGuestContact({
    required String email,
    required String subject,
    required String body,
    required String category,
    String? platform,
    String? appLanguage,
  });
}

class SupportService implements HelpDataSource, TicketDataSource {
  final ApiService _api = ApiService();

  // ── Public reads ──────────────────────────────────────────────────────────

  /// GET /support/policies/privacy/?lang=xx
  Future<SupportResult<PolicyDocument>> getPrivacyPolicy({
    required String lang,
  }) {
    return _get('/support/policies/privacy/', {
      'lang': lang,
    }, (body) => PolicyDocument.fromJson(body));
  }

  /// GET /support/help/categories/?lang=&audience=
  @override
  Future<SupportResult<List<HelpCategory>>> getHelpCategories({
    required String lang,
    String? audience,
  }) {
    return _get(
      '/support/help/categories/',
      {'lang': lang, 'audience': audience},
      (body) => _list(body).map(HelpCategory.fromJson).toList(),
    );
  }

  /// GET /support/help/articles/?category=&q=&lang=&audience=
  @override
  Future<SupportResult<List<HelpArticleSummary>>> getHelpArticles({
    required String lang,
    String? audience,
    String? category,
    String? query,
  }) {
    return _get(
      '/support/help/articles/',
      {'lang': lang, 'audience': audience, 'category': category, 'q': query},
      (body) => _list(body).map(HelpArticleSummary.fromJson).toList(),
    );
  }

  /// GET `/support/help/articles/{slug}/?lang=&audience=`
  @override
  Future<SupportResult<HelpArticle>> getHelpArticle({
    required String slug,
    required String lang,
    String? audience,
  }) {
    return _get(
      '/support/help/articles/${Uri.encodeComponent(slug)}/',
      {'lang': lang, 'audience': audience},
      (body) => HelpArticle.fromJson(body),
    );
  }

  // ── Tickets (login required) ──────────────────────────────────────────────

  /// GET /support/tickets/
  @override
  Future<SupportResult<List<SupportTicketSummary>>> getTickets() {
    return _get(
      '/support/tickets/',
      const {},
      (body) => _list(body).map(SupportTicketSummary.fromJson).toList(),
    );
  }

  /// GET /support/tickets/{id}/
  @override
  Future<SupportResult<SupportTicketDetail>> getTicket(int id) {
    return _get(
      '/support/tickets/$id/',
      const {},
      (body) => SupportTicketDetail.fromJson(body),
    );
  }

  /// POST /support/tickets/
  @override
  Future<SupportResult<SupportTicketDetail>> createTicket({
    required String subject,
    required String body,
    required String category,
    String? platform,
    String? appLanguage,
  }) {
    return _post('/support/tickets/', {
      'subject': subject,
      'body': body,
      'category': category,
      'platform': ?platform,
      'app_language': ?appLanguage,
    }, (json) => SupportTicketDetail.fromJson(json));
  }

  /// POST /support/tickets/{id}/messages/
  @override
  Future<SupportResult<SupportTicketDetail>> replyToTicket(
    int id,
    String body,
  ) {
    return _post(
      '/support/tickets/$id/messages/',
      {'body': body},
      (json) => SupportTicketDetail.fromJson(json),
    );
  }

  /// POST /support/tickets/{id}/close/
  @override
  Future<SupportResult<SupportTicketDetail>> closeTicket(int id) {
    return _post(
      '/support/tickets/$id/close/',
      const {},
      (json) => SupportTicketDetail.fromJson(json),
    );
  }

  // ── Guest contact ─────────────────────────────────────────────────────────

  /// POST /support/contact/  (no login)
  @override
  Future<SupportResult<GuestReceipt>> sendGuestContact({
    required String email,
    required String subject,
    required String body,
    required String category,
    String? platform,
    String? appLanguage,
  }) {
    return _post('/support/contact/', {
      'email': email,
      'subject': subject,
      'body': body,
      'category': category,
      'platform': ?platform,
      'app_language': ?appLanguage,
    }, (json) => GuestReceipt.fromJson(json));
  }

  // ── Plumbing ──────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _list(Map<String, dynamic> body) {
    final raw = body['results'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<SupportResult<T>> _get<T>(
    String path,
    Map<String, String?> params,
    T Function(Map<String, dynamic> body) parse,
  ) {
    final query = params.entries
        .where((e) => e.value != null && e.value!.isNotEmpty)
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value!)}')
        .join('&');
    return _run(() => _api.get(query.isEmpty ? path : '$path?$query'), parse);
  }

  Future<SupportResult<T>> _post<T>(
    String path,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic> body) parse,
  ) {
    return _run(() => _api.post(path, data), parse);
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
