// lib/features/admin/widgets/report_detail_panel.dart
//
// Full inspection + moderation view for a single report. It is one widget
// used in two places: embedded in the right pane of the desktop split view,
// and inside AdminReportDetailScreen on phones.
//
// Data sources (no GET /reports/<id>/ exists, so the detail is composed):
//   • the report row handed in from the list
//   • GET /admin-panel/users/<reported user>/moderation-actions/
//     (full history; "active" and "this report" views are derived from it)
//   • other reports about the same user, derived from the list already loaded
//
// Privacy: the reporter section is admin-only and labelled as such. Text the
// affected user will see (moderation reason) is kept visually distinct from
// internal notes. Nothing here prefills a user-facing field from report text,
// so reporter details cannot leak into a moderation reason by accident.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/ts_models.dart';
import '../services/trust_safety_service.dart';
import 'moderation_history_list.dart';
import 'take_action_sheet.dart';
import 'ts_reason_dialog.dart';
import 'ts_ui.dart';

class ReportDetailPanel extends StatefulWidget {
  final TsReport report;
  final List<TsReport> allReports;
  final TrustSafetyService service;

  /// Called whenever this panel changes the report (status / internal note).
  final ValueChanged<TsReport> onReportChanged;

  /// Called when the admin taps another report about the same user.
  final ValueChanged<TsReport> onOpenReport;

  const ReportDetailPanel({
    super.key,
    required this.report,
    required this.allReports,
    required this.service,
    required this.onReportChanged,
    required this.onOpenReport,
  });

  @override
  State<ReportDetailPanel> createState() => _ReportDetailPanelState();
}

class _TimelineEvent {
  final DateTime? at;
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  const _TimelineEvent({
    required this.at,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
  });
}

class _ReportDetailPanelState extends State<ReportDetailPanel> {
  late TsReport _report;
  List<ModerationAction>? _history;
  bool _historyLoading = true;
  String? _historyError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _loadHistory(initial: true);
  }

  @override
  void didUpdateWidget(covariant ReportDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report.id != widget.report.id) {
      _report = widget.report;
      _history = null;
      _historyError = null;
      _historyLoading = true;
      _busy = false;
      _loadHistory(initial: true);
    } else if (!identical(oldWidget.report, widget.report)) {
      _report = widget.report;
    }
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadHistory({bool initial = false}) async {
    final requestedFor = _report.reportedUserId;
    if (!initial && mounted) {
      setState(() {
        _historyLoading = true;
        _historyError = null;
      });
    }
    try {
      final rows = await widget.service.fetchUserHistory(requestedFor);
      if (!mounted || requestedFor != _report.reportedUserId) return;
      setState(() {
        _history = rows;
        _historyLoading = false;
      });
    } catch (e) {
      if (!mounted || requestedFor != _report.reportedUserId) return;
      final l = AppLocalizations.of(context);
      setState(() {
        _historyLoading = false;
        _historyError = tsErrorMessage(l, e);
      });
    }
  }

  List<ModerationAction> get _activeActions =>
      (_history ?? const <ModerationAction>[]).where((a) => a.isActive).toList();

  // ── Flows ─────────────────────────────────────────────────────────────────

  Future<void> _takeAction() async {
    final result = await TakeActionSheet.show(
      context,
      service: widget.service,
      report: _report,
      activeActions: _activeActions,
    );
    if (result == null || !mounted) return;
    final l = AppLocalizations.of(context);
    tsSnack(context, l.tsActionApplied);
    await _loadHistory();
    if (result.markReportActionTaken && mounted) {
      await _markActionTaken();
    }
  }

  /// Second step after an action is applied. Deliberately separate from the
  /// POST so a failure here never hides the fact that the action succeeded.
  Future<void> _markActionTaken() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await widget.service
          .updateReport(_report.id, status: ReportStatus.actionTaken);
      if (!mounted) return;
      setState(() => _report = updated);
      widget.onReportChanged(updated);
    } catch (_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.tsActionAppliedReportFailed),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: l.tsRetry,
            textColor: Colors.white,
            onPressed: _markActionTaken,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resolve(String status) async {
    final l = AppLocalizations.of(context);
    final dismiss = status == ReportStatus.dismissed;
    final updated = await showTsReasonDialog<TsReport>(
      context,
      icon: dismiss ? Icons.close_rounded : Icons.visibility_outlined,
      color: dismiss ? TsColors.textMuted : TsColors.reviewed,
      title: dismiss ? l.tsDismissTitle : l.tsReviewTitle,
      message: dismiss ? l.tsDismissMessage : l.tsReviewMessage,
      fieldLabel: l.tsInternalNoteLabel,
      fieldHint: l.tsInternalNoteHint,
      audienceNote: l.tsInternalNoteNote,
      requireText: false,
      initialText: _report.adminNote,
      confirmLabel: dismiss ? l.tsDismissConfirm : l.tsReviewConfirm,
      notes: [l.tsResolveReporterNote],
      onSubmit: (text) =>
          widget.service.updateReport(_report.id, status: status, adminNote: text),
    );
    if (updated == null || !mounted) return;
    setState(() => _report = updated);
    widget.onReportChanged(updated);
    tsSnack(context, l.tsReportUpdated);
  }

  Future<void> _reverse(ModerationAction action) async {
    final l = AppLocalizations.of(context);
    final label = tsActionTypeLabel(l, action.actionType,
        fallback: action.actionTypeDisplay);
    final notes = <String>[l.tsReverseAuditNote];
    if (action.actionType != ActionType.warning) {
      notes.add(l.tsReverseNotifyNote);
    }
    if (action.legacyBanApplied) notes.add(l.tsReverseLegacyNote);

    final done = await showTsReasonDialog<ModerationAction>(
      context,
      icon: Icons.undo_rounded,
      color: TsColors.suspension,
      title: l.tsReverseTitle,
      message: l.tsReverseMessage(label),
      fieldLabel: l.tsReversalReasonLabel,
      fieldHint: l.tsReversalReasonHint,
      notes: notes,
      confirmLabel: l.tsReverseConfirm,
      onSubmit: (text) => widget.service.reverseAction(action.id, text),
    );
    if (done == null || !mounted) return;
    tsSnack(context, l.tsActionReversed);
    await _loadHistory();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TsColors.bg,
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 860;
          final left = <Widget>[
            _headerCard(context),
            _descriptionSection(context),
            _evidenceSection(context),
            _peopleSection(context),
          ];
          final right = <Widget>[
            _activeSection(context),
            _timelineSection(context),
            _historySection(context),
            ..._otherReportsSection(context),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _spaced(left)),
                          const SizedBox(width: 16),
                          Expanded(child: _spaced(right)),
                        ],
                      )
                    : _spaced([...left, ...right]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _spaced(List<Widget> children) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) out.add(const SizedBox(height: 14));
      out.add(children[i]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: out);
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  Widget _headerCard(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = _report;
    final canReview = r.status == ReportStatus.pending;
    final canDismiss =
        r.status == ReportStatus.pending || r.status == ReportStatus.reviewed;

    return TsCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.tsReportNumber(r.id.toString()),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: TsColors.textPrimary,
                  ),
                ),
              ),
              Text(
                l.tsSubmittedOn(tsFmtDateTime(r.createdAt)),
                style: const TextStyle(fontSize: 11.5, color: TsColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TsBadge(
                label: tsCategoryLabel(l, r.category, fallback: r.categoryDisplay),
                color: TsColors.textBody,
                icon: Icons.flag_outlined,
              ),
              TsSeverityBadge(severity: r.severity),
              TsStatusBadge(status: r.status, display: r.statusDisplay),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TsUserAvatar(name: r.reportedUserName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.reportedUserName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: TsColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${tsRoleLabel(l, r.reportedUserRole)} · ${r.reportedUserEmail}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: TsColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (!r.reportedUserActive)
                TsBadge(
                  label: l.tsAccountBlocked,
                  color: AppColors.error,
                  icon: Icons.block_rounded,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!r.targetIsAdmin)
                ElevatedButton.icon(
                  onPressed: (_busy || _historyLoading) ? null : _takeAction,
                  icon: const Icon(Icons.gavel_rounded, size: 17),
                  label: Text(l.tsTakeAction),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TsColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: TsColors.accent.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              if (canReview)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _resolve(ReportStatus.reviewed),
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: Text(l.tsMarkReviewed),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TsColors.reviewed,
                    side: BorderSide(color: TsColors.reviewed.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              if (canDismiss)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _resolve(ReportStatus.dismissed),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: Text(l.tsDismiss),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TsColors.textMuted,
                    side: const BorderSide(color: TsColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TsColors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _descriptionSection(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TsSection(
      icon: Icons.notes_rounded,
      title: l.tsSecDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            _report.description.isEmpty ? l.tsNoDescription : _report.description,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: _report.description.isEmpty
                  ? TsColors.textMuted
                  : TsColors.textPrimary,
            ),
          ),
          if (_report.adminNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
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
                      const Icon(Icons.lock_outline_rounded,
                          size: 12, color: Color(0xFF92400E)),
                      const SizedBox(width: 5),
                      Text(
                        l.tsInternalNoteLabel,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  SelectableText(
                    _report.adminNote,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: TsColors.textBody,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _evidenceSection(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = _report;
    return TsSection(
      icon: Icons.attach_file_rounded,
      title: l.tsSecEvidence,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _miniLabel(l.tsEvidenceLabel),
          const SizedBox(height: 6),
          if (r.hasEvidence)
            TsLinkTile(url: r.evidenceUrl!)
          else
            Text(
              l.tsNoEvidence,
              style: const TextStyle(fontSize: 12.5, color: TsColors.textMuted),
            ),
          const SizedBox(height: 14),
          _miniLabel(l.tsBookingLabel),
          const SizedBox(height: 6),
          if (r.hasBooking) _bookingCard(l, r) else _noneText(l.tsNoRelated),
          const SizedBox(height: 14),
          _miniLabel(l.tsMessageLabel),
          const SizedBox(height: 6),
          if (r.hasMessage) _messageCard(l, r) else _noneText(l.tsNoRelated),
        ],
      ),
    );
  }

  Widget _miniLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: TsColors.textFaint,
          letterSpacing: 0.3,
        ),
      );

  Widget _noneText(String text) => Text(
        text,
        style: const TextStyle(fontSize: 12.5, color: TsColors.textMuted),
      );

  Widget _bookingCard(AppLocalizations l, TsReport r) {
    final b = r.relatedBooking;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TsColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 16, color: TsColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.tsBookingNumber((r.relatedBookingId ?? 0).toString()),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TsColors.textPrimary,
                  ),
                ),
              ),
              if (b != null && b.status.isNotEmpty)
                TsBadge(
                  label: b.statusDisplay ?? b.status,
                  color: TsColors.textBody,
                ),
            ],
          ),
          if (b != null) ...[
            const SizedBox(height: 8),
            if (b.date != null)
              TsInfoRow(
                label: l.tsFieldWhen,
                value: b.time == null ? b.date! : '${b.date}  ${b.time}',
              ),
            if (b.customerName != null && b.professionalName != null)
              TsInfoRow(
                label: l.tsFieldParties,
                value: l.tsBookingWith(b.customerName!, b.professionalName!),
              ),
          ],
        ],
      ),
    );
  }

  Widget _messageCard(AppLocalizations l, TsReport r) {
    final m = r.relatedMessage;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TsColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 16, color: TsColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.tsMessageNumber((r.relatedMessageId ?? 0).toString()),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TsColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (m != null) ...[
            const SizedBox(height: 8),
            if (m.senderName != null)
              TsInfoRow(label: l.tsFieldSender, value: m.senderName!),
            if (m.createdAt != null)
              TsInfoRow(label: l.tsFieldWhen, value: tsFmtDateTime(m.createdAt)),
            const SizedBox(height: 6),
            if (m.isDeleted)
              TsHint(icon: Icons.visibility_off_outlined, text: l.tsMessageDeleted)
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TsColors.border),
                ),
                child: SelectableText(
                  m.text.isEmpty ? '—' : m.text,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: TsColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            if (m.attachmentCount > 0) ...[
              const SizedBox(height: 6),
              TsHint(
                icon: Icons.attach_file_rounded,
                text: l.tsMessageAttachments(m.attachmentCount.toString()),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _personTile(
    AppLocalizations l, {
    required String heading,
    required String name,
    required String email,
    String? sub,
    Color color = TsColors.accent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TsUserAvatar(name: name, color: color, size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _miniLabel(heading),
              const SizedBox(height: 2),
              Text(
                name.isEmpty ? '—' : name,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: TsColors.textPrimary,
                ),
              ),
              SelectableText(
                email,
                style: const TextStyle(fontSize: 12, color: TsColors.textMuted),
              ),
              if (sub != null) ...[
                const SizedBox(height: 4),
                TsHint(icon: Icons.lock_outline_rounded, text: sub),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _peopleSection(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = _report;
    return TsSection(
      icon: Icons.people_outline_rounded,
      title: l.tsSecPeople,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _personTile(
            l,
            heading: l.tsReportedUser,
            name: r.reportedUserName,
            email: r.reportedUserEmail,
          ),
          if (!r.reportedUserActive) ...[
            const SizedBox(height: 8),
            TsHint(icon: Icons.block_rounded, text: l.tsAccountBlockedNote),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: TsColors.border),
          ),
          _personTile(
            l,
            heading: l.tsReporterLabel,
            name: r.reporterName,
            email: r.reporterEmail,
            sub: l.tsReporterAdminOnly,
            color: TsColors.info,
          ),
        ],
      ),
    );
  }

  Widget _historyState(
    BuildContext context, {
    required Widget Function(List<ModerationAction> rows) builder,
  }) {
    final l = AppLocalizations.of(context);
    if (_historyLoading && _history == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: TsColors.accent),
          ),
        ),
      );
    }
    if (_historyError != null && _history == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TsInlineError(message: '${l.tsHistoryLoadError} $_historyError'),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(l.tsRetry),
          ),
        ],
      );
    }
    return builder(_history ?? const <ModerationAction>[]);
  }

  Widget _activeSection(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TsSection(
      icon: Icons.shield_outlined,
      iconColor: TsColors.restriction,
      title: l.tsSecActive,
      child: _historyState(
        context,
        builder: (rows) {
          final active = rows.where((a) => a.isActive).toList();
          if (active.isEmpty) {
            return Text(
              l.tsNoActive,
              style: const TextStyle(fontSize: 12.5, color: TsColors.textMuted),
            );
          }
          return Column(
            children: [
              for (var i = 0; i < active.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _activeRow(l, active[i]),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _activeRow(AppLocalizations l, ModerationAction a) {
    final color = tsActionColor(a.actionType);
    String when;
    if (a.expiresAt != null) {
      when = l.tsExpiresOn(tsFmtDateTime(a.expiresAt));
    } else if (a.actionType == ActionType.suspendPermanent) {
      when = l.tsNoExpiryPermanent;
    } else {
      when = l.tsNoExpiryOpen;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(tsActionIcon(a.actionType), size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tsActionTypeLabel(l, a.actionType, fallback: a.actionTypeDisplay),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TsColors.textPrimary,
                  ),
                ),
                Text(
                  when,
                  style: const TextStyle(fontSize: 11.5, color: TsColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_TimelineEvent> _events(AppLocalizations l) {
    final r = _report;
    final events = <_TimelineEvent>[
      _TimelineEvent(
        at: r.createdAt,
        icon: Icons.flag_outlined,
        color: TsColors.pending,
        title: l.tsTlSubmitted,
      ),
    ];
    if (r.reviewedAt != null) {
      events.add(
        _TimelineEvent(
          at: r.reviewedAt,
          icon: Icons.visibility_outlined,
          color: tsStatusColor(r.status),
          title: l.tsTlReviewed(
            tsStatusLabel(l, r.status, fallback: r.statusDisplay),
            r.reviewedByEmail ?? l.tsAdminUnknown,
          ),
          subtitle: r.adminNote.isEmpty ? null : l.tsTlInternalNote(r.adminNote),
        ),
      );
    }
    for (final a in (_history ?? const <ModerationAction>[])) {
      if (a.reportId != r.id) continue;
      final label = tsActionTypeLabel(l, a.actionType, fallback: a.actionTypeDisplay);
      events.add(
        _TimelineEvent(
          at: a.createdAt,
          icon: Icons.gavel_rounded,
          color: tsActionColor(a.actionType),
          title: l.tsTlActionApplied(
            label,
            a.performedByLabel.isEmpty ? l.tsAdminUnknown : a.performedByLabel,
          ),
        ),
      );
      if (a.isReversed && a.reversedAt != null) {
        events.add(
          _TimelineEvent(
            at: a.reversedAt,
            icon: Icons.undo_rounded,
            color: TsColors.textMuted,
            title: l.tsTlActionReversed(
              label,
              a.reversedByLabel.isEmpty ? l.tsAdminUnknown : a.reversedByLabel,
            ),
            subtitle: a.reversalReason.isEmpty
                ? null
                : l.tsTlInternalNote(a.reversalReason),
          ),
        );
      }
    }
    events.sort((a, b) {
      final x = a.at;
      final y = b.at;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    });
    return events;
  }

  Widget _timelineSection(BuildContext context) {
    final l = AppLocalizations.of(context);
    final events = _events(l);
    return TsSection(
      icon: Icons.history_rounded,
      title: l.tsSecTimeline,
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++)
            _timelineRow(events[i], isLast: i == events.length - 1),
        ],
      ),
    );
  }

  Widget _timelineRow(_TimelineEvent e, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: e.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(e.icon, size: 13, color: e.color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: TsColors.border),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14, left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: TsColors.textPrimary,
                    ),
                  ),
                  if (e.at != null)
                    Text(
                      tsFmtDateTime(e.at),
                      style: const TextStyle(fontSize: 11, color: TsColors.textMuted),
                    ),
                  if (e.subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      e.subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TsColors.textBody,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historySection(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TsSection(
      icon: Icons.gavel_rounded,
      title: l.tsSecHistory,
      trailing: IconButton(
        tooltip: l.tsRetry,
        visualDensity: VisualDensity.compact,
        onPressed: _historyLoading ? null : _loadHistory,
        icon: const Icon(Icons.refresh_rounded, size: 18, color: TsColors.textMuted),
      ),
      child: _historyState(
        context,
        builder: (rows) => ModerationHistoryList(
          actions: rows,
          highlightReportId: _report.id,
          onReverse: _reverse,
          busy: _busy,
        ),
      ),
    );
  }

  List<Widget> _otherReportsSection(BuildContext context) {
    final l = AppLocalizations.of(context);
    final others = widget.allReports
        .where((x) => x.reportedUserId == _report.reportedUserId && x.id != _report.id)
        .toList();
    if (others.isEmpty) return const [];
    final shown = others.take(5).toList();

    return [
      TsSection(
        icon: Icons.flag_outlined,
        title: l.tsSecOtherReports,
        trailing: TsBadge(label: others.length.toString(), color: TsColors.textBody),
        child: Column(
          children: [
            for (final o in shown)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => widget.onOpenReport(o),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l.tsReportNumber(o.id.toString())} · ${tsCategoryLabel(l, o.category, fallback: o.categoryDisplay)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: TsColors.textPrimary,
                              ),
                            ),
                            Text(
                              tsFmtDate(o.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: TsColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TsStatusBadge(status: o.status, display: o.statusDisplay),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: TsColors.textFaint),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}