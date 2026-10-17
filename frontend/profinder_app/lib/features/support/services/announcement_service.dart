// lib/features/support/services/announcement_service.dart
//
// Fetches currently-active announcements for given audience from public endpoint.

import '../../../core/localization/locale_provider.dart';
import '../../../core/network/api_service.dart';

class AnnouncementService {
  final ApiService _api = ApiService();

  /// [audience] must be one of: 'guest', 'customer', 'professional'.
  Future<List<Map<String, dynamic>>> getActiveAnnouncements(
    String audience,
  ) async {
    try {
      final response = await _api.get(
        '/admin-panel/announcements/active/?audience=$audience&lang=${LocaleProvider.currentCode}',
      );
      final body = response.data as Map<String, dynamic>? ?? {};
      final list = body['announcements'] as List? ?? [];
      return list.map((a) => Map<String, dynamic>.from(a as Map)).toList();
    } catch (e) {
      return [];
    }
  }
}
