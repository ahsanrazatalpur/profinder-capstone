// lib/features/subscription/models/subscription_model.dart

class PlanFeature {
  final String key;
  final String value;
  final String featureType;
  final String label;

  PlanFeature({
    required this.key,
    required this.value,
    required this.featureType,
    required this.label,
  });

  factory PlanFeature.fromJson(Map<String, dynamic> json) {
    return PlanFeature(
      key:         json['key']          ?? '',
      value:       json['value']        ?? '0',
      featureType: json['feature_type'] ?? 'int',
      label:       json['label']        ?? '',
    );
  }

  // Type ke hisaab se value lo
  int    asInt()  => int.tryParse(value) ?? 0;
  bool   asBool() => value == '1' || value.toLowerCase() == 'true';
  String asStr()  => value;
}


class SubscriptionPlan {
  final int    id;
  final String name;
  final String planType;  // 'customer' | 'professional'
  final String billing;   // 'free' | 'monthly' | 'yearly'
  final double price;
  final String currency;
  final int    durationDays;
  final bool   isActive;
  final List<PlanFeature> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.planType,
    required this.billing,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.isActive,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id:           json['id']           ?? 0,
      name:         json['name']         ?? '',
      planType:     json['plan_type']    ?? '',
      billing:      json['billing']      ?? 'free',
      price:        double.tryParse(json['price'].toString()) ?? 0.0,
      currency:     json['currency']     ?? 'PKR',
      durationDays: json['duration_days']?? 0,
      isActive:     json['is_active']    ?? true,
      features:     (json['features'] as List<dynamic>? ?? [])
          .map((f) => PlanFeature.fromJson(f))
          .toList(),
    );
  }

  bool get isFree => billing == 'free';
  bool get isPremium => billing != 'free';

  // Feature shortcut getters
  PlanFeature? _feature(String key) {
    try {
      return features.firstWhere((f) => f.key == key);
    } catch (_) {
      return null;
    }
  }

  int    getInt(String key,  {int    defaultVal = 0})     => _feature(key)?.asInt()  ?? defaultVal;
  bool   getBool(String key, {bool   defaultVal = false}) => _feature(key)?.asBool() ?? defaultVal;
  String getStr(String key,  {String defaultVal = ''})    => _feature(key)?.asStr()  ?? defaultVal;
}


class UserPlanStatus {
  final bool   hasSubscription;
  final String planName;
  final String planType;
  final String billing;
  final bool   isPremium;
  final String? endDate;
  final Map<String, dynamic> features;
  final bool   adsEnabled;

  UserPlanStatus({
    required this.hasSubscription,
    required this.planName,
    required this.planType,
    required this.billing,
    required this.isPremium,
    this.endDate,
    required this.features,
    required this.adsEnabled,
  });

  factory UserPlanStatus.fromJson(Map<String, dynamic> json) {
    return UserPlanStatus(
      hasSubscription: json['has_subscription'] ?? false,
      planName:        json['plan_name']        ?? 'Free',
      planType:        json['plan_type']        ?? '',
      billing:         json['billing']          ?? 'free',
      isPremium:       json['is_premium']       ?? false,
      endDate:         json['end_date'],
      features:        Map<String, dynamic>.from(json['features'] ?? {}),
      adsEnabled:      json['ads_enabled']      ?? true,
    );
  }

  // Feature getters
  int getInt(String key, {int defaultVal = 0}) {
    final val = features[key];
    if (val == null) return defaultVal;
    return int.tryParse(val.toString()) ?? defaultVal;
  }

  bool getBool(String key, {bool defaultVal = false}) {
    final val = features[key];
    if (val == null) return defaultVal;
    if (val is bool) return val;
    return val == 1 || val.toString().toLowerCase() == 'true';
  }

  // Shortcut getters
  int  get aiSearchLimit    => getInt('ai_search_limit',    defaultVal: 5);
  int  get messageSendLimit => getInt('message_send_limit', defaultVal: 20);
  int  get bookingLimit     => getInt('booking_limit',      defaultVal: 5);
  int  get portfolioLimit   => getInt('portfolio_limit',    defaultVal: 3);
  bool get hasPremiumBadge  => getBool('premium_badge');
  bool get hasFeaturedProfile => getBool('featured_profile');
  bool get hasPriorityRanking => getBool('priority_ranking');

  // Free default (jab API call na ho)
  factory UserPlanStatus.free(String role) {
    return UserPlanStatus(
      hasSubscription: false,
      planName:        'Free',
      planType:        role,
      billing:         'free',
      isPremium:       false,
      endDate:         null,
      features:        {},
      adsEnabled:      true,
    );
  }
}
