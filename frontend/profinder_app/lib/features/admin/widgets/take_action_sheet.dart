// lib/features/admin/widgets/take_action_sheet.dart
//
// "Take moderation action" flow for one report / user.
//
//   pick action → (duration) → reason → internal note → Apply
//       → confirmation dialog (extra acknowledgement for permanent suspension)
//       → POST /admin-panel/moderation-actions/
//
// Rules enforced here (the backend remains the authority and re-validates):
//   • a reason is required before anything can be applied
//   • temporary suspension needs a future end; permanent suspension has none
//   • restrictions may optionally carry an end; warnings never do
//   • options the backend would reject with 409 (duplicate active action, or a
//     temporary suspension on a permanently suspended user) are disabled
//   • the form cannot be submitted twice, and cannot be dismissed while the
//     request is running
//
// Report, block and moderation stay separate: this flow only ever creates a
// ModerationAction. It never sends the legacy `ban_user` flag.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/ts_models.dart';
import '../services/trust_safety_service.dart';
import 'ts_ui.dart';

class TakeActionResult {
  final ModerationAction action;

  /// The admin asked for the report to be marked "Action taken" afterwards.
  final bool markReportActionTaken;

  const TakeActionResult({
    required this.action,
    required this.markReportActionTaken,
  });
}

class TakeActionSheet {
  TakeActionSheet._();

  /// Dialog on wide screens, bottom sheet on phones.
  static Future<TakeActionResult?> show(
    BuildContext context, {
    required TrustSafetyService service,
    required TsReport report,
    required List<ModerationAction> activeActions,
  }) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    if (wide) {
      return showDialog<TakeActionResult>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 620,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.9,
            ),
            child: _TakeActionForm(
              service: service,
              report: report,
              activeActions: activeActions,
              asDialog: true,
            ),
          ),
        ),
      );
    }
    return showModalBottomSheet<TakeActionResult>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SizedBox(
        width: MediaQuery.sizeOf(sheetContext).width,
        child: _TakeActionForm(
          service: service,
          report: report,
          activeActions: activeActions,
          asDialog: false,
        ),
      ),
    );
  }
}

class _TakeActionForm extends StatefulWidget {
  final TrustSafetyService service;
  final TsReport report;
  final List<ModerationAction> activeActions;
  final bool asDialog;

  const _TakeActionForm({
    required this.service,
    required this.report,
    required this.activeActions,
    required this.asDialog,
  });

  @override
  State<_TakeActionForm> createState() => _TakeActionFormState();
}

class _TakeActionFormState extends State<_TakeActionForm> {
  static const int _minReasonLength = 5;
  static const List<int> _presets = [3, 7, 14, 30, 90];

  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  String? _type;

  /// 0 = no end date ("until lifted"), >0 = number of days, -1 = custom date.
  int _preset = 0;
  DateTime? _customExpiry;

  bool _markTaken = true;
  bool _showValidation = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _markTaken = widget.report.status != ReportStatus.actionTaken;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Derived state ─────────────────────────────────────────────────────────

  bool get _showsDuration =>
      _type == ActionType.suspendTemporary ||
      (_type != null && ActionType.allowsOptionalExpiry(_type!));

  bool get _canMarkTaken => widget.report.status != ReportStatus.actionTaken;

  bool get _reasonOk => _reasonCtrl.text.trim().length >= _minReasonLength;

  String? _disabledReason(AppLocalizations l, String type) {
    final active = widget.activeActions;
    if (type != ActionType.warning &&
        active.any((a) => a.actionType == type && a.isActive)) {
      return l.tsAlreadyActive;
    }
    if (type == ActionType.suspendTemporary &&
        active.any((a) => a.actionType == ActionType.suspendPermanent && a.isActive)) {
      return l.tsAlreadyPermanentlySuspended;
    }
    return null;
  }

  DateTime? _resolveExpiry() {
    if (!_showsDuration) return null;
    if (_preset > 0) return DateTime.now().add(Duration(days: _preset));
    if (_preset == -1) return _customExpiry;
    return null;
  }

  String? _expiryError(AppLocalizations l) {
    final needs = _type == ActionType.suspendTemporary;
    final custom = _preset == -1;
    if (!needs && !custom) return null;
    final e = _resolveExpiry();
    if (e == null) return l.tsExpiryRequired;
    if (!e.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return l.tsExpiryMustBeFuture;
    }
    return null;
  }

  bool _isValid(AppLocalizations l) =>
      _type != null &&
      !widget.report.targetIsAdmin &&
      _reasonOk &&
      _expiryError(l) == null;

  String? _durationLabel(AppLocalizations l) {
    if (_type == ActionType.suspendPermanent) return l.tsDurationPermanent;
    if (_type == ActionType.warning || _type == null) return null;
    final e = _resolveExpiry();
    return e == null ? l.tsDurationUntilLifted : l.tsUntilDate(tsFmtDateTime(e));
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _selectType(String type) {
    setState(() {
      _type = type;
      _error = null;
      if (type == ActionType.suspendTemporary && _preset == 0) _preset = 7;
    });
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final current = _customExpiry;
    final initial = (current != null && current.isAfter(now))
        ? current
        : now.add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _customExpiry = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _preset = -1;
    });
  }

  Future<void> _onApply() async {
    if (_submitting) return; // duplicate-submit guard
    final l = AppLocalizations.of(context);
    setState(() => _showValidation = true);
    if (!_isValid(l)) return;

    final type = _type!;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ConfirmActionDialog(
        actionType: type,
        actionLabel: tsActionTypeLabel(l, type),
        userName: widget.report.reportedUserName,
        durationLabel: _durationLabel(l),
        reason: _reasonCtrl.text.trim(),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _submit();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final action = await widget.service.createAction(
        targetUserId: widget.report.reportedUserId,
        actionType: _type!,
        reason: _reasonCtrl.text,
        adminNote: _noteCtrl.text,
        reportId: widget.report.id,
        expiresAt: _resolveExpiry(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        TakeActionResult(
          action: action,
          markReportActionTaken: _markTaken && _canMarkTaken,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = tsErrorMessage(l, e);
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final radius = widget.asDialog
        ? BorderRadius.circular(20)
        : const BorderRadius.vertical(top: Radius.circular(22));
    final bottomInset =
        widget.asDialog ? 0.0 : MediaQuery.viewInsetsOf(context).bottom;

    final content = Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: radius),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(l),
          const Divider(height: 1, color: TsColors.border),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildBody(l),
              ),
            ),
          ),
          const Divider(height: 1, color: TsColors.border),
          _buildFooter(l),
        ],
      ),
    );

    return PopScope(
      canPop: !_submitting,
      // In dialog mode, the parent ConstrainedBox (maxWidth: 620) already
      // governs the width — forcing the full screen width here conflicts
      // with it and can produce unbounded-width layout errors on rebuild.
      child: widget.asDialog
          ? content
          : SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: content,
            ),
    );
  }

  Widget _buildHeader(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.gavel_rounded, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.tsTakeActionTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TsColors.textPrimary,
                  ),
                ),
                Text(
                  l.tsRegardingReport(widget.report.id.toString()),
                  style: const TextStyle(fontSize: 12, color: TsColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l.tsClose,
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: TsColors.textMuted),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(AppLocalizations l) {
    final report = widget.report;
    final expiryError = _showValidation ? _expiryError(l) : null;

    return [
      // Target user
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TsColors.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            TsUserAvatar(name: report.reportedUserName, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.reportedUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: TsColors.textPrimary,
                    ),
                  ),
                  Text(
                    tsRoleLabel(l, report.reportedUserRole),
                    style: const TextStyle(fontSize: 11.5, color: TsColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (report.targetIsAdmin) ...[
        const SizedBox(height: 12),
        TsInlineError(message: l.tsCannotActOnAdmin),
      ],
      const SizedBox(height: 16),

      // Action picker
      _sectionLabel(l.tsChooseAction),
      const SizedBox(height: 8),
      for (final t in ActionType.all) _optionCard(l, t),
      if (_showValidation && _type == null)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            l.tsChooseActionError,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ),

      // Duration
      if (_showsDuration) ...[
        const SizedBox(height: 16),
        _sectionLabel(l.tsDurationTitle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_type != null && ActionType.allowsOptionalExpiry(_type!))
              _pill(l.tsDurationUntilLifted, _preset == 0, () {
                setState(() => _preset = 0);
              }),
            for (final d in _presets)
              _pill(l.tsDurationDays(d.toString()), _preset == d, () {
                setState(() => _preset = d);
              }),
            _pill(l.tsDurationCustom, _preset == -1, _pickCustomDate,
                icon: Icons.calendar_today_rounded),
          ],
        ),
        if (_preset == -1 && _customExpiry != null) ...[
          const SizedBox(height: 8),
          TsHint(
            icon: Icons.schedule_rounded,
            text: l.tsEndsAt(tsFmtDateTime(_customExpiry)),
            color: TsColors.textBody,
          ),
        ],
        if (expiryError != null) ...[
          const SizedBox(height: 6),
          Text(
            expiryError,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
      ],

      // Reason (user-visible)
      const SizedBox(height: 16),
      _sectionLabel(l.tsReasonLabel),
      const SizedBox(height: 6),
      _textField(
        controller: _reasonCtrl,
        hint: l.tsReasonHint,
        errorText: (_showValidation && !_reasonOk)
            ? l.tsReasonTooShort(_minReasonLength.toString())
            : null,
        onChanged: (_) {
          if (_showValidation) setState(() {});
        },
      ),
      const SizedBox(height: 4),
      TsHint(icon: Icons.person_outline_rounded, text: l.tsReasonUserVisibleNote),

      // Internal note
      const SizedBox(height: 16),
      _sectionLabel(l.tsInternalNoteLabel),
      const SizedBox(height: 6),
      _textField(controller: _noteCtrl, hint: l.tsInternalNoteHint, lines: 2),
      const SizedBox(height: 4),
      TsHint(icon: Icons.lock_outline_rounded, text: l.tsInternalNoteNote),

      // Report status
      if (_canMarkTaken) ...[
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _markTaken,
          onChanged: _submitting
              ? null
              : (v) => setState(() => _markTaken = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: TsColors.accent,
          dense: true,
          title: Text(
            l.tsMarkReportTaken,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TsColors.textPrimary,
            ),
          ),
          subtitle: Text(
            l.tsMarkReportTakenHint,
            style: const TextStyle(fontSize: 11.5, color: TsColors.textMuted),
          ),
        ),
      ],

      if (_error != null) ...[
        const SizedBox(height: 12),
        TsInlineError(message: _error!),
      ],
    ];
  }

  Widget _buildFooter(AppLocalizations l) {
    final destructive = _type != null && ActionType.isSuspension(_type!);
    final color = destructive ? TsColors.suspension : TsColors.accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Wrapped in Flexible so Row hands these a bounded main-axis
          // width instead of an unbounded one (Row gives non-flex children
          // maxWidth: infinity by design), which is what was tripping the
          // "BoxConstraints forces an infinite width" layout crash.
          Flexible(
            child: TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              child: Text(l.tsCancel, style: const TextStyle(color: TsColors.textMuted)),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ElevatedButton(
              onPressed: (_submitting || widget.report.targetIsAdmin) ? null : _onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: color.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      l.tsApplyAction,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Small pieces ──────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: TsColors.textBody,
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    String? errorText,
    int lines = 3,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: !_submitting,
      minLines: lines,
      maxLines: lines + 2,
      maxLength: 2000,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: TsColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12.5, color: TsColors.textFaint),
        filled: true,
        fillColor: TsColors.bg,
        contentPadding: const EdgeInsets.all(12),
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TsColors.accent, width: 1.4),
        ),
      ),
    );
  }

  Widget _pill(String label, bool selected, VoidCallback onTap, {IconData? icon}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _submitting ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? TsColors.accent.withValues(alpha: 0.1) : TsColors.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? TsColors.accent : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: selected ? TsColors.accent : TsColors.textMuted),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? TsColors.accent : TsColors.textBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard(AppLocalizations l, String type) {
    final color = tsActionColor(type);
    final selected = _type == type;
    final disabledReason = _disabledReason(l, type);
    final disabled = disabledReason != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: (disabled || _submitting) ? null : () => _selectType(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.07) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? color : TsColors.border,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(tsActionIcon(type), size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tsActionTypeLabel(l, type),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: TsColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          disabledReason ?? tsActionTypeDescription(l, type),
                          style: const TextStyle(
                            fontSize: 12,
                            color: TsColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded, size: 20, color: color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Final "are you sure" step. Suspensions get a red treatment; a permanent
/// suspension additionally needs an explicit acknowledgement.
class _ConfirmActionDialog extends StatefulWidget {
  final String actionType;
  final String actionLabel;
  final String userName;
  final String? durationLabel;
  final String reason;

  const _ConfirmActionDialog({
    required this.actionType,
    required this.actionLabel,
    required this.userName,
    required this.durationLabel,
    required this.reason,
  });

  @override
  State<_ConfirmActionDialog> createState() => _ConfirmActionDialogState();
}

class _ConfirmActionDialogState extends State<_ConfirmActionDialog> {
  bool _ack = false;

  bool get _needsAck => widget.actionType == ActionType.suspendPermanent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = tsActionColor(widget.actionType);
    final canConfirm = !_needsAck || _ack;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 12, 16, 14),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tsActionIcon(widget.actionType), size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.tsConfirmTitle(widget.actionLabel),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: TsColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.tsConfirmBody(widget.userName),
                style: const TextStyle(
                  fontSize: 13,
                  color: TsColors.textBody,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              TsInfoRow(label: l.tsFieldUser, value: widget.userName),
              TsInfoRow(label: l.tsFieldAction, value: widget.actionLabel),
              if (widget.durationLabel != null)
                TsInfoRow(label: l.tsFieldDuration, value: widget.durationLabel!),
              TsInfoRow(label: l.tsFieldReason, value: widget.reason),
              if (_needsAck) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _ack,
                  onChanged: (v) => setState(() => _ack = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: color,
                  dense: true,
                  title: Text(
                    l.tsConfirmPermanentAck,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: TsColors.textBody,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.tsCancel, style: const TextStyle(color: TsColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: canConfirm ? () => Navigator.of(context).pop(true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: color.withValues(alpha: 0.4),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            l.tsApplyAction,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}