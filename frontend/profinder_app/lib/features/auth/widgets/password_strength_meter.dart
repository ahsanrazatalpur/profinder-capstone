// lib/features/auth/widgets/password_strength_meter.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Live password-strength widget shown under the password field on Step 1
/// of Register. Renders an animated segmented bar + level label + a
/// realtime checklist — each requirement turns green the instant it's
/// satisfied, no need to wait for submission.
class PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  static const Map<PasswordStrengthLevel, Color> _levelColors = {
    PasswordStrengthLevel.veryWeak: AppColors.favoriteRed, // 🔴
    PasswordStrengthLevel.weak: AppColors.badgeTrending, // 🟠
    PasswordStrengthLevel.medium: AppColors.warningAmber, // 🟡
    PasswordStrengthLevel.strong: AppColors.onlineGreen, // 🟢
    PasswordStrengthLevel.excellent: AppColors.walletGradientStart, // 💚
  };

  static String _levelLabel(PasswordStrengthLevel level, AppLocalizations t) {
    switch (level) {
      case PasswordStrengthLevel.veryWeak:
        return t.pwStrengthVeryWeak;
      case PasswordStrengthLevel.weak:
        return t.pwStrengthWeak;
      case PasswordStrengthLevel.medium:
        return t.pwStrengthMedium;
      case PasswordStrengthLevel.strong:
        return t.pwStrengthStrong;
      case PasswordStrengthLevel.excellent:
        return t.pwStrengthExcellent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: password.isEmpty
          ? const SizedBox(width: double.infinity)
          : _buildMeter(context),
    );
  }

  Widget _buildMeter(BuildContext context) {
    final t = AppLocalizations.of(context);
    final result = AppValidators.passwordStrength(password, t);
    final color = _levelColors[result.level]!;
    final label = _levelLabel(result.level, t);

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: result.score),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: context.colors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTextStyles.label.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                child: Text(label),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.xs,
            children: result.requirements.map((req) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: req.met
                      ? context.colors.accentLight
                      : context.colors.background,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: req.met
                        ? context.colors.accent
                        : context.colors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      req.met ? Icons.check_circle : Icons.circle_outlined,
                      size: 14,
                      color: req.met
                          ? context.colors.accent
                          : context.colors.textDisabled,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      req.label,
                      style: AppTextStyles.caption.copyWith(
                        color: req.met
                            ? context.colors.accent
                            : context.colors.textSecondary,
                        fontWeight: req.met
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
