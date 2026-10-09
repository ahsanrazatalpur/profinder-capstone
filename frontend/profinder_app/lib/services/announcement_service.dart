// lib/services/announcement_service.dart
//
// Fetches the currently-active announcements for the given audience from
// the public (no-auth) endpoint. Mirrors PromoBannerService's shape —
// used by AnnouncementBanner on the Guest/Customer/Professional home
// screens.
//
// Backend: GET /api/admin-panel/announcements/active/?audience=guest|customer|professional&lang=<code>
// `lang` = the app's current language; untranslated fields come back in English.

import 'api_service.dart';
import '../core/localization/locale_provider.dart';

class AnnouncementService {
  final ApiService _api = ApiService();

  /// [audience] must be one of: 'guest', 'customer', 'professional'.
  Future<List<Map<String, dynamic>>> getActiveAnnouncements(String audience) async {
    try {
      final response = await _api.get(
        '/admin-panel/announcements/active/?audience=$audience&lang=${LocaleProvider.currentCode}',
      );
      final body = response.data as Map<String, dynamic>? ?? {};
      final list = body['announcements'] as List? ?? [];
      return list.map((a) => Map<String, dynamic>.from(a as Map)).toList();
    } catch (e) {
      // Never break the home screen over a failed announcement fetch.
      return [];
    }
  }
}