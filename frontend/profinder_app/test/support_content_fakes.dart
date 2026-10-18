// Shared fake for the admin Help-content widget tests. No network, no Dio.

import 'package:profinder_app/features/admin/models/support_content_models.dart';
import 'package:profinder_app/services/support_content_service.dart';

AdminPolicyVersion policyVersion({
  int id = 1,
  int version = 1,
  String status = 'draft',
  String title = 'Privacy Policy',
  String body = 'Contact [PLACEHOLDER: SUPPORT EMAIL] now.',
  String summary = '',
}) =>
    AdminPolicyVersion(
      id: id,
      version: version,
      status: status,
      isLocked: status != 'draft',
      effectiveDate: null,
      publishedAt: null,
      changeSummary: summary,
      title: title,
      body: body,
      placeholdersLeft: kPlaceholderPattern.allMatches(body).length,
    );

AdminHelpArticle helpArticle({
  int id = 1,
  String title = 'Reset password',
  bool published = false,
  String body = 'Tap forgot password.',
}) =>
    AdminHelpArticle(
      id: id,
      slug: 'article-$id',
      categoryId: 1,
      categoryTitle: 'Account',
      audience: 'all',
      order: 0,
      isPublished: published,
      title: title,
      body: body,
    );

class FakeContentSource implements SupportContentDataSource {
  final List<AdminPolicyVersion> policies;
  final List<AdminHelpArticle> articles;
  final List<AdminHelpCategory> categories;

  /// When set, every write fails with this server-style message.
  String? failMessage;

  final List<String> calls = [];
  final List<bool?> articleListFilters = [];
  final List<int> deleted = [];

  FakeContentSource({
    List<AdminPolicyVersion>? policies,
    List<AdminHelpArticle>? articles,
    List<AdminHelpCategory>? categories,
    this.failMessage,
  })  : policies = policies ?? [],
        articles = articles ?? [],
        categories = categories ??
            const [AdminHelpCategory(id: 1, slug: 'account', title: 'Account', audience: 'all')];

  ContentResult<T> _fail<T>() => ContentResult.fail(failMessage!);

  @override
  Future<ContentResult<List<AdminPolicyVersion>>> listPolicies() async {
    calls.add('listPolicies');
    return ContentResult.ok(List.of(policies));
  }

  @override
  Future<ContentResult<AdminPolicyVersion>> getPolicy(int id) async {
    calls.add('getPolicy:$id');
    return ContentResult.ok(policies.firstWhere((p) => p.id == id));
  }

  @override
  Future<ContentResult<AdminPolicyVersion>> newPolicyVersion() async {
    calls.add('newPolicyVersion');
    if (failMessage != null) return _fail<AdminPolicyVersion>();
    final next = policyVersion(
      id: policies.length + 1,
      version: policies.length + 1,
      body: 'Old text.',
    );
    policies.insert(0, next);
    return ContentResult.ok(next);
  }

  @override
  Future<ContentResult<AdminPolicyVersion>> savePolicy(
    int id, {
    required String title,
    required String body,
    required String changeSummary,
    DateTime? effectiveDate,
  }) async {
    calls.add('savePolicy:$id');
    if (failMessage != null) return _fail<AdminPolicyVersion>();
    final i = policies.indexWhere((p) => p.id == id);
    final old = policies[i];
    policies[i] = policyVersion(
      id: id,
      version: old.version,
      status: old.status,
      title: title,
      body: body,
      summary: changeSummary,
    );
    return ContentResult.ok(policies[i]);
  }

  @override
  Future<ContentResult<AdminPolicyVersion>> publishPolicy(int id) async {
    calls.add('publishPolicy:$id');
    if (failMessage != null) return _fail<AdminPolicyVersion>();
    final i = policies.indexWhere((p) => p.id == id);
    final old = policies[i];
    if (old.placeholdersLeft > 0) {
      return ContentResult.fail('${old.placeholdersLeft} [PLACEHOLDER] marker(s) are still in the text.');
    }
    policies[i] = policyVersion(
      id: id,
      version: old.version,
      status: 'published',
      title: old.title,
      body: old.body,
      summary: old.changeSummary,
    );
    return ContentResult.ok(policies[i]);
  }

  @override
  Future<ContentResult<List<AdminHelpCategory>>> listCategories() async =>
      ContentResult.ok(List.of(categories));

  @override
  Future<ContentResult<List<AdminHelpArticle>>> listArticles({String? query, bool? published}) async {
    articleListFilters.add(published);
    final q = (query ?? '').trim().toLowerCase();
    return ContentResult.ok([
      for (final a in articles)
        if ((published == null || a.isPublished == published) &&
            (q.isEmpty || a.title.toLowerCase().contains(q)))
          a,
    ]);
  }

  @override
  Future<ContentResult<AdminHelpArticle>> getArticle(int id) async =>
      ContentResult.ok(articles.firstWhere((a) => a.id == id));

  @override
  Future<ContentResult<AdminHelpArticle>> createArticle({
    required int categoryId,
    required String audience,
    required String title,
    required String body,
  }) async {
    calls.add('createArticle');
    if (failMessage != null) return _fail<AdminHelpArticle>();
    final a = helpArticle(id: articles.length + 1, title: title, body: body);
    articles.add(a);
    return ContentResult.ok(a);
  }

  @override
  Future<ContentResult<AdminHelpArticle>> updateArticle(
    int id, {
    int? categoryId,
    String? audience,
    String? title,
    String? body,
    bool? isPublished,
  }) async {
    calls.add('updateArticle:$id');
    if (failMessage != null) return _fail<AdminHelpArticle>();
    final i = articles.indexWhere((a) => a.id == id);
    final old = articles[i];
    articles[i] = helpArticle(
      id: id,
      title: title ?? old.title,
      body: body ?? old.body,
      published: isPublished ?? old.isPublished,
    );
    return ContentResult.ok(articles[i]);
  }

  @override
  Future<ContentResult<bool>> deleteArticle(int id) async {
    calls.add('deleteArticle:$id');
    if (failMessage != null) return _fail<bool>();
    deleted.add(id);
    articles.removeWhere((a) => a.id == id);
    return const ContentResult.ok(true);
  }
}
