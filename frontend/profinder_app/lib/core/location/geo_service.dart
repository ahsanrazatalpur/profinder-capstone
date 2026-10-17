// lib/core/location/geo_service.dart
//
// Public reference-data calls for Location (countries and cities).

import '../constants/app_constants.dart';
import '../network/api_service.dart';

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

  /// Active cities for [countryId] only.
  Future<Map<String, dynamic>> getCities(int countryId) async {
    try {
      final response = await _api.get(
        '${AppConstants.cities}?country=$countryId',
      );
      return {'success': true, 'data': response.data ?? []};
    } catch (e) {
      return {'success': false, 'data': []};
    }
  }
}
