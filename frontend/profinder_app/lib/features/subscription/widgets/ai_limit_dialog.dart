// Modal dialog displayed when a customer exceeds their daily AI search quota.
// Informs the user of their usage limit and prompts them to upgrade to a premium plan.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../screens/subscription_screen.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

class AiLimitDialog extends StatelessWidget {
  final int       used;
  final int       limit;
  final String    userRole;
  final DateTime? resetAt;

  const AiLimitDialog({
    super.key,
    required this.used,
    required this.limit,
    required this.userRole,
    this.resetAt,
  });

  static Future<void> show(
    BuildContext context, {
    required int    used,
    required int    limit,
    String          userRole = 'customer',
    DateTime?       resetAt,
  }) {
    return showDialog(
      context:            context,
      barrierDismissible: true,
      builder: (_) => AiLimitDialog(
        used:     used,
        limit:    limit,
        userRole: userRole,
        resetAt:  resetAt,
      ),
    );
  }

  String _formattedReset(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (resetAt == null) return t.subscriptionAiResetsTomorrowMidnight;
    final local = resetAt!.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final now  = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final dayLabel = sameDay ? t.commonToday : t.commonTomorrow;
    return t.subscriptionResetsAt(dayLabel, '$h:$m $ampm');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusChip)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Animated Icon ─────────────────────────────
            Container(
              width:  72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.15),
                    AppColors.accentPurple.withValues(alpha: 0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size:  36,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              t.subscriptionAiSearchLimitReached,
              style: TextStyle(
                fontSize: AppFontSizes.h3,
                fontWeight: FontWeight.bold,
                color:      context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            Text(
              t.subscriptionVeUsedAiSearchesTodayAi('$used', '$limit'),
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color:    context.colors.textSecondary,
                height:   1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // ── Progress Bar ──────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.subscriptionAiSearchesToday,
                        style: TextStyle(
                            fontSize: AppFontSizes.small, color: context.colors.textSecondary)),
                    Text('$used / $limit',
                        style: const TextStyle(
                            fontSize: AppFontSizes.small,
                            fontWeight: FontWeight.bold,
                            color:      AppColors.error)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radius10),
                  child: LinearProgressIndicator(
                    value:      1.0,
                    minHeight:  8,
                    backgroundColor: context.colors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Reset info ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        context.colors.background,
                borderRadius: BorderRadius.circular(AppSizes.radius10),
                border:       Border.all(color: context.colors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formattedReset(context),
                      style: TextStyle(
                          fontSize: AppFontSizes.small, color: context.colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Premium benefits ──────────────────────────
            _buildPremiumBenefits(context),
            const SizedBox(height: 20),

            // ── Buttons ───────────────────────────────────
            SizedBox(
              width:  double.infinity,
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
                  elevation:       0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium, size: 18),
                    const SizedBox(width: 8),
                    Text(t.subscriptionGetPremium20AiDay,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: AppFontSizes.input)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.subscriptionContinueNormalSearch,
                  style: TextStyle(color: context.colors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBenefits(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary.withValues(alpha: 0.06),
            AppColors.accentPurple.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border:       Border.all(color: context.colors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: context.colors.primary),
              const SizedBox(width: 6),
              Text(t.subscriptionPremiumAiFeatures,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppFontSizes.secondary,
                      color:      context.colors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            t.subscriptionBenefit20AiSearchesDay,
            t.subscriptionBenefitAdvancedAiRecommendations,
            t.subscriptionBenefitSearchByBudgetLocationHistory,
            t.subscriptionBenefitPriorityMatchingResults,
          ].map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(f,
                        style: TextStyle(
                            fontSize: AppFontSizes.secondary,
                            color:    context.colors.textPrimary)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}