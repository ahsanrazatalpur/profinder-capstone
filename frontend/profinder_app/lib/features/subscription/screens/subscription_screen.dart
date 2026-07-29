// lib/features/subscription/screens/subscription_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

class SubscriptionScreen extends StatefulWidget {
  /// role: 'customer' ya 'professional'
  final String userRole;

  const SubscriptionScreen({super.key, required this.userRole});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _service = SubscriptionService();

  List<SubscriptionPlan> _plans       = [];
  UserPlanStatus?        _currentPlan;
  bool                   _loading     = true;
  bool                   _subscribing = false;
  String?                _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getPlans(widget.userRole),
        _service.getMyPlan(),
      ]);
      setState(() {
        _plans       = results[0] as List<SubscriptionPlan>;
        _currentPlan = results[1] as UserPlanStatus?;
        _loading     = false;
      });
    } catch (e) {
      setState(() { _error = AppLocalizations.of(context)!.subscriptionFailedToLoadPlans; _loading = false; });
    }
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    if (plan.isFree) return; // Free plan subscribe nahi hoti

    final confirm = await _showConfirmDialog(plan);
    if (!confirm) return;

    setState(() => _subscribing = true);
    final result = await _service.subscribe(plan.id);
    setState(() => _subscribing = false);

    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccess(AppLocalizations.of(context)!.subscriptionSubscribedTo(plan.name));
      await _loadData(); // Refresh plan status
    } else {
      _showError(result['error'] ?? AppLocalizations.of(context)!.subscriptionSubscriptionFailed);
    }
  }

  Future<bool> _showConfirmDialog(SubscriptionPlan plan) async {
    final t = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t.subscriptionConfirmSubscription,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          t.subscriptionSubscribe(plan.name, plan.currency,
              '${plan.price.toStringAsFixed(0)}${plan.billing == 'monthly' ? t.subscriptionPerMonth : t.subscriptionPerYear}?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Text(t.subscriptionSubscribe2),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(t.subscriptionChoosePlan),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: context.colors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: Text(t.retry)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final t = AppLocalizations.of(context)!;
    // Free plan ko alag, paid plans alag
    final freePlan  = _plans.where((p) => p.isFree).firstOrNull;
    final paidPlans = _plans.where((p) => p.isPremium).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Current Plan Banner ───────────────────────────
            if (_currentPlan != null) _buildCurrentPlanBanner(),
            const SizedBox(height: 24),

            // ── Header ───────────────────────────────────────
            Text(t.subscriptionAvailablePlans,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary)),
            const SizedBox(height: 4),
            Text(
              widget.userRole == 'customer'
                  ? t.subscriptionUpgradeUnlimitedAiSearches
                  : t.subscriptionUpgradeUnlimitedBookings,
              style: TextStyle(
                  fontSize: 14, color: context.colors.textSecondary),
            ),
            const SizedBox(height: 20),

            // ── Free Plan Card ────────────────────────────────
            if (freePlan != null) ...[
              _buildPlanCard(freePlan, isRecommended: false),
              const SizedBox(height: 16),
            ],

            // ── Paid Plan Cards ───────────────────────────────
            ...paidPlans.asMap().entries.map((entry) {
              final isFirst = entry.key == 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPlanCard(entry.value, isRecommended: isFirst),
              );
            }),

            const SizedBox(height: 12),
            _buildCancelNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanBanner() {
    final plan = _currentPlan!;
    final t = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: plan.isPremium
              ? [const Color(0xFF7C3AED), const Color(0xFF2563EB)]
              : [context.colors.textSecondary, context.colors.textDisabled],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            plan.isPremium ? Icons.workspace_premium : Icons.person,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.subscriptionCurrentPlan(plan.planName),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                if (plan.endDate != null)
                  Text(t.subscriptionValidUntil('${plan.endDate}'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                if (!plan.isPremium)
                  Text(t.subscriptionUpgradeUnlockPremiumFeatures,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (plan.isPremium)
            const Icon(Icons.verified, color: Colors.amber, size: 24),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, {required bool isRecommended}) {
    final t = AppLocalizations.of(context)!;
    final isCurrentPlan = _currentPlan?.planName == plan.name &&
        _currentPlan?.billing == plan.billing;
    final isPremium = plan.isPremium;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentPlan
                  ? AppColors.success
                  : isPremium && isRecommended
                      ? context.colors.primary
                      : context.colors.divider,
              width: isCurrentPlan || (isPremium && isRecommended) ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Plan Header ─────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPremium
                          ? context.colors.primaryLight
                          : context.colors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPremium
                          ? Icons.workspace_premium
                          : Icons.person_outline,
                      color: isPremium
                          ? context.colors.primary
                          : context.colors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: context.colors.textPrimary)),
                        Text(
                          plan.isFree
                              ? t.subscriptionFreeForever
                              : plan.billing == 'monthly'
                                  ? t.subscriptionBilledMonthly
                                  : t.subscriptionBilledYearly,
                          style: TextStyle(
                              fontSize: 12, color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.isFree
                            ? t.subscriptionFree
                            : '${plan.currency} ${plan.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: plan.isFree ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: isPremium
                              ? context.colors.primary
                              : context.colors.textPrimary,
                        ),
                      ),
                      if (!plan.isFree)
                        Text(
                          plan.billing == 'monthly' ? t.subscriptionPerMonth : t.subscriptionPerYear,
                          style: TextStyle(
                              fontSize: 12, color: context.colors.textSecondary),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: context.colors.divider),
              const SizedBox(height: 12),

              // ── Features List ───────────────────────────────
              ..._buildFeaturesList(plan),
              const SizedBox(height: 20),

              // ── Button ──────────────────────────────────────
              _buildPlanButton(plan, isCurrentPlan),
            ],
          ),
        ),

        // ── Recommended Badge ────────────────────────────────
        if (isRecommended && isPremium)
          Positioned(
            top: -12,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t.subscriptionRecommended,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
          ),

        // ── Active Check ─────────────────────────────────────
        if (isCurrentPlan)
          Positioned(
            top: -12,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t.subscriptionCurrentPlan2,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildFeaturesList(SubscriptionPlan plan) {
    final t = AppLocalizations.of(context)!;
    final features = <Map<String, dynamic>>[];

    if (widget.userRole == 'customer') {
      final aiLimit  = plan.getInt('ai_search_limit');
      final msgLimit = plan.getInt('message_send_limit');
      features.addAll([
        {'label': t.subscriptionFeatureAiSearchesDay,  'value': aiLimit == 0  ? t.subscriptionUnlimited : '$aiLimit',  'enabled': true},
        {'label': t.subscriptionFeatureMessagesDay,     'value': msgLimit == 0 ? t.subscriptionUnlimited : '$msgLimit', 'enabled': true},
        {'label': t.subscriptionFeatureUnlimitedBookings,'value': '',                                         'enabled': true},
        {'label': t.subscriptionFeaturePrioritySupport, 'value': '', 'enabled': plan.getBool('priority_support')},
        {'label': t.subscriptionFeaturePremiumBadge,    'value': '', 'enabled': plan.getBool('premium_badge')},
        {'label': t.subscriptionFeatureNoAds,           'value': '', 'enabled': !plan.getBool('ads_enabled', defaultVal: true)},
      ]);
    } else {
      final bookLimit = plan.getInt('booking_limit');
      final portLimit = plan.getInt('portfolio_limit');
      final svcLimit  = plan.getInt('service_limit');
      final msgLimit  = plan.getInt('message_send_limit');
      features.addAll([
        {'label': t.subscriptionFeatureBookingsMonth,    'value': bookLimit == 0 ? t.subscriptionUnlimited : '$bookLimit', 'enabled': true},
        {'label': t.subscriptionFeaturePortfolioImages,  'value': portLimit == 0 ? t.subscriptionUnlimited : '$portLimit', 'enabled': true},
        {'label': t.subscriptionFeatureServicesListed,   'value': svcLimit  == 0 ? t.subscriptionUnlimited : '$svcLimit',  'enabled': true},
        {'label': t.subscriptionFeatureMessagesDay,      'value': msgLimit  == 0 ? t.subscriptionUnlimited : '$msgLimit',  'enabled': true},
        {'label': t.subscriptionFeatureFeaturedProfile,  'value': '', 'enabled': plan.getBool('featured_profile')},
        {'label': t.subscriptionFeaturePriorityRanking,  'value': '', 'enabled': plan.getBool('priority_ranking')},
        {'label': t.subscriptionFeaturePremiumBadge,     'value': '', 'enabled': plan.getBool('premium_badge')},
        {'label': t.subscriptionFeatureNoAds,            'value': '', 'enabled': !plan.getBool('ads_enabled', defaultVal: true)},
      ]);
    }

    return features.map((f) {
      final enabled = f['enabled'] as bool;
      final value   = f['value']   as String;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              enabled ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: enabled ? AppColors.success : context.colors.textDisabled,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                f['label'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: enabled ? context.colors.textPrimary : context.colors.textDisabled,
                ),
              ),
            ),
            if (value.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(value,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary)),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPlanButton(SubscriptionPlan plan, bool isCurrentPlan) {
    final t = AppLocalizations.of(context)!;
    if (isCurrentPlan) {
      return Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: context.colors.accentLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, color: AppColors.success, size: 18),
              const SizedBox(width: 6),
              Text(t.subscriptionCurrentPlan3,
                  style: const TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    if (plan.isFree) {
      return Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.divider),
        ),
        child: Center(
          child: Text(t.subscriptionBasicPlan,
              style: TextStyle(color: context.colors.textSecondary)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _subscribing ? null : () => _subscribe(plan),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _subscribing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                t.subscriptionGet(plan.name),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
      ),
    );
  }

  Widget _buildCancelNote() {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          t.subscriptionCancelAnytimeSecurePayment,
          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
        ),
      ),
    );
  }
}