// lib/shared/widgets/universal_dialog.dart
//
// Universal Modal Dialog System for ProFinder.
// Standardizes all large modal popups (Success, Confirmation, Danger/Logout/Delete,
// Warnings & Prompts) with identical geometry, padding, typography, animations,
// and semantic function-specific colors.

import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_context_ext.dart';
import '../../l10n/generated/app_localizations.dart';

enum UniversalDialogType { success, danger, warning, info }

class UniversalDialog {
  UniversalDialog._();

  static Color _colorForType(UniversalDialogType type, BuildContext context) {
    switch (type) {
      case UniversalDialogType.success:
        return AppColors.emerald;
      case UniversalDialogType.danger:
        return AppColors.error;
      case UniversalDialogType.warning:
        return AppColors.warningAmber;
      case UniversalDialogType.info:
        return context.colors.primary;
    }
  }

  static IconData _iconForType(UniversalDialogType type) {
    switch (type) {
      case UniversalDialogType.success:
        return Icons.check_circle_rounded;
      case UniversalDialogType.danger:
        return Icons.error_outline_rounded;
      case UniversalDialogType.warning:
        return Icons.warning_amber_rounded;
      case UniversalDialogType.info:
        return Icons.info_outline_rounded;
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  1. CONFIRMATION DIALOG (Logout, Delete, Cancel, Confirmation)
  // ══════════════════════════════════════════════════════════════════
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    UniversalDialogType type = UniversalDialogType.danger,
    IconData? icon,
    Color? customColor,
    Widget? customContent,
    bool barrierDismissible = true,
  }) {
    final t = AppLocalizations.of(context);
    final themeColor = customColor ?? _colorForType(type, context);
    final themeIcon = icon ?? _iconForType(type);

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) {
        return Dialog(
          backgroundColor: ctx.colors.surface,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusChip),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero Icon Container with soft ambient glow ──
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(themeIcon, color: themeColor, size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Title ───────────────────────────────────────
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFontSizes.title,
                      fontWeight: FontWeight.w800,
                      color: ctx.colors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Subtitle / Message ──────────────────────────
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFontSizes.body,
                      color: ctx.colors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  // ── Optional Custom Middle Content ──────────────
                  if (customContent != null) ...[
                    const SizedBox(height: 16),
                    customContent,
                  ],

                  const SizedBox(height: 22),

                  // ── Dual Action Buttons (Cancel & Confirm) ──────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            foregroundColor: ctx.colors.textSecondary,
                            side: BorderSide(color: ctx.colors.divider),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              cancelLabel ?? t.cancelCta,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              confirmLabel ?? t.okCta,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  2. SUCCESS DIALOG (Booking Confirmed, Payment Done, Form Sent)
  // ══════════════════════════════════════════════════════════════════
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
    IconData icon = Icons.check_circle_rounded,
    Color? iconColor,
    Widget? customContent,
    bool barrierDismissible = false,
  }) {
    final color = iconColor ?? AppColors.emerald;

    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) {
        return Dialog(
          backgroundColor: ctx.colors.surface,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusChip),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Celebration Icon Container ──────────────────
                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Icon(icon, color: color, size: 38)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Title ───────────────────────────────────────
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFontSizes.title2,
                      fontWeight: FontWeight.w800,
                      color: ctx.colors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Subtitle / Details ──────────────────────────
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFontSizes.secondary,
                      color: ctx.colors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  // ── Optional Middle Details ─────────────────────
                  if (customContent != null) ...[
                    const SizedBox(height: 16),
                    customContent,
                  ],

                  const SizedBox(height: 22),

                  // ── Primary CTA Button ──────────────────────────
                  ElevatedButton(
                    onPressed: onPrimary,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                      backgroundColor: AppColors.customerColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    child: Text(
                      primaryLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),

                  // ── Optional Secondary CTA (e.g. Back to Home) ──
                  if (secondaryLabel != null && onSecondary != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onSecondary,
                      child: Text(
                        secondaryLabel,
                        style: TextStyle(
                          color: ctx.colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  3. CONVENIENCE HELPERS (Logout, Delete, Login Prompt)
  // ══════════════════════════════════════════════════════════════════
  static Future<bool?> showLogout(
    BuildContext context, {
    String? title,
    String? message,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
  }) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showConfirmation(
      context: context,
      title: title ?? t.logoutDialogTitle,
      message: message ?? t.logoutDialogContent,
      confirmLabel: confirmLabel ?? t.logoutCta,
      cancelLabel: cancelLabel ?? t.cancelCta,
      type: UniversalDialogType.danger,
      icon: Icons.logout_rounded,
    );

    if (confirmed == true && onConfirm != null) {
      onConfirm();
    }
    return confirmed;
  }

  static Future<bool?> showDelete(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String? confirmLabel,
    String? cancelLabel,
  }) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showConfirmation(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmLabel ?? t.deleteCta,
      cancelLabel: cancelLabel ?? t.cancelCta,
      type: UniversalDialogType.danger,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true && onConfirm != null) {
      onConfirm();
    }
    return confirmed;
  }

  static Future<bool?> showLoginPrompt(
    BuildContext context, {
    String? featureName,
    String? title,
    String? message,
    VoidCallback? onLogin,
  }) async {
    final t = AppLocalizations.of(context);
    final feat = featureName != null ? ' ($featureName)' : '';
    final confirmed = await showConfirmation(
      context: context,
      title: title ?? 'Sign In Required',
      message:
          message ??
          'You are currently browsing as a guest. Please log in or create an account to access this feature$feat.',
      confirmLabel: t.login,
      cancelLabel: t.cancelCta,
      type: UniversalDialogType.info,
      icon: Icons.lock_outline_rounded,
      customColor: AppColors.customerColor,
    );

    if (confirmed == true) {
      if (onLogin != null) {
        onLogin();
      } else if (context.mounted) {
        Navigator.pushNamed(context, '/login');
      }
    }
    return confirmed;
  }
}
