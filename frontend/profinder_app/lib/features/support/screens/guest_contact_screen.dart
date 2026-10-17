// lib/features/support/screens/guest_contact_screen.dart
//
// Contact form for people who are not signed in. The server answers with a
// reference number only (a guest cannot read tickets back), so the success
// state tells them we will use the email they gave.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../services/support_service.dart';
import '../widgets/ticket_compose_fields.dart';
import '../widgets/ticket_labels.dart';

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class GuestContactScreen extends StatefulWidget {
  final TicketDataSource? source;

  const GuestContactScreen({super.key, this.source});

  @override
  State<GuestContactScreen> createState() => _GuestContactScreenState();
}

class _GuestContactScreenState extends State<GuestContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  late final TicketDataSource _source = widget.source ?? SupportService();

  String _category = 'other';
  bool _sending = false;
  String? _error;
  bool _sent = false;
  String? _reference;

  @override
  void dispose() {
    _email.dispose();
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
    final result = await _source.sendGuestContact(
      email: _email.text.trim(),
      subject: _subject.text.trim(),
      body: _body.text.trim(),
      category: _category,
      platform: defaultTargetPlatform.name,
      appLanguage: lang,
    );
    if (!mounted) return;
    if (result.isOk) {
      setState(() {
        _sending = false;
        _sent = true;
        _reference = result.data!.reference;
      });
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
      appBar: UniversalAppBar(title: t.guestContactTitle, icon: Icons.support_agent_rounded),
      body: SafeArea(child: _sent ? _success(context, t) : _form(context, t)),
    );
  }

  Widget _form(BuildContext context, AppLocalizations t) {
    final styles = context.textStyles;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsetsDirectional.all(AppSizes.md),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Text(t.guestContactIntro, style: styles.bodyMedium.copyWith(letterSpacing: 0)),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: _email,
                enabled: !_sending,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                style: styles.inputText.copyWith(letterSpacing: 0),
                decoration: InputDecoration(
                  labelText: t.guestEmailLabel,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return t.ticketFieldRequired;
                  return _emailPattern.hasMatch(value) ? null : t.guestEmailInvalid;
                },
              ),
              const SizedBox(height: AppSizes.md),
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
    );
  }

  Widget _success(BuildContext context, AppLocalizations t) {
    final colors = context.colors;
    final styles = context.textStyles;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(AppSizes.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: AppSizes.iconXl, color: colors.accent),
              const SizedBox(height: AppSizes.md),
              Text(
                t.guestContactSentTitle,
                textAlign: TextAlign.center,
                style: styles.h3.copyWith(letterSpacing: 0),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                t.guestContactSentMessage,
                textAlign: TextAlign.center,
                style: styles.bodyMedium.copyWith(letterSpacing: 0),
              ),
              if (_reference != null) ...[
                const SizedBox(height: AppSizes.sm),
                Text(
                  t.guestContactReference(_reference!),
                  textAlign: TextAlign.center,
                  style: styles.bodySmall.copyWith(letterSpacing: 0),
                ),
              ],
              const SizedBox(height: AppSizes.lg),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.doneCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}