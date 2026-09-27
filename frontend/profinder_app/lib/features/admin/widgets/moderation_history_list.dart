// lib/features/admin/widgets/moderation_history_list.dart
//
// Renders a user's moderation actions: type, reason, admin, created date,
// expiration and active / scheduled / expired / reversed state.
//
// Audience labelling matters here: `reason` is what the affected user is told,
// `adminNote` and the reversal reason are INTERNAL. Each is labelled so an
// admin never has to guess which text a user can see.

import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/ts_models.dart';
import 'ts_ui.dart';

class ModerationHistoryList extends StatelessWidget {
  final List<ModerationAction> actions;

  /// Actions linked to this report get a "This report" badge.
  final int? highlightReportId;

  /// When null the reverse button is hidden (read-only usage).
  final void Function(ModerationAction action)? onReverse;

  /// Disables reverse buttons while another request is running.
  final bool busy;

  const ModerationHistoryList({
    super.key,
    required this.actions,
    this.highlightReportId,
    this.onReverse,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (actions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l.tsHistoryEmpty,
          style: const TextStyle(fontSize: 12.5, color: TsColors.textMuted),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _ActionTile(
            action: actions[i],
            highlight: highlightReportId != null &&
                actions[i].reportId == highlightReportId,
            onReverse: onReverse,
            busy: busy,
          ),
        ],
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final ModerationAction action;
  final bool highlight;
  final void Function(ModerationAction action)? onReverse;
  final bool busy;

  const _ActionTile({
    required this.action,
    required this.highlight,
    required this.onReverse,
    required this.busy,
  });

  String _expiryLine(AppLocalizations l) {
    if (action.expiresAt != null) {
      return l.tsExpiresOn(tsFmtDateTime(action.expiresAt));
    }
    if (action.actionType == ActionType.suspendPermanent) {
      return l.tsNoExpiryPermanent;
    }
    if (action.actionType == ActionType.warning) return '';
    return l.tsNoExpiryOpen;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = tsActionColor(action.actionType);
    final admin = action.performedByLabel.isEmpty
        ? l.tsAdminUnknown
        : action.performedByLabel;
    final expiry = _expiryLine(l);
    final dimmed = action.state == ActionState.reversed ||
        action.state == ActionState.expired;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dimmed ? TsColors.bg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? TsColors.accent.withValues(alpha: 0.5) : TsColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tsActionIcon(action.actionType), size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tsActionTypeLabel(l, action.actionType,
                          fallback: action.actionTypeDisplay),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: TsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        TsBadge(
                          label: tsStateLabel(l, action.state),
                          color: tsStateColor(action.state),
                        ),
                        if (highlight)
                          TsBadge(label: l.tsThisReport, color: TsColors.accent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.tsHistPerformedBy(admin, tsFmtDateTime(action.createdAt)),
            style: const TextStyle(fontSize: 11.5, color: TsColors.textMuted),
          ),
          if (action.state == ActionState.scheduled && action.startsAt != null)
            Text(
              l.tsStartsOn(tsFmtDateTime(action.startsAt)),
              style: const TextStyle(fontSize: 11.5, color: TsColors.textMuted),
            ),
          if (expiry.isNotEmpty)
            Text(
              expiry,
              style: const TextStyle(fontSize: 11.5, color: TsColors.textMuted),
            ),
          const SizedBox(height: 10),
          _labelled(l.tsReasonShownToUser, action.reason, TsColors.textBody),
          if (action.adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            _internalBox(l.tsInternalNoteLabel, action.adminNote),
          ],
          if (action.isReversed) ...[
            const SizedBox(height: 8),
            _internalBox(
              l.tsHistReversedBy(
                action.reversedByLabel.isEmpty
                    ? l.tsAdminUnknown
                    : action.reversedByLabel,
                tsFmtDateTime(action.reversedAt),
              ),
              action.reversalReason,
            ),
          ],
          if (onReverse != null && action.isReversible) ...[
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: busy ? null : () => onReverse!(action),
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: Text(l.tsReverse),
                style: TextButton.styleFrom(foregroundColor: TsColors.suspension),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _labelled(String label, String text, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: TsColors.textFaint,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(
          text.isEmpty ? '—' : text,
          style: TextStyle(fontSize: 12.5, color: color, height: 1.4),
        ),
      ],
    );
  }

  /// Internal (admin-only) text sits in a tinted box so it reads as private.
  Widget _internalBox(String label, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF92400E)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          SelectableText(
            text.isEmpty ? '—' : text,
            style: const TextStyle(fontSize: 12.5, color: TsColors.textBody, height: 1.4),
          ),
        ],
      ),
    );
  }
}