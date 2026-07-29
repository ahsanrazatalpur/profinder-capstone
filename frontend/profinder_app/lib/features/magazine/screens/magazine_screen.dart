// lib/features/magazine/screens/magazine_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../models/article_model.dart';
import '../services/magazine_service.dart';
import '../widgets/article_card.dart';
import 'article_detail_screen.dart';
import '../../../core/theme/theme_context_ext.dart';

class MagazineScreen extends StatefulWidget {
  const MagazineScreen({super.key});

  @override
  State<MagazineScreen> createState() => _MagazineScreenState();
}

class _MagazineScreenState extends State<MagazineScreen> {
  final _service = MagazineService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<ArticleCategory> _categories = [];
  List<Article> _articles = [];
  int? _selectedCat;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getCategories(),
        _service.getArticles(categoryId: _selectedCat, query: _searchQuery),
      ]);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _categories = results[0] as List<ArticleCategory>;
        _articles = results[1] as List<Article>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load articles.';
      });
    }
  }

  Future<void> _filterBy(int? catId) async {
    if (_selectedCat == catId) return;
    setState(() {
      _selectedCat = catId;
      _loading = true;
      _error = null;
    });
    final articles = await _service.getArticles(
      categoryId: catId,
      query: _searchQuery,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _articles = articles;
    });
  }

  Future<void> _search(String q) async {
    _searchQuery = q;
    setState(() {
      _loading = true;
      _error = null;
      _isSearching = q.isNotEmpty;
    });
    final articles = await _service.getArticles(
      categoryId: _selectedCat,
      query: q,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _articles = articles;
    });
  }

  bool get _canPop => Navigator.of(context).canPop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.primary,
          onRefresh: _loadAll,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(isDark)),
              SliverToBoxAdapter(child: _buildSearchBar(isDark)),
              if (_categories.isNotEmpty)
                SliverToBoxAdapter(child: _buildCategoryRow(isDark)),
              if (!_loading && _error == null)
                SliverToBoxAdapter(child: _buildCountLine()),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Enhanced Header ──────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.screenPadding(width, base: 16),
        20,
        ResponsiveUtils.screenPadding(width, base: 20),
        24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1E40AF), const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF1E40AF).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_canPop)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: ResponsiveUtils.sp(40, scale, min: 36, max: 48),
                height: ResponsiveUtils.sp(40, scale, min: 36, max: 48),
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: ResponsiveUtils.sp(18, scale, min: 17, max: 22),
                ),
              ),
            ),
          Container(
            width: ResponsiveUtils.sp(48, scale, min: 42, max: 56),
            height: ResponsiveUtils.sp(48, scale, min: 42, max: 56),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: ResponsiveUtils.sp(26, scale, min: 22, max: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Magazine',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.sp(22, scale, min: 18, max: 26),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Health · Legal · Home & Lifestyle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.sp(13, scale, min: 11, max: 15),
                    letterSpacing: 0.3,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Enhanced Search Bar ──────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchCtrl,
          onSubmitted: _search,
          onChanged: (v) {
            if (v.isEmpty) _search('');
          },
          textInputAction: TextInputAction.search,
          style: TextStyle(
            fontSize: 15,
            letterSpacing: 0.2,
            color: context.colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search articles...',
            hintStyle: TextStyle(
              color: context.colors.textSecondary.withOpacity(0.6),
              fontSize: 15,
              letterSpacing: 0.2,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: context.colors.textSecondary.withOpacity(0.6),
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      _search('');
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.textSecondary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: context.colors.textSecondary,
                        size: 16,
                      ),
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Enhanced Category Chips ──────────────────────────────────
  Widget _buildCategoryRow(bool isDark) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return _chip(null, 'All', isDark);
          final cat = _categories[i - 1];
          return _chip(cat.id, cat.name, isDark);
        },
      ),
    );
  }

  Widget _chip(int? catId, String label, bool isDark) {
    final isSelected = _selectedCat == catId;
    
    return GestureDetector(
      onTap: () => _filterBy(catId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    context.colors.primary,
                    context.colors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : isDark
                  ? context.colors.surface.withOpacity(0.5)
                  : context.colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : isDark
                    ? Colors.white.withOpacity(0.1)
                    : context.colors.divider.withOpacity(0.5),
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.colors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
            color: isSelected
                ? Colors.white
                : context.colors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ── Enhanced Count Line ──────────────────────────────────────
  Widget _buildCountLine() {
    final label = _articles.length == 1
        ? '1 Article'
        : '${_articles.length} Articles';
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.primary,
                  context.colors.primary.withOpacity(0.4),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 0.3,
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_isSearching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Search Results',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Enhanced Body ────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: context.colors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading articles...',
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(child: _buildError());
    }

    if (_articles.isEmpty) {
      return SliverFillRemaining(child: _buildEmpty());
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          const maxCrossAxisExtent = 420.0;
          const crossAxisSpacing = 16.0;
          const mainAxisSpacing = 16.0;
          final crossAxisExtent = constraints.crossAxisExtent;
          final columns = (crossAxisExtent / maxCrossAxisExtent)
              .ceil()
              .clamp(1, 6);
          final cardWidth = (crossAxisExtent - crossAxisSpacing * (columns - 1)) /
              columns;
          final cardHeight = ArticleCard.heightFor(
            context,
            cardWidth: cardWidth,
          );

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxCrossAxisExtent,
              mainAxisExtent: cardHeight,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => ArticleCard(
                article: _articles[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailScreen(
                      slug: _articles[i].slug,
                    ),
                  ),
                ),
              ),
              childCount: _articles.length,
            ),
          );
        },
      ),
    );
  }

  // ── Enhanced Error State ─────────────────────────────────────
  Widget _buildError() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary.withOpacity(0.1),
                    context.colors.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Could not load articles. Please check your internet connection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 0.2,
                height: 1.5,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Enhanced Empty State ─────────────────────────────────────
  Widget _buildEmpty() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary.withOpacity(0.12),
                    context.colors.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colors.primary.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                color: context.colors.primary.withOpacity(0.6),
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isSearching ? 'No Results Found' : 'No Articles Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isSearching
                  ? 'Try adjusting your search terms or filters.'
                  : 'Check back soon for new tips and advice.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 0.2,
                height: 1.5,
                color: context.colors.textSecondary,
              ),
            ),
            if (_isSearching) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  _search('');
                },
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text('Clear Search'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(
                    color: context.colors.primary.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}