// lib/shared/widgets/app_error_state.dart

import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_context_ext.dart';

/// Standardized error state presentation widget for ProFinder.
///
/// Displays a clear error icon, message, and an optional retry button.
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final IconData? icon;

  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSizes.body,
                color: context.colors.textPrimary,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel ?? 'Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
