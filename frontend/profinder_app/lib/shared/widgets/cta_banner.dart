// Reusable call-to-action and promotional banner card.
//
// Adapts dynamically between horizontal (wide) and stacked (narrow) layouts
// based on available constraints, supporting custom badges, emojis, and gradients.

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_context_ext.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/generated/app_localizations.dart';

class CtaBanner extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  final String? title;
  final String? subtitle;
  final String? ctaLabel;

  /// Optional emoji icon taking precedence over [icon].
  final String? emoji;

  /// Fallback icon displayed when [emoji] is null.
  final IconData icon;

  /// Starting color of the badge and button gradient.
  final Color accentStart;

  /// Ending color of the badge and button gradient.
  final Color accentEnd;

  const CtaBanner({
    super.key,
    required this.isDark,
    required this.onTap,
    this.title,
    this.subtitle,
    this.ctaLabel,
    this.emoji,
    this.icon = Icons.workspace_premium_rounded,
    this.accentStart = AppColors.ctaGradientStart,
    this.accentEnd = AppColors.ctaGradientEnd,
  });

  static const double _narrowBreakpoint = 320;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding - 10,
        vertical: AppSizes.xs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          splashColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : accentStart.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [AppColors.surface, AppColors.background]
                    : const [AppColors.slate50, AppColors.slate100],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : accentStart.withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : accentStart.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < _narrowBreakpoint;
                return narrow ? _narrowLayout(context) : _wideLayout(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  // Wide layout: places badge, text description, and CTA button horizontally
  Widget _wideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _badge(),
        const SizedBox(width: 14),
        Expanded(child: _texts(context)),
        const SizedBox(width: 10),
        _ctaButton(context),
      ],
    );
  }

  // Narrow layout: stacks the CTA button below the title to preserve readability
  Widget _narrowLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _badge(),
            const SizedBox(width: 12),
            Expanded(child: _texts(context)),
          ],
        ),
        const SizedBox(height: 12),
        _ctaButton(context, fullWidth: true),
      ],
    );
  }

  // Leading badge graphic — displays emoji if provided, otherwise defaults to icon.
  Widget _badge() {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentStart, accentEnd],
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: accentStart.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: emoji != null
          ? Text(
              emoji!,
              style: const TextStyle(fontSize: AppFontSizes.h3, height: 1),
            )
          : Icon(icon, color: Colors.white, size: 21),
    );
  }

  Widget _texts(BuildContext context) {
    final t = AppLocalizations.of(context);
    final title = this.title ?? t.ctaGrowYourBusiness;
    final subtitle = this.subtitle ?? t.ctaJoinProfessionalsSubtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppFontSizes.input,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppFontSizes.secondary,
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _ctaButton(BuildContext context, {bool fullWidth = false}) {
    final ctaLabel = this.ctaLabel ?? AppLocalizations.of(context).ctaJoinNow;
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentStart, accentEnd],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: accentStart.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            ctaLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppFontSizes.secondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }
}
