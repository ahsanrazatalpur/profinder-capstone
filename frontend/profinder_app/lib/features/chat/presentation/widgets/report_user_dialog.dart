// lib/features/chat/presentation/widgets/report_user_dialog.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../../l10n/generated/app_localizations.dart';

// 🐛 FIX: these must exactly match apps.admin_panel.models.UserReport
// .REASON_CHOICES — the endpoint we now submit to (see AppConstants
// .reportUser). The old list ('inappropriate', 'scam') matched a
// different, unrelated model and would 400 against this one.
const _reasonKeys = ['spam', 'harassment', 'fraud', 'fake_profile', 'inappropriate_content', 'other'];

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
  final _detailsController = TextEditingController();
  String _reason = 'spam';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);
    try {
      await _repo.reportUser(widget.userId, _reason, _detailsController.text.trim(), messageId: widget.messageId);
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
      default: return t.chatReasonOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(t.chatReport(widget.userName)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._reasonKeys.map((key) => RadioListTile<String>(
                  value: key,
                  groupValue: _reason,
                  onChanged: (v) => setState(() => _reason = v!),
                  title: Text(_reasonLabel(t, key), style: const TextStyle(fontSize: 13.5)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: context.colors.primary,
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: t.chatAdditionalDetailsOptional,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
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