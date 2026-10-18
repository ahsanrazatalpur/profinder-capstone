// lib/features/support/screens/new_ticket_screen.dart
//
// Create a support ticket (signed-in users). Pops with the created
// SupportTicketDetail on success; the text is kept if sending fails.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../models/ticket_models.dart';
import '../../../services/support_service.dart';
import '../widgets/ticket_compose_fields.dart';
import '../widgets/ticket_labels.dart';

class NewTicketScreen extends StatefulWidget {
  final TicketDataSource? source;

  /// Category selected when the form opens (one of [kTicketCategories]).
  final String? initialCategory;

  const NewTicketScreen({super.key, this.source, this.initialCategory});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  late final TicketDataSource _source = widget.source ?? SupportService();

  late String _category = kTicketCategories.contains(widget.initialCategory)
      ? widget.initialCategory!
      : 'other';
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await _source.createTicket(
      subject: _subject.text.trim(),
      body: _body.text.trim(),
      category: _category,
      platform: defaultTargetPlatform.name,
      appLanguage: lang,
    );
    if (!mounted) return;
    if (result.isOk) {
      Navigator.pop(context, result.data);
      return;
    }
    setState(() {
      _sending = false;
      _error = ticketFailureMessage(t, result.failure);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: UniversalAppBar(
        title: t.ticketNewTitle,
        icon: Icons.edit_note_rounded,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsetsDirectional.all(AppSizes.md),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  TicketComposeFields(
                    subject: _subject,
                    body: _body,
                    category: _category,
                    onCategory: (c) => setState(() => _category = c),
                    enabled: !_sending,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSizes.sm),
                    TicketFormError(message: _error!),
                  ],
                  const SizedBox(height: AppSizes.md),
                  FilledButton.icon(
                    onPressed: _sending ? null : _submit,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(t.ticketSubmitCta),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
