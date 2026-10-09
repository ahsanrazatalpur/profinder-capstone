// lib/features/admin/screens/admin_magazine_analytics_screen.dart
//
// Admin — Tips Magazine Analytics Dashboard.
// Shows total views, unique readers, per-article breakdown,
// category performance, and recent viewer logs.
//
// FIX: The screen's SingleChildScrollView had no explicit ScrollController.
// On web/desktop, Flutter auto-attaches a Scrollbar to the
// PrimaryScrollController when none is supplied — but a SingleChildScrollView
// that isn't marked `primary: true` (or given its own controller) never
// registers a ScrollPosition with it. Every scroll/animation tick then threw
// "The Scrollbar's ScrollController has no ScrollPosition attached." We now
// create our own ScrollController and wire it directly into the
// SingleChildScrollView (primary: false), so there's nothing left for the
// PrimaryScrollController to fail to find.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../magazine/models/article_model.dart';
import '../../magazine/services/magazine_service.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminMagazineAnalyticsScreen extends StatefulWidget {
  const AdminMagazineAnalyticsScreen({super.key});

  @override
  State<AdminMagazineAnalyticsScreen> createState() =>
      _AdminMagazineAnalyticsScreenState();
}

class _AdminMagazineAnalyticsScreenState
    extends State<AdminMagazineAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final _service = MagazineService();

  // Owns the scroll position for the dashboard body. Passed explicitly to
  // both the Scrollbar and the SingleChildScrollView below so the two are
  // always talking to the same controller — this is what the crash was
  // missing.
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  String? _error;
  MagazineAnalyticsSummary? _data;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _load();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final data = await _service.adminGetAnalytics();
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _loading = false;
        _error = 'Failed to load analytics.';
      });
    } else {
      setState(() {
        _loading = false;
        _data = data;
      });
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final isMediumScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      // AnimatedSwitcher gives the same smooth loading → error → content
      // cross-fade used on the Bookings screen, instead of an abrupt swap.
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _loading
            ? _buildLoader()
            : _error != null
                ? _buildError()
                : _buildDashboard(isSmallScreen, isMediumScreen),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return UniversalAppBar(
      title: 'Magazine Analytics',
      icon: Icons.bar_chart_rounded,
      actions: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _loading ? 0.5 : 1.0,
          child: AppBarIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onPressed: _load,
            onGradient: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(bool isSmallScreen, bool isMediumScreen) {
    final d = _data!;
    return RefreshIndicator(
      key: const ValueKey('content'),
      color: AppColors.adminColor,
      onRefresh: _load,
      // Scrollbar now wraps a SingleChildScrollView that shares the exact
      // same controller — this pairing is what eliminates the
      // "no ScrollPosition attached" crash on web/desktop.
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: isMediumScreen ? false : true,
        child: SingleChildScrollView(
          controller: _scrollController,
          primary: false,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 12 : 16,
              16,
              isSmallScreen ? 12 : 16,
              isMediumScreen ? 100 : 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary Cards ──────────────────────────────
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: child,
                    ),
                  );
                },
                child: _buildSummarySection(d, isSmallScreen, isMediumScreen),
              ),

              const SizedBox(height: 24),

              // ── Category Breakdown ─────────────────────────
              if (d.categoryBreakdown.isNotEmpty) ...[
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 0.5),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCategorySection(d),
                ),
                const SizedBox(height: 24),
              ],

              // ── Per Article ────────────────────────────────
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value * 0.3),
                      child: child,
                    ),
                  );
                },
                child: _buildArticlesSection(d, isSmallScreen),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(
      MagazineAnalyticsSummary d, bool isSmallScreen, bool isMediumScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Overview', Icons.dashboard_rounded),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isSmallScreen ? 1 : (isMediumScreen ? 2 : 2),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isSmallScreen ? 4.5 : 1.8,
          children: [
            _statCard(
              'Total Views',
              '${d.totalViews}',
              Icons.visibility_rounded,
              AppColors.customerColor,
              'All time views across all articles',
            ),
            _statCard(
              'Today',
              '${d.viewsToday}',
              Icons.today_rounded,
              AppColors.emerald,
              'Views in the last 24 hours',
            ),
            _statCard(
              'This Week',
              '${d.viewsThisWeek}',
              Icons.date_range_rounded,
              AppColors.violet,
              'Views in the last 7 days',
            ),
            _statCard(
              'Unique Readers',
              '${d.uniqueReaders}',
              Icons.people_alt_rounded,
              AppColors.warningAmber,
              'Distinct readers across all articles',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection(MagazineAnalyticsSummary d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Views by Category', Icons.category_rounded),
        const SizedBox(height: 12),
        ...d.categoryBreakdown.map((c) => _categoryBar(c, d.totalViews)),
      ],
    );
  }

  Widget _buildArticlesSection(MagazineAnalyticsSummary d, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Articles Performance', Icons.article_rounded),
        const SizedBox(height: 12),
        ...d.articles.map((a) => _articleAnalyticsCard(a, isSmallScreen)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.adminColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, size: 18, color: AppColors.adminColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppFontSizes.input,
            fontWeight: FontWeight.w800,
            color: AppColors.gray900,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color, String subtitle) {
    return _HoverLift(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: AppFontSizes.small,
                      color: AppColors.grayDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: AppFontSizes.nano,
                        color: AppColors.neutral400,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryBar(CategoryBreakdown cat, int totalViews) {
    Color color;
    try {
      color = Color(int.parse(cat.categoryColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      color = context.colors.primary;
    }
    final pct = totalViews > 0 ? cat.totalViews / totalViews : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return _HoverLift(
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radius14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cat.categoryName,
                          style: const TextStyle(
                            fontSize: AppFontSizes.secondary,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                      ),
                      child: Text(
                        '${cat.totalViews} views',
                        style: TextStyle(
                          fontSize: AppFontSizes.caption,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: color.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(value * 100).toStringAsFixed(1)}% of total',
                      style: const TextStyle(
                        fontSize: AppFontSizes.micro,
                        color: AppColors.neutral400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${pct > 0 ? (cat.totalViews ~/ pct).toString() : '0'} avg/read',
                      style: const TextStyle(
                        fontSize: AppFontSizes.micro,
                        color: AppColors.neutral400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _articleAnalyticsCard(ArticleAnalytics a, bool isSmallScreen) {
    Color catColor;
    try {
      catColor = Color(int.parse(a.categoryColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      catColor = context.colors.primary;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: _HoverLift(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Icon(
                        Icons.article_outlined,
                        color: catColor,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      a.title,
                      style: const TextStyle(
                        fontSize: AppFontSizes.secondary,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _miniStat(
                            Icons.visibility_rounded,
                            '${a.viewsCount} views',
                            AppColors.customerColor,
                          ),
                          _miniStat(
                            Icons.people_alt_rounded,
                            '${a.uniqueViewers} unique',
                            AppColors.emerald,
                          ),
                          if (a.recentViews.isNotEmpty)
                            _miniStat(
                              Icons.access_time_rounded,
                              '${a.recentViews.length} recent',
                              AppColors.violet,
                            ),
                        ],
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                      ),
                      child: Text(
                        a.recentViews.isNotEmpty ? 'Details ▾' : 'No views',
                        style: TextStyle(
                          fontSize: AppFontSizes.micro,
                          fontWeight: FontWeight.w600,
                          color: catColor,
                        ),
                      ),
                    ),
                    children: [
                      if (a.recentViews.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(AppSizes.radius10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: AppColors.neutral400,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'No views recorded yet',
                                  style: TextStyle(
                                    fontSize: AppFontSizes.small,
                                    color: AppColors.neutral400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        const Divider(height: 1, color: AppColors.slate100),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 14,
                              color: AppColors.gray700,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Recent Viewers',
                              style: TextStyle(
                                fontSize: AppFontSizes.small,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.slate100,
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              ),
                              child: Text(
                                '${a.recentViews.length}',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.micro,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.grayDeep,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...a.recentViews.map((v) => _viewerRow(v)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSizes.caption,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _viewerRow(ViewLog v) {
    final isGuest = v.userName == 'Guest' || v.userName.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isGuest
                  ? AppColors.slate100
                  : context.colors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: isGuest
                    ? AppColors.neutral200
                    : context.colors.primary.withValues(alpha: 0.20),
                width: 1.5,
              ),
            ),
            child: Icon(
              isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
              size: 16,
              color: isGuest ? AppColors.neutral400 : context.colors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGuest ? 'Guest User' : v.userName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isGuest && v.userRole.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    v.userRole,
                    style: const TextStyle(
                      fontSize: AppFontSizes.micro,
                      color: AppColors.neutral400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: AppColors.neutral200,
                width: 0.5,
              ),
            ),
            child: Text(
              _formatDate(v.viewedAt),
              style: const TextStyle(
                fontSize: AppFontSizes.nano,
                color: AppColors.neutral400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() => const Center(
        key: ValueKey('loading'),
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: AppColors.adminColor,
            strokeWidth: 2.6,
          ),
        ),
      );

  /// Error state — same visual language (icon-in-circle + branded Retry
  /// button) used across the admin panel's other screens.
  Widget _buildError() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load analytics.',
              style: const TextStyle(
                fontSize: AppFontSizes.input,
                color: AppColors.gray700,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Please check your connection and try again',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.neutral400,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 46),
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Small shared UI helpers — visual polish only, no logic
// ═══════════════════════════════════════════════════════════════════════════

/// Wraps a card with a gentle hover "lift" (translate) on platforms that
/// support a mouse cursor. No-ops on touch-only devices. Same component
/// used on the Bookings screen's cards, for visual consistency.
class _HoverLift extends StatefulWidget {
  final Widget child;

  const _HoverLift({required this.child});

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!mounted) return;
        setState(() => _hovering = true);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() => _hovering = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: _hovering
            ? (Matrix4.identity()..translateByDouble(0.0, -2.0, 0.0, 1.0))
            : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}