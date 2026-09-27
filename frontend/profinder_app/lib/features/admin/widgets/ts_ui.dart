// lib/features/admin/widgets/ts_ui.dart
//
// Shared building blocks for the Trust & Safety admin UI: design tokens,
// badges, cards, empty/error states, localized label mapping for the
// backend's code vocabularies, and small helpers.
//
// Visual language deliberately mirrors the existing admin screens (light
// surfaces, AppColors.adminColor accent, the same neutral greys) so the new
// screens sit naturally next to Users / Bookings / Complaints.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/ts_models.dart';
import '../services/trust_safety_service.dart';

// ── Tokens ───────────────────────────────────────────────────────────────────

class TsColors {
  TsColors._();
  static const Color bg = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textBody = Color(0xFF374151);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textFaint = Color(0xFF9CA3AF);
  static const Color accent = AppColors.adminColor;

  // Report status (same palette the original Reported Users screen used)
  static const Color pending = Color(0xFFF59E0B);
  static const Color reviewed = Color(0xFF3B82F6);
  static const Color actionTaken = Color(0xFFEF4444);
  static const Color dismissed = Color(0xFF9CA3AF);

  // Severity
  static const Color sevLow = Color(0xFF64748B);
  static const Color sevMedium = Color(0xFFD97706);
  static const Color sevHigh = Color(0xFFEA580C);
  static const Color sevCritical = Color(0xFFDC2626);

  // Moderation
  static const Color warning = Color(0xFFD97706);
  static const Color restriction = Color(0xFF7C3AED);
  static const Color suspension = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color info = Color(0xFF2563EB);
}

Color tsStatusColor(String status) {
  switch (status) {
    case ReportStatus.reviewed:
      return TsColors.reviewed;
    case ReportStatus.actionTaken:
      return TsColors.actionTaken;
    case ReportStatus.dismissed:
      return TsColors.dismissed;
    default:
      return TsColors.pending;
  }
}

Color tsSeverityColor(String? severity) {
  switch (severity) {
    case Severity.critical:
      return TsColors.sevCritical;
    case Severity.high:
      return TsColors.sevHigh;
    case Severity.medium:
      return TsColors.sevMedium;
    default:
      return TsColors.sevLow;
  }
}

Color tsActionColor(String type) {
  switch (type) {
    case ActionType.warning:
      return TsColors.warning;
    case ActionType.restrictMessaging:
    case ActionType.restrictBooking:
      return TsColors.restriction;
    default:
      return TsColors.suspension;
  }
}

IconData tsActionIcon(String type) {
  switch (type) {
    case ActionType.warning:
      return Icons.warning_amber_rounded;
    case ActionType.restrictMessaging:
      return Icons.speaker_notes_off_rounded;
    case ActionType.restrictBooking:
      return Icons.event_busy_rounded;
    case ActionType.suspendTemporary:
      return Icons.pause_circle_outline_rounded;
    default:
      return Icons.gpp_bad_rounded;
  }
}

Color tsStateColor(String state) {
  switch (state) {
    case ActionState.active:
      return TsColors.success;
    case ActionState.scheduled:
      return TsColors.info;
    case ActionState.reversed:
      return TsColors.textMuted;
    default:
      return TsColors.textFaint; // expired
  }
}

Color tsAppealColor(String status) {
  switch (status) {
    case AppealStatus.approved:
      return TsColors.success;
    case AppealStatus.rejected:
      return TsColors.actionTaken;
    default:
      return TsColors.pending;
  }
}

// ── Localized labels for backend codes ───────────────────────────────────────
// Unknown / future codes fall back to the backend's own display string, then
// to the raw code, so a new backend value never renders blank.

String _fb(String? display, String code) =>
    (display != null && display.isNotEmpty) ? display : code;

String tsCategoryLabel(AppLocalizations l, String code, {String? fallback}) {
  switch (code) {
    case 'spam':
      return l.tsCatSpam;
    case 'harassment':
      return l.tsCatHarassment;
    case 'fraud':
      return l.tsCatFraud;
    case 'fake_profile':
      return l.tsCatFakeProfile;
    case 'inappropriate_content':
      return l.tsCatInappropriate;
    case 'payment_fraud':
      return l.tsCatPaymentFraud;
    case 'off_platform_payment':
      return l.tsCatOffPlatform;
    case 'threats_safety':
      return l.tsCatThreats;
    case 'discrimination':
      return l.tsCatDiscrimination;
    case 'service_misconduct':
      return l.tsCatMisconduct;
    case 'other':
      return l.tsCatOther;
    default:
      return _fb(fallback, code);
  }
}

String tsStatusLabel(AppLocalizations l, String code, {String? fallback}) {
  switch (code) {
    case ReportStatus.pending:
      return l.tsStatusPending;
    case ReportStatus.reviewed:
      return l.tsStatusReviewed;
    case ReportStatus.actionTaken:
      return l.tsStatusActionTaken;
    case ReportStatus.dismissed:
      return l.tsStatusDismissed;
    default:
      return _fb(fallback, code);
  }
}

String tsSeverityLabel(AppLocalizations l, String? code) {
  switch (code) {
    case Severity.low:
      return l.tsSevLow;
    case Severity.medium:
      return l.tsSevMedium;
    case Severity.high:
      return l.tsSevHigh;
    case Severity.critical:
      return l.tsSevCritical;
    default:
      return code ?? '';
  }
}

String tsActionTypeLabel(AppLocalizations l, String code, {String? fallback}) {
  switch (code) {
    case ActionType.warning:
      return l.tsActWarning;
    case ActionType.restrictMessaging:
      return l.tsActRestrictMessaging;
    case ActionType.restrictBooking:
      return l.tsActRestrictBooking;
    case ActionType.suspendTemporary:
      return l.tsActSuspendTemporary;
    case ActionType.suspendPermanent:
      return l.tsActSuspendPermanent;
    default:
      return _fb(fallback, code);
  }
}

String tsActionTypeDescription(AppLocalizations l, String code) {
  switch (code) {
    case ActionType.warning:
      return l.tsActWarningDesc;
    case ActionType.restrictMessaging:
      return l.tsActRestrictMessagingDesc;
    case ActionType.restrictBooking:
      return l.tsActRestrictBookingDesc;
    case ActionType.suspendTemporary:
      return l.tsActSuspendTemporaryDesc;
    case ActionType.suspendPermanent:
      return l.tsActSuspendPermanentDesc;
    default:
      return '';
  }
}

String tsStateLabel(AppLocalizations l, String state) {
  switch (state) {
    case ActionState.active:
      return l.tsStateActive;
    case ActionState.scheduled:
      return l.tsStateScheduled;
    case ActionState.expired:
      return l.tsStateExpired;
    case ActionState.reversed:
      return l.tsStateReversed;
    default:
      return state;
  }
}

String tsAppealStatusLabel(AppLocalizations l, String status, {String? fallback}) {
  switch (status) {
    case AppealStatus.pending:
      return l.tsAppealPending;
    case AppealStatus.approved:
      return l.tsAppealApproved;
    case AppealStatus.rejected:
      return l.tsAppealRejected;
    default:
      return _fb(fallback, status);
  }
}

String tsRoleLabel(AppLocalizations l, String role) {
  switch (role) {
    case 'customer':
      return l.tsRoleCustomer;
    case 'professional':
      return l.tsRoleProfessional;
    case 'admin':
      return l.tsRoleAdmin;
    default:
      return role;
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String tsFmtDateTime(DateTime? d) => d == null ? '' : AppHelpers.formatDateTime(d);
String tsFmtDate(DateTime? d) => d == null ? '' : AppHelpers.formatDate(d);

/// Maps a failed request to the message shown to the admin. The backend's own
/// message is used for 400 / 404 / 409 because it is specific and actionable
/// (e.g. "This user already has an active ..."); everything else is localized.
String tsErrorMessage(AppLocalizations l, Object error) {
  if (error is TsApiException) {
    if (error.isForbidden) return l.tsErrForbidden;
    if (error.isNetwork) return l.tsErrNetwork;
    final code = error.statusCode;
    final msg = error.message;
    if (msg != null && msg.isNotEmpty && (code == 400 || code == 404 || code == 409)) {
      return msg;
    }
  }
  return l.tsErrGeneric;
}

void tsSnack(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: error ? AppColors.error : TsColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Opens an http(s) link externally. Anything else is refused.
Future<void> tsOpenUrl(BuildContext context, String url) async {
  final l = AppLocalizations.of(context);
  final uri = Uri.tryParse(url.trim());
  final ok = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  var launched = false;
  if (ok) {
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
  }
  if (!launched && context.mounted) {
    tsSnack(context, l.tsLinkOpenFailed, error: true);
  }
}

Future<void> tsCopy(BuildContext context, String text) async {
  final l = AppLocalizations.of(context);
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) tsSnack(context, l.tsCopied);
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class TsBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  const TsBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: filled ? color : color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class TsSeverityBadge extends StatelessWidget {
  final String? severity;
  const TsSeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    if (severity == null || severity!.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final color = tsSeverityColor(severity);
    return TsBadge(
      label: tsSeverityLabel(l, severity),
      color: color,
      icon: Icons.priority_high_rounded,
      filled: severity == Severity.critical,
    );
  }
}

class TsStatusBadge extends StatelessWidget {
  final String status;
  final String? display;
  const TsStatusBadge({super.key, required this.status, this.display});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TsBadge(
      label: tsStatusLabel(l, status, fallback: display),
      color: tsStatusColor(status),
    );
  }
}

class TsUserAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  const TsUserAvatar({
    super.key,
    required this.name,
    this.color = TsColors.accent,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        AppHelpers.getInitials(name.isEmpty ? '?' : name),
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

/// White rounded surface used for list cards and detail sections.
class TsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool selected;
  final Color? accentBorder;

  const TsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.selected = false,
    this.accentBorder,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? TsColors.accent
        : (accentBorder ?? TsColors.border);
    return Container(
      decoration: BoxDecoration(
        color: TsColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A titled section inside a detail view.
class TsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final Color iconColor;

  const TsSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.iconColor = TsColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return TsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TsColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// "Label: value" row that wraps gracefully on narrow widths.
class TsInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool selectable;

  const TsInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(
      fontSize: 12.5,
      color: TsColors.textBody,
      height: 1.4,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: TsColors.textMuted),
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText(value, style: valueStyle)
                : Text(value, style: valueStyle),
          ),
        ],
      ),
    );
  }
}

/// A short, clearly-labelled note about audience (internal / user-visible).
class TsHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const TsHint({
    super.key,
    required this.icon,
    required this.text,
    this.color = TsColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11.5, color: color, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class TsInlineError extends StatelessWidget {
  final String message;
  const TsInlineError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF991B1B),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Color color;

  const TsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.color = TsColors.textFaint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: TsColors.textBody,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: TsColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const TsErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 38, color: AppColors.error),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TsColors.textBody,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l.tsRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: TsColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TsLoading extends StatelessWidget {
  const TsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: TsColors.accent, strokeWidth: 2.5),
    );
  }
}

/// Evidence / reference link with open + copy actions.
class TsLinkTile extends StatelessWidget {
  final String url;
  const TsLinkTile({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: TsColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TsColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, size: 16, color: TsColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              url,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: TsColors.info),
            ),
          ),
          IconButton(
            tooltip: l.tsCopy,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_rounded, size: 17, color: TsColors.textMuted),
            onPressed: () => tsCopy(context, url),
          ),
          IconButton(
            tooltip: l.tsOpenLink,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.open_in_new_rounded, size: 17, color: TsColors.textMuted),
            onPressed: () => tsOpenUrl(context, url),
          ),
        ],
      ),
    );
  }
}

/// Gradient screen header shared by the Reports and Appeals screens; matches
/// the header the original Reported Users screen used.
class TsScreenHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color dotColor;
  final VoidCallback? onRefresh;
  final String? refreshTooltip;

  const TsScreenHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.dotColor,
    this.onRefresh,
    this.refreshTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.adminColor, Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              tooltip: refreshTooltip,
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }
}