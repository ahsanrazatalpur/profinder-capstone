// lib/features/admin/screens/admin_articles_screen.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../magazine/models/article_model.dart';
import '../../magazine/services/magazine_service.dart';
import '../../magazine/screens/article_detail_screen.dart';
import 'admin_magazine_analytics_screen.dart';
import '../../../core/theme/theme_context_ext.dart';

// ─────────────────────────────────────────────────────────────────────────
// Responsive breakpoints used throughout this screen. Centralizing them
// keeps the mobile / tablet / desktop layout decisions consistent.
// ─────────────────────────────────────────────────────────────────────────
class _Breakpoints {
  static const double tablet = 720;
  static const double desktop = 1080;
}

class AdminArticlesScreen extends StatefulWidget {
  const AdminArticlesScreen({super.key});

  @override
  State<AdminArticlesScreen> createState() => _AdminArticlesScreenState();
}

class _AdminArticlesScreenState extends State<AdminArticlesScreen>
    with TickerProviderStateMixin {

  final _service = MagazineService();
  final _picker  = ImagePicker();
  final _api     = ApiService();

  late TabController _tabCtrl;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  bool                  _loading    = true;
  String?               _error;
  List<Article>         _articles   = [];
  List<ArticleCategory> _categories = [];
  Map<String, dynamic>  _summary    = {};

  List<Article> get _published => _articles.where((a) => a.isPublished).toList();
  List<Article> get _drafts    => _articles.where((a) => !a.isPublished).toList();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.adminGetAll(),
        _service.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _loading    = false;
        _articles   = results[0] as List<Article>;
        _categories = results[1] as List<ArticleCategory>;
      });
      _animationController.forward(from: 0);

      try {
        final r = await _api.get('/articles/admin/analytics/');
        if (!mounted) return;
        setState(() => _summary = Map<String, dynamic>.from(r.data['summary'] ?? {}));
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load data.'; });
    }
  }

  Future<void> _togglePublish(Article a) async {
    final result = await _service.adminUpdate(a.slug, {'is_published': !a.isPublished});
    if (!mounted) return;
    if (result['success'] == true) {
      await _loadAll();
      _showSnack(
        a.isPublished ? 'Article unpublished' : 'Article published',
        a.isPublished ? AppColors.warning : context.colors.accent,
      );
    } else {
      _showSnack('Update failed', AppColors.error);
    }
  }

  Future<void> _delete(Article a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 26),
        ),
        title: const Text('Delete Article',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        content: Text(
          '"${a.title}" will be permanently deleted.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await _service.adminDelete(a.slug);
      if (!mounted) return;
      if (ok) {
        await _loadAll();
        _showSnack('Deleted', AppColors.error);
      } else {
        _showSnack('Delete failed', AppColors.error);
      }
    }
  }

  Future<void> _openForm({Article? editing}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ArticleFormDialog(
        editing:    editing,
        categories: _categories,
        service:    _service,
        picker:     _picker,
        onSaved: () { Navigator.pop(context); _loadAll(); },
      ),
    );
  }

  Future<void> _openCategoryManager() async {
    await showDialog(
      context: context,
      builder: (_) => _CategoryManagerDialog(
        categories: _categories,
        service:    _service,
        onChanged:  _loadAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= _Breakpoints.tablet;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      // AnimatedSwitcher smooths the transition between the loading spinner,
      // the error state, and the loaded content whenever `_loading`/`_error`
      // change, instead of an abrupt jump-cut.
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _loading
              ? const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(
                      color: AppColors.adminColor, strokeWidth: 2.5),
                )
              : _error != null
                  ? _buildError()
                  : Column(
                      key: const ValueKey('content'),
                      children: [
                        if (_summary.isNotEmpty) _buildSummaryCards(),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isWide ? 1080 : double.infinity,
                              ),
                              child: _buildTabView(),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: isWide
            ? FloatingActionButton.extended(
                key: const ValueKey('fab_extended'),
                onPressed: () => _openForm(),
                backgroundColor: AppColors.adminColor,
                elevation: 3,
                highlightElevation: 6,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'New Article',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              )
            : FloatingActionButton(
                heroTag: 'admin_articles_fab',
                key: const ValueKey('fab_compact'),
                onPressed: () => _openForm(),
                backgroundColor: AppColors.adminColor,
                elevation: 3,
                highlightElevation: 6,
                tooltip: 'Create Article',
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleSpacing: 0,
    title: const Text(
      'Tips Magazine',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF111827),
        letterSpacing: -0.3,
      ),
    ),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF374151)),
      tooltip: 'Back',
      onPressed: () => Navigator.pop(context),
    ),
    actions: [
      _HoverIconButton(
        icon: Icons.analytics_rounded,
        tooltip: 'Analytics',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminMagazineAnalyticsScreen()),
        ),
      ),
      _HoverIconButton(
        icon: Icons.folder_rounded,
        tooltip: 'Manage Categories',
        onPressed: _openCategoryManager,
      ),
      _HoverIconButton(
        icon: Icons.refresh_rounded,
        tooltip: 'Refresh',
        color: const Color(0xFF9CA3AF),
        onPressed: _loadAll,
      ),
      const SizedBox(width: 6),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
        child: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.adminColor,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
          splashBorderRadius: BorderRadius.circular(8),
          labelColor: AppColors.adminColor,
          unselectedLabelColor: const Color(0xFF9CA3AF),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            _tabItem('All', _articles.length),
            _tabItem('Published', _published.length),
            _tabItem('Drafts', _drafts.length),
          ],
        ),
      ),
    ),
  );

  Widget _tabItem(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          // AnimatedSwitcher lets the count badge fade/scale in as it
          // updates instead of snapping to the new number.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Container(
              key: ValueKey(count),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_summary.isEmpty) return const SizedBox.shrink();
    final cards = [
      ('Total', '${_summary['total_articles'] ?? 0}', Icons.article_rounded, AppColors.adminColor),
      ('Published', '${_summary['published_this_month'] ?? 0}', Icons.check_rounded, context.colors.accent),
      ('Views', '${_summary['total_views'] ?? 0}', Icons.visibility_rounded, AppColors.info),
      ('Popular', _summary['most_read_title'] != null
          ? '${_summary['most_read_views']}' : '—', Icons.trending_up_rounded, const Color(0xFF7C3AED)),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: SizedBox(
        height: 76,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final (label, value, icon, color) = cards[i];
            return _SummaryCard(label: label, value: value, icon: icon, color: color);
          },
        ),
      ),
    );
  }

  Widget _buildTabView() => TabBarView(
    controller: _tabCtrl,
    children: [
      _buildList(_articles),
      _buildList(_published),
      _buildList(_drafts),
    ],
  );

  Widget _buildList(List<Article> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.adminColor.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_outlined,
              color: AppColors.adminColor.withOpacity(0.4),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No articles found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the + button to create one',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ]),
      );
    }

    // Determine the layout column count based on available width, giving a
    // dedicated tablet layout in addition to mobile / desktop.
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _Breakpoints.desktop;
    final isWide = screenWidth >= _Breakpoints.tablet;

    return RefreshIndicator(
      color: AppColors.adminColor,
      onRefresh: _loadAll,
      child: isWide
          ? GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isDesktop ? 2.2 : 2.6,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) => _animatedCard(list[i], i),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: list.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _animatedCard(list[i], i),
              ),
            ),
    );
  }

  Widget _animatedCard(Article a, int i) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final delay = i * 0.05;
        final animation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (delay).clamp(0.0, 0.8),
            1.0,
            curve: Curves.easeOutCubic,
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 20),
            child: child,
          ),
        );
      },
      child: _ArticleCard(
        article: a,
        onPreview: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ArticleDetailScreen(slug: a.slug)),
        ),
        onTogglePublish: () => _togglePublish(a),
        onEdit: () => _openForm(editing: a),
        onDelete: () => _delete(a),
      ),
    );
  }

  Widget _buildError() => Center(
    key: const ValueKey('error'),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
      ),
      const SizedBox(height: 16),
      Text(
        _error!,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF374151),
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Please check your connection and try again',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF9CA3AF),
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: _loadAll,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Retry'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.adminColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    ]),
  );

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppColors.error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Small shared UI helpers — visual polish only, no logic
// ═══════════════════════════════════════════════════════════════════════════════

/// A single stat pill shown in the summary strip. Extracted into its own
/// stateful widget so each card can carry its own hover animation on
/// desktop/web without rebuilding the whole strip.
class _SummaryCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 128,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        transform: _hovering
            ? (Matrix4.identity()..translate(0.0, -2.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_hovering ? 0.09 : 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.color.withOpacity(0.14), width: 1.5),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, size: 18, color: widget.color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: widget.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon button with a subtle hover background on desktop/web and a tooltip.
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _HoverIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _hovering ? const Color(0xFFF1F5F9) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          // `Semantics` label mirrors the tooltip so screen readers announce
          // the action even where a tooltip isn't visually surfaced.
          child: Semantics(
            label: widget.tooltip,
            button: true,
            child: IconButton(
              icon: Icon(widget.icon, color: widget.color ?? const Color(0xFF374151), size: 22),
              onPressed: widget.onPressed,
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps a small chip-style button with tap ripple + a gentle hover/press scale.
class _HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverScale({required this.child, required this.onTap});

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Article Card — extracted for clarity + a desktop hover "lift" effect
// ═══════════════════════════════════════════════════════════════════════════════
class _ArticleCard extends StatefulWidget {
  final Article article;
  final VoidCallback onPreview;
  final VoidCallback onTogglePublish;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ArticleCard({
    required this.article,
    required this.onPreview,
    required this.onTogglePublish,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      // The card lifts slightly with a deeper shadow on hover (desktop/web)
      // to signal interactivity without affecting touch devices.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: _hovering
            ? (Matrix4.identity()..translate(0.0, -2.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovering ? 0.08 : 0.04),
              blurRadius: _hovering ? 18 : 12,
              offset: Offset(0, _hovering ? 6 : 2),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: _hovering ? AppColors.adminColor.withOpacity(0.15) : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: a.coverImage.isNotEmpty
                    ? Image.network(
                        a.coverImage,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumb(context, a.categoryColor),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 80,
                            height: 80,
                            color: const Color(0xFFF1F5F9),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.adminColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : _thumb(context, a.categoryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: a.isPublished
                                ? context.colors.accent.withOpacity(0.10)
                                : const Color(0xFFF59E0B).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                a.isPublished
                                    ? Icons.check_circle_rounded
                                    : Icons.edit_note_rounded,
                                size: 12,
                                color: a.isPublished
                                    ? context.colors.accent
                                    : const Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                a.isPublished ? 'Published' : 'Draft',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: a.isPublished
                                      ? context.colors.accent
                                      : const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (a.categoryName.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                a.categoryName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.editorialLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${a.readTime} min read',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.visibility_rounded,
                          size: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _fmtCount(a.viewsCount),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _btn(
                          'Preview',
                          const Color(0xFF64748B),
                          Icons.visibility_rounded,
                          widget.onPreview,
                        ),
                        _btn(
                          a.isPublished ? 'Unpublish' : 'Publish',
                          a.isPublished ? const Color(0xFFF59E0B) : context.colors.accent,
                          a.isPublished ? Icons.unpublished_rounded : Icons.publish_rounded,
                          widget.onTogglePublish,
                        ),
                        _btn(
                          'Edit',
                          context.colors.primary,
                          Icons.edit_rounded,
                          widget.onEdit,
                        ),
                        _btn(
                          'Delete',
                          AppColors.error,
                          Icons.delete_outline_rounded,
                          widget.onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb(BuildContext context, String hex) {
    Color c;
    try { c = Color(int.parse(hex.replaceFirst('#', '0xFF'))); }
    catch (_) { c = context.colors.primary; }
    return Container(
      width: 80,
      height: 80,
      color: c.withOpacity(0.08),
      child: Icon(Icons.image_rounded, color: c.withOpacity(0.3), size: 32),
    );
  }

  // Action chip used for Preview / Publish / Edit / Delete. Kept as a
  // minimum 44dp-tall tap target so it stays comfortable to tap on mobile.
  Widget _btn(String label, Color color, IconData icon, VoidCallback onTap) {
    return _HoverScale(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.15), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Article Form Dialog — Premium Design
// ═══════════════════════════════════════════════════════════════════════════════
class _ArticleFormDialog extends StatefulWidget {
  final Article?              editing;
  final List<ArticleCategory> categories;
  final MagazineService       service;
  final ImagePicker           picker;
  final VoidCallback          onSaved;

  const _ArticleFormDialog({
    required this.editing,
    required this.categories,
    required this.service,
    required this.picker,
    required this.onSaved,
  });

  @override
  State<_ArticleFormDialog> createState() => _ArticleFormDialogState();
}

class _ArticleFormDialogState extends State<_ArticleFormDialog> {
  final _titleCtrl     = TextEditingController();
  final _summaryCtrl   = TextEditingController();
  final _contentCtrl   = TextEditingController();
  final _imageCtrl     = TextEditingController();
  final _readCtrl      = TextEditingController(text: '3');
  final _editorialCtrl = TextEditingController(text: 'ProFinder Editorial');

  // Dedicated controller for the dialog's scrollable body. Required so the
  // `Scrollbar` below has a `ScrollPosition` to attach to — without this,
  // the Scrollbar falls back to the (unattached) PrimaryScrollController
  // and throws on every scroll/hover event.
  final _formScrollCtrl = ScrollController();

  int?    _catId;
  bool    _isPublished    = false;
  bool    _saving         = false;
  bool    _uploadingImage = false;
  String? _dialogError;

  static const _editorialSuggestions = [
    'ProFinder Editorial',
    'ProFinder Health Desk',
    'Legal Advisory Team',
    'ProFinder Home Advisory',
    'Finance & Money Desk',
    'ProFinder Lifestyle',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _titleCtrl.text     = e.title;
      _summaryCtrl.text   = e.summary;
      _contentCtrl.text   = e.content;
      _imageCtrl.text     = e.coverImage;
      _readCtrl.text      = e.readTime.toString();
      _editorialCtrl.text = e.editorialLabel.isNotEmpty
          ? e.editorialLabel
          : 'ProFinder Editorial';
      _catId              = e.categoryId;
      _isPublished        = e.isPublished;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _contentCtrl.dispose();
    _imageCtrl.dispose();
    _readCtrl.dispose();
    _editorialCtrl.dispose();
    _formScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await widget.picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() { _uploadingImage = true; _dialogError = null; });
    try {
      dio.MultipartFile mp;
      if (kIsWeb) {
        final Uint8List bytes = await picked.readAsBytes();
        mp = dio.MultipartFile.fromBytes(bytes, filename: picked.name);
      } else {
        mp = await dio.MultipartFile.fromFile(picked.path, filename: picked.name);
      }
      final url = await widget.service.uploadCoverImage(
          dio.FormData.fromMap({'image': mp}));
      if (url != null) _imageCtrl.text = url;
    } catch (_) {
      setState(() { _dialogError = 'Image upload failed.'; });
    } finally {
      setState(() { _uploadingImage = false; });
    }
  }

  Future<void> _save() async {
    final title     = _titleCtrl.text.trim();
    final content   = _contentCtrl.text.trim();
    final editorial = _editorialCtrl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      setState(() { _dialogError = 'Title and content are required.'; });
      return;
    }
    setState(() { _saving = true; _dialogError = null; });

    final data = <String, dynamic>{
      'title':           title,
      'summary':         _summaryCtrl.text.trim(),
      'content':         content,
      'cover_image':     _imageCtrl.text.trim(),
      'read_time':       int.tryParse(_readCtrl.text.trim()) ?? 3,
      'is_published':    _isPublished,
      'editorial_label': editorial.isEmpty ? 'ProFinder Editorial' : editorial,
      if (_catId != null) 'category': _catId,
    };

    final result = widget.editing != null
        ? await widget.service.adminUpdate(widget.editing!.slug, data)
        : await widget.service.adminCreate(data);

    setState(() { _saving = false; });
    if (result['success'] == true) {
      widget.onSaved();
    } else {
      setState(() { _dialogError = result['message'] ?? 'Save failed.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width >= 640
        ? 560.0
        : screenSize.width - 32;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      // TweenAnimationBuilder gives the dialog a light fade + scale-in on
      // open without needing a manually managed AnimationController.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.96, end: 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (context, scale, child) => Opacity(
          opacity: scale,
          child: Transform.scale(scale: scale, child: child),
        ),
        child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.92,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dialog Header ─────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.adminColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_rounded : Icons.add_rounded,
                    color: AppColors.adminColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Article' : 'Create Article',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                _HoverIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  color: const Color(0xFF9CA3AF),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 18),
            // ── Scrollable Fields ─────────────────────────────────────────
            Expanded(
              child: Scrollbar(
                controller: _formScrollCtrl,
                thumbVisibility: false,
                child: SingleChildScrollView(
                  controller: _formScrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        _titleCtrl,
                        'Title',
                        'Enter article title',
                        'Title is required',
                        maxLines: 2,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _summaryCtrl,
                        'Summary',
                        'Brief preview for cards',
                        'Summarize your article',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _contentCtrl,
                        'Content',
                        'Write full article content',
                        'Content is required',
                        maxLines: 8,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      // ── Cover Image ───────────────────────────────────────
                      _buildLabel('Cover Image', false),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _imageCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: _buildInputDecoration(
                                'Enter image URL',
                                null,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Tooltip(
                            message: 'Upload from device',
                            child: _HoverScale(
                              onTap: _uploadingImage ? () {} : _pickImage,
                              child: Container(
                                height: 48,
                                width: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.adminColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.adminColor.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: _uploadingImage
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.adminColor,
                                        ),
                                      )
                                    : Icon(
                                        Icons.photo_library_rounded,
                                        color: AppColors.adminColor,
                                        size: 22,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // AnimatedSize smoothly reveals the image preview as
                      // soon as a valid URL is entered or uploaded.
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: _imageCtrl.text.trim().isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _imageCtrl.text.trim(),
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      // ── Editorial Label ─────────────────────────────
                      _buildLabel('Editorial Byline', false),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _editorialCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: _buildInputDecoration(
                          'e.g. ProFinder Health Desk',
                          null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      // Quick suggestion chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _editorialSuggestions.map((s) {
                          final isSelected = _editorialCtrl.text == s;
                          return _HoverScale(
                            onTap: () => setState(() => _editorialCtrl.text = s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.adminColor
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.adminColor
                                      : const Color(0xFFE5E7EB),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // ── Category + Read Time ──────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Category', false),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<int>(
                                  value: _catId,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFF9CA3AF)),
                                  hint: const Text(
                                    'Select category',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.adminColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                  ),
                                  items: widget.categories
                                      .map((c) => DropdownMenuItem(
                                            value: c.id,
                                            child: Text(
                                              c.name,
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => _catId = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Read Time', false),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _readCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _buildInputDecoration(
                                    'Minutes',
                                    null,
                                  ).copyWith(
                                    suffixText: 'min',
                                    suffixStyle: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // ── Publish Toggle ────────────────────────────────────
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isPublished
                              ? context.colors.accent.withOpacity(0.04)
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isPublished
                                ? context.colors.accent.withOpacity(0.2)
                                : const Color(0xFFE5E7EB),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isPublished
                                    ? context.colors.accent.withOpacity(0.12)
                                    : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPublished
                                    ? Icons.public_rounded
                                    : Icons.lock_outline_rounded,
                                color: _isPublished
                                    ? context.colors.accent
                                    : const Color(0xFF9CA3AF),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isPublished ? 'Published' : 'Draft',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _isPublished
                                          ? context.colors.accent
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                  Text(
                                    _isPublished
                                        ? 'Visible to all users'
                                        : 'Only visible to admins',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPublished,
                              activeColor: context.colors.accent,
                              onChanged: (v) => setState(() => _isPublished = v),
                            ),
                          ],
                        ),
                      ),
                      // ── Error Box ─────────────────────────────────────────
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: _dialogError != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.error.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: AppColors.error,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _dialogError!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // ── Save Button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminColor,
                  disabledBackgroundColor: AppColors.adminColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: _saving
                      ? const SizedBox(
                          key: ValueKey('saving'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          key: const ValueKey('idle'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEditing
                                  ? Icons.save_rounded
                                  : Icons.add_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEditing ? 'Save Changes' : 'Create Article',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    String hint,
    String helper, {
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: _buildInputDecoration(hint, helper),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, bool required) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint, String? helper) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      helperText: helper,
      helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.adminColor, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Category Manager Dialog — Premium Design
// ═══════════════════════════════════════════════════════════════════════════════
class _CategoryManagerDialog extends StatefulWidget {
  final List<ArticleCategory> categories;
  final MagazineService       service;
  final VoidCallback          onChanged;

  const _CategoryManagerDialog({
    required this.categories,
    required this.service,
    required this.onChanged,
  });

  @override
  State<_CategoryManagerDialog> createState() => _CategoryManagerDialogState();
}

class _CategoryManagerDialogState extends State<_CategoryManagerDialog> {
  final _nameCtrl = TextEditingController();

  // Dedicated controller for the category list's Scrollbar, mirroring the
  // fix applied to the article form dialog above — a Scrollbar always
  // needs an explicitly attached ScrollController inside a Dialog.
  final _listScrollCtrl = ScrollController();

  late List<ArticleCategory> _cats;
  bool    _saving = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _cats = List.from(widget.categories);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _listScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { setState(() { _err = 'Name is required.'; }); return; }
    setState(() { _saving = true; _err = null; });
    final res = await widget.service.adminCreateCategory({'name': name});
    setState(() { _saving = false; });
    if (res['success'] == true) {
      _nameCtrl.clear();
      widget.onChanged();
      final updated = await widget.service.getCategories();
      if (mounted) setState(() => _cats = updated);
    } else {
      setState(() { _err = 'Failed to add.'; });
    }
  }

  Future<void> _delete(ArticleCategory c) async {
    final ok = await widget.service.adminDeleteCategory(c.id);
    if (!mounted) return;
    if (ok) {
      widget.onChanged();
      setState(() => _cats.removeWhere((x) => x.id == c.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width >= 560
        ? 480.0
        : screenSize.width - 40;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      // Same lightweight fade + scale entrance as the article form dialog.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.96, end: 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (context, scale, child) => Opacity(
          opacity: scale,
          child: Transform.scale(scale: scale, child: child),
        ),
        child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.adminColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: AppColors.adminColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Manage Categories',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                _HoverIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  color: const Color(0xFF9CA3AF),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Existing categories list
            if (_cats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 48,
                        color: const Color(0xFF9CA3AF).withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No categories',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: Scrollbar(
                  controller: _listScrollCtrl,
                  child: ListView.builder(
                    controller: _listScrollCtrl,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _cats.length,
                    itemBuilder: (_, i) {
                      final c = _cats[i];
                      Color col;
                      try {
                        col = Color(int.parse(c.color.replaceFirst('#', '0xFF')));
                      } catch (_) { col = context.colors.primary; }

                      return _CategoryRow(
                        name: c.name,
                        articlesCount: c.articlesCount,
                        color: col,
                        onDelete: () => _delete(c),
                      );
                    },
                  ),
                ),
              ),
            const Divider(height: 24),
            const Text(
              'Add New Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Category name',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.adminColor,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 46,
                  width: 46,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _add,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: _saving
                          ? const SizedBox(
                              key: ValueKey('saving'),
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.add_rounded, key: ValueKey('idle'), size: 24),
                    ),
                  ),
                ),
              ],
            ),
            // AnimatedSize smooths the inline validation message in/out.
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              child: _err != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _err!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// A single category row in the manager dialog, with a subtle hover
/// highlight on desktop/web to indicate the delete action target.
class _CategoryRow extends StatefulWidget {
  final String name;
  final int articlesCount;
  final Color color;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.name,
    required this.articlesCount,
    required this.color,
    required this.onDelete,
  });

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_hovering ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.color.withOpacity(_hovering ? 0.2 : 0.1),
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.label_rounded,
              color: widget.color,
              size: 18,
            ),
          ),
          title: Text(
            widget.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${widget.articlesCount} articles',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
            ),
          ),
          trailing: Tooltip(
            message: 'Delete category',
            child: IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
              onPressed: widget.onDelete,
            ),
          ),
        ),
      ),
    );
  }
}