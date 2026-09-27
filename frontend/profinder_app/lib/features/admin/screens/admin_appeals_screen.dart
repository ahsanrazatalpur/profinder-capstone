// lib/features/admin/screens/admin_appeals_screen.dart
//
// Admin → Appeals (Trust & Safety, Part 6 backend).
//
// Queue of user appeals against moderation actions. An admin can approve
// (reverses the action) or reject (action stays) with a decision note.
// The decision note is INTERNAL: the backend never sends it to the user, and
// the UI labels it that way everywhere.
//
// Endpoints: GET /admin-panel/appeals/, POST .../<id>/approve/, .../<id>/reject/
//
// Note: users are only told they can appeal once the backend flag
// APPEALS_AVAILABLE is enabled and a user-facing appeal UI exists, so this
// queue is expected to be empty until then.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/ts_models.dart';
import '../services/trust_safety_service.dart';
import '../widgets/ts_reason_dialog.dart';
import '../widgets/ts_ui.dart';

class AdminAppealsScreen extends StatefulWidget {
  const AdminAppealsScreen({super.key});

  @override
  State<AdminAppealsScreen> createState() => _AdminAppealsScreenState();
}

class _AdminAppealsScreenState extends State<AdminAppealsScreen> {
  static const double _splitBreakpoint = 1000;

  final TrustSafetyService _service = TrustSafetyService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<TsAppeal> _all = [];
  bool _loading = true;
  String? _error;
  int? _selectedId;
  String? _status = AppealStatus.pending; // queue first
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load(showSpinner: false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final rows = await _service.fetchAppeals();
      if (!mounted) return;
      setState(() {
        _all = rows;
        _loading = false;
        _error = null;
        if (_selectedId != null && !rows.any((a) => a.id == _selectedId)) {
          _selectedId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      setState(() {
        _loading = false;
        _error = tsErrorMessage(l, e);
      });
    }
  }

  void _replace(TsAppeal updated) {
    if (!mounted) return;
    setState(() {
      _all = _all.map((a) => a.id == updated.id ? updated : a).toList();
    });
  }

  List<TsAppeal> _apply({required bool ignoreStatus}) {
    final q = _search.trim().toLowerCase();
    final out = _all.where((a) {
      if (!ignoreStatus && _status != null && a.status != _status) return false;
      if (q.isNotEmpty) {
        final hay =
            '${a.id} ${a.userName} ${a.userEmail} ${a.reason}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final oldestFirst = _status == AppealStatus.pending;
    out.sort((a, b) {
      final c = (a.createdAt ?? epoch).compareTo(b.createdAt ?? epoch);
      return oldestFirst ? c : -c;
    });
    return out;
  }

  void _select(TsAppeal a, bool split) {
    if (split) {
      setState(() => _selectedId = a.id);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AppealDetailScreen(
          appeal: a,
          service: _service,
          onChanged: _replace,
          onStale: () => _load(showSpinner: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: TsColors.bg,
      body: LayoutBuilder(
        builder: (context, c) {
          final split = c.maxWidth >= _splitBreakpoint;
          final list = _buildListColumn(l, split, c.maxWidth);
          if (!split) return list;
          return Row(
            children: [
              SizedBox(width: 460, child: list),
              const VerticalDivider(width: 1, color: TsColors.border),
              Expanded(child: _buildDetailPane(l)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailPane(AppLocalizations l) {
    TsAppeal? selected;
    for (final a in _all) {
      if (a.id == _selectedId) selected = a;
    }
    if (selected == null) {
      return TsEmptyState(
        icon: Icons.touch_app_outlined,
        title: l.tsSelectAppeal,
        message: l.tsSelectAppealHint,
      );
    }
    return _AppealDetailPanel(
      key: ValueKey<int>(selected.id),
      appeal: selected,
      service: _service,
      onChanged: _replace,
      onStale: () => _load(showSpinner: false),
    );
  }

  Widget _buildListColumn(AppLocalizations l, bool split, double width) {
    final pending = _all.where((a) => a.isPending).length;
    final hPad = split ? 14.0 : (width >= 700 ? 24.0 : 12.0);
    final base = _apply(ignoreStatus: true);
    int countFor(String? s) =>
        s == null ? base.length : base.where((a) => a.status == s).length;

    return Column(
      children: [
        TsScreenHeader(
          icon: Icons.gavel_rounded,
          title: l.tsAppealsTitle,
          subtitle: l.tsPendingAppeals(pending.toString()),
          dotColor: pending > 0 ? Colors.amber : Colors.greenAccent,
          onRefresh: _loading ? null : () => _load(),
          refreshTooltip: l.tsRefresh,
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(fontSize: 13, color: TsColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l.tsSearchAppealsHint,
                    hintStyle:
                        const TextStyle(fontSize: 13, color: TsColors.textFaint),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: TsColors.textFaint),
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: TsColors.textFaint),
                            onPressed: () => setState(() {
                              _search = '';
                              _searchCtrl.clear();
                            }),
                          ),
                    filled: true,
                    fillColor: TsColors.bg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  children: [
                    _chip(l.tsAll, null, countFor(null), TsColors.accent),
                    for (final s in AppealStatus.all)
                      _chip(tsAppealStatusLabel(l, s), s, countFor(s),
                          tsAppealColor(s)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody(l, split, hPad)),
      ],
    );
  }

  Widget _chip(String label, String? value, int count, Color color) {
    final selected = _status == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _status = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? color : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l, bool split, double hPad) {
    if (_loading) return const TsLoading();
    if (_error != null) {
      return TsErrorState(message: _error!, onRetry: () => _load());
    }
    final rows = _apply(ignoreStatus: false);
    if (rows.isEmpty) {
      return RefreshIndicator(
        color: TsColors.accent,
        onRefresh: () => _load(showSpinner: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            TsEmptyState(
              icon: Icons.task_alt_rounded,
              color: TsColors.success,
              title: l.tsNoAppeals,
              message: l.tsNoAppealsHint,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: TsColors.accent,
      onRefresh: () => _load(showSpinner: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 24),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final a = rows[i];
          return _AppealCard(
            appeal: a,
            selected: split && a.id == _selectedId,
            onTap: () => _select(a, split),
          );
        },
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _AppealCard extends StatelessWidget {
  final TsAppeal appeal;
  final bool selected;
  final VoidCallback onTap;

  const _AppealCard({
    required this.appeal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = appeal;
    final act = a.action;
    return TsCard(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TsUserAvatar(name: a.userName, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: TsColors.textPrimary,
                      ),
                    ),
                    Text(
                      a.userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: TsColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tsFmtDate(a.createdAt),
                style: const TextStyle(fontSize: 11, color: TsColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TsBadge(
                label: tsAppealStatusLabel(l, a.status, fallback: a.statusDisplay),
                color: tsAppealColor(a.status),
              ),
              if (act != null) ...[
                TsBadge(
                  label: tsActionTypeLabel(l, act.actionType,
                      fallback: act.actionTypeDisplay),
                  color: tsActionColor(act.actionType),
                  icon: tsActionIcon(act.actionType),
                ),
                TsBadge(
                  label: tsStateLabel(l, act.state),
                  color: tsStateColor(act.state),
                ),
              ],
            ],
          ),
          if (a.reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              a.reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: TsColors.textBody,
                height: 1.4,
              ),
            ),
          ],
          if (a.hasEvidence) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_file_rounded, size: 13, color: TsColors.info),
                const SizedBox(width: 4),
                Text(
                  l.tsIndEvidence,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: TsColors.info,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Detail (phone route) ─────────────────────────────────────────────────────

class _AppealDetailScreen extends StatelessWidget {
  final TsAppeal appeal;
  final TrustSafetyService service;
  final ValueChanged<TsAppeal> onChanged;
  final VoidCallback onStale;

  const _AppealDetailScreen({
    required this.appeal,
    required this.service,
    required this.onChanged,
    required this.onStale,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: TsColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: TsColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l.tsAppealNumber(appeal.id.toString()),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: TsColors.border),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _AppealDetailPanel(
          appeal: appeal,
          service: service,
          onChanged: onChanged,
          onStale: onStale,
        ),
      ),
    );
  }
}

// ── Detail panel ─────────────────────────────────────────────────────────────

class _AppealDetailPanel extends StatefulWidget {
  final TsAppeal appeal;
  final TrustSafetyService service;
  final ValueChanged<TsAppeal> onChanged;

  /// The appeal changed or vanished on the server (409 / 404): reload the queue.
  final VoidCallback onStale;

  const _AppealDetailPanel({
    super.key,
    required this.appeal,
    required this.service,
    required this.onChanged,
    required this.onStale,
  });

  @override
  State<_AppealDetailPanel> createState() => _AppealDetailPanelState();
}

class _AppealDetailPanelState extends State<_AppealDetailPanel> {
  late TsAppeal _appeal;

  @override
  void initState() {
    super.initState();
    _appeal = widget.appeal;
  }

  @override
  void didUpdateWidget(covariant _AppealDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appeal.id != widget.appeal.id) {
      _appeal = widget.appeal;
    } else if (!identical(oldWidget.appeal, widget.appeal)) {
      _appeal = widget.appeal;
    }
  }

  Future<TsAppeal> _guarded(Future<TsAppeal> Function() call) async {
    try {
      return await call();
    } on TsApiException catch (e) {
      if (e.isConflict || e.isNotFound) widget.onStale();
      rethrow;
    }
  }

  Future<void> _approve() async {
    final l = AppLocalizations.of(context);
    final act = _appeal.action;
    final inEffect = act == null || act.isReversible;
    final updated = await showTsReasonDialog<TsAppeal>(
      context,
      icon: Icons.check_circle_outline_rounded,
      color: TsColors.success,
      title: l.tsApproveTitle,
      message: l.tsApproveMessage,
      notes: [inEffect ? l.tsAppealApproveNote : l.tsAppealApproveInactive],
      fieldLabel: l.tsDecisionNoteLabel,
      fieldHint: l.tsDecisionNoteHint,
      audienceNote: l.tsDecisionNoteNote,
      requireText: false,
      confirmLabel: l.tsApproveConfirm,
      onSubmit: (text) => _guarded(
        () => widget.service.approveAppeal(_appeal.id, decisionNote: text),
      ),
    );
    _afterDecision(updated, l.tsAppealApprovedSnack);
  }

  Future<void> _reject() async {
    final l = AppLocalizations.of(context);
    final updated = await showTsReasonDialog<TsAppeal>(
      context,
      icon: Icons.cancel_outlined,
      color: TsColors.actionTaken,
      title: l.tsRejectTitle,
      message: l.tsRejectMessage,
      notes: [l.tsAppealRejectNote],
      fieldLabel: l.tsDecisionNoteLabel,
      fieldHint: l.tsDecisionNoteHint,
      audienceNote: l.tsDecisionNoteNote,
      requireText: true,
      confirmLabel: l.tsRejectConfirm,
      onSubmit: (text) => _guarded(
        () => widget.service.rejectAppeal(_appeal.id, decisionNote: text),
      ),
    );
    _afterDecision(updated, l.tsAppealRejectedSnack);
  }

  void _afterDecision(TsAppeal? updated, String message) {
    if (updated == null || !mounted) return;
    setState(() => _appeal = updated);
    widget.onChanged(updated);
    tsSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = _appeal;
    final act = a.action;

    final children = <Widget>[
      // Header + decision buttons
      TsCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.tsAppealNumber(a.id.toString()),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: TsColors.textPrimary,
                    ),
                  ),
                ),
                TsBadge(
                  label: tsAppealStatusLabel(l, a.status, fallback: a.statusDisplay),
                  color: tsAppealColor(a.status),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.tsSubmittedOn(tsFmtDateTime(a.createdAt)),
              style: const TextStyle(fontSize: 11.5, color: TsColors.textMuted),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                TsUserAvatar(name: a.userName, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.userName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: TsColors.textPrimary,
                        ),
                      ),
                      SelectableText(
                        a.userEmail,
                        style: const TextStyle(fontSize: 12, color: TsColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (a.isPending) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _approve,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(l.tsAppealApprove),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TsColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _reject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(l.tsAppealReject),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),

      // The appeal itself
      TsSection(
        icon: Icons.notes_rounded,
        title: l.tsSecAppealReason,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              a.reason.isEmpty ? '—' : a.reason,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: TsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.tsEvidenceLabel,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: TsColors.textFaint,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            if (a.hasEvidence)
              TsLinkTile(url: a.evidenceUrl!)
            else
              Text(
                l.tsNoEvidence,
                style: const TextStyle(fontSize: 12.5, color: TsColors.textMuted),
              ),
          ],
        ),
      ),

      // The action being appealed
      TsSection(
        icon: Icons.gavel_rounded,
        title: l.tsSecAppealedAction,
        child: act == null
            ? Text(
                '#${a.moderationActionId}',
                style: const TextStyle(fontSize: 12.5, color: TsColors.textMuted),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      TsBadge(
                        label: tsActionTypeLabel(l, act.actionType,
                            fallback: act.actionTypeDisplay),
                        color: tsActionColor(act.actionType),
                        icon: tsActionIcon(act.actionType),
                      ),
                      TsBadge(
                        label: tsStateLabel(l, act.state),
                        color: tsStateColor(act.state),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TsInfoRow(
                    label: l.tsFieldPerformedBy,
                    value: act.performedByLabel.isEmpty
                        ? l.tsAdminUnknown
                        : act.performedByLabel,
                  ),
                  TsInfoRow(
                    label: l.tsFieldCreated,
                    value: tsFmtDateTime(act.createdAt),
                  ),
                  if (act.expiresAt != null)
                    TsInfoRow(
                      label: l.tsFieldExpires,
                      value: tsFmtDateTime(act.expiresAt),
                    ),
                  if (a.reportId != null)
                    TsInfoRow(
                      label: l.tsFieldReport,
                      value: l.tsReportNumber(a.reportId.toString()),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    l.tsReasonShownToUser,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: TsColors.textFaint,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    act.reason.isEmpty ? '—' : act.reason,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: TsColors.textBody,
                      height: 1.4,
                    ),
                  ),
                  if (act.adminNote.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _internalBox(l.tsInternalNoteLabel, act.adminNote),
                  ],
                ],
              ),
      ),

      // Decision (once resolved)
      if (!a.isPending)
        TsSection(
          icon: Icons.fact_check_outlined,
          iconColor: tsAppealColor(a.status),
          title: l.tsSecDecision,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TsInfoRow(
                label: l.tsFieldDecidedBy,
                value: a.reviewedByLabel.isEmpty ? l.tsAdminUnknown : a.reviewedByLabel,
              ),
              if (a.resolvedAt != null)
                TsInfoRow(
                  label: l.tsFieldDecidedOn,
                  value: tsFmtDateTime(a.resolvedAt),
                ),
              const SizedBox(height: 8),
              _internalBox(
                l.tsDecisionNoteLabel,
                a.decisionNote.isEmpty ? l.tsNoDecisionNote : a.decisionNote,
              ),
            ],
          ),
        ),
    ];

    return Container(
      color: TsColors.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

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
              const Icon(Icons.lock_outline_rounded,
                  size: 12, color: Color(0xFF92400E)),
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
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: TsColors.textBody,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}