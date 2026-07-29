// lib/features/professional/screens/professional_home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import 'professional_main_screen.dart';
import 'professional_portfolio_screen.dart';
import 'professional_wallet_screen.dart';
import 'professional_reviews_screen.dart';
import '../../chat/presentation/screens/chat_screen.dart';
import '../../chat/data/models/conversation_model.dart';
import '../../subscription/widgets/promo_banner_mixin.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../shared/widgets/cta_banner.dart';

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
        (proProfile['hourly_rate'] ?? '').toString().isNotEmpty) filled++;
    if ((proProfile['experience_years'] ?? 0).toString() != '0' &&
        (proProfile['experience_years'] ?? '').toString().isNotEmpty) filled++;
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

      if (!mounted) return;

      final dashboard = results[0].data as Map<String, dynamic>;
      final portfolio = results[1].data is List ? results[1].data as List : [];
      final proProfile = results[2].data is Map ? results[2].data as Map<String, dynamic> : <String, dynamic>{};
      final userProfile = results[3].data is Map ? results[3].data as Map<String, dynamic> : <String, dynamic>{};
      final reviewsData = results[4].data;
      final reviewsList = reviewsData is List
          ? reviewsData
          : (reviewsData is Map ? (reviewsData['results'] ?? reviewsData['reviews'] ?? []) as List : []);
      final myPlan = results[5].data is Map ? results[5].data as Map<String, dynamic> : <String, dynamic>{};
      final conversations = results[6].data is List ? results[6].data as List : [];
      final bookingsData = results[7].data;
      final bookingsList = bookingsData is Map ? (bookingsData['bookings'] ?? []) as List : [];
      final meData = results[8].data is Map ? results[8].data as Map<String, dynamic> : <String, dynamic>{};

      setState(() {
        _dashboard = dashboard;
        _portfolio = portfolio.take(4).toList();
        _recentReviews = reviewsList.take(3).toList();
        _recentConversations = conversations.take(3).toList();
        _allBookings = bookingsList;
        _myPlan = myPlan;
        _proProfile = proProfile;
        _myUserId = int.tryParse(meData['id']?.toString() ?? '');
        _profileCompletion = _calculateCompletion(proProfile, userProfile, portfolio);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load dashboard. Pull down to retry.';
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
        final res = await _api.get('${AppConstants.professionalBookings}?search=$query');
        if (!mounted || _searchQuery != query) return;
        final data = res.data;
        final list = data is Map ? (data['bookings'] ?? []) as List : (data as List);
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
      body: _isLoading
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
                    'Loading your dashboard...',
                    style: TextStyle(
                      fontSize: 14,
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
                  SliverToBoxAdapter(child: _buildHeader(isDark)),
                  SliverToBoxAdapter(child: _buildSearchBar(isDark)),
                  if (isSearchMode)
                    SliverToBoxAdapter(child: _buildSearchResults(isDark))
                  else ...[
                    if (_error != null) SliverToBoxAdapter(child: _buildErrorBanner(isDark)),
                    SliverToBoxAdapter(child: _buildProfileCompletionCard(isDark)),
                    SliverToBoxAdapter(child: _buildSubscriptionUpgradeBanner(isDark)),
                    SliverToBoxAdapter(child: _buildVerificationBanner(isDark)),
                    SliverToBoxAdapter(child: _buildQuickActions(isDark)),
                    SliverToBoxAdapter(child: _buildEarningsSection(isDark)),
                    SliverToBoxAdapter(child: _buildStatsGrid(isDark)),
                    SliverToBoxAdapter(child: _buildQuickProfileCard(isDark)),
                    SliverToBoxAdapter(child: _buildTodaysScheduleSection(isDark)),
                    SliverToBoxAdapter(child: _buildCalendarSection(isDark)),
                    SliverToBoxAdapter(child: _buildPortfolioSection(isDark)),
                    SliverToBoxAdapter(child: _buildRecentMessagesSection(isDark)),
                    SliverToBoxAdapter(child: _buildRecentReviewsSection(isDark)),
                    SliverToBoxAdapter(child: _buildRecentBookingsSection(isDark)),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    final header = _dashboard?['header'] as Map<String, dynamic>? ?? {};
    final fullName = (header['name'] ?? 'Professional').toString();
    final name = fullName.split(' ').first;
    final isVerified = header['is_verified'] ?? false;
    final photo = header['photo_url'];
    final unreadCount = (_dashboard?['unread_notifications'] ?? 0) as int;
    final category = (header['category_name'] ?? _proProfile['category_name'] ?? '').toString();

    // Real KPI numbers — same data already loaded for the rest of the
    // dashboard, just surfaced here too. No placeholder/fake values.
    final stats = _dashboard?['stats'] as Map<String, dynamic>? ?? {};
    final rating = _dashboard?['rating'] as Map<String, dynamic>? ?? {};
    final earnings = _dashboard?['earnings'] as Map<String, dynamic>? ?? {};
    final totalBookings = _allBookings.isNotEmpty
        ? _allBookings.length
        : ((stats['pending_bookings'] ?? 0) as int) +
            ((stats['accepted_bookings'] ?? 0) as int) +
            ((stats['completed_bookings'] ?? 0) as int);
    final avgRating = (rating['average'] ?? 0).toDouble();
    final totalEarnings = (earnings['total'] ?? 0).toDouble();
    final clientsCount = _allBookings
        .map((b) => (b['customer_id'] ?? b['customer_name'] ?? '').toString())
        .where((c) => c.isNotEmpty)
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF4C1D95), const Color(0xFF312E81)]
              : [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
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
                : const Color(0xFF7C3AED).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Glowing avatar ring
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.25),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: (photo != null && photo.toString().isNotEmpty)
                          ? NetworkImage(AppHelpers.getFullImageUrl(photo.toString()))
                          : null,
                      child: (photo == null || photo.toString().isEmpty)
                          ? Text(
                              AppHelpers.getInitials(fullName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (isVerified == true)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: context.colors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greetingOnly(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.1,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (category.isNotEmpty || isVerified == true)
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _categoryIcon(category),
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                category.isNotEmpty
                                    ? category
                                    : 'Verified Professional',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Notification bell
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/notifications'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          constraints: const BoxConstraints(minWidth: 18),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: const Color(0xFF7C3AED),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          // KPI stats strip — real dashboard data
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _headerStat(
                    Icons.calendar_month_rounded,
                    '$totalBookings',
                    'Total Bookings',
                  ),
                ),
                _headerStatDivider(),
                Expanded(
                  child: _headerStat(
                    Icons.star_rounded,
                    avgRating > 0 ? avgRating.toStringAsFixed(1) : '—',
                    'Rating',
                  ),
                ),
                _headerStatDivider(),
                Expanded(
                  child: _headerStat(
                    Icons.people_alt_rounded,
                    _formatCompactNumber(clientsCount),
                    'Clients',
                  ),
                ),
                _headerStatDivider(),
                Expanded(
                  child: _headerStat(
                    Icons.account_balance_wallet_rounded,
                    '\$${_formatMoney(totalEarnings)}',
                    'Earnings',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _headerStatDivider() => Container(
        width: 1,
        height: 34,
        color: Colors.white.withOpacity(0.15),
      );

  String _formatCompactNumber(int n) {
    if (n < 1000) return '$n';
    final k = n / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
  }

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


  String _greeting(String name) {
    final hour = DateTime.now().hour;
    String time;
    if (hour < 12) {
      time = 'Good Morning';
    } else if (hour < 17) {
      time = 'Good Afternoon';
    } else {
      time = 'Good Evening';
    }
    return '$time, $name';
  }

  String _greetingOnly() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  IconData _categoryIcon(String profession) {
    final p = profession.toLowerCase();
    if (p.contains('tutor') || p.contains('educat') || p.contains('teach')) 
      return Icons.menu_book_rounded;
    if (p.contains('doctor') || p.contains('medic') || p.contains('health')) 
      return Icons.medical_services_outlined;
    if (p.contains('lawyer') || p.contains('legal')) 
      return Icons.gavel_outlined;
    if (p.contains('engineer')) 
      return Icons.engineering_outlined;
    if (p.contains('plumb')) 
      return Icons.plumbing_outlined;
    if (p.contains('electric')) 
      return Icons.electrical_services;
    if (p.contains('clean')) 
      return Icons.cleaning_services;
    if (p.contains('carpent')) 
      return Icons.carpenter;
    if (p.contains('paint')) 
      return Icons.format_paint_outlined;
    if (p.contains('architect')) 
      return Icons.architecture;
    if (p.contains('account') || p.contains('financ')) 
      return Icons.account_balance_outlined;
    if (p.contains('comput') || p.contains('it ') || p.contains('developer') || p.contains('software')) 
      return Icons.computer_outlined;
    if (p.contains('beauty') || p.contains('salon') || p.contains('makeup')) 
      return Icons.face_retouching_natural_outlined;
    if (p.contains('fitness') || p.contains('trainer') || p.contains('gym')) 
      return Icons.fitness_center_outlined;
    if (p.contains('photo')) 
      return Icons.camera_alt_outlined;
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocused
                ? AppColors.professionalColor
                : isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.15),
            width: isFocused ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
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
                  : context.colors.textSecondary.withOpacity(0.5),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Search bookings by client name...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: context.colors.textSecondary.withOpacity(0.5),
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
                    color: context.colors.divider.withOpacity(0.3),
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
                ? 'Searching...'
                : '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'} for "${_searchController.text}"',
            style: TextStyle(
              fontSize: 13,
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
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    color: context.colors.textSecondary.withOpacity(0.3),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No clients found',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try adjusting your search terms',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textSecondary.withOpacity(0.6),
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
  // Global CtaBanner widget use karta hai (guest ke "become pro" card
  // wali hi body/layout) — professional ke apne emoji, color aur
  // content ke sath.
  Widget _buildSubscriptionUpgradeBanner(bool isDark) {
    final isPremium = _myPlan?['is_premium'] == true;
    if (isPremium) return const SizedBox.shrink();

    final planName = _myPlan?['plan_name'] ?? 'Free';

    return CtaBanner(
      isDark: isDark,
      title: 'You\'re on the $planName plan',
      subtitle: 'Upgrade for more bookings & priority ranking',
      ctaLabel: 'Upgrade',
      icon: Icons.workspace_premium_rounded,
      accentStart: const Color(0xFF9F7AEA),
      accentEnd: AppColors.professionalColor,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionScreen(userRole: 'professional')),
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.04),
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
                  'Profile Completion',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  '$_profileCompletion%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _profileCompletion / 100,
                minHeight: 6,
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.06)
                    : context.colors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Complete your profile to get more bookings',
              style: TextStyle(
                fontSize: 11,
                color: context.colors.textSecondary.withOpacity(0.7),
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
            ? const Color(0xFF450A0A).withOpacity(0.8)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF7F1D1D).withOpacity(0.5)
              : const Color(0xFFFECACA),
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
              _error!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFFCA5A5) : AppColors.error,
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
            ? const Color(0xFF451A03).withOpacity(0.8)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF78350F).withOpacity(0.5)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: const Color(0xFFF59E0B),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              portCount == 0
                  ? 'Add portfolio items to get verified by admin.'
                  : 'Portfolio submitted. Waiting for admin approval.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (portCount == 0)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfessionalPortfolioScreen()),
              ),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Add',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────
  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
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
                label: 'Bookings',
                color: const Color(0xFF3B82F6),
                onTap: () => ProfessionalMainScreen.switchTab(1),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _actionCard(
                icon: Icons.photo_library_outlined,
                label: 'Portfolio',
                color: AppColors.professionalColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfessionalPortfolioScreen()),
                ),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _actionCard(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                color: const Color(0xFF059669),
                onTap: () => ProfessionalMainScreen.switchTab(5),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _actionCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Wallet',
                color: const Color(0xFFF59E0B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfessionalWalletScreen()),
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
    final badgeGradient = [
      Color.lerp(color, Colors.white, 0.15)!,
      color,
    ];

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : color.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.15) : color.withOpacity(0.08),
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
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
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
                  fontSize: 10.5,
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

  // ── Earnings Section ──────────────────────────────────
  Widget _buildEarningsSection(bool isDark) {
    final earnings = _dashboard?['earnings'] as Map<String, dynamic>? ?? {};
    final today = (earnings['today'] ?? 0).toDouble();
    final month = (earnings['month'] ?? 0).toDouble();
    final total = (earnings['total'] ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Earnings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfessionalWalletScreen()),
                ),
                child: Text(
                  'View Wallet',
                  style: TextStyle(
                    fontSize: 13,
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
                flex: 3,
                child: _earningsHeroCard('Today\'s Earnings', today, isDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _earningsMiniCard('This Month', month, Icons.calendar_view_month_rounded, isDark)),
              const SizedBox(width: 10),
              Expanded(child: _earningsMiniCard('Total Earned', total, Icons.savings_outlined, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _earningsHeroCard(String label, double amount, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF065F46), const Color(0xFF047857)]
              : [const Color(0xFF10B981), const Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningsMiniCard(String label, double amount, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.professionalColor,
            size: 18,
          ),
          const SizedBox(height: 8),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
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
            'Performance',
            style: TextStyle(
              fontSize: 16,
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
              _dashboardCard('Pending', '$pending', Icons.access_time_rounded, AppColors.warning, isDark),
              _dashboardCard('Accepted', '$accepted', Icons.check_circle_outline_rounded, context.colors.primary, isDark),
              _dashboardCard('Completed', '$completed', Icons.task_alt_rounded, context.colors.accent, isDark),
              _dashboardCard('Rating', '${avgRating.toStringAsFixed(1)} ($totalRev)', Icons.star_rounded, const Color(0xFFF59E0B), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashboardCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.04),
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
              color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
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
    final skills = skillsRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final rate = _proProfile['hourly_rate']?.toString() ?? '0';
    final isAvailable = _proProfile['is_available'] ?? true;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.04),
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
                'Skills & Pricing',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              GestureDetector(
                onTap: () => ProfessionalMainScreen.switchTab(5),
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 13,
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
                      '\$$rate/hr',
                      style: TextStyle(
                        fontSize: 13,
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
                  Text(
                    isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isAvailable
                          ? context.colors.accent
                          : context.colors.textSecondary,
                      letterSpacing: 0.2,
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
                            activeColor: context.colors.accent,
                            activeTrackColor: context.colors.accent.withOpacity(0.3),
                            inactiveTrackColor: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.3),
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
              'No skills added yet',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textSecondary.withOpacity(0.6),
                fontWeight: FontWeight.w400,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills.take(6).map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.professionalColor.withOpacity(0.12)
                          : AppColors.professionalColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.professionalColor.withOpacity(isDark ? 0.15 : 0.1),
                      ),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.professionalColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                  )).toList(),
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
        value ? 'You are now available for bookings' : 'You are now marked unavailable',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _proProfile = {..._proProfile, 'is_available': previous});
      AppHelpers.showError(context, 'Could not update availability');
    } finally {
      if (mounted) setState(() => _isTogglingAvailability = false);
    }
  }

  // ── Today's Schedule ──────────────────────────────────
  List<dynamic> _bookingsForDate(DateTime date) {
    return _allBookings.where((b) {
      final raw = b['date']?.toString();
      if (raw == null) return false;
      try {
        final d = DateTime.parse(raw);
        return d.year == date.year && d.month == date.month && d.day == date.day;
      } catch (_) {
        return false;
      }
    }).where((b) => b['status'] != 'cancelled' && b['status'] != 'rejected').toList();
  }

  Widget _buildTodaysScheduleSection(bool isDark) {
    final today = DateTime.now();
    final todaysBookings = _bookingsForDate(today)
      ..sort((a, b) => (a['time']?.toString() ?? '').compareTo(b['time']?.toString() ?? ''));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Schedule",
            style: TextStyle(
              fontSize: 16,
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.1),
                ),
              ),
              child: Text(
                'No bookings scheduled for today',
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.textSecondary.withOpacity(0.6),
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
    final customerName = booking['customer_name']?.toString() ?? 'Customer';
    final time = booking['time']?.toString() ?? '';
    final status = booking['status']?.toString() ?? 'pending';
    final statusColor = status == 'accepted'
        ? const Color(0xFF10B981)
        : (status == 'completed' ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.05)
                : Colors.grey.withOpacity(0.03),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
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
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.isEmpty ? status : status[0].toUpperCase() + status.substring(1),
              style: TextStyle(
                fontSize: 10,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.04),
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
                onPressed: () => setState(() => _selectedCalendarDate = DateTime(year, month - 1, 1)),
                color: context.colors.textSecondary,
              ),
              Text(
                '${_monthName(month)} $year',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: () => setState(() => _selectedCalendarDate = DateTime(year, month + 1, 1)),
                color: context.colors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textSecondary.withOpacity(0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ))
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
                final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                final hasBookings = _bookingsForDate(date).isNotEmpty;

                return Expanded(
                  child: Container(
                    height: 38,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.professionalColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
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
                                  : AppColors.professionalColor.withOpacity(0.6),
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

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[month - 1];
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
                'My Portfolio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfessionalPortfolioScreen()),
                ),
                child: Text(
                  'Manage',
                  style: TextStyle(
                    fontSize: 13,
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
                MaterialPageRoute(builder: (_) => const ProfessionalPortfolioScreen()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.professionalColor.withOpacity(0.06)
                      : AppColors.professionalColor.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.professionalColor.withOpacity(isDark ? 0.12 : 0.08),
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
                        color: AppColors.professionalColor.withOpacity(isDark ? 0.12 : 0.06),
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
                            'Add your work samples',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.professionalColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Get verified by adding portfolio',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.textSecondary.withOpacity(0.6),
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
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == _portfolio.length) {
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfessionalPortfolioScreen()),
                      ),
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.03)
                              : const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : const Color(0xFFDDD6FE),
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
                              'Add',
                              style: TextStyle(
                                fontSize: 10,
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
                          borderRadius: BorderRadius.circular(12),
                          color: context.colors.divider,
                          image: imageUrl != null && imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(AppHelpers.getFullImageUrl(imageUrl)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageUrl == null || imageUrl.isEmpty
                            ? Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: context.colors.textSecondary.withOpacity(0.3),
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
                'Recent Messages',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              GestureDetector(
                onTap: () => ProfessionalMainScreen.switchTab(2),
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.1),
                ),
              ),
              child: Text(
                'No messages yet',
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.textSecondary.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          else
            ..._recentConversations.map((c) => _buildMessagePreviewTile(c, isDark)),
        ],
      ),
    );
  }

  Widget _buildMessagePreviewTile(dynamic conv, bool isDark) {
    final name = conv['other_user_name']?.toString() ?? 'Customer';
    final lastMessage = conv['last_message']?.toString() ?? '';
    final unread = (conv['unread_count'] ?? 0) as int;
    final photo = conv['other_user_photo']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
                      otherUserPhoto: photo,
                      conversationSnapshot: ConversationModel.fromJson(
                        conv as Map<String, dynamic>,
                      ),
                    ),
                  ),
                ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.03),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: context.colors.primaryLight,
                  backgroundImage: (photo != null && photo.isNotEmpty)
                      ? NetworkImage(photo)
                      : null,
                  child: (photo == null || photo.isEmpty)
                      ? Text(
                          AppHelpers.getInitials(name),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
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
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.professionalColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        fontSize: 10,
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
                'Recent Reviews',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfessionalReviewsScreen()),
                ),
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.1),
                ),
              ),
              child: Text(
                'No reviews yet',
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.textSecondary.withOpacity(0.6),
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
    final customerName = r['reviewer_name'] ?? r['customer_name'] ?? 'Customer';
    final rating = (r['rating'] ?? 0).toDouble();
    final comment = r['comment']?.toString() ?? r['review']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.05)
                : Colors.grey.withOpacity(0.03),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: context.colors.primaryLight,
                child: Text(
                  AppHelpers.getInitials(customerName.toString()),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  customerName.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                      i < rating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 14,
                      color: const Color(0xFFF59E0B),
                    )),
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
                fontSize: 12,
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
                'Recent Bookings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              GestureDetector(
                onTap: () => ProfessionalMainScreen.switchTab(1),
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.1),
                ),
              ),
              child: Text(
                'No bookings yet',
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.textSecondary.withOpacity(0.6),
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
    final customerName = b['customer_name'] ?? 'Customer';
    final status = b['status']?.toString() ?? 'pending';
    final date = b['date']?.toString() ?? '';
    final time = b['time']?.toString() ?? '';

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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.03),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.colors.primaryLight,
              child: Text(
                AppHelpers.getInitials(customerName.toString()),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (date.isNotEmpty)
                    Text(
                      '$date${time.isNotEmpty ? ' • $time' : ''}',
                      style: TextStyle(
                        fontSize: 11,
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
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                AppHelpers.capitalize(status),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.textSecondary.withOpacity(0.3),
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
    final customerName = b['customer_name'] ?? 'Customer';
    final date = b['date']?.toString() ?? 'Not set';
    final time = b['time']?.toString() ?? '';
    final note = b['note']?.toString() ?? '';
    final bookingId = b['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              'Booking Details',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.person_outline_rounded, 'Customer', customerName.toString(), isDark),
            _detailRow(Icons.calendar_today_outlined, 'Date', date, isDark),
            if (time.isNotEmpty) _detailRow(Icons.access_time_rounded, 'Time', time, isDark),
            if (note.isNotEmpty) _detailRow(Icons.notes_rounded, 'Notes', note, isDark),
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
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                  label: const Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                  label: const Text('Cancel Booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                  child: const Text('Close'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
            color: context.colors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: context.colors.textSecondary.withOpacity(0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
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
      await _api.patch('${AppConstants.professionalBookings}$bookingId/', {'status': newStatus});
      if (!mounted) return;
      AppHelpers.showInfo(context, 'Booking updated to "$newStatus"');
      await _loadData();
      if (_searchQuery.isNotEmpty) _onSearchChanged(_searchQuery);
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showInfo(context, 'Could not update booking. Please try again.');
    }
  }
}