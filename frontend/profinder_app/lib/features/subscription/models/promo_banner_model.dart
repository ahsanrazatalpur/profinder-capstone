// lib/features/subscription/models/promo_banner_model.dart

class PromoBanner {
  final int    id;
  final String title;
  final String description;
  final String imageUrl;
  final String buttonText;
  final String buttonLinkType;   // subscription | category | external_url | offer | none
  final String buttonLinkValue;
  final String targetAudience;
  final String trigger;
  final int    triggerXDays;   // trigger == 'every_x_days' hone par cooldown (days)
  final bool   isActive;
  final int    priority;

  PromoBanner({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.buttonText,
    required this.buttonLinkType,
    required this.buttonLinkValue,
    required this.targetAudience,
    required this.trigger,
    required this.triggerXDays,
    required this.isActive,
    required this.priority,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id:               json['id']                ?? 0,
      title:            json['title']             ?? '',
      description:      json['description']       ?? '',
      imageUrl:         json['image_url']         ?? '',
      buttonText:       json['button_text']       ?? 'Get Premium',
      buttonLinkType:   json['button_link_type']  ?? 'subscription',
      buttonLinkValue:  json['button_link_value'] ?? '',
      targetAudience:   json['target_audience']   ?? 'everyone',
      trigger:          json['trigger']           ?? 'home',
      triggerXDays:     json['trigger_x_days']    ?? 3,
      isActive:         json['is_currently_active'] ?? json['is_active'] ?? false,
      priority:         json['priority']          ?? 0,
    );
  }
}