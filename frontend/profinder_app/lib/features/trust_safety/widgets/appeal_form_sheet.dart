// lib/features/trust_safety/widgets/appeal_form_sheet.dart
//
// Trust & Safety Part 8 — the appeal SUBMISSION form. Shown as a modal
// bottom sheet from AccountStatusScreen for one specific, already-active
// moderation action belonging to the current user. Mirrors the validation
// and duplicate-submission guards used elsewhere in this codebase (see
// ReportUserDialog): a Form with a required-field validator, a submitting
// flag that disables the button and blocks re-entry, and errors surfaced
// via a SnackBar rather than silently swallowed.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/user_ts_models.dart';
import '../services/user_trust_safety_service.dart';
import 'ts_labels.dart';

/// Shows the sheet and returns `true` if an appeal was submitted
/// successfully (so the caller knows to refresh), or `null`/`false` if the
/// sheet was dismissed without submitting.
Future<bool?> showAppealFormSheet(
  BuildContext context, {
  required MyModerationAction action,
  required Color accentColor,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AppealFormSheet(action: action, accentColor: accentColor),
  );
}

class _AppealFormSheet extends StatefulWidget {
  final MyModerationAction action;
  final Color accentColor;

  const _AppealFormSheet({required this.action, required this.accentColor});

  @override
  State<_AppealFormSheet> createState() => _AppealFormSheetState();
}

class _AppealFormSheetState extends State<_AppealFormSheet> {
  final _service = UserTrustSafetyService();
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _evidenceController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  bool _looksLikeHttpUrl(String v) {
    final s = v.trim().toLowerCase();
    return s.startsWith('http://') || s.startsWith('https://');
  }

  Future<void> _submit() async {
    if (_isSubmitting) return; // guard against double-tap / duplicate submits
    final t = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await _service.submitAppeal(
        moderationActionId: widget.action.id,
        reason: _reasonController.text.trim(),
        evidenceUrl: _evidenceController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.myTsAppealSubmitSuccess), backgroundColor: AppColors.success),
      );
    } on UserTsApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final message = e.isConflict
          ? (e.message ?? t.myTsAppealAlreadyPending)
          : e.isBadRequest
              ? (e.message ?? t.myTsAppealNotEligible)
              : t.myTsAppealSubmitError;
      AppHelpers.showError(context, message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppHelpers.showError(context, t.myTsAppealSubmitError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: context.colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  t.myTsSubmitAppealTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  moderationActionTypeLabel(t, widget.action.actionType, fallback: widget.action.actionTypeDisplay),
                  style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                ),
                const SizedBox(height: 18),
                Text(
                  t.myTsAppealReasonLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  enabled: !_isSubmitting,
                  maxLines: 4,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: t.myTsAppealReasonHint,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: context.colors.background,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? t.myTsAppealReasonRequired : null,
                ),
                const SizedBox(height: 14),
                Text(
                  t.tsEvidenceLinkOptional,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _evidenceController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    prefixIcon: const Icon(Icons.link_rounded, size: 18),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: context.colors.background,
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return null;
                    if (!_looksLikeHttpUrl(value)) return t.tsInvalidHttpUrl;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            t.myTsAppealSubmitCta,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}