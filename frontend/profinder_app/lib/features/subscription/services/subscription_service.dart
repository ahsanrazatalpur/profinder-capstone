// lib/features/subscription/services/subscription_service.dart

import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/subscription_model.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/payment_service.dart';

class SubscriptionService {
  final ApiService _api = ApiService();

  // ── Plans List ──────────────────────────────────────────────────────────────
  /// Fetches subscription plans filtered by audience role (`customer` or `professional`).
  Future<List<SubscriptionPlan>> getPlans(String planType) async {
    try {
      final res = await _api.get(
        '${AppConstants.subscriptions}plans/?type=$planType',
      );
      final List data = res.data as List;
      return data.map((e) => SubscriptionPlan.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // ── My Plan Status ──────────────────────────────────────────────────────────
  /// Retrieves the current authenticated user's plan details, quota usage, and premium entitlements.
  Future<UserPlanStatus?> getMyPlan() async {
    try {
      final res = await _api.get('${AppConstants.subscriptions}my-plan/');
      return UserPlanStatus.fromJson(res.data);
    } catch (e) {
      return null;
    }
  }

  // ── Subscribe ───────────────────────────────────────────────────────────────
  /// Subscribes to a plan (free plans activate immediately, paid plans create checkout order)
  Future<Map<String, dynamic>> subscribe(int planId, {bool isFree = false, String? currency}) async {
    if (isFree) {
      try {
        final res = await _api.post(AppConstants.subscriptions, {'plan': planId});
        return {'success': true, 'data': res.data};
      } catch (e) {
        final msg = _extractError(e);
        return {'success': false, 'error': msg};
      }
    }

    // Paid plan: initiate payment checkout
    final paymentService = PaymentService();
    final paymentRes = await paymentService.createSubscriptionPayment(
      planId: planId,
      currency: currency,
    );

    if (paymentRes['success'] != true) {
      return {'success': false, 'error': paymentRes['error']};
    }

    final data = paymentRes['data'] as Map<String, dynamic>;
    if (data['is_free'] == true) {
      return {'success': true, 'data': data};
    }

    return {
      'success': true,
      'requires_payment': true,
      'approval_url': data['approval_url'] ?? '',
      'paypal_order_id': data['paypal_order_id'] ?? '',
      'order_id': data['order_id'] ?? '',
      'amount': data['amount'],
      'currency': data['currency'],
      'display_formatted': data['display_formatted'],
    };
  }

  // ── Cancel ──────────────────────────────────────────────────────────────────
  /// POST /subscriptions/cancel/
  Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final res = await _api.post(
        '${AppConstants.subscriptions}cancel/', {});
      return {'success': true, 'data': res.data};
    } catch (e) {
      final msg = _extractError(e);
      return {'success': false, 'error': msg};
    }
  }

  // ── Error helper ────────────────────────────────────────────────────────────
  String _extractError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map) return data['error'] ?? data['detail'] ?? AppStrings.errSomethingWentWrong;
    } catch (_) {}
    return AppStrings.errSomethingWentWrong;
  }
}