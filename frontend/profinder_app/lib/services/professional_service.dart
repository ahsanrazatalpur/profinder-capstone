// lib/services/professional_service.dart

import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ProfessionalService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getProfessionalProfile(String id) async {
    try {
      final response = await _api.get('/profiles/professional/$id/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      debugPrint('[ProfessionalService] getProfessionalProfile($id) failed: $e');
      return {'success': false, 'data': null};
    }
  }

  Future<Map<String, dynamic>> getReviews(String id) async {
    try {
      final response = await _api.get('/reviews/professionals/$id/reviews/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      debugPrint('[ProfessionalService] getReviews($id) failed: $e');
      return {'success': false, 'data': []};
    }
  }

  // FIXED: correct URL /profiles/portfolio/user/<id>/
  Future<Map<String, dynamic>> getPortfolio(String id) async {
    try {
      final response = await _api.get('/profiles/portfolio/user/$id/');
      return {'success': true, 'data': response.data};
    } catch (e) {
      debugPrint('[ProfessionalService] getPortfolio($id) failed: $e');
      return {'success': false, 'data': []};
    }
  }
}