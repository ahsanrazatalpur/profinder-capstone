// lib/features/support/screens/help_article_screen.dart
//
// One Help article. The body is laid out in the direction of the language it
// was actually SERVED in, so an English fallback inside an Urdu UI stays LTR.

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../services/support_service.dart';
import '../models/help_models.dart';
import '../widgets/support_blocks_view.dart';
import '../widgets/support_info_note.dart';
import '../widgets/support_state_views.dart';

class HelpArticleScreen extends StatefulWidget {
  final String slug;

  /// Title already known from the list (shown in the app bar while loading).
  final String title;
  final String? audience;
  final HelpDataSource source;

  const HelpArticleScreen({
    super.key,
    required this.slug,
    required this.title,
    required this.source,
    this.audience,
  });

  @override
  State<HelpArticleScreen> createState() => _HelpArticleScreenState();
}

class _HelpArticleScreenState extends State<HelpArticleScreen> {
  SupportResult<HelpArticle>? _result;
  bool _loading = true;
  String? _lang;
  int _reqId = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang != _lang) {
      _lang = lang;
      _load();
    }
  }

  Future<void> _load() async {
    final id = ++_reqId;
    setState(() => _loading = true);
    final result = await widget.source.getHelpArticle(
      slug: widget.slug,
      lang: _lang ?? 'en',
      audience: widget.audience,
    );
    if (!mounted || id != _reqId) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: UniversalAppBar(
        title: t.homeHelpCenter,
        icon: Icons.help_outline_rounded,
      ),
      body: SafeArea(child: _body(context, t)),
    );
  }

  Widget _body(BuildContext context, AppLocalizations t) {
    if (_loading) return const SupportLoadingState();
    final result = _result;
    if (result != null &&
        !result.isOk &&
        result.failure == SupportFailure.notFound) {
      return SupportEmptyState(
        icon: Icons.article_outlined,
        title: widget.title,
        message: t.helpArticleNotFound,
      );
    }
    if (result == null || !result.isOk)
      return SupportErrorState(onRetry: _load);

    final article = result.data!;
    final styles = context.textStyles;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsetsDirectional.all(AppSizes.md),
          children: [
            if (article.isFallback) ...[
              SupportInfoNote(message: t.helpShownInEnglish),
              const SizedBox(height: AppSizes.md),
            ],
            Directionality(
              textDirection: article.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Semantics(
                header: true,
                child: Text(
                  article.title,
                  style: styles.h2.copyWith(letterSpacing: 0),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            SupportBlocksView(blocks: article.blocks, isRtl: article.isRtl),
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }
}
