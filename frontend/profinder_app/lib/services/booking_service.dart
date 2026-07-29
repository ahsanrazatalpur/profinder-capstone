// lib/services/booking_service.dart
//
// UPDATED — booking_limit_reached error handle karta hai
// Backend 403 + error:'booking_limit_reached' bhejta hai jab limit khatam ho

import 'api_service.dart';
import '../core/constants/app_constants.dart';

class BookingService {
  final ApiService _api = ApiService();

  // ── Create Booking ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createBooking({
    required int    professionalId,
    required String date,
    required String time,
    String          note = '',
  }) async {
    try {
      final response = await _api.post(AppConstants.bookings, {
        'professional': professionalId,
        'date':         date,
        'time':         time,
        'note':         note,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  // ── Get Customer Bookings ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMyBookings() async {
    try {
      final response = await _api.get(AppConstants.bookings);
      final data = response.data;
      final list = data is List ? data : (data['results'] ?? []);
      return {'success': true, 'data': list};
    } catch (e) {
      return _handleError(e);
    }
  }

  // ── Cancel Booking ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> cancelBooking(
      int bookingId, {String reason = ''}) async {
    try {
      final response = await _api.patch(
        '${AppConstants.bookings}$bookingId/',
        {'status': 'cancelled', 'cancel_reason': reason},
      );
      return {'success': true, 'data': response.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  // ── Error Handler ───────────────────────────────────────────────────────────
  Map<String, dynamic> _handleError(dynamic e) {
    if (e.runtimeType.toString().contains('DioException')) {
      final response = (e as dynamic).response;
      if (response != null) {
        final data       = response.data;
        final statusCode = response.statusCode;

        if (data is Map) {
          // ── Booking limit reached (403) ──────────────────
          if (statusCode == 403 &&
              data['error'] == 'booking_limit_reached') {
            return {
              'success':          false,
              'error_type':       'booking_limit_reached',
              'message':          data['message'] ?? 'Booking limit reached.',
              'limit':            data['limit']            ?? 5,
              'used_this_month':  data['used_this_month']  ?? 0,
              'subscription_end': data['subscription_end'],
              'upgrade':          data['upgrade']          ?? true,
            };
          }

          // ── Other errors ──────────────────────────────────
          final msg = data['error'] is Map
              ? (data['error'] as Map).values.first.toString()
              : data['error'] ?? data['detail'] ?? 'Something went wrong';
          return {'success': false, 'message': msg, 'error_type': 'general'};
        }
      }
      return {
        'success': false,
        'message': 'Network error. Check connection.',
        'error_type': 'network',
      };
    }
    return {
      'success': false,
      'message': 'Something went wrong.',
      'error_type': 'general',
    };
  }
}
