// lib/features/support/screens/privacy_policy_screen.dart
//
// In-app Privacy Policy. Reads the latest PUBLISHED version from the server
// (same source as the public /privacy/ web page). Works for guests (no login).
//
// Direction: the policy text is laid out in the direction of the language it
// was actually SERVED in (`isRtl`), not the app locale, so an English fallback
// inside an Urdu UI still reads left-to-right.

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../services/support_service.dart';
import '../models/policy_document.dart';
import '../widgets/support_section_heading.dart';
import '../widgets/support_state_views.dart';

typedef PolicyLoader = Future<SupportResult<PolicyDocument>> Function(String lang);

class PrivacyPolicyScreen extends StatefulWidget {
  /// Overridable for tests; defaults to the real API.
  final PolicyLoader? loader;

  const PrivacyPolicyScreen({super.key, this.loader});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  SupportResult<PolicyDocument>? _result;
  bool _loading = true;
  String? _loadedLang;
  int _requestId = 0;

  Future<SupportResult<PolicyDocument>> _fetch(String lang) =>
      (widget.loader ?? (l) => SupportService().getPrivacyPolicy(lang: l))(lang);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang != _loadedLang) {
      _loadedLang = lang;
      _load(lang);
    }
  }

  Future<void> _load(String lang) async {
    final id = ++_requestId;
    setState(() => _loading = true);
    final result = await _fetch(lang);
    if (!mounted || id != _requestId) return; // a newer request superseded this one
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: UniversalAppBar(title: t.profilePrivacyPolicy, icon: Icons.privacy_tip_rounded),
      body: SafeArea(child: _body(context, t)),
    );
  }

  Widget _body(BuildContext context, AppLocalizations t) {
    if (_loading) return const SupportLoadingState();
    final result = _result;
    if (result == null) {
      return SupportErrorState(onRetry: () => _load(_loadedLang ?? 'en'));
    }
    if (result.isOk) return _content(context, t, result.data!);
    if (result.failure == SupportFailure.notFound) {
      return SupportEmptyState(
        icon: Icons.privacy_tip_outlined,
        title: t.profilePrivacyPolicy,
        message: t.privacyNotPublished,
      );
    }
    return SupportErrorState(onRetry: () => _load(_loadedLang ?? 'en'));
  }

  Widget _content(BuildContext context, AppLocalizations t, PolicyDocument doc) {
    final colors = context.colors;
    final styles = context.textStyles;
    final meta = [
      t.privacyVersionLabel(doc.version),
      if (doc.effectiveDate != null) t.privacyEffectiveLabel(doc.effectiveDate!),
    ].join(' · ');

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsetsDirectional.all(AppSizes.md),
          children: [
            if (doc.isFallback) ...[
              Container(
                padding: const EdgeInsetsDirectional.all(AppSizes.sm + 4),
                decoration: BoxDecoration(
                  color: colors.infoBg,
                  border: Border.all(color: colors.infoBorder),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: AppSizes.iconMd - 4, color: colors.infoText),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        t.privacyShownInEnglish,
                        style: styles.bodySmall.copyWith(color: colors.infoText, letterSpacing: 0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],
            // Everything below follows the language of the text itself.
            Directionality(
              textDirection: doc.isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(doc.title, style: styles.h2.copyWith(letterSpacing: 0)),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(meta, style: styles.bodySmall.copyWith(letterSpacing: 0)),
                  const SizedBox(height: AppSizes.sm),
                  for (final block in doc.blocks) _block(context, block),
                  const SizedBox(height: AppSizes.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _block(BuildContext context, PolicyBlock block) {
    final colors = context.colors;
    final styles = context.textStyles;
    switch (block.type) {
      case PolicyBlockType.heading:
        return SupportSectionHeading(
          text: block.text,
          padding: const EdgeInsetsDirectional.only(top: AppSizes.lg - 4, bottom: AppSizes.sm),
        );
      case PolicyBlockType.bullet:
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSizes.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 9, end: AppSizes.sm + 4),
                child: Icon(Icons.circle, size: 6, color: colors.textSecondary),
              ),
              Expanded(
                child: Text(
                  block.text,
                  style: styles.bodyLarge.copyWith(height: 1.55, letterSpacing: 0),
                ),
              ),
            ],
          ),
        );
      case PolicyBlockType.paragraph:
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSizes.sm + 4),
          child: Text(
            block.text,
            style: styles.bodyLarge.copyWith(height: 1.55, letterSpacing: 0),
          ),
        );
    }
  }
}