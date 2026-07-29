// lib/features/home/screens/guest_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/auth_provider.dart';
import '../../../services/home_provider.dart';
import '../../../services/location_service.dart';
import '../../../shared/widgets/professional_card.dart';
import '../../../shared/widgets/featured_category_card.dart';
import '../../../shared/widgets/category_card.dart';
import '../../../shared/widgets/cta_banner.dart';
import '../../../core/constants/category_style.dart';
import '../../search/screens/professional_detail_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../magazine/models/article_model.dart';
import '../../magazine/services/magazine_service.dart';
import '../../magazine/screens/article_detail_screen.dart';
import '../../magazine/screens/magazine_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_screen.dart';
import '../../subscription/widgets/promo_banner_mixin.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

class GuestHomeScreen extends StatefulWidget {
  final bool isVisible;

  const GuestHomeScreen({super.key, this.isVisible = true});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen>
    with PromoBannerMixin, AutomaticKeepAliveClientMixin {
  final MagazineService _magazineService = MagazineService();

  List<Article> _articles = [];
  bool _articlesLoading = true;
  bool _bannerTriggered = false;

  final Set<String> _favourites = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isVisible && mounted) {
        _onFirstShow();
      }
    });
  }

  @override
  void didUpdateWidget(covariant GuestHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVisible && widget.isVisible && mounted) {
      _onFirstShow();
    }
  }

  void _onFirstShow() {
    _loadHome();
    _loadArticles();
    if (!_bannerTriggered) {
      _bannerTriggered = true;
      showBannerForScreen('home');
    }
  }

  Future<void> _loadHome() async {
    try {
      final location = await LocationService.getCurrentLocation();
      if (!mounted) return;
      final provider = context.read<HomeProvider>();
      await Future.wait([
        provider.loadHomeData(
          latitude: location?.lat ?? 0,
          longitude: location?.lng ?? 0,
        ),
        provider.loadHomeFeed(latitude: location?.lat, longitude: location?.lng),
      ]);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadArticles() async {
    try {
      if (!mounted) return;
      setState(() => _articlesLoading = true);
      final articles = await _magazineService.getArticles();
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _articlesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _articlesLoading = false);
    }
  }

  Future<void> _refresh() async {
    try {
      await Future.wait([_loadHome(), _loadArticles()]);
    } catch (e) {
      // Handle error
    }
  }

  void _requireLogin(String message) {
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.colors.primary,
                    context.colors.primaryLight,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_person_rounded,
                color: AppColors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              t.homeLoginRequired,
              style: context.textStyles.h2.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  t.login,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  t.homeCreateAccount,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final home = context.watch<HomeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final topRated = home.topRatedFeed ?? [];
    final nearby = home.nearbyInCity ?? [];
    final trending = home.trendingFeed ?? [];
    final recentlyAdded = home.recentlyAddedFeed ?? [];
    final popular = home.popularProfessionalsFeed ?? [];

    final hasAnyProfessionals = topRated.isNotEmpty || trending.isNotEmpty ||
        recentlyAdded.isNotEmpty || nearby.isNotEmpty ||
        popular.isNotEmpty;
    final feedStillLoading = home.feedLoading && !hasAnyProfessionals;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.colors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(nearby, isDark)),
              SliverToBoxAdapter(child: _buildHeroSearch(isDark)),
              SliverToBoxAdapter(child: _buildQuickActionChips(home.categories ?? [], isDark)),

              if (feedStillLoading)
                SliverToBoxAdapter(child: _buildLoadingSkeleton(isDark))
              else ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(t.homePopularCategories,
                      onViewAll: () => _showAllCategories(home.categories ?? [], isDark)),
                ),
                SliverToBoxAdapter(
                    child: _buildPopularCategories(home.categories ?? [], isDark)),

                SliverToBoxAdapter(
                  child: _buildSectionHeader(t.homeFeaturedCategoriesSection),
                ),
                SliverToBoxAdapter(
                    child: _buildFeaturedCategories(home.featuredCategories ?? [], isDark)),

                if (!hasAnyProfessionals) ...[
                  SliverToBoxAdapter(child: _buildEmptyState(isDark)),
                ] else ...[
                  _buildProSection(t.homeTopRatedProfessionals, topRated,
                      icon: Icons.star_rounded,
                      limit: 10,
                      badgeTag: t.homeTopRatedLabel,
                      badgeIcon: Icons.emoji_events_rounded,
                      badgeColor: AppColors.badgeTopRated,
                      isDark: isDark),

                  ..._buildNearbySection(nearby, home.feedNearbyMeta ?? {}, isDark),

                  SliverToBoxAdapter(
                    child: CtaBanner(
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen(initialRole: 'professional')),
                      ),
                    ),
                  ),

                  _buildProSection(t.homeTrendingThisWeek, trending,
                      icon: Icons.trending_up_rounded,
                      limit: 10,
                      badgeTag: t.homeTrendingLabel,
                      badgeIcon: Icons.trending_up_rounded,
                      badgeColor: AppColors.badgeTrending,
                      headerTopPadding: AppSizes.sm,
                      isDark: isDark),
                  _buildProSection(t.homePopularProfessionals, popular,
                      icon: Icons.local_fire_department_rounded,
                      limit: 10,
                      badgeTag: t.homePopularLabel,
                      badgeIcon: Icons.local_fire_department_rounded,
                      badgeColor: AppColors.badgePopular,
                      isDark: isDark),
                  _buildProSection(t.homeRecentlyAdded, recentlyAdded,
                      icon: Icons.new_releases_rounded,
                      limit: 10,
                      badgeTag: t.homeNewLabel,
                      badgeIcon: Icons.fiber_new_rounded,
                      badgeColor: AppColors.badgeNew,
                      isDark: isDark),
                ],

                SliverToBoxAdapter(
                  child: _buildSectionHeader(t.homeFromTheMagazine,
                      onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MagazineScreen()),
                        );
                      }),
                ),
                SliverToBoxAdapter(child: _buildMagazineSection(isDark)),

                SliverToBoxAdapter(child: _buildLoginBanner(isDark)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _num(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  void _openSearch({int? categoryId, String? categoryName}) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          initialCategoryId: categoryId,
          initialCategoryName: categoryName,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHeader(List<dynamic> pros, bool isDark) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding, AppSizes.md, AppSizes.screenPadding, AppSizes.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  AppColors.heroGradientDark1,
                  AppColors.heroGradientDark2,
                  AppColors.heroGradientDark3,
                ]
              : [
                  AppColors.heroGradientLight1,
                  AppColors.heroGradientLight2,
                  context.colors.primary,
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          t.homeWelcomeGuest,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.appTagline,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              _headerIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () => _requireLogin(t.homeNotificationsSignInMessage),
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _headerIconButton(
                icon: Icons.search_rounded,
                onTap: _openSearch,
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _requireLogin(t.homeSetUpProfileMessage),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.08),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.white,
          size: 22,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HERO SEARCH
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHeroSearch(bool isDark) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding, 0, AppSizes.screenPadding, AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  AppColors.heroGradientDark1,
                  AppColors.heroGradientDark2,
                  AppColors.heroGradientDark3,
                ]
              : [
                  AppColors.heroGradientLight1,
                  AppColors.heroGradientLight2,
                  context.colors.primary,
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.homeWhatAreYouLookingForToday,
            style: AppTextStyles.h1.copyWith(
              color: AppColors.white,
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          GestureDetector(
            onTap: _openSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: isDark
                    ? Border.all(color: Colors.white.withOpacity(0.1))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: context.colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.homeSearchDoctorsLawyersPlumbers,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.6)
                            : context.colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          color: AppColors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t.homeFilter,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUICK ACTION CHIPS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildQuickActionChips(List<dynamic> categories, bool isDark) {
    final t = AppLocalizations.of(context)!;
    final top = categories.take(6).toList();
    return Container(
      color: context.colors.background,
      padding: const EdgeInsets.only(top: AppSizes.md, bottom: AppSizes.sm),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          itemCount: top.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            if (i == 0) {
              return _chip(
                t.homeTrendingLabel,
                context.colors.primary,
                filled: true,
                icon: Icons.trending_up_rounded,
                onTap: () => _openSearch(),
                isDark: isDark,
              );
            }
            final cat = top[i - 1] as Map;
            return _chip(
              cat['name']?.toString() ?? '',
              context.colors.primary,
              onTap: () => _openSearch(
                categoryId: cat['id'] is int
                    ? cat['id']
                    : int.tryParse('${cat['id']}'),
                categoryName: cat['name']?.toString(),
              ),
              isDark: isDark,
            );
          },
        ),
      ),
    );
  }

  Widget _chip(String label, Color color,
      {bool filled = false, IconData? icon, VoidCallback? onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color : context.colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: filled
                ? color
                : isDark
                    ? Colors.white.withOpacity(0.1)
                    : context.colors.divider,
            width: 1.5,
          ),
          boxShadow: filled
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: filled ? AppColors.white : context.colors.textPrimary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: filled ? AppColors.white : context.colors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSectionHeader(String title,
      {IconData? icon, String? caption, VoidCallback? onViewAll, double? topPadding}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSizes.screenPadding,
          topPadding ?? AppSizes.lg, AppSizes.screenPadding, AppSizes.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textStyles.h3.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.homeViewAll,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: context.colors.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // POPULAR CATEGORIES
  // ═══════════════════════════════════════════════════════════════════
  void _showAllCategories(List<dynamic> categories, bool isDark) {
    if (!mounted) return;
    showAllCategoriesSheet(
      context,
      categories: categories,
      isDark: isDark,
      onCategoryTap: (cat) => _openSearch(
        categoryId: cat['id'] is int ? cat['id'] : int.tryParse('${cat['id']}'),
        categoryName: cat['name']?.toString(),
      ),
    );
  }

  Widget _buildPopularCategories(List<dynamic> categories, bool isDark) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: PopularCategoriesGrid(
        categories: categories,
        isDark: isDark,
        limit: 8,
        onCategoryTap: (cat) => _openSearch(
          categoryId: cat['id'] is int ? cat['id'] : int.tryParse('${cat['id']}'),
          categoryName: cat['name']?.toString(),
        ),
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════════
  // FEATURED CATEGORIES
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFeaturedCategories(List<dynamic> categories, bool isDark) {
    final items = categories.take(6).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final gradients = CategoryStyles.featuredGradients;
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final cat = items[i] as Map;
          final style = CategoryStyles.forName(cat['name']?.toString() ?? '', i);
          return FeaturedCategoryCard(
            title: cat['name']?.toString() ?? '',
            icon: style.icon,
            gradient: gradients[i % gradients.length],
            onTap: () => _openSearch(
              categoryId: cat['id'] is int
                  ? cat['id']
                  : int.tryParse('${cat['id']}'),
              categoryName: cat['name']?.toString(),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // NEARBY PROFESSIONALS SECTION
  // ═══════════════════════════════════════════════════════════════════
  List<Widget> _buildNearbySection(
      List<dynamic> nearby, Map<String, dynamic> meta, bool isDark) {
    final t = AppLocalizations.of(context)!;
    final source = meta['results_source'] as String?;
    final unavailableMessage = meta['city_unavailable_message'] as String?;
    final otherCitiesLabel = meta['other_cities_section'] as String?;
    final locationLabel = meta['location_label'] as String?;

    String title = t.nearbyProfessionals;
    IconData icon = Icons.near_me_rounded;
    String? caption;
    String? bannerLine1;
    String? bannerLine2;
    String badgeTag = t.homeNearbyLabel;
    IconData badgeIcon = Icons.near_me_rounded;
    Color badgeColor = context.colors.primary;

    switch (source) {
      case 'radius':
        if (locationLabel != null) caption = t.homeNearLocation(locationLabel);
        break;
      case 'saved_city':
        if (locationLabel != null) title = t.homeProfessionalsInLocation(locationLabel);
        break;
      case 'popular':
        title = t.homePopularProfessionals;
        icon = Icons.local_fire_department_rounded;
        badgeTag = t.homePopularLabel;
        badgeIcon = Icons.local_fire_department_rounded;
        badgeColor = AppColors.badgePopular;
        break;
      case 'nearest_by_distance':
        title = t.homeClosestProfessionals;
        break;
      case 'nationwide':
        title = otherCitiesLabel ?? t.homeTopRatedProfessionalsNationwide;
        icon = Icons.public_rounded;
        bannerLine1 = unavailableMessage;
        badgeTag = t.homeTopRatedLabel;
        badgeIcon = Icons.emoji_events_rounded;
        badgeColor = AppColors.badgeTopRated;
        break;
    }

    return [
      if (bannerLine1 != null)
        SliverToBoxAdapter(
          child: _buildLocationFallbackBanner(bannerLine1, bannerLine2, isDark),
        ),
      _buildProSection(title, nearby,
          icon: icon,
          caption: caption,
          badgeTag: badgeTag,
          badgeIcon: badgeIcon,
          badgeColor: badgeColor,
          isDark: isDark),
    ];
  }

  String? _mostCommonCity(List<dynamic> list) {
    final counts = <String, int>{};
    for (final p in list) {
      final city = (p as Map)['city']?.toString().trim();
      if (city == null || city.isEmpty) continue;
      counts[city] = (counts[city] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  Widget _buildLocationFallbackBanner(String line1, String? line2, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding, AppSizes.sm, AppSizes.screenPadding, 0),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary.withOpacity(isDark ? 0.15 : 0.08),
            context.colors.primary.withOpacity(isDark ? 0.05 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.primary.withOpacity(isDark ? 0.2 : 0.12),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line1,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (line2 != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    line2,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PROFESSIONAL SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProSection(String title, List<dynamic> list,
      {IconData? icon,
      String? caption,
      int? limit,
      String? badgeTag,
      IconData? badgeIcon,
      Color? badgeColor,
      double? headerTopPadding,
      required bool isDark}) {
    if (list.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final items = limit != null ? list.take(limit).toList() : list;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
            child: _buildSectionHeader(title,
                icon: icon, caption: caption, topPadding: headerTopPadding)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: ProfessionalCard.heightFor(context),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _buildProfessionalCard(
                items[i] as Map,
                badgeTag: badgeTag,
                badgeIcon: badgeIcon,
                badgeColor: badgeColor,
                isDark: isDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PROFESSIONAL CARD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProfessionalCard(Map pro,
      {String? badgeTag,
      IconData? badgeIcon,
      Color? badgeColor,
      required bool isDark}) {
    final t = AppLocalizations.of(context)!;
    final id = pro['id']?.toString() ?? '';
    final name = pro['name']?.toString() ?? 'Professional';
    final isFav = _favourites.contains(id);
    return RepaintBoundary(
      child: ProfessionalCard(
        pro: pro,
        sectionTag: badgeTag,
        sectionTagIcon: badgeIcon,
        sectionTagColor: badgeColor,
        isFavorite: isFav,
        onFavoriteToggle: () => _requireLogin(t.homeLoginToSaveFavourites),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfessionalDetailScreen(
                professional: Map<String, dynamic>.from(pro)),
          ),
        ),
        onBookNow: () => _requireLogin(t.homeLoginToBookName(name)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MAGAZINE SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMagazineSection(bool isDark) {
    if (_articlesLoading) {
      return SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, __) => Container(
            width: 240,
            decoration: BoxDecoration(
              color: context.colors.divider.withOpacity(isDark ? 0.2 : 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }
    if (_articles.isEmpty) return const SizedBox.shrink();
    final items = _articles.take(6).toList();
    final textScaler =
        MediaQuery.textScalerOf(context).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15);
    final cardHeight = 190 + (textScaler.scale(1.0) - 1.0) * 50;
    return SizedBox(
      height: cardHeight,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            final a = items[i];
            final cover = AppHelpers.getFullImageUrl(a.coverImage);
            return GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(slug: a.slug))),
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : context.colors.divider.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18)),
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        color: context.colors.primaryLight,
                        child: cover.isNotEmpty
                            ? Image.network(
                                cover,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.menu_book_rounded,
                                  color: context.colors.primary,
                                  size: 40,
                                ),
                              )
                            : Icon(
                                Icons.menu_book_rounded,
                                color: context.colors.primary,
                                size: 40,
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: context.colors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: context.colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.magazineMinRead('${a.readTime}'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: context.colors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.homeArticleLabel,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LOGIN BANNER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildLoginBanner(bool isDark) {
    final t = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding, AppSizes.md, AppSizes.screenPadding, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary.withOpacity(isDark ? 0.15 : 0.08),
            context.colors.primary.withOpacity(isDark ? 0.05 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.colors.primary.withOpacity(isDark ? 0.2 : 0.12),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.waving_hand_rounded,
              color: context.colors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.homeUnlockFullExperience,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.colors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  t.homeBookProfessionalsSaveFavouritesTrackRequests,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: Text(
              t.login,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // EMPTY & LOADING STATES
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildEmptyState(bool isDark) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(isDark ? 0.1 : 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.travel_explore_rounded,
              size: 64,
              color: context.colors.primary.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t.homeNoProfessionalsNearbyYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.homeTrySearchingCategoryCheckBackSoon,
            style: TextStyle(
              fontSize: 14,
              color: context.colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: _openSearch,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              t.homeSearchNow,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: context.colors.divider.withOpacity(isDark ? 0.2 : 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
        );
    return Padding(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(160, 22),
          Row(children: [
            bar(70, 70),
            const SizedBox(width: 12),
            bar(70, 70),
            const SizedBox(width: 12),
            bar(70, 70),
            const SizedBox(width: 12),
            bar(70, 70),
          ]),
          const SizedBox(height: 20),
          bar(140, 20),
          SizedBox(
            height: 280,
            child: Row(children: [
              Expanded(child: bar(double.infinity, 280)),
              const SizedBox(width: 14),
              Expanded(child: bar(double.infinity, 280)),
            ]),
          ),
        ],
      ),
    );
  }
}