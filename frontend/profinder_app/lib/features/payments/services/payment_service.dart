// lib/features/payments/services/payment_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final ApiService _api = ApiService();
  static const String _currencyPrefKey = 'selected_user_currency';

  // ─── Currency Preference ───────────────────────────────────────────────────

  Future<String> getSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyPrefKey) ?? 'USD';
  }

  Future<void> setSelectedCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyPrefKey, currencyCode.toUpperCase());
  }

  // ─── Supported Currencies & Rates ──────────────────────────────────────────

  Future<Map<String, dynamic>?> getCurrencies() async {
    try {
      final res = await _api.get(AppConstants.paymentCurrencies);
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Booking Checkout ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createBookingPayment({
    required int bookingId,
    String? currency,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    try {
      final curr = currency ?? await getSelectedCurrency();
      final res = await _api.post(AppConstants.paymentBookingCreate, {
        'booking_id': bookingId,
        'currency': curr,
        'return_url': returnUrl ?? 'https://profinder.app/payment/success',
        'cancel_url': cancelUrl ?? 'https://profinder.app/payment/cancel',
      });
      return {'success': true, 'data': res.data};
    } catch (e) {
      return {'success': false, 'error': _extractError(e)};
    }
  }

  // ─── Subscription Checkout ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> createSubscriptionPayment({
    required int planId,
    String? currency,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    try {
      final curr = currency ?? await getSelectedCurrency();
      final res = await _api.post(AppConstants.paymentSubscriptionCreate, {
        'plan_id': planId,
        'currency': curr,
        'return_url': returnUrl ?? 'https://profinder.app/payment/success',
        'cancel_url': cancelUrl ?? 'https://profinder.app/payment/cancel',
      });
      return {'success': true, 'data': res.data};
    } catch (e) {
      return {'success': false, 'error': _extractError(e)};
    }
  }

  // ─── Capture Payment ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> capturePayment({
    String? paypalOrderId,
    String? orderId,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (paypalOrderId != null) payload['paypal_order_id'] = paypalOrderId;
      if (orderId != null) payload['order_id'] = orderId;
      final res = await _api.post(AppConstants.paymentCapture, payload);
      return {'success': true, 'data': res.data};
    } catch (e) {
      return {'success': false, 'error': _extractError(e)};
    }
  }

  // ─── Launch PayPal Approval URL ────────────────────────────────────────────

  Future<bool> launchApprovalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  // ─── Error Formatter ───────────────────────────────────────────────────────

  String _extractError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map) {
        return data['error'] ??
            data['detail'] ??
            data['message'] ??
            'Payment request failed';
      }
    } catch (_) {}
    return 'Payment request failed. Please try again.';
  }
}
