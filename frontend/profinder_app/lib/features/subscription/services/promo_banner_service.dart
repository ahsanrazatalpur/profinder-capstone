// lib/features/subscription/services/promo_banner_service.dart

import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/locale_provider.dart';
import '../models/promo_banner_model.dart';

class PromoBannerService {
  final ApiService _api = ApiService();

  /// Fetches active promotional banners targeting the specified trigger context and user role.
  ///
  /// [trigger]: Navigation trigger ('home', 'search', 'ai_search', 'booking', 'login').
  /// [userType]: Audience role segment ('guest', 'free_customer', 'premium_customer', etc.).
  Future<List<PromoBanner>> getActiveBanners({
    String trigger = 'home',
    String userType = 'guest',
  }) async {
    try {
      final res = await _api.get(
        '${AppConstants.activeBanner}?trigger=$trigger&user_type=$userType&lang=${LocaleProvider.currentCode}',
      );
      final data = res.data as Map<String, dynamic>;

      if (data['active'] != true) return [];

      final banners = data['banners'] as List<dynamic>? ?? [];
      return banners.map((b) => PromoBanner.fromJson(b)).toList();
    } catch (_) {
      return [];
    }
  }
}
