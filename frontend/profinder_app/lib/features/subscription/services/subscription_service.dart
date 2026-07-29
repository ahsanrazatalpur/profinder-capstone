// lib/features/subscription/services/subscription_service.dart

import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final ApiService _api = ApiService();

  // ── Plans List ──────────────────────────────────────────────────────────────
  /// GET /subscriptions/plans/?type=customer  ya  ?type=professional
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
  /// GET /subscriptions/my-plan/
  /// Flutter is se user ka current plan, limits, premium status jaanta hai
  Future<UserPlanStatus?> getMyPlan() async {
    try {
      final res = await _api.get('${AppConstants.subscriptions}my-plan/');
      return UserPlanStatus.fromJson(res.data);
    } catch (e) {
      return null;
    }
  }

  // ── Subscribe ───────────────────────────────────────────────────────────────
  /// POST /subscriptions/  { plan: plan_id }
  Future<Map<String, dynamic>> subscribe(int planId) async {
    try {
      final res = await _api.post(AppConstants.subscriptions, {'plan': planId});
      return {'success': true, 'data': res.data};
    } catch (e) {
      final msg = _extractError(e);
      return {'success': false, 'error': msg};
    }
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
      if (data is Map) return data['error'] ?? data['detail'] ?? 'Something went wrong';
    } catch (_) {}
    return 'Something went wrong';
  }
}
