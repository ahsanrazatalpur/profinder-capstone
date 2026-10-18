// lib/features/support/screens/help_center_screen.dart
//
// Help Center home: search + topic (category) list, backed by the public
// /api/support/help/... endpoints. Works for guests (no login).
//
// Legacy fallback: while no Help content is published (or the list can't be
// loaded), [fallbackBuilder] (the old static Help screen) is shown instead, so
// the entry points never regress. When Help content exists, the old screen is
// still reachable through a "Contact support" tile at the bottom.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/support_icons.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../services/support_service.dart';
import '../models/help_models.dart';
import '../widgets/support_category_tile.dart';
import '../widgets/support_info_note.dart';
import '../widgets/support_search_field.dart';
import '../widgets/support_section_heading.dart';
import '../widgets/support_state_views.dart';
import 'help_article_screen.dart';
import 'guest_contact_screen.dart';
import 'help_category_screen.dart';
import 'my_tickets_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  /// 'customer' | 'professional' | null (guest -> only content for everyone).
  final String? audience;

  /// Old static Help screen, used as fallback (see file header).
  final WidgetBuilder? fallbackBuilder;

  /// Overridable for tests; defaults to the real API.
  final HelpDataSource? source;

  /// Same idea for the ticket screens opened from "Contact support".
  final TicketDataSource? ticketSource;

  const HelpCenterScreen({
    super.key,
    this.audience,
    this.fallbackBuilder,
    this.source,
    this.ticketSource,
  });

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const _minQueryLen = 2;
  static const _debounce = Duration(milliseconds: 400);

  late final HelpDataSource _source = widget.source ?? SupportService();
  final TextEditingController _controller = TextEditingController();
  Timer? _timer;

  SupportResult<List<HelpCategory>>? _categories;
  bool _loading = true;
  String? _lang;
  int _categoriesReq = 0;

  String _query = '';
  SupportResult<List<HelpArticleSummary>>? _search;
  bool _searching = false;
  int _searchReq = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang != _lang) {
      _lang = lang;
      _loadCategories();
      if (_query.length >= _minQueryLen) _runSearch();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final id = ++_categoriesReq;
    setState(() => _loading = true);
    final result = await _source.getHelpCategories(
      lang: _lang ?? 'en',
      audience: widget.audience,
    );
    if (!mounted || id != _categoriesReq) return;
    setState(() {
      _categories = result;
      _loading = false;
    });
  }

  void _onQueryChanged(String value) {
    _query = value.trim();
    _timer?.cancel();
    if (_query.length < _minQueryLen) {
      _searchReq++; // drop any in-flight search
      setState(() {
        _search = null;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _timer = Timer(_debounce, _runSearch);
  }

  void _onSubmitted(String value) {
    _query = value.trim();
    _timer?.cancel();
    if (_query.length >= _minQueryLen) _runSearch();
  }

  Future<void> _runSearch() async {
    final id = ++_searchReq;
    setState(() => _searching = true);
    final result = await _source.getHelpArticles(
      lang: _lang ?? 'en',
      audience: widget.audience,
      query: _query,
    );
    if (!mounted || id != _searchReq) return;
    setState(() {
      _search = result;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final fallback = widget.fallbackBuilder;

    // Nothing published yet, or the list couldn't be loaded: old static screen.
    if (!_loading && fallback != null) {
      final cats = _categories;
      if (cats == null || !cats.isOk || cats.data!.isEmpty)
        return fallback(context);
    }

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
    final cats = _categories;
    if (cats == null || !cats.isOk) {
      return SupportErrorState(onRetry: _loadCategories);
    }
    if (cats.data!.isEmpty) {
      // No dead end: even with no articles yet, people can still reach support.
      return Column(
        children: [
          Expanded(
            child: SupportEmptyState(
              icon: Icons.help_outline_rounded,
              title: t.homeHelpCenter,
              message: t.helpNoArticlesMessage,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(AppSizes.md),
            child: _contactTile(context, t),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSizes.md,
                AppSizes.md,
                AppSizes.md,
                AppSizes.sm,
              ),
              child: SupportSearchField(
                controller: _controller,
                hintText: t.helpSearchHint,
                clearTooltip: t.searchClear,
                onChanged: _onQueryChanged,
                onSubmitted: _onSubmitted,
              ),
            ),
            Expanded(
              child: _query.isEmpty
                  ? _topics(context, t, cats.data!)
                  : _results(context, t),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topics(
    BuildContext context,
    AppLocalizations t,
    List<HelpCategory> cats,
  ) {
    final anyFallback = cats.any((c) => c.isFallback);
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSizes.md,
        0,
        AppSizes.md,
        AppSizes.lg,
      ),
      children: [
        if (anyFallback) ...[
          const SizedBox(height: AppSizes.sm),
          SupportInfoNote(message: t.helpShownInEnglish),
        ],
        SupportSectionHeading(
          text: t.helpBrowseTopics,
          icon: Icons.help_outline_rounded,
        ),
        for (final c in cats) ...[
          SupportCategoryTile(
            icon: resolveSupportIcon(c.iconKey),
            title: c.title,
            subtitle: c.description.trim().isNotEmpty
                ? c.description
                : t.helpArticleCount(c.articleCount),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HelpCategoryScreen(
                  category: c,
                  audience: widget.audience,
                  source: _source,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
        ],
        const SizedBox(height: AppSizes.sm),
        _contactTile(context, t),
        if (widget.fallbackBuilder != null) ...[
          const SizedBox(height: AppSizes.sm),
          SupportCategoryTile(
            icon: Icons.alternate_email_rounded,
            title: t.helpOtherWaysTitle,
            subtitle: t.helpContactSupportSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: widget.fallbackBuilder!),
            ),
          ),
        ],
      ],
    );
  }

  /// Signed-in users (audience set) open their tickets; guests get the
  /// logged-out contact form.
  Widget _contactTile(BuildContext context, AppLocalizations t) {
    final signedIn = widget.audience != null;
    return SupportCategoryTile(
      icon: Icons.support_agent_rounded,
      title: t.ticketsContactTitle,
      subtitle: t.ticketsContactSubtitle,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => signedIn
              ? MyTicketsScreen(source: widget.ticketSource)
              : GuestContactScreen(source: widget.ticketSource),
        ),
      ),
    );
  }

  Widget _results(BuildContext context, AppLocalizations t) {
    if (_query.length < _minQueryLen) {
      return _hint(context, t.helpSearchTooShort);
    }
    if (_searching && _search == null) return const SupportLoadingState();
    final result = _search;
    if (result == null) return const SupportLoadingState();
    if (!result.isOk) return SupportErrorState(onRetry: _runSearch);

    final items = result.data!;
    if (items.isEmpty) {
      return SupportEmptyState(
        icon: Icons.search_off_rounded,
        title: t.helpNoResultsTitle,
        message: t.helpNoResultsMessage,
      );
    }
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSizes.md,
        0,
        AppSizes.md,
        AppSizes.lg,
      ),
      children: [
        if (items.any((a) => a.isFallback)) ...[
          const SizedBox(height: AppSizes.sm),
          SupportInfoNote(message: t.helpShownInEnglish),
        ],
        SupportSectionHeading(
          text: t.helpSearchResultsHeading,
          icon: Icons.search_rounded,
        ),
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
                  source: _source,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
        ],
      ],
    );
  }

  Widget _hint(BuildContext context, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSizes.lg),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall.copyWith(letterSpacing: 0),
        ),
      ),
    );
  }
}
