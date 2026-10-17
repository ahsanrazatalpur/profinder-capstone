// lib/features/support/models/policy_document.dart
//
// Parsed response of GET /api/support/policies/privacy/. Parsing is defensive:
// a missing or unknown field never throws (an unknown block type renders as a
// paragraph), so a small server change can't blank the screen.

enum PolicyBlockType { heading, paragraph, bullet }

class PolicyBlock {
  final PolicyBlockType type;
  final String text;

  const PolicyBlock(this.type, this.text);

  factory PolicyBlock.fromJson(Map<String, dynamic> json) {
    final type = switch (json['type']) {
      'heading' => PolicyBlockType.heading,
      'bullet' => PolicyBlockType.bullet,
      _ => PolicyBlockType.paragraph,
    };
    return PolicyBlock(type, (json['text'] ?? '').toString());
  }
}

class PolicyDocument {
  final int version;
  final String? effectiveDate;
  final String title;
  final List<PolicyBlock> blocks;

  /// Language of the text actually served (may differ from the requested one).
  final String language;
  final String requestedLanguage;

  /// True when the requested language had no human-reviewed text yet and
  /// English is shown instead.
  final bool isFallback;

  /// Whether the SERVED text is right-to-left (independent of the app locale).
  final bool isRtl;

  const PolicyDocument({
    required this.version,
    required this.effectiveDate,
    required this.title,
    required this.blocks,
    required this.language,
    required this.requestedLanguage,
    required this.isFallback,
    required this.isRtl,
  });

  factory PolicyDocument.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['blocks'];
    return PolicyDocument(
      version: (json['version'] as num?)?.toInt() ?? 0,
      effectiveDate: json['effective_date'] as String?,
      title: (json['title'] ?? '').toString(),
      blocks: rawBlocks is List
          ? rawBlocks
              .whereType<Map>()
              .map((b) => PolicyBlock.fromJson(Map<String, dynamic>.from(b)))
              .where((b) => b.text.trim().isNotEmpty)
              .toList()
          : const [],
      language: (json['language'] ?? 'en').toString(),
      requestedLanguage: (json['requested_language'] ?? 'en').toString(),
      isFallback: json['is_fallback'] == true,
      isRtl: json['is_rtl'] == true,
    );
  }
}