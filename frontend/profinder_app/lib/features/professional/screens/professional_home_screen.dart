import '../widgets/featured_promotion_sheet.dart';
import '../../payments/services/payment_service.dart';
// lib/features/professional/screens/professional_home_screen.dart

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_text_styles.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import 'professional_main_screen.dart';
import 'professional_portfolio_screen.dart';
import 'professional_wallet_screen.dart';
import 'professional_reviews_screen.dart';
import 'professional_availability_screen.dart';
import '../../chat/presentation/screens/chat_screen.dart';
import '../../chat/data/models/conversation_model.dart';
import '../../subscription/widgets/promo_banner_mixin.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../shared/widgets/cta_banner.dart';
import '../../../shared/widgets/announcement_banner.dart';
import '../../../shared/widgets/display_ad_banner.dart';
import '../../../shared/widgets/role_app_bar.dart';
import '../../../l10n/generated/app_localizations.dart';

class ProfessionalHomeScreen extends StatefulWidget {
  final bool isVisible;

  const ProfessionalHomeScreen({super.key, this.isVisible = true});

  @override
  State<ProfessionalHomeScreen> createState() => _ProfessionalHomeScreenState();
}

class _ProfessionalHomeScreenState extends State<ProfessionalHomeScreen>
    with PromoBannerMixin {
  final _api = ApiService();

  Map<String, dynamic>? _dashboard;
  List<dynamic> _portfolio = [];
  List<dynamic> _recentReviews = [];
  List<dynamic> _recentConversations = [];
  List<dynamic> _allBookings = [];
  DateTime _selectedCalendarDate = DateTime.now();
  Map<String, dynamic>? _myPlan;
  Map<String, dynamic>? _featuredStatus;
  Map<String, dynamic> _proProfile = {};
  int? _myUserId;
  bool _isTogglingAvailability = false;
  bool _isLoading = true;
  String? _error;

  int _profileCompletion = 0;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  bool _bannerTriggered = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
    _loadData();
    if (widget.isVisible && !_bannerTriggered) {
      _bannerTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showBannerForScreen('home');
      });
    }
  }

  @override
  void didUpdateWidget(covariant ProfessionalHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVisible && widget.isVisible && !_bannerTriggered) {
      _bannerTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showBannerForScreen('home');
      });
    }
    if (!oldWidget.isVisible && widget.isVisible) {
      _loadData();
    }
  }

  int _calculateCompletion(
    Map<String, dynamic> proProfile,
    Map<String, dynamic> userProfile,
    List<dynamic> portfolio,
  ) {
    int filled = 0;
    const total = 8;

    if ((proProfile['photo_url'] ?? '').toString().isNotEmpty) filled++;
    if ((proProfile['bio'] ?? '').toString().trim().isNotEmpty) filled++;
    if ((userProfile['city'] ?? '').toString().trim().isNotEmpty) filled++;
    if ((userProfile['phone'] ?? '').toString().trim().isNotEmpty) filled++;
    if ((proProfile['hourly_rate'] ?? 0).toString() != '0' &&
        (proProfile['hourly_rate'] ?? '').toString().isNotEmpty) {
      filled++;
    }
    if ((proProfile['experience_years'] ?? 0).toString() != '0' &&
        (proProfile['experience_years'] ?? '').toString().isNotEmpty) {
      filled++;
    }
    if ((proProfile['skills'] ?? '').toString().trim().isNotEmpty) filled++;
    if (portfolio.isNotEmpty) filled++;

    return ((filled / total) * 100).round();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.get(AppConstants.professionalDashboard),
        _api.get(AppConstants.portfolio),
        _api.get(AppConstants.professionalProfile),
        _api.get(AppConstants.userProfile),
        _api.get(AppConstants.reviews),
        _api.get(AppConstants.myPlan),
        _api.get(AppConstants.conversations),
        _api.get(AppConstants.professionalBookings),
        _api.get(AppConstants.me),
      ]);
      final featuredStatus = await PaymentService().getFeaturedStatus();

      if (!mounted) return;

      final dashboard = results[0].data as Map<String, dynamic>;
      final portfolio = results[1].data is List ? results[1].data as List : [];
      final proProfile = results[2].data is Map
          ? results[2].data as Map<String, dynamic>
          : <String, dynamic>{};
      final userProfile = results[3].data is Map
          ? results[3].data as Map<String, dynamic>
          : <String, dynamic>{};
      final reviewsData = results[4].data;
      final reviewsList = reviewsData is List
          ? reviewsData
          : (reviewsData is Map
                ? (reviewsData['results'] ?? reviewsData['reviews'] ?? [])
                      as List
                : []);
      final myPlan = results[5].data is Map
          ? results[5].data as Map<String, dynamic>
          : <String, dynamic>{};
      final conversations = results[6].data is List
          ? results[6].data as List
          : [];
      final bookingsData = results[7].data;
      final bookingsList = bookingsData is Map
          ? (bookingsData['bookings'] ?? []) as List
          : [];
      final meData = results[8].data is Map
          ? results[8].data as Map<String, dynamic>
          : <String, dynamic>{};

      setState(() {
        _dashboard = dashboard;
        _portfolio = portfolio.take(4).toList();
        _recentReviews = reviewsList.take(3).toList();
        _recentConversations = conversations.take(3).toList();
        _allBookings = bookingsList;
        _myPlan = myPlan;
        _proProfile = proProfile;
        _featuredStatus = featuredStatus;
        _myUserId = int.tryParse(meData['id']?.toString() ?? '');
        _profileCompletion = _calculateCompletion(
          proProfile,
          userProfile,
          portfolio,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = AppLocalizations.of(context).dashboardLoadError;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    setState(() => _searchQuery = query);

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final res = await _api.get(
          '${AppConstants.professionalBookings}?search=$query',
        );
        if (!mounted || _searchQuery != query) return;
        final data = res.data;
        final list = data is Map
            ? (data['bookings'] ?? []) as List
            : (data as List);
        setState(() {
          _searchResults = list;
          _isSearching = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSearching = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSearchMode = _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: AppColors.professionalColor,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).loadingDashboard,
                      style: TextStyle(
                        fontSize: AppFontSizes.body,
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.professionalColor,
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: AnnouncementBanner(audience: 'professional'),
                    ),
                    _buildAppBar(),
                    SliverToBoxAdapter(child: _buildGreetingAndKpis(isDark)),
                    SliverToBoxAdapter(child: _buildSearchBar(isDark)),
                    const SliverToBoxAdapter(
                      child: DisplayAdBanner(placementSlot: 'homepage_masthead'),
                    ),
                    if (isSearchMode)
                      SliverToBoxAdapter(child: _buildSearchResults(isDark))
                    else ...[
                      if (_error != null)
                        SliverToBoxAdapter(child: _buildErrorBanner(isDark)),
                      SliverToBoxAdapter(
                        child: _buildProfileCompletionCard(isDark),
                      ),
                      SliverToBoxAdapter(
                        child: _buildSubscriptionUpgradeBanner(isDark),
                      ),
                      SliverToBoxAdapter(
                        child: _buildVerificationBanner(isDark),
                      ),
                      SliverToBoxAdapter(
                        child: _buildFeaturedPromotionSection(isDark),
                      ),
                      SliverToBoxAdapter(child: _buildQuickActions(isDark)),
                      SliverToBoxAdapter(child: _buildEarningsSection(isDark)),
                      SliverToBoxAdapter(child: _buildStatsGrid(isDark)),
                      SliverToBoxAdapter(child: _buildQuickProfileCard(isDark)),
                      SliverToBoxAdapter(
                        child: _buildTodaysScheduleSection(isDark),
                      ),
                      SliverToBoxAdapter(child: _buildCalendarSection(isDark)),
                      SliverToBoxAdapter(child: _buildPortfolioSection(isDark)),
                      SliverToBoxAdapter(
                        child: _buildRecentMessagesSection(isDark),
                      ),
                      SliverToBoxAdapter(
                        child: _buildRecentReviewsSection(isDark),
                      ),
                      SliverToBoxAdapter(
                        child: _buildRecentBookingsSection(isDark),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
      ),
    );
  }

  // ── AppBar (logo + notifications + profile avatar only) ──────────────
  Widget _buildAppBar() {
    final header = _dashboard?['header'] as Map<String, dynamic>? ?? {};
    final fullName =
        (header['name'] ?? AppLocalizations.of(context).professionalDefaultName)
            .toString();
    final photo = header['photo_url'];
    final unread = (_dashboard?['unread_notifications'] ?? 0) as int;
    return ProfessionalAppBar(
      name: fullName,
      photoUrl: (photo != null && photo.toString().isNotEmpty)
          ? AppHelpers.getFullImageUrl(photo.toString())
          : null,
      unreadCount: unread,
      isVerified: header['is_verified'] == true,
      onNotifications: () => Navigator.pushNamed(context, '/notifications'),
      onProfile: () => ProfessionalMainScreen.switchTab(5), // Profile tab
    );
  }

  // ── Greeting + KPI strip (page content, not AppBar) ──────────────────
  Widget _buildGreetingAndKpis(bool isDark) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final header = _dashboard?['header'] as Map<String, dynamic>? ?? {};
    final fullName = (header['name'] ?? t.professionalDefaultName).toString();
    final isVerified = header['is_verified'] ?? false;
    final category =
        (header['category_name'] ?? _proProfile['category_name'] ?? '')
            .toString();

    final stats = _dashboard?['stats'] as Map<String, dynamic>? ?? {};
    final rating = _dashboard?['rating'] as Map<String, dynamic>? ?? {};
    // Direct dealing model - in-app wallet balance tracking is disabled
    // final earnings = _dashboard?['earnings'] as Map<String, dynamic>? ?? {};
    final totalBookings = _allBookings.isNotEmpty
        ? _allBookings.length
        : ((stats['pending_bookings'] ?? 0) as int) +
              ((stats['accepted_bookings'] ?? 0) as int) +
              ((stats['completed_bookings'] ?? 0) as int);
    final avgRating = (rating['average'] ?? 0).toDouble();
    final clientsCount = _allBookings
        .map((b) => (b['customer_id'] ?? b['customer_name'] ?? '').toString())
        .where((c) => c.isNotEmpty)
        .toSet()
        .length;

    const accent = AppColors.professionalColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoleGreeting(
          greeting: roleTimeGreeting(context),
          name: fullName,
          subtitle: t.proReadyToGrowToday,
          footer: (category.isNotEmpty || isVerified == true)
              ? Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_categoryIcon(category), color: accent, size: 14),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          category.isNotEmpty
                              ? AppHelpers.localizedCategoryName(
                                  context,
                                  category,
                                )
                              : t.verifiedProfessionalLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppFontSizes.secondary,
                            fontWeight: FontWeight.w600,
                            color: accent,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: c.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _headerStat(
                    Icons.calendar_month_rounded,
                    '$totalBookings',
                    t.totalBookingsLabel,
                  ),
                ),
                _headerStatDivider(),
                Expanded(
                  child: _headerStat(
                    Icons.star_rounded,
                    avgRating > 0 ? avgRating.toStringAsFixed(1) : '—',
                    t.ratingLabel,
                  ),
                ),
                _headerStatDivider(),
                Expanded(
                  child: _headerStat(
                    Icons.people_alt_rounded,
                    _formatCompactNumber(clientsCount),
                    t.clientsLabel,
                  ),
                ),
                _headerStatDivider(),
                Expanded(
                  child: _headerStat(
                    Icons.mark_email_read_rounded,
                    _formatCompactNumber(totalBookings),
                    'Inquiries',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerStat(IconData icon, String value, String label) {
    final c = context.colors;
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.professionalColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.professionalColor, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppFontSizes.caption,
            color: c.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _headerStatDivider() =>
      Container(width: 1, height: 34, color: context.colors.divider);

  String _formatCompactNumber(int n) {
    if (n < 1000) return '$n';
    final k = n / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
  }

  // ignore: unused_element
  String _formatMoney(double amount) {
    final rounded = amount.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  IconData _categoryIcon(String profession) {
    final p = profession.toLowerCase();
    if (p.contains('tutor') || p.contains('educat') || p.contains('teach')) {
      return Icons.menu_book_rounded;
    }
    if (p.contains('doctor') || p.contains('medic') || p.contains('health')) {
      return Icons.medical_services_outlined;
    }
    if (p.contains('lawyer') || p.contains('legal')) {
      return Icons.gavel_outlined;
    }
    if (p.contains('engineer')) {
      return Icons.engineering_outlined;
    }
    if (p.contains('plumb')) {
      return Icons.plumbing_outlined;
    }
    if (p.contains('electric')) {
      return Icons.electrical_services;
    }
    if (p.contains('clean')) {
      return Icons.cleaning_services;
    }
    if (p.contains('carpent')) {
      return Icons.carpenter;
    }
    if (p.contains('paint')) {
      return Icons.format_paint_outlined;
    }
    if (p.contains('architect')) {
      return Icons.architecture;
    }
    if (p.contains('account') || p.contains('financ')) {
      return Icons.account_balance_outlined;
    }
    if (p.contains('comput') ||
        p.contains('it ') ||
        p.contains('developer') ||
        p.contains('software')) {
      return Icons.computer_outlined;
    }
    if (p.contains('beauty') || p.contains('salon') || p.contains('makeup')) {
      return Icons.face_retouching_natural_outlined;
    }
    if (p.contains('fitness') || p.contains('trainer') || p.contains('gym')) {
      return Icons.fitness_center_outlined;
    }
    if (p.contains('photo')) {
      return Icons.camera_alt_outlined;
    }
    return Icons.work_outline_rounded;
  }

  // ── Search Bar ──────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    final isFocused = _searchFocusNode.hasFocus;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isFocused
                ? AppColors.professionalColor
                : isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.15),
            width: isFocused ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: isFocused
                  ? AppColors.professionalColor
                  : context.colors.textSecondary.withValues(alpha: 0.5),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).searchBookingsHint,
                  hintStyle: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: context.colors.textSecondary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_isSearching)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.professionalColor,
                ),
              )
            else if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _searchResults = [];
                  _debounce?.cancel();
                }),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.colors.divider.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: context.colors.textSecondary,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Search Results ──────────────────────────────────────
  Widget _buildSearchResults(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSearching
                ? AppLocalizations.of(context).searchingLabel
                : AppLocalizations.of(context).searchResultsLabel(
                    _searchResults.length,
                    _searchController.text,
                  ),
            style: TextStyle(
              fontSize: AppFontSizes.secondary,
              fontWeight: FontWeight.w500,
              color: context.colors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          if (!_isSearching && _searchResults.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    color: context.colors.textSecondary.withValues(alpha: 0.3),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).noClientsFound,
                    style: TextStyle(
                      fontSize: AppFontSizes.body,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).adjustSearchTerms,
                    style: TextStyle(
                      fontSize: AppFontSizes.small,
                      color: context.colors.textSecondary.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._searchResults.map((b) => _buildBookingTile(b, isDark)),
        ],
      ),
    );
  }

  // ── Subscription Upgrade Banner ──────────────────────
  // Uses the shared CtaBanner component to prompt free-tier users to upgrade.
  Widget _buildSubscriptionUpgradeBanner(bool isDark) {
    final isPremium = _myPlan?['is_premium'] == true;
    if (isPremium) return const SizedBox.shrink();

    final planName = _myPlan?['plan_name'] ?? 'Free';

    return CtaBanner(
      isDark: isDark,
      title: AppLocalizations.of(context).planUpgradeTitle(planName),
      subtitle: AppLocalizations.of(context).planUpgradeSubtitle,
      ctaLabel: AppLocalizations.of(context).upgradeCta,
      icon: Icons.workspace_premium_rounded,
      accentStart: AppColors.violet400,
      accentEnd: AppColors.professionalColor,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SubscriptionScreen(userRole: 'professional'),
        ),
      ),
    );
  }

  // ── Profile Completion Card ────────────────────────────
  Widget _buildProfileCompletionCard(bool isDark) {
    if (_profileCompletion >= 100) return const SizedBox.shrink();

    final color = _profileCompletion < 50
        ? AppColors.error
        : (_profileCompletion < 80 ? AppColors.warning : context.colors.accent);

    return GestureDetector(
      onTap: () => ProfessionalMainScreen.switchTab(5),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.04),
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
                Text(
                  AppLocalizations.of(context).profileCompletionLabel,
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  '$_profileCompletion%',
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusXs),
              child: LinearProgressIndicator(
                value: _profileCompletion / 100,
                minHeight: 6,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : context.colors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).profileCompletionHint,
              style: TextStyle(
                fontSize: AppFontSizes.caption,
                color: context.colors.textSecondary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error Banner ──────────────────────────────────────
  Widget _buildErrorBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.red950.withValues(alpha: 0.8)
            : AppColors.red50,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark
              ? AppColors.red800.withValues(alpha: 0.5)
              : AppColors.red200,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                fontSize: AppFontSizes.small,
                color: isDark ? AppColors.red300 : AppColors.error,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Verification Banner ──────────────────────────────
  Widget _buildVerificationBanner(bool isDark) {
    final header = _dashboard?['header'] as Map<String, dynamic>? ?? {};
    final isVerified = header['is_verified'] ?? false;
    final portCount = _portfolio.length;
    if (isVerified == true) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.amber950.withValues(alpha: 0.8)
            : AppColors.tintAmber,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark
              ? AppColors.amber900.withValues(alpha: 0.5)
              : AppColors.amber200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warningAmber,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              portCount == 0
                  ? AppLocalizations.of(context).verificationAddPortfolio
                  : AppLocalizations.of(context).verificationPending,
              style: TextStyle(
                fontSize: AppFontSizes.small,
                color: isDark ? AppColors.starGold : AppColors.amber800,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (portCount == 0)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfessionalPortfolioScreen(),
                ),
              ),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppLocalizations.of(context).addCta,
                style: TextStyle(
                  fontSize: AppFontSizes.small,
                  color: AppColors.warningAmber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────
  // ── Featured Listing Promotion Section (Safepay) ─────────────
  Widget _buildFeaturedPromotionSection(bool isDark) {
    final hasActive = _featuredStatus?['has_active_promotion'] == true;
    final activeCamp = _featuredStatus?['active_campaign'] as Map<String, dynamic>?;
    final history = (_featuredStatus?['history'] as List?) ?? [];

    if (hasActive && activeCamp != null) {
      final catName = activeCamp['category_name'] ?? 'Your Category';
      final pkgName = activeCamp['package_name'] ?? 'Featured Listing';
      final remainingDays = activeCamp['remaining_days'] ?? 0;
      final remainingHours = activeCamp['remaining_hours'] ?? 0;
      final expiryStr = activeCamp['end_date_formatted'] ?? 'Soon';
      final orderId = activeCamp['order_id'] ?? '';

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2E2413), const Color(0xFF1E1E28)]
                  : [const Color(0xFFFFFBEB), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.6 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 16),
                        SizedBox(width: 4),
                        Text(
                          'FEATURED ACTIVE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text(
                          remainingDays > 0 ? '$remainingDays days left' : '$remainingHours hrs left',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Pinned at Top of $catName',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your profile is currently featured and pinned at the top of category search results.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.amber.shade50.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Active Package: $pkgName • Expires: $expiryStr',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade300 : const Color(0xFF78350F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (orderId.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Safepay Verified Transaction: $orderId',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey.shade400,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showPromotionHistoryModal(context, history),
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text('Campaign History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      side: const BorderSide(color: Color(0xFFD97706)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final catName = _proProfile['category']?['name'] ?? _proProfile['category_name'] ?? _featuredStatus?['default_category_name'] ?? 'Your Category';
    final catId = _proProfile['category_id'] ?? _featuredStatus?['default_category_id'] ?? 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF282116)]
                : [Colors.white, const Color(0xFFFFFBEB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.4 : 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Color(0xFFD97706),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Promote My Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pin your profile to the top of $catName search',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _promoPill('⭐ Pinned Top Placement', isDark),
                _promoPill('🚀 Up to 5x More Inquiries', isDark),
                _promoPill('💳 Safepay Pakistan', isDark),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      FeaturedPromotionSheet.show(
                        context,
                        defaultCategoryId: catId,
                        defaultCategoryName: catName,
                        onPromotionActivated: _loadData,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Promote Now • from Rs. 99',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                if (history.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Promotion History',
                    onPressed: () => _showPromotionHistoryModal(context, history),
                    icon: const Icon(Icons.history_rounded, color: Color(0xFFD97706)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _promoPill(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFEF3C7).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.amber.shade200 : const Color(0xFF92400E),
        ),
      ),
    );
  }

  void _showPromotionHistoryModal(BuildContext context, List history) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.history_rounded, color: Color(0xFFD97706)),
                SizedBox(width: 8),
                Text(
                  'Promotion History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('No previous featured promotions found.')),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (ctx, i) {
                    final item = history[i] as Map<String, dynamic>;
                    final pkg = item['package_name'] ?? 'Promotion';
                    final cat = item['category_name'] ?? '';
                    final amt = item['amount'] ?? '0';
                    final date = item['created_at'] ?? '';
                    final isActive = item['is_active'] == true;
                    final status = item['payment_status'] ?? 'unknown';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isActive
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        child: Icon(
                          isActive ? Icons.star_rounded : Icons.star_border_rounded,
                          color: isActive ? const Color(0xFF059669) : Colors.grey,
                        ),
                      ),
                      title: Text(
                        '$pkg ($cat)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Date: $date • Status: $status • PKR $amt',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'COMPLETED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? const Color(0xFF059669) : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).quickActionsLabel,
            style: TextStyle(
              fontSize: AppFontSizes.title,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionCard(
                icon: Icons.calendar_today_outlined,
                label: AppLocalizations.of(context).bookingsLabel,
                color: AppColors.primary,
                onTap: () => ProfessionalMainScreen.switchTab(1),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _actionCard(
                icon: Icons.photo_library_outlined,
                label: AppLocalizations.of(context).portfolioLabel,
                color: AppColors.professionalColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfessionalPortfolioScreen(),
                  ),
                ),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _actionCard(
                icon: Icons.person_outline_rounded,
                label: AppLocalizations.of(context).profileLabel,
                color: AppColors.successDeep,
                onTap: () => ProfessionalMainScreen.switchTab(5),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _actionCard(
                icon: Icons.account_balance_wallet_outlined,
                label: AppLocalizations.of(context).walletLabel,
                color: AppColors.warningAmber,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfessionalWalletScreen(),
                  ),
                ),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final badgeGradient = [Color.lerp(color, Colors.white, 0.15)!, color];

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : color.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.15)
                    : color.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: badgeGradient,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppFontSizes.caption,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Direct Settlement & Service Performance Section ───────────────────
  Widget _buildEarningsSection(bool isDark) {
    final stats = _dashboard?['stats'] as Map<String, dynamic>? ?? {};
    final pendingCount = (stats['pending_bookings'] ?? 0).toInt();
    final acceptedCount = (stats['accepted_bookings'] ?? 0).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Direct Settlement Model',
                style: TextStyle(
                  fontSize: AppFontSizes.title,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.professionalColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '0% Commission',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.professionalColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Direct Client Dealing',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep 100% of your earnings. Clients pay you directly with zero deduction.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.handshake_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _earningsMiniCard(
                  'Pending Inquiries',
                  pendingCount.toDouble(),
                  Icons.mark_email_unread_rounded,
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _earningsMiniCard(
                  'Accepted Inquiries',
                  acceptedCount.toDouble(),
                  Icons.thumb_up_alt_rounded,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _earningsHeroCard(String label, double amount, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfessionalWalletScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.successDeep, AppColors.emerald],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -36,
              top: -52,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              right: 70,
              bottom: -64,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: AppFontSizes.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Rs ${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSizes.display,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _earningsMiniCard(
    String label,
    double amount,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.professionalColor, size: 18),
          const SizedBox(height: 8),
          Text(
            'Rs ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: AppFontSizes.title2,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSizes.caption,
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Grid ─────────────────────────────────────────
  Widget _buildStatsGrid(bool isDark) {
    final stats = _dashboard?['stats'] as Map<String, dynamic>? ?? {};
    final rating = _dashboard?['rating'] as Map<String, dynamic>? ?? {};

    final pending = stats['pending_bookings'] ?? 0;
    final accepted = stats['accepted_bookings'] ?? 0;
    final completed = stats['completed_bookings'] ?? 0;
    final avgRating = (rating['average'] ?? 0).toDouble();
    final totalRev = rating['total_reviews'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).performanceLabel,
            style: TextStyle(
              fontSize: AppFontSizes.title,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _dashboardCard(
                AppLocalizations.of(context).pendingLabel,
                '$pending',
                Icons.access_time_rounded,
                AppColors.warning,
                isDark,
              ),
              _dashboardCard(
                AppLocalizations.of(context).acceptedLabel,
                '$accepted',
                Icons.check_circle_outline_rounded,
                context.colors.primary,
                isDark,
              ),
              _dashboardCard(
                AppLocalizations.of(context).completedLabel,
                '$completed',
                Icons.task_alt_rounded,
                context.colors.accent,
                isDark,
              ),
              _dashboardCard(
                AppLocalizations.of(context).ratingLabel,
                '${avgRating.toStringAsFixed(1)} ($totalRev)',
                Icons.star_rounded,
                AppColors.warningAmber,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashboardCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.12)
                  : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFontSizes.caption,
                    color: context.colors.textSecondary,
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

  // ── Quick Profile Card ──────────────────────────────────
  Widget _buildQuickProfileCard(bool isDark) {
    final skillsRaw = (_proProfile['skills'] ?? '').toString();
    final skills = skillsRaw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final rate = _proProfile['hourly_rate']?.toString() ?? '0';
    final isAvailable = _proProfile['is_available'] ?? true;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.04),
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
              Text(
                AppLocalizations.of(context).skillsPricingLabel,
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              GestureDetector(
                onTap: () => ProfessionalMainScreen.switchTab(5),
                child: Text(
                  AppLocalizations.of(context).editLabel,
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: AppColors.professionalColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: context.colors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Rs $rate/hr',
                      style: TextStyle(
                        fontSize: AppFontSizes.secondary,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfessionalAvailabilityScreen(),
                      ),
                    ).then((_) => _loadData()),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isAvailable
                              ? AppLocalizations.of(context).availableLabel
                              : AppLocalizations.of(context).unavailableLabel,
                          style: TextStyle(
                            fontSize: AppFontSizes.small,
                            fontWeight: FontWeight.w600,
                            color: isAvailable
                                ? context.colors.accent
                                : context.colors.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: isAvailable
                              ? context.colors.accent
                              : context.colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _isTogglingAvailability
                      ? SizedBox(
                          width: 32,
                          height: 18,
                          child: Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.colors.accent,
                              ),
                            ),
                          ),
                        )
                      : Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: isAvailable,
                            activeThumbColor: context.colors.accent,
                            activeTrackColor: context.colors.accent.withValues(
                              alpha: 0.3,
                            ),
                            inactiveTrackColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.3),
                            onChanged: _toggleAvailability,
                          ),
                        ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (skills.isEmpty)
            Text(
              AppLocalizations.of(context).noSkillsAdded,
              style: TextStyle(
                fontSize: AppFontSizes.small,
                color: context.colors.textSecondary.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills
                  .take(6)
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.professionalColor.withValues(
                                alpha: 0.12,
                              )
                            : AppColors.professionalColor.withValues(
                                alpha: 0.06,
                              ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(
                          color: AppColors.professionalColor.withValues(
                            alpha: isDark ? 0.15 : 0.1,
                          ),
                        ),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: AppFontSizes.caption,
                          fontWeight: FontWeight.w500,
                          color: AppColors.professionalColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(bool value) async {
    final previous = _proProfile['is_available'] ?? true;
    setState(() {
      _proProfile = {..._proProfile, 'is_available': value};
      _isTogglingAvailability = true;
    });
    try {
      await _api.patchForm(
        AppConstants.professionalProfile,
        FormData.fromMap({'is_available': value.toString()}),
      );
      if (!mounted) return;
      AppHelpers.showSuccess(
        context,
        value
            ? AppLocalizations.of(context).availabilityOnSuccess
            : AppLocalizations.of(context).availabilityOffSuccess,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _proProfile = {..._proProfile, 'is_available': previous});
      AppHelpers.showError(
        context,
        AppLocalizations.of(context).availabilityUpdateError,
      );
    } finally {
      if (mounted) setState(() => _isTogglingAvailability = false);
    }
  }

  // ── Today's Schedule ──────────────────────────────────
  List<dynamic> _bookingsForDate(DateTime date) {
    return _allBookings
        .where((b) {
          final raw = b['date']?.toString();
          if (raw == null) return false;
          try {
            final d = DateTime.parse(raw);
            return d.year == date.year &&
                d.month == date.month &&
                d.day == date.day;
          } catch (_) {
            return false;
          }
        })
        .where((b) => b['status'] != 'cancelled' && b['status'] != 'rejected')
        .toList();
  }

  Widget _buildTodaysScheduleSection(bool isDark) {
    final today = DateTime.now();
    final todaysBookings = _bookingsForDate(today)
      ..sort(
        (a, b) => (a['time']?.toString() ?? '').compareTo(
          b['time']?.toString() ?? '',
        ),
      );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).todaysScheduleLabel,
            style: TextStyle(
              fontSize: AppFontSizes.title,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          if (todaysBookings.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).noBookingsToday,
                style: TextStyle(
                  fontSize: AppFontSizes.secondary,
                  color: context.colors.textSecondary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          else
            ...todaysBookings.map((b) => _buildScheduleTile(b, isDark)),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(dynamic booking, bool isDark) {
    final customerName =
        booking['customer_name']?.toString() ??
        AppLocalizations.of(context).customerDefault;
    final time = booking['time']?.toString() ?? '';
    final status = booking['status']?.toString() ?? 'pending';
    final statusColor = status == 'accepted'
        ? AppColors.emerald
        : (status == 'completed' ? AppColors.primary : AppColors.warningAmber);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.03),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: AppFontSizes.caption,
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
            ),
            child: Text(
              status.isEmpty ? status : AppHelpers.capitalize(status),
              style: TextStyle(
                fontSize: AppFontSizes.caption,
                fontWeight: FontWeight.w600,
                color: statusColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar ────────────────────────────────────────────
  Widget _buildCalendarSection(bool isDark) {
    final year = _selectedCalendarDate.year;
    final month = _selectedCalendarDate.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7;
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed: () => setState(
                  () => _selectedCalendarDate = DateTime(year, month - 1, 1),
                ),
                color: context.colors.textSecondary,
              ),
              Text(
                DateFormat.yMMMM(
                  Localizations.localeOf(context).toString(),
                ).format(DateTime(year, month, 1)),
                style: TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: () => setState(
                  () => _selectedCalendarDate = DateTime(year, month + 1, 1),
                ),
                color: context.colors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: AppLocalizations.of(context).calendarWeekDays
                .split('')
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: AppFontSizes.caption,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textSecondary.withValues(
                            alpha: 0.6,
                          ),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          ...List.generate(((daysInMonth + startWeekday) / 7).ceil(), (week) {
            return Row(
              children: List.generate(7, (weekday) {
                final dayNum = week * 7 + weekday - startWeekday + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 38));
                }
                final date = DateTime(year, month, dayNum);
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final hasBookings = _bookingsForDate(date).isNotEmpty;

                return Expanded(
                  child: Container(
                    height: 38,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.professionalColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: AppFontSizes.small,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isToday
                                ? Colors.white
                                : context.colors.textPrimary,
                          ),
                        ),
                        if (hasBookings)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isToday
                                  ? Colors.white
                                  : AppColors.professionalColor.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  // ── Portfolio Section ──────────────────────────────────
  Widget _buildPortfolioSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).myPortfolioLabel,
                style: TextStyle(
                  fontSize: AppFontSizes.title,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfessionalPortfolioScreen(),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).manageLabel,
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: AppColors.professionalColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_portfolio.isEmpty)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfessionalPortfolioScreen(),
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.professionalColor.withValues(alpha: 0.06)
                      : AppColors.professionalColor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: AppColors.professionalColor.withValues(
                      alpha: isDark ? 0.12 : 0.08,
                    ),
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.professionalColor.withValues(
                          alpha: isDark ? 0.12 : 0.06,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 22,
                        color: AppColors.professionalColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).addWorkSamplesLabel,
                            style: TextStyle(
                              fontSize: AppFontSizes.secondary,
                              fontWeight: FontWeight.w600,
                              color: AppColors.professionalColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppLocalizations.of(context).addPortfolioHint,
                            style: TextStyle(
                              fontSize: AppFontSizes.caption,
                              color: context.colors.textSecondary.withValues(
                                alpha: 0.6,
                              ),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.professionalColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _portfolio.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == _portfolio.length) {
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfessionalPortfolioScreen(),
                        ),
                      ),
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : AppColors.violet50,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : AppColors.violet200,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: AppColors.professionalColor,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context).addCta,
                              style: TextStyle(
                                fontSize: AppFontSizes.caption,
                                color: AppColors.professionalColor,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final item = _portfolio[i];
                  final imageUrl = item['image_url']?.toString();
                  final status = item['status']?.toString() ?? 'pending';

                  Color badgeColor;
                  switch (status) {
                    case 'approved':
                      badgeColor = context.colors.accent;
                      break;
                    case 'rejected':
                      badgeColor = AppColors.error;
                      break;
                    default:
                      badgeColor = AppColors.warning;
                  }

                  return Stack(
                    children: [
                      Container(
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          color: context.colors.divider,
                          image: imageUrl != null && imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(
                                    AppHelpers.getFullImageUrl(imageUrl),
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageUrl == null || imageUrl.isEmpty
                            ? Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: context.colors.textSecondary
                                      .withValues(alpha: 0.3),
                                  size: 28,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.black : Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Recent Messages ────────────────────────────────────
  Widget _buildRecentMessagesSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).recentMessagesLabel,
                style: TextStyle(
                  fontSize: AppFontSizes.title,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              GestureDetector(
                onTap: () => ProfessionalMainScreen.switchTab(2),
                child: Text(
                  AppLocalizations.of(context).seeAllLabel,
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: AppColors.professionalColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentConversations.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).noMessagesYet,
                style: TextStyle(
                  fontSize: AppFontSizes.secondary,
                  color: context.colors.textSecondary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          else
            ..._recentConversations.map(
              (c) => _buildMessagePreviewTile(c, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildMessagePreviewTile(dynamic conv, bool isDark) {
    final name =
        conv['other_user_name']?.toString() ??
        AppLocalizations.of(context).customerDefault;
    final lastMessage = conv['last_message']?.toString() ?? '';
    final unread = (conv['unread_count'] ?? 0) as int;
    final rawPhoto =
        (conv['other_user_photo'] ?? conv['photo_url'] ?? conv['photo'] ?? '')
            .toString();
    final photo = AppHelpers.getFullImageUrl(rawPhoto);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          onTap: _myUserId == null
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationId: conv['id'] is int
                          ? conv['id'] as int
                          : int.parse(conv['id'].toString()),
                      currentUserId: _myUserId!,
                      otherUserName: name,
                      otherUserPhoto: photo.isNotEmpty ? photo : null,
                      conversationSnapshot: ConversationModel.fromJson(
                        conv as Map<String, dynamic>,
                      ),
                    ),
                  ),
                ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.03),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 36,
                    height: 36,
                    color: context.colors.primaryLight,
                    child: photo.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photo,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            memCacheWidth: 100,
                            memCacheHeight: 100,
                            placeholder: (_, _) => const SizedBox(),
                            errorWidget: (context, error, stackTrace) => Center(
                              child: Text(
                                AppHelpers.getInitials(name),
                                style: TextStyle(
                                  fontSize: AppFontSizes.caption,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.primary,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              AppHelpers.getInitials(name),
                              style: TextStyle(
                                fontSize: AppFontSizes.caption,
                                fontWeight: FontWeight.w600,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: AppFontSizes.secondary,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastMessage.isEmpty
                            ? AppLocalizations.of(context).noMessagesPlaceholder
                            : lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppFontSizes.small,
                          fontWeight: unread > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: unread > 0
                              ? context.colors.textPrimary
                              : context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.professionalColor,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        fontSize: AppFontSizes.caption,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Recent Reviews ─────────────────────────────────────
  Widget _buildRecentReviewsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).recentReviewsLabel,
                style: TextStyle(
                  fontSize: AppFontSizes.title,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfessionalReviewsScreen(),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).seeAllLabel,
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: AppColors.professionalColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentReviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).noReviewsYet,
                style: TextStyle(
                  fontSize: AppFontSizes.secondary,
                  color: context.colors.textSecondary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          else
            ..._recentReviews.map((r) => _buildReviewTile(r, isDark)),
        ],
      ),
    );
  }

  Widget _buildReviewTile(dynamic r, bool isDark) {
    final customerName =
        r['reviewer_name'] ??
        r['customer_name'] ??
        AppLocalizations.of(context).customerDefault;
    final rating = (r['rating'] ?? 0).toDouble();
    final comment = r['comment']?.toString() ?? r['review']?.toString() ?? '';
    final rawPhoto =
        (r['reviewer_photo'] ??
                r['customer_photo'] ??
                r['photo_url'] ??
                r['photo'] ??
                '')
            .toString();
    final photo = AppHelpers.getFullImageUrl(rawPhoto);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.03),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  color: context.colors.primaryLight,
                  child: photo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photo,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          memCacheWidth: 100,
                          memCacheHeight: 100,
                          placeholder: (_, _) => const SizedBox(),
                          errorWidget: (context, error, stackTrace) => Center(
                            child: Text(
                              AppHelpers.getInitials(customerName.toString()),
                              style: TextStyle(
                                fontSize: AppFontSizes.caption,
                                fontWeight: FontWeight.w600,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            AppHelpers.getInitials(customerName.toString()),
                            style: TextStyle(
                              fontSize: AppFontSizes.caption,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  customerName.toString(),
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: AppColors.warningAmber,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppFontSizes.small,
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Recent Bookings ────────────────────────────────────
  Widget _buildRecentBookingsSection(bool isDark) {
    final recentBookings = (_dashboard?['recent_bookings'] as List?) ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).recentBookingsLabel,
                style: TextStyle(
                  fontSize: AppFontSizes.title,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              GestureDetector(
                onTap: () => ProfessionalMainScreen.switchTab(1),
                child: Text(
                  AppLocalizations.of(context).seeAllLabel,
                  style: TextStyle(
                    fontSize: AppFontSizes.secondary,
                    color: AppColors.professionalColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentBookings.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).noBookingsYet,
                style: TextStyle(
                  fontSize: AppFontSizes.secondary,
                  color: context.colors.textSecondary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          else
            ...recentBookings.map((b) => _buildBookingTile(b, isDark)),
        ],
      ),
    );
  }

  Widget _buildBookingTile(dynamic b, bool isDark) {
    final customerName =
        b['customer_name'] ?? AppLocalizations.of(context).customerDefault;
    final status = b['status']?.toString() ?? 'pending';
    final date = b['date']?.toString() ?? '';
    final time = b['time']?.toString() ?? '';
    final rawPhoto = (b['customer_photo'] ?? b['photo_url'] ?? b['photo'] ?? '')
        .toString();
    final photo = AppHelpers.getFullImageUrl(rawPhoto);

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'accepted':
        statusColor = context.colors.accent;
        break;
      case 'completed':
        statusColor = context.colors.primary;
        break;
      case 'rejected':
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return GestureDetector(
      onTap: () => _showBookingDetail(b, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.03),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                color: context.colors.primaryLight,
                child: photo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photo,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        memCacheWidth: 120,
                        memCacheHeight: 120,
                        placeholder: (_, _) => const SizedBox(),
                        errorWidget: (context, error, stackTrace) => Center(
                          child: Text(
                            AppHelpers.getInitials(customerName.toString()),
                            style: TextStyle(
                              fontSize: AppFontSizes.small,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          AppHelpers.getInitials(customerName.toString()),
                          style: TextStyle(
                            fontSize: AppFontSizes.small,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName.toString(),
                    style: TextStyle(
                      fontSize: AppFontSizes.secondary,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (date.isNotEmpty)
                    Text(
                      '$date${time.isNotEmpty ? ' • $time' : ''}',
                      style: TextStyle(
                        fontSize: AppFontSizes.caption,
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusBadge),
              ),
              child: Text(
                AppHelpers.capitalize(status),
                style: TextStyle(
                  fontSize: AppFontSizes.caption,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.textSecondary.withValues(alpha: 0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Booking Detail ─────────────────────────────────────
  void _showBookingDetail(dynamic b, bool isDark) {
    final status = b['status']?.toString() ?? 'pending';
    final isPending = status.toLowerCase() == 'pending';
    final isAccepted = status.toLowerCase() == 'accepted';
    final isCancellable = isPending || isAccepted;
    final customerName =
        b['customer_name'] ?? AppLocalizations.of(context).customerDefault;
    final date =
        b['date']?.toString() ?? AppLocalizations.of(context).dateNotSet;
    final time = b['time']?.toString() ?? '';
    final note = b['note']?.toString() ?? '';
    final bookingId = b['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusSheet),
        ),
      ),
      backgroundColor: context.colors.surface,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).bookingDetailsTitle,
              style: TextStyle(
                fontSize: AppFontSizes.title,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow(
              Icons.person_outline_rounded,
              AppLocalizations.of(context).customerLabel,
              customerName.toString(),
              isDark,
            ),
            _detailRow(
              Icons.calendar_today_outlined,
              AppLocalizations.of(context).dateLabel,
              date,
              isDark,
            ),
            if (time.isNotEmpty)
              _detailRow(
                Icons.access_time_rounded,
                AppLocalizations.of(context).timeLabel,
                time,
                isDark,
              ),
            if (note.isNotEmpty)
              _detailRow(
                Icons.notes_rounded,
                AppLocalizations.of(context).notesLabel,
                note,
                isDark,
              ),
            const SizedBox(height: 16),
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _updateBookingStatus(bookingId, 'rejected');
                      },
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(AppLocalizations.of(context).rejectCta),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _updateBookingStatus(bookingId, 'accepted');
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(AppLocalizations.of(context).acceptCta),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (isAccepted) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _updateBookingStatus(bookingId, 'completed');
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: Text(AppLocalizations.of(context).markCompletedCta),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            if (isCancellable) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _updateBookingStatus(bookingId, 'cancelled');
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: Text(AppLocalizations.of(context).cancelBookingCta),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
            if (!isPending && !isAccepted) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context).closeCta),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: AppFontSizes.secondary,
              color: context.colors.textSecondary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppFontSizes.secondary,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBookingStatus(dynamic bookingId, String newStatus) async {
    try {
      await _api.patch('${AppConstants.professionalBookings}$bookingId/', {
        'status': newStatus,
      });
      if (!mounted) return;
      AppHelpers.showInfo(
        context,
        AppLocalizations.of(context).bookingUpdatedToast(newStatus),
      );
      await _loadData();
      if (_searchQuery.isNotEmpty) _onSearchChanged(_searchQuery);
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showInfo(
        context,
        AppLocalizations.of(context).bookingUpdateError,
      );
    }
  }
}
