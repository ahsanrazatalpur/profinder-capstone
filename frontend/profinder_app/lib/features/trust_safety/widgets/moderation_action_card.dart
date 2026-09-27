// lib/features/trust_safety/widgets/moderation_action_card.dart
//
// Trust & Safety Part 8 — one card per currently-active moderation action
// against the CURRENT user. Layout follows the task spec exactly:
//   * temporary suspension → reason, start time, expiration time
//   * restriction (messaging/booking) → affected feature, reason
//   * permanent suspension → reason, appeal availability
//   * warning → informational only, never blocks anything

import 'package:flutter/material.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/user_ts_models.dart';
import 'ts_labels.dart';

class ModerationActionCard extends StatelessWidget {
  final MyModerationAction action;
  final Color accentColor;
  final VoidCallback? onAppealTap;

  const ModerationActionCard({
    super.key,
    required this.action,
    required this.accentColor,
    this.onAppealTap,
  });

  IconData get _icon {
    if (action.isPermanentSuspension) return Icons.block_rounded;
    if (action.isTemporarySuspension) return Icons.pause_circle_outline_rounded;
    if (action.isMessagingRestriction) return Icons.chat_bubble_outline_rounded;
    if (action.isBookingRestriction) return Icons.event_busy_rounded;
    return Icons.warning_amber_rounded; // warning
  }

  Color get _severityColor {
    if (action.isPermanentSuspension) return const Color(0xFFDC2626);
    if (action.isTemporarySuspension) return const Color(0xFFF59E0B);
    if (action.isRestriction) return const Color(0xFFF97316);
    return const Color(0xFFEAB308); // warning
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severity = _severityColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severity.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.12) : Colors.grey.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: severity.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                child: Icon(_icon, color: severity, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  moderationActionTypeLabel(t, action.actionType, fallback: action.actionTypeDisplay),
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Affected feature (restrictions only) ──
          if (action.isRestriction) ...[
            _infoRow(
              context,
              t.myTsAffectedFeatureLabel,
              action.isMessagingRestriction ? t.myTsFeatureMessaging : t.myTsFeatureBooking,
            ),
            const SizedBox(height: 8),
          ],

          // ── Reason (always shown — it's this user's own action) ──
          _infoRow(context, t.tsReasonLabel, action.reason.isEmpty ? '—' : action.reason, multiline: true),

          // ── Timing (temporary suspension) ──
          if (action.isTemporarySuspension) ...[
            const SizedBox(height: 8),
            _infoRow(
              context,
              t.myTsStartTimeLabel,
              action.startsAt != null ? AppHelpers.formatDateTime(action.startsAt!) : '—',
            ),
            const SizedBox(height: 8),
            _infoRow(
              context,
              t.myTsExpirationTimeLabel,
              action.expiresAt != null ? AppHelpers.formatDateTime(action.expiresAt!) : '—',
            ),
          ],

          // ── Warning note ──
          if (action.isWarning) ...[
            const SizedBox(height: 10),
            Text(
              t.myTsWarningInfoNote,
              style: TextStyle(fontSize: 12, color: context.colors.textSecondary, height: 1.4),
            ),
          ],

          // ── Appeal availability / action ──
          if (action.isSuspension || action.isRestriction) ...[
            const SizedBox(height: 14),
            if (action.hasPendingAppeal)
              _pendingAppealChip(context, t)
            else if (action.canAppeal)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAppealTap,
                  icon: const Icon(Icons.gavel_rounded, size: 16),
                  label: Text(t.myTsAppealButtonLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColor,
                    side: BorderSide(color: accentColor.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _pendingAppealChip(BuildContext context, AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_top_rounded, size: 15, color: Color(0xFF3B82F6)),
          const SizedBox(width: 6),
          Text(
            t.myTsAppealPendingNote,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, {bool multiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.textSecondary, letterSpacing: 0.3),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: multiline ? 4 : 1,
          overflow: multiline ? TextOverflow.ellipsis : TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: context.colors.textPrimary, height: 1.3),
        ),
      ],
    );
  }
}