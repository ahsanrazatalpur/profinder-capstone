// lib/services/geo_service.dart
//
// Public reference-data calls for the Register screen's Location step.
// Same pattern as HomeService.getCategories() — returns raw
// List<dynamic> maps ({'id', 'name'}), no separate model classes, to stay
// consistent with how the rest of the app already handles this kind of data.

import 'api_service.dart';
import '../core/constants/app_constants.dart';

class GeoService {
  final ApiService _api = ApiService();

  /// Active countries only, alphabetically sorted by the backend.
  Future<Map<String, dynamic>> getCountries() async {
    try {
      final response = await _api.get(AppConstants.countries);
      return {'success': true, 'data': response.data ?? []};
    } catch (e) {
      return {'success': false, 'data': []};
    }
  }

  /// Active cities for [countryId] only — the backend rejects an inactive
  /// or unknown country, so an invalid city can never be selected.
  Future<Map<String, dynamic>> getCities(int countryId) async {
    try {
      final response = await _api.get('${AppConstants.cities}?country=$countryId');
      return {'success': true, 'data': response.data ?? []};
    } catch (e) {
      return {'success': false, 'data': []};
    }
  }
}