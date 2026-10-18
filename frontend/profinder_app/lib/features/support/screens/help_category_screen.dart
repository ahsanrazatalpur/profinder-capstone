// lib/features/support/screens/help_category_screen.dart
//
// Articles of one Help Center topic.

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../services/support_service.dart';
import '../models/help_models.dart';
import '../widgets/support_category_tile.dart';
import '../widgets/support_info_note.dart';
import '../widgets/support_state_views.dart';
import 'help_article_screen.dart';

class HelpCategoryScreen extends StatefulWidget {
  final HelpCategory category;
  final String? audience;
  final HelpDataSource source;

  const HelpCategoryScreen({
    super.key,
    required this.category,
    required this.source,
    this.audience,
  });

  @override
  State<HelpCategoryScreen> createState() => _HelpCategoryScreenState();
}

class _HelpCategoryScreenState extends State<HelpCategoryScreen> {
  SupportResult<List<HelpArticleSummary>>? _result;
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
    final result = await widget.source.getHelpArticles(
      lang: _lang ?? 'en',
      audience: widget.audience,
      category: widget.category.slug,
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
        title: widget.category.title,
        icon: Icons.help_outline_rounded,
      ),
      body: SafeArea(child: _body(context, t)),
    );
  }

  Widget _body(BuildContext context, AppLocalizations t) {
    if (_loading) return const SupportLoadingState();
    final result = _result;
    if (result == null || !result.isOk)
      return SupportErrorState(onRetry: _load);
    final items = result.data!;
    if (items.isEmpty) {
      return SupportEmptyState(
        icon: Icons.article_outlined,
        title: t.helpNoArticlesTitle,
        message: t.helpNoArticlesMessage,
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsetsDirectional.all(AppSizes.md),
          children: [
            if (items.any((a) => a.isFallback)) ...[
              SupportInfoNote(message: t.helpShownInEnglish),
              const SizedBox(height: AppSizes.md),
            ],
            for (final a in items) ...[
              SupportCategoryTile(
                icon: Icons.article_rounded,
                title: a.title,
                subtitle: a.snippet.trim().isEmpty ? null : a.snippet,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HelpArticleScreen(
                      slug: a.slug,
                      title: a.title,
                      audience: widget.audience,
                      source: widget.source,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
            ],
          ],
        ),
      ),
    );
  }
}
