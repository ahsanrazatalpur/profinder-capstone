// lib/features/about/models/about_page_model.dart

class AboutSectionItem {
  final int    id;
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final String imageUrl;
  final String value;
  final String linkUrl;
  final Map<String, dynamic> extraData;
  final int    order;
  final bool   isEnabled;

  AboutSectionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.imageUrl,
    required this.value,
    required this.linkUrl,
    required this.extraData,
    required this.order,
    this.isEnabled = true,
  });

  factory AboutSectionItem.fromJson(Map<String, dynamic> json) {
    return AboutSectionItem(
      id:          json['id']          ?? 0,
      title:       json['title']       ?? '',
      subtitle:    json['subtitle']    ?? '',
      description: json['description'] ?? '',
      icon:        json['icon']        ?? '',
      imageUrl:    json['image_url']   ?? '',
      value:       json['value']       ?? '',
      linkUrl:     json['link_url']    ?? '',
      extraData:   Map<String, dynamic>.from(json['extra_data'] ?? {}),
      order:       json['order']       ?? 0,
      isEnabled:   json['is_enabled']  ?? true,
    );
  }

  AboutSectionItem copyWith({
    String? title, String? subtitle, String? description, String? icon,
    String? imageUrl, String? value, String? linkUrl,
    Map<String, dynamic>? extraData, int? order, bool? isEnabled,
  }) {
    return AboutSectionItem(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      value: value ?? this.value,
      linkUrl: linkUrl ?? this.linkUrl,
      extraData: extraData ?? this.extraData,
      order: order ?? this.order,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class AboutSection {
  final int    id;
  final String sectionType;
  final String sectionKey;
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final String imageUrl;
  final String ctaText;
  final String ctaUrl;
  final String ctaStyle;
  final Map<String, dynamic> extraData;
  final int    order;
  final bool   isEnabled;
  final List<AboutSectionItem> items;

  AboutSection({
    required this.id,
    required this.sectionType,
    required this.sectionKey,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.imageUrl,
    required this.ctaText,
    required this.ctaUrl,
    required this.ctaStyle,
    required this.extraData,
    required this.order,
    this.isEnabled = true,
    required this.items,
  });

  factory AboutSection.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List? ?? []);
    return AboutSection(
      id:          json['id']           ?? 0,
      sectionType: json['section_type'] ?? 'custom',
      sectionKey:  json['section_key']  ?? '',
      title:       json['title']        ?? '',
      subtitle:    json['subtitle']     ?? '',
      description: json['description']  ?? '',
      icon:        json['icon']         ?? '',
      imageUrl:    json['image_url']    ?? '',
      ctaText:     json['cta_text']     ?? '',
      ctaUrl:      json['cta_url']      ?? '',
      ctaStyle:    json['cta_style']    ?? 'primary',
      extraData:   Map<String, dynamic>.from(json['extra_data'] ?? {}),
      order:       json['order']        ?? 0,
      isEnabled:   json['is_enabled']   ?? true,
      items:       itemsJson.map((i) => AboutSectionItem.fromJson(i)).toList(),
    );
  }

  bool get hasCta => ctaText.trim().isNotEmpty && ctaUrl.trim().isNotEmpty;

  static const Set<String> collectionTypes = {
    'why_choose_us', 'how_it_works', 'statistics', 'core_values',
    'team_members', 'investors_partners', 'certifications', 'awards',
  };

  bool get isCollectionType => collectionTypes.contains(sectionType);
}

class AboutPageSeo {
  final String metaTitle;
  final String metaDescription;
  final String metaKeywords;
  final String ogImageUrl;

  AboutPageSeo({
    required this.metaTitle,
    required this.metaDescription,
    required this.metaKeywords,
    required this.ogImageUrl,
  });

  factory AboutPageSeo.fromJson(Map<String, dynamic> json) {
    return AboutPageSeo(
      metaTitle:       json['meta_title']       ?? '',
      metaDescription: json['meta_description'] ?? '',
      metaKeywords:    json['meta_keywords']    ?? '',
      ogImageUrl:      json['og_image_url'] ?? json['og_image'] ?? '',
    );
  }
}

class AboutPageData {
  final List<AboutSection> sections;
  final AboutPageSeo       seo;
  final int?               version;

  AboutPageData({
    required this.sections,
    required this.seo,
    required this.version,
  });

  factory AboutPageData.fromJson(Map<String, dynamic> json) {
    final sectionsJson = (json['sections'] as List? ?? []);
    return AboutPageData(
      sections: sectionsJson.map((s) => AboutSection.fromJson(s)).toList(),
      seo:      AboutPageSeo.fromJson(Map<String, dynamic>.from(json['seo'] ?? {})),
      version:  json['version'],
    );
  }

  AboutSection? sectionByKey(String key) {
    for (final s in sections) {
      if (s.sectionKey == key) return s;
    }
    return null;
  }
}