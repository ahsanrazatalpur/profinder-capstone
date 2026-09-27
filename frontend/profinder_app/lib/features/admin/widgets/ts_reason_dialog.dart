// lib/features/admin/widgets/ts_reason_dialog.dart
//
// One reusable "type a note, confirm" dialog for every low-volume decision in
// the Trust & Safety UI: reversing an action, dismissing / reviewing a report,
// approving / rejecting an appeal.
//
// It owns the submit lifecycle so callers cannot double-submit:
//   • the confirm button is disabled and shows a spinner while [onSubmit] runs
//   • the dialog cannot be dismissed (barrier or back) while it runs
//   • a failure is shown inline and the typed text is kept for a retry
//   • it closes itself with the value [onSubmit] returned on success

import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'ts_ui.dart';

Future<T?> showTsReasonDialog<T>(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String title,
  String? message,
  required String fieldLabel,
  String? fieldHint,
  String? audienceNote,
  bool requireText = true,
  int minLength = 3,
  String initialText = '',
  required String confirmLabel,
  List<String> notes = const [],
  required Future<T> Function(String text) onSubmit,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _TsReasonDialog<T>(
      icon: icon,
      color: color,
      title: title,
      message: message,
      fieldLabel: fieldLabel,
      fieldHint: fieldHint,
      audienceNote: audienceNote,
      requireText: requireText,
      minLength: minLength,
      initialText: initialText,
      confirmLabel: confirmLabel,
      notes: notes,
      onSubmit: onSubmit,
    ),
  );
}

class _TsReasonDialog<T> extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? message;
  final String fieldLabel;
  final String? fieldHint;
  final String? audienceNote;
  final bool requireText;
  final int minLength;
  final String initialText;
  final String confirmLabel;
  final List<String> notes;
  final Future<T> Function(String text) onSubmit;

  const _TsReasonDialog({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.fieldLabel,
    required this.fieldHint,
    required this.audienceNote,
    required this.requireText,
    required this.minLength,
    required this.initialText,
    required this.confirmLabel,
    required this.notes,
    required this.onSubmit,
  });

  @override
  State<_TsReasonDialog<T>> createState() => _TsReasonDialogState<T>();
}

class _TsReasonDialogState<T> extends State<_TsReasonDialog<T>> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialText);
  bool _submitting = false;
  bool _touched = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _tooShort =>
      widget.requireText && _ctrl.text.trim().length < widget.minLength;

  Future<void> _submit() async {
    if (_submitting) return; // duplicate-submit guard
    if (_tooShort) {
      setState(() => _touched = true);
      return;
    }
    final l = AppLocalizations.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await widget.onSubmit(_ctrl.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = tsErrorMessage(l, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: !_submitting,
      child: AlertDialog(
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
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, size: 19, color: widget.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
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
                if (widget.message != null) ...[
                  Text(
                    widget.message!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TsColors.textBody,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                for (final n in widget.notes) ...[
                  TsHint(icon: Icons.info_outline_rounded, text: n),
                  const SizedBox(height: 6),
                ],
                if (widget.notes.isNotEmpty) const SizedBox(height: 6),
                Text(
                  widget.fieldLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: TsColors.textBody,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _ctrl,
                  enabled: !_submitting,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 2000,
                  onChanged: (_) {
                    if (_touched) setState(() {});
                  },
                  style: const TextStyle(fontSize: 13, color: TsColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: widget.fieldHint,
                    hintStyle: const TextStyle(fontSize: 12.5, color: TsColors.textFaint),
                    filled: true,
                    fillColor: TsColors.bg,
                    contentPadding: const EdgeInsets.all(12),
                    errorText: (_touched && _tooShort)
                        ? l.tsReasonTooShort(widget.minLength.toString())
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.color, width: 1.4),
                    ),
                  ),
                ),
                if (widget.audienceNote != null) ...[
                  const SizedBox(height: 4),
                  TsHint(icon: Icons.lock_outline_rounded, text: widget.audienceNote!),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  TsInlineError(message: _error!),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: Text(
              l.tsCancel,
              style: const TextStyle(color: TsColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: widget.color.withValues(alpha: 0.6),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.confirmLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }
}