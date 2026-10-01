// lib/features/profile/screens/wallet_screen.dart
//
// WALLET — real spend total (sum of completed payments) + current plan.
// There's no stored-balance/top-up concept in the backend yet, so this is
// an honest "spend & plan" summary, not a fake wallet balance.

import 'package:flutter/material.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../services/api_service.dart';
import '../../subscription/screens/subscription_screen.dart';
import 'payments_screen.dart';
import '../../../shared/widgets/cta_banner.dart';
import '../../../l10n/generated/app_localizations.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _api = ApiService();

  bool   _loading    = true;
  double _totalSpent = 0;
  int    _txCount    = 0;
  bool   _isPremium  = false;
  String _planName   = 'Free';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.get('/payments/'),
        _api.get('${AppConstants.subscriptions}my-plan/'),
      ]);
      final payments = results[0].data is List ? List<dynamic>.from(results[0].data) : [];
      final completed = payments.where((p) => p['status'] == 'completed').toList();
      _totalSpent = completed.fold(0.0, (sum, p) => sum + (double.tryParse('${p['amount']}') ?? 0));
      _txCount    = payments.length;
      final plan  = results[1].data as Map<String, dynamic>;
      _isPremium  = plan['is_premium'] == true;
      _planName   = plan['plan_name']?.toString() ?? 'Free';
    } catch (_) {
      // keep zeros — screen still renders usefully
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: UniversalAppBar(
        title: AppLocalizations.of(context)!.walletTitle,
        icon: Icons.account_balance_wallet_rounded,
      ),
      body: _loading
          ? Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.customerColor,
                  strokeWidth: 3,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.customerColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Balance Card ──────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
          clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(children: [
          Positioned(right: -36, top: -52, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.10)))),
          Positioned(right: 70, bottom: -64, child: Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
          Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.of(context)!.totalSpentLabel,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '\$${_totalSpent.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.transactionCountLabel(_txCount),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
        ]),
                    ),

                    const SizedBox(height: 14),

                    // ── Subscription Banner ──────────────────
                    CtaBanner(
                      isDark: isDark,
                      title: AppLocalizations.of(context)!.currentPlanLabel(_planName),
                      subtitle: _isPremium
                          ? AppLocalizations.of(context)!.premiumActiveSubtitle
                          : AppLocalizations.of(context)!.premiumUpgradeSubtitle,
                      ctaLabel: _isPremium ? AppLocalizations.of(context)!.manageCta : AppLocalizations.of(context)!.upgradeCta,
                      icon: Icons.workspace_premium_rounded,
                      accentStart: const Color(0xFFA78BFA),
                      accentEnd: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionScreen(userRole: 'customer'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Payment History Tile ──────────────────
                    Material(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFE5E7EB),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.customerColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.customerColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            AppLocalizations.of(context)!.paymentHistoryLabel,
                            style: TextStyle(
                              fontSize: isTablet ? 15.0 : 14.0,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                              letterSpacing: -0.1,
                            ),
                          ),
                          subtitle: Text(
                            AppLocalizations.of(context)!.paymentHistorySubtitle,
                            style: TextStyle(
                              fontSize: isTablet ? 12.0 : 11.5,
                              color: context.colors.textSecondary,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: context.colors.textSecondary,
                            size: 20,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}