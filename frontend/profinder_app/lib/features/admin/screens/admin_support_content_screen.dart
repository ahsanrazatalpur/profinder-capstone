// lib/features/admin/screens/admin_support_content_screen.dart
//
// Admin tab "Help Content" (English only): edit and publish the Privacy Policy
// and the Help Center articles without the Django admin site.
//
// Backend: /api/support/admin/policy/...  and  /api/support/admin/help/...

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/support_content_service.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../models/support_content_models.dart';
import '../widgets/admin_content_ui.dart';
import '../widgets/admin_ticket_ui.dart';
import 'admin_article_editor_screen.dart';
import 'admin_policy_editor_screen.dart';

class AdminSupportContentScreen extends StatelessWidget {
  /// Overridable for tests; defaults to the real API.
  final SupportContentDataSource? source;

  const AdminSupportContentScreen({super.key, this.source});

  @override
  Widget build(BuildContext context) {
    final src = source ?? SupportContentService();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.lightScaffold,
        appBar: UniversalAppBar(
          title: 'Help content',
          icon: Icons.edit_note_rounded,
          color: AppColors.adminColor,
          showBack: false,
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Material(
                color: Colors.white,
                child: TabBar(
                  labelColor: AppColors.adminColor,
                  indicatorColor: AppColors.adminColor,
                  tabs: const [
                    Tab(text: 'Privacy policy'),
                    Tab(text: 'Help articles'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _PolicyTab(source: src),
                    _ArticlesTab(source: src),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Privacy policy tab ──────────────────────────────────────────────────────

class _PolicyTab extends StatefulWidget {
  final SupportContentDataSource source;

  const _PolicyTab({required this.source});

  @override
  State<_PolicyTab> createState() => _PolicyTabState();
}

class _PolicyTabState extends State<_PolicyTab> {
  List<AdminPolicyVersion> _versions = [];
  bool _loading = true;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool spinner = true}) async {
    if (spinner) setState(() { _loading = true; _error = null; });
    final result = await widget.source.listPolicies();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isOk) {
        _versions = result.data ?? [];
        _error = null;
      } else {
        _error = result.error;
      }
    });
  }

  bool get _hasDraft => _versions.any((v) => v.isDraft);

  Future<void> _open(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminPolicyEditorScreen(versionId: id, source: widget.source)),
    );
    if (mounted) _load(spinner: false);
  }

  Future<void> _createVersion() async {
    if (_creating) return;
    setState(() => _creating = true);
    final result = await widget.source.newPolicyVersion();
    if (!mounted) return;
    setState(() => _creating = false);
    if (!result.isOk) {
      showContentSnack(context, result.error ?? 'Could not create a new version.');
      return;
    }
    await _open(result.data!.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.adminColor));
    }
    if (_error != null) return AdminContentError(message: _error!, onRetry: _load);

    return RefreshIndicator(
      onRefresh: () => _load(spinner: false),
      color: AppColors.adminColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (!_hasDraft)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _creating ? null : _createVersion,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(_versions.isEmpty ? 'Create first draft' : 'Start new version'),
                  ),
                ),
              if (_versions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: Text('No privacy policy yet.')),
                ),
              for (final v in _versions) ...[
                const SizedBox(height: 10),
                _PolicyCard(version: v, onTap: () => _open(v.id)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final AdminPolicyVersion version;
  final VoidCallback onTap;

  const _PolicyCard({required this.version, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (version.status) {
      'published' => ('Published', AppColors.greenDeep, Icons.check_circle_rounded),
      'archived' => ('Archived', AppColors.neutral400, Icons.inventory_2_rounded),
      _ => ('Draft', AppColors.warningAmber, Icons.edit_rounded),
    };
    final effective = version.effectiveDate == null
        ? 'No effective date'
        : 'Effective ${MaterialLocalizations.of(context).formatShortDate(version.effectiveDate!)}';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Version ${version.version}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  AdminTicketPill(label: label, icon: icon, color: color),
                ],
              ),
              const SizedBox(height: 4),
              Text(effective, style: const TextStyle(color: AppColors.slate500)),
              if (version.changeSummary.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(version.changeSummary, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (version.isDraft && version.placeholdersLeft > 0) ...[
                const SizedBox(height: 8),
                AdminTicketPill(
                  label: '${version.placeholdersLeft} blanks to fill',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warningAmber,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Help articles tab ───────────────────────────────────────────────────────

class _ArticlesTab extends StatefulWidget {
  final SupportContentDataSource source;

  const _ArticlesTab({required this.source});

  @override
  State<_ArticlesTab> createState() => _ArticlesTabState();
}

class _ArticlesTabState extends State<_ArticlesTab> {
  final _search = TextEditingController();
  Timer? _debounce;

  String _filter = 'all'; // all | published | draft
  List<AdminHelpArticle> _articles = [];
  bool _loading = true;
  String? _error;
  int _reqId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool spinner = true}) async {
    final id = ++_reqId;
    if (spinner) setState(() { _loading = true; _error = null; });
    final result = await widget.source.listArticles(
      query: _search.text,
      published: switch (_filter) {
        'published' => true,
        'draft' => false,
        _ => null,
      },
    );
    if (!mounted || id != _reqId) return;
    setState(() {
      _loading = false;
      if (result.isOk) {
        _articles = result.data ?? [];
        _error = null;
      } else {
        _error = result.error;
      }
    });
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _open({int? id}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminArticleEditorScreen(articleId: id, source: widget.source)),
    );
    if (mounted) _load(spinner: false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            children: [
              TextField(
                controller: _search,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _load(),
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search articles',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final f in const [
                          ('all', 'All'),
                          ('published', 'Published'),
                          ('draft', 'Drafts'),
                        ])
                          ChoiceChip(
                            label: Text(f.$2),
                            selected: _filter == f.$1,
                            selectedColor: AppColors.adminColor.withValues(alpha: 0.15),
                            onSelected: (_) {
                              setState(() => _filter = f.$1);
                              _load();
                            },
                          ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _open(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.adminColor));
    }
    if (_error != null) return AdminContentError(message: _error!, onRetry: _load);
    if (_articles.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(spinner: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.article_outlined, size: 40, color: AppColors.neutral400),
            SizedBox(height: 12),
            Center(child: Text('No articles here.')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(spinner: false),
      color: AppColors.adminColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: _articles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ArticleCard(
              article: _articles[i],
              onTap: () => _open(id: _articles[i].id),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final AdminHelpArticle article;
  final VoidCallback onTap;

  const _ArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = [
      article.categoryTitle,
      kAdminAudienceLabels[article.audience] ?? article.audience,
    ].where((s) => s.isNotEmpty).join(' · ');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(meta, style: const TextStyle(color: AppColors.slate500)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AdminTicketPill(
                label: article.isPublished ? 'Published' : 'Draft',
                icon: article.isPublished ? Icons.check_circle_rounded : Icons.edit_rounded,
                color: article.isPublished ? AppColors.greenDeep : AppColors.warningAmber,
              ),
            ],
          ),
        ),
      ),
    );
  }
}