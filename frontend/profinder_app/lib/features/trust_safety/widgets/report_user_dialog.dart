// lib/features/chat/presentation/widgets/report_user_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../l10n/generated/app_localizations.dart';

// ✅ Trust & Safety Part 8: full list now matches apps.admin_panel.models
// .UserReport.REASON_CHOICES exactly, including the five categories added
// alongside the admin Trust & Safety work (Part 7) that this dialog never
// picked up. The original six ('spam' … 'other') are unchanged and still
// map to the same localization keys they always did.
const _reasonKeys = [
  'spam',
  'harassment',
  'fraud',
  'fake_profile',
  'inappropriate_content',
  'payment_fraud',
  'off_platform_payment',
  'threats_safety',
  'discrimination',
  'service_misconduct',
  'other',
];

/// Very small http(s)-only check — mirrors the backend's own
/// `CreateUserReportSerializer.validate_evidence_url`, so a bad link is
/// caught client-side before a round trip.
bool _looksLikeHttpUrl(String v) {
  final s = v.trim().toLowerCase();
  return s.startsWith('http://') || s.startsWith('https://');
}

class ReportUserDialog extends StatefulWidget {
  final int userId;
  final String userName;
  final String? messageId;

  const ReportUserDialog({super.key, required this.userId, required this.userName, this.messageId});

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  final _repo = ChatRepositoryImpl();
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  final _evidenceController = TextEditingController();
  String _reason = 'spam';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    if (_isSubmitting) return; // guard against double-tap / duplicate submits
    if (!(_formKey.currentState?.validate() ?? true)) return;

    setState(() => _isSubmitting = true);
    try {
      await _repo.reportUser(
        widget.userId,
        _reason,
        _detailsController.text.trim(),
        messageId: widget.messageId,
        evidenceUrl: _evidenceController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.chatReportSubmittedThank)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.chatCouldNotSubmitReportTryAgain)));
    }
  }

  String _reasonLabel(AppLocalizations t, String key) {
    switch (key) {
      case 'spam': return t.chatReasonSpam;
      case 'harassment': return t.chatReasonHarassmentBullying;
      case 'fraud': return t.chatReasonScamFraud;
      case 'fake_profile': return t.chatReasonFakeProfile;
      case 'inappropriate_content': return t.chatReasonInappropriateContent;
      // ✅ Trust & Safety Part 8: these five categories were added to the
      // backend's REASON_CHOICES in Part 7, alongside the admin Trust &
      // Safety screens — which already localize them as `tsCat*`. Reusing
      // those here (rather than adding duplicate `chatReason*` strings)
      // keeps one label per category across the whole app.
      case 'payment_fraud': return t.tsCatPaymentFraud;
      case 'off_platform_payment': return t.tsCatOffPlatform;
      case 'threats_safety': return t.tsCatThreats;
      case 'discrimination': return t.tsCatDiscrimination;
      case 'service_misconduct': return t.tsCatMisconduct;
      default: return t.chatReasonOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.chatReport(widget.userName)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._reasonKeys.map((key) => RadioListTile<String>(
                    value: key,
                    groupValue: _reason,
                    onChanged: _isSubmitting ? null : (v) => setState(() => _reason = v!),
                    title: Text(_reasonLabel(t, key), style: const TextStyle(fontSize: 13.5)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: context.colors.primary,
                  )),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailsController,
                maxLines: 3,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: t.chatAdditionalDetailsOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _evidenceController,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: t.tsEvidenceLinkOptional,
                  prefixIcon: const Icon(Icons.link_rounded, size: 18),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return null; // optional field
                  if (!_looksLikeHttpUrl(value)) return t.tsInvalidHttpUrl;
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSubmitting ? null : () => Navigator.pop(context), child: Text(t.cancel)),
        TextButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(t.chatSubmit, style: const TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }
}