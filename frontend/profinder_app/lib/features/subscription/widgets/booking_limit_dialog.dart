// lib/features/subscription/widgets/booking_limit_dialog.dart
//
// Yeh dialog tab dikhta hai jab professional ka monthly booking limit khatam ho.
// Backend se 403 + error:'booking_limit_reached' aane par show karo.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../screens/subscription_screen.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

class BookingLimitDialog extends StatelessWidget {
  final int    limit;           // max bookings (e.g. 5)
  final int    usedThisMonth;   // is mahine kitne ho gaye
  final String? subscriptionEnd; // kab reset hoga (e.g. "30 Jun 2026")
  final String  userRole;        // 'professional'

  const BookingLimitDialog({
    super.key,
    required this.limit,
    required this.usedThisMonth,
    this.subscriptionEnd,
    required this.userRole,
  });

  /// Static helper — seedha call karo jab booking fail ho
  static Future<void> show(
    BuildContext context, {
    required int limit,
    required int usedThisMonth,
    String? subscriptionEnd,
    String userRole = 'professional',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => BookingLimitDialog(
        limit:           limit,
        usedThisMonth:   usedThisMonth,
        subscriptionEnd: subscriptionEnd,
        userRole:        userRole,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ─────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_clock,
                size: 36,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ─────────────────────────────────────────
            Text(
              t.subscriptionBookingLimitReached,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // ── Message ───────────────────────────────────────
            Text(
              t.subscriptionVeUsedBookingsMonthFreePlan('$usedThisMonth', '$limit'),
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // ── Progress Bar ──────────────────────────────────
            _buildProgressBar(context),
            const SizedBox(height: 16),

            // ── Reset Info ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.colors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.refresh, size: 18, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subscriptionEnd != null
                          ? t.subscriptionLimitResetsOn(subscriptionEnd!)
                          : t.subscriptionLimitResetsNextMonth,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Premium Features Preview ──────────────────────
            _buildPremiumFeatures(context),
            const SizedBox(height: 20),

            // ── Buttons ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SubscriptionScreen(userRole: userRole),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium, size: 18),
                    const SizedBox(width: 8),
                    Text(t.subscriptionUpgradePremium,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                t.subscriptionMaybeLater,
                style: TextStyle(color: context.colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final progress = limit > 0 ? usedThisMonth / limit : 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t.subscriptionMonthlyBookings,
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
            Text('$usedThisMonth / $limit',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: context.colors.divider,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumFeatures(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final features = [
      t.subscriptionFeatureUnlimitedBookingsMonth,
      t.subscriptionFeatureFeaturedProfileSearch,
      t.subscriptionFeaturePriorityAiRanking,
      t.subscriptionFeatureNoAdsProfile,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary.withOpacity(0.06),
            context.colors.primaryLight.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium,
                  size: 16, color: context.colors.primary),
              const SizedBox(width: 6),
              Text(t.subscriptionPremiumIncludes,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: context.colors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(f,
                        style: TextStyle(
                            fontSize: 13, color: context.colors.textPrimary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}