// lib/features/support/services/support_content_service.dart
//
// Admin editor for Privacy Policy and Help articles.

import 'package:dio/dio.dart';

import '../../../core/network/api_service.dart';
import '../../admin/models/support_content_models.dart';

class ContentResult<T> {
  final T? data;
  final String? error;

  const ContentResult.ok(this.data) : error = null;
  const ContentResult.fail(String this.error) : data = null;

  bool get isOk => error == null;
}

abstract class SupportContentDataSource {
  Future<ContentResult<List<AdminPolicyVersion>>> listPolicies();
  Future<ContentResult<AdminPolicyVersion>> getPolicy(int id);
  Future<ContentResult<AdminPolicyVersion>> newPolicyVersion();
  Future<ContentResult<AdminPolicyVersion>> savePolicy(
    int id, {
    required String title,
    required String body,
    required String changeSummary,
    DateTime? effectiveDate,
  });
  Future<ContentResult<AdminPolicyVersion>> publishPolicy(int id);

  Future<ContentResult<List<AdminHelpCategory>>> listCategories();
  Future<ContentResult<List<AdminHelpArticle>>> listArticles({
    String? query,
    bool? published,
  });
  Future<ContentResult<AdminHelpArticle>> getArticle(int id);
  Future<ContentResult<AdminHelpArticle>> createArticle({
    required int categoryId,
    required String audience,
    required String title,
    required String body,
  });
  Future<ContentResult<AdminHelpArticle>> updateArticle(
    int id, {
    int? categoryId,
    String? audience,
    String? title,
    String? body,
    bool? isPublished,
  });
  Future<ContentResult<bool>> deleteArticle(int id);
}

class SupportContentService implements SupportContentDataSource {
  final ApiService _api = ApiService();

  static const _policy = '/support/admin/policy/';
  static const _cats = '/support/admin/help/categories/';
  static const _articles = '/support/admin/help/articles/';

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<ContentResult<List<AdminPolicyVersion>>> listPolicies() => _run(
    () => _api.get(_policy),
    (body) => _list(body, AdminPolicyVersion.fromJson),
  );

  @override
  Future<ContentResult<AdminPolicyVersion>> getPolicy(int id) => _run(
    () => _api.get('$_policy$id/'),
    (b) => AdminPolicyVersion.fromJson(_map(b)),
  );

  @override
  Future<ContentResult<AdminPolicyVersion>> newPolicyVersion() => _run(
    () => _api.post(_policy, {}),
    (b) => AdminPolicyVersion.fromJson(_map(b)),
  );

  @override
  Future<ContentResult<AdminPolicyVersion>> savePolicy(
    int id, {
    required String title,
    required String body,
    required String changeSummary,
    DateTime? effectiveDate,
  }) => _run(
    () => _api.patch('$_policy$id/', {
      'title': title,
      'body': body,
      'change_summary': changeSummary,
      'effective_date': effectiveDate == null ? null : _isoDate(effectiveDate),
    }),
    (b) => AdminPolicyVersion.fromJson(_map(b)),
  );

  @override
  Future<ContentResult<AdminPolicyVersion>> publishPolicy(int id) => _run(
    () => _api.post('$_policy$id/publish/', {}),
    (b) => AdminPolicyVersion.fromJson(_map(b)),
  );

  @override
  Future<ContentResult<List<AdminHelpCategory>>> listCategories() =>
      _run(() => _api.get(_cats), (b) => _list(b, AdminHelpCategory.fromJson));

  @override
  Future<ContentResult<List<AdminHelpArticle>>> listArticles({
    String? query,
    bool? published,
  }) {
    final params = <String, String>{
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      'published': ?(published == null ? null : (published ? 'true' : 'false')),
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return _run(
      () => _api.get(qs.isEmpty ? _articles : '$_articles?$qs'),
      (b) => _list(b, AdminHelpArticle.fromJson),
    );
  }

  @override
  Future<ContentResult<AdminHelpArticle>> getArticle(int id) => _run(
    () => _api.get('$_articles$id/'),
    (b) => AdminHelpArticle.fromJson(_map(b)),
  );

  @override
  Future<ContentResult<AdminHelpArticle>> createArticle({
    required int categoryId,
    required String audience,
    required String title,
    required String body,
  }) => _run(
    () => _api.post(_articles, {
      'category_id': categoryId,
      'audience': audience,
      'title': title,
      'body': body,
    }),
    (b) => AdminHelpArticle.fromJson(_map(b)),
  );

  @override
  Future<ContentResult<AdminHelpArticle>> updateArticle(
    int id, {
    int? categoryId,
    String? audience,
    String? title,
    String? body,
    bool? isPublished,
  }) => _run(
    () => _api.patch('$_articles$id/', {
      'category_id': ?categoryId,
      'audience': ?audience,
      'title': ?title,
      'body': ?body,
      'is_published': ?isPublished,
    }),
    (b) => AdminHelpArticle.fromJson(_map(b)),
  );

  @override
  Future<ContentResult<bool>> deleteArticle(int id) =>
      _run(() => _api.delete('$_articles$id/'), (_) => true);

  // ── helpers ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _map(Object? body) =>
      body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};

  static List<T> _list<T>(
    Object? body,
    T Function(Map<String, dynamic>) parse,
  ) {
    final raw = body is Map ? body['results'] : null;
    if (raw is! List) return <T>[];
    return [
      for (final item in raw)
        if (item is Map) parse(Map<String, dynamic>.from(item)),
    ];
  }

  Future<ContentResult<T>> _run<T>(
    Future<Response> Function() call,
    T Function(Object? body) parse,
  ) async {
    try {
      final response = await call();
      return ContentResult.ok(parse(response.data));
    } on DioException catch (e) {
      return ContentResult.fail(_message(e));
    } catch (_) {
      return const ContentResult.fail(
        'Something went wrong. Please try again.',
      );
    }
  }

  static String _message(DioException e) {
    final data = e.response?.data;
    if (data is Map &&
        data['error'] is String &&
        (data['error'] as String).isNotEmpty) {
      return data['error'] as String;
    }
    switch (e.response?.statusCode) {
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have access to this.';
      case 404:
        return 'This item no longer exists.';
    }
    final offline =
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
    return offline
        ? 'No connection. Check your internet and try again.'
        : 'Something went wrong. Please try again.';
  }
}
