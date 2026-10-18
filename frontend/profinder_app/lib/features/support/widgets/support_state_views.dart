// lib/features/support/widgets/support_state_views.dart
//
// Loading / empty / error panels shared by the Help & Support screens. Theme
// tokens only, Material icons only. Each panel scrolls instead of overflowing,
// so it survives small screens and large text scales.

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

class SupportLoadingState extends StatelessWidget {
  const SupportLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: AppLocalizations.of(context).loading,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String? title;
  final String message;
  final Widget? action;

  const _StatePanel({
    required this.icon,
    required this.iconColor,
    required this.message,
    this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.iconXl, color: iconColor),
            const SizedBox(height: AppSizes.md),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: styles.h3.copyWith(letterSpacing: 0),
              ),
              const SizedBox(height: AppSizes.sm),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: styles.bodySmall.copyWith(letterSpacing: 0),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSizes.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class SupportEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const SupportEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: icon,
      iconColor: context.colors.textSecondary,
      title: title,
      message: message,
    );
  }
}

class SupportErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  /// Defaults to the generic "couldn't load" text.
  final String? message;

  const SupportErrorState({super.key, required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _StatePanel(
      icon: Icons.cloud_off_rounded,
      iconColor: context.colors.danger,
      message: message ?? t.supportErrorMessage,
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(t.retryCta),
      ),
    );
  }
}
