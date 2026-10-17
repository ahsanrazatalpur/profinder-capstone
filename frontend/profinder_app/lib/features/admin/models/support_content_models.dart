// lib/features/admin/models/support_content_models.dart
//
// Parsed responses of /api/support/admin/policy/... and /api/support/admin/help/...
// (admin only, English). Defensive parsing: a missing field never throws.

String _s(Object? v) => (v ?? '').toString();

DateTime? _date(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;

/// Matches the markers that still need a real value, e.g.
/// "[PLACEHOLDER: SUPPORT EMAIL]".
final RegExp kPlaceholderPattern = RegExp(r'\[PLACEHOLDER[^\]]*\]');

/// "[PLACEHOLDER: SUPPORT EMAIL]" -> "SUPPORT EMAIL".
String placeholderLabel(String marker) {
  final inner = marker.replaceFirst('[PLACEHOLDER', '').replaceAll(']', '');
  final label = inner.replaceFirst(':', '').trim();
  return label.isEmpty ? 'Value' : label;
}

class AdminPolicyVersion {
  final int id;
  final int version;
  final String status; // draft | published | archived
  final bool isLocked;
  final DateTime? effectiveDate;
  final DateTime? publishedAt;
  final String changeSummary;
  final String title;
  final String body;
  final int placeholdersLeft;

  const AdminPolicyVersion({
    required this.id,
    required this.version,
    required this.status,
    required this.isLocked,
    required this.effectiveDate,
    required this.publishedAt,
    required this.changeSummary,
    required this.title,
    required this.body,
    required this.placeholdersLeft,
  });

  bool get isDraft => status == 'draft';

  factory AdminPolicyVersion.fromJson(Map<String, dynamic> json) => AdminPolicyVersion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        version: (json['version'] as num?)?.toInt() ?? 0,
        status: _s(json['status']),
        isLocked: json['is_locked'] == true,
        effectiveDate: _date(json['effective_date']),
        publishedAt: _date(json['published_at']),
        changeSummary: _s(json['change_summary']),
        title: _s(json['title']),
        body: _s(json['body']),
        placeholdersLeft: (json['placeholders_left'] as num?)?.toInt() ?? 0,
      );
}

class AdminHelpCategory {
  final int id;
  final String slug;
  final String title;
  final String audience;

  const AdminHelpCategory({
    required this.id,
    required this.slug,
    required this.title,
    required this.audience,
  });

  factory AdminHelpCategory.fromJson(Map<String, dynamic> json) => AdminHelpCategory(
        id: (json['id'] as num?)?.toInt() ?? 0,
        slug: _s(json['slug']),
        title: _s(json['title']),
        audience: _s(json['audience']),
      );
}

class AdminHelpArticle {
  final int id;
  final String slug;
  final int categoryId;
  final String categoryTitle;
  final String audience; // all | customer | professional
  final int order;
  final bool isPublished;
  final String title;
  final String body;

  const AdminHelpArticle({
    required this.id,
    required this.slug,
    required this.categoryId,
    required this.categoryTitle,
    required this.audience,
    required this.order,
    required this.isPublished,
    required this.title,
    required this.body,
  });

  factory AdminHelpArticle.fromJson(Map<String, dynamic> json) => AdminHelpArticle(
        id: (json['id'] as num?)?.toInt() ?? 0,
        slug: _s(json['slug']),
        categoryId: (json['category_id'] as num?)?.toInt() ?? 0,
        categoryTitle: _s(json['category_title']),
        audience: _s(json['audience']),
        order: (json['order'] as num?)?.toInt() ?? 0,
        isPublished: json['is_published'] == true,
        title: _s(json['title']),
        body: _s(json['body']),
      );
}

const Map<String, String> kAdminAudienceLabels = {
  'all': 'Everyone',
  'customer': 'Customers',
  'professional': 'Professionals',
};