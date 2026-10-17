// lib/features/support/models/help_models.dart
//
// Parsed responses of GET /api/support/help/... Parsing is defensive: a
// missing or unexpected field never throws, so a small server change can't
// blank the screen.

import 'policy_document.dart';

class HelpCategory {
  final String slug;
  final String iconKey;
  final String title;
  final String description;
  final int articleCount;

  /// True when this item is shown in English because the requested language
  /// has no human-reviewed text yet.
  final bool isFallback;

  const HelpCategory({
    required this.slug,
    required this.iconKey,
    required this.title,
    required this.description,
    required this.articleCount,
    required this.isFallback,
  });

  factory HelpCategory.fromJson(Map<String, dynamic> json) => HelpCategory(
        slug: (json['slug'] ?? '').toString(),
        iconKey: (json['icon_key'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        articleCount: (json['article_count'] as num?)?.toInt() ?? 0,
        isFallback: json['is_fallback'] == true,
      );
}

/// List item (search results / category list). No body.
class HelpArticleSummary {
  final String slug;
  final String categorySlug;
  final String title;
  final String snippet;
  final bool isFallback;

  const HelpArticleSummary({
    required this.slug,
    required this.categorySlug,
    required this.title,
    required this.snippet,
    required this.isFallback,
  });

  factory HelpArticleSummary.fromJson(Map<String, dynamic> json) => HelpArticleSummary(
        slug: (json['slug'] ?? '').toString(),
        categorySlug: (json['category_slug'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        snippet: (json['snippet'] ?? '').toString(),
        isFallback: json['is_fallback'] == true,
      );
}

/// Full article. Reuses [PolicyBlock] (heading / paragraph / bullet).
class HelpArticle {
  final String slug;
  final String categorySlug;
  final String title;
  final List<PolicyBlock> blocks;
  final bool isFallback;

  /// Whether the SERVED text is right-to-left (independent of the app locale).
  final bool isRtl;

  const HelpArticle({
    required this.slug,
    required this.categorySlug,
    required this.title,
    required this.blocks,
    required this.isFallback,
    required this.isRtl,
  });

  factory HelpArticle.fromJson(Map<String, dynamic> json) {
    final raw = json['blocks'];
    return HelpArticle(
      slug: (json['slug'] ?? '').toString(),
      categorySlug: (json['category_slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      blocks: raw is List
          ? raw
              .whereType<Map>()
              .map((b) => PolicyBlock.fromJson(Map<String, dynamic>.from(b)))
              .where((b) => b.text.trim().isNotEmpty)
              .toList()
          : const [],
      isFallback: json['is_fallback'] == true,
      isRtl: json['is_rtl'] == true,
    );
  }
}