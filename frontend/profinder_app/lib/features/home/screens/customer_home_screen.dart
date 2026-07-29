// PATH: lib/features/home/screens/customer_home_screen.dart
// lib/features/home/screens/customer_home_screen.dart
//
// CUSTOMER DASHBOARD — every section is wired to a REAL backend endpoint
// where one exists. Where the backend doesn't have a concept yet (review
// counts on cards, availability status, true booking-linked payments,
// trending-by-bookings, featured-by-editor), the code takes the most
// honest client-side approximation and says so in a comment — never a
// fake number. See each section below for specifics.
//
//   • AI Recommendation + Recommended  → GET /ai/recommendations/ (+ hydrate via /profiles/professional/<id>/)
//   • Recent Searches + AI card        → GET /ai/search-history/, GET /ai/search-status/
//   • Book Again                       → GET /bookings/ (completed, deduped) + hydrate
//   • Upcoming / Recent Bookings       → GET /bookings/
//   • Wallet / Payment Summary/History → GET /payments/ + SubscriptionService.getMyPlan()
//   • Notifications preview            → GET /notifications/
//   • Magazine + Featured Articles     → MagazineService (Featured = sorted by views_count)
//   • Messages tab                     → ConversationListEntry (real chat, WebSocket + REST)
//   • Recent Chats icon (inline, 2 spots) → still ComingSoonScreen — see note near _openComingSoon()
//   • Favourites                       → on-device (services/favorites_store.dart)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/coming_soon_screen.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/home_provider.dart';
import '../../../services/location_service.dart';
import '../../../services/api_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/favorites_store.dart';
import '../../../shared/widgets/professional_card.dart';
import '../../../shared/widgets/category_card.dart';
import '../../../shared/widgets/cta_banner.dart';
import '../../../core/constants/category_style.dart';
import '../../search/screens/professional_detail_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../bookings/screens/booking_screen.dart';
import 'all_professionals_screen.dart';
import '../../bookings/screens/my_bookings_screen.dart';
import '../../magazine/models/article_model.dart';
import '../../magazine/services/magazine_service.dart';
import '../../magazine/screens/article_detail_screen.dart';
import '../../chat/presentation/providers/conversation_list_provider.dart';
import '../../chat/domain/entities/conversation_entity.dart';
import '../../chat/presentation/screens/chat_screen.dart';
import '../../chat/presentation/screens/conversation_list_screen.dart';
import '../../magazine/screens/magazine_screen.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../profile/screens/help_screen.dart';
import '../../profile/screens/wallet_screen.dart';
import '../../profile/screens/payments_screen.dart';
import '../../profile/screens/saved_professionals_screen.dart';
import '../../subscription/services/subscription_service.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../../subscription/widgets/promo_banner_mixin.dart';
import '../../chat/presentation/screens/conversation_list_entry.dart';   // ✅ NEW — Messages tab
import '../../chat/presentation/providers/conversation_list_provider.dart';
import '../../chat/presentation/widgets/unread_nav_badge.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../l10n/generated/app_localizations.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with PromoBannerMixin {
  int    _currentNavIndex = 0;
  int?   _selectedCategory;
  String? _selectedCategoryName;

  double _minPrice     = 0;
  double _maxPrice     = 1000;
  double _minRating    = 0;
  bool   _verifiedOnly = false;
  String _cityFilter   = '';

  // 🐛 FIX: Customer Home never requested live GPS at all — only Guest
  // Home did — so the customer's saved profile city (or nothing) was
  // always used instead of real-time location. Both must behave
  // identically: live GPS is the primary source, saved city is only a
  // fallback (see LocationService / _apply_location_priority on the
  // backend). Cached here so every section that needs location
  // (Nearby via loadHomeData + loadHomeFeed) uses the SAME coordinates
  // from a single permission prompt, instead of prompting repeatedly.
  double? _liveLat;
  double? _liveLng;

  final _api        = ApiService();
  final _bookingSvc = BookingService();
  final _favStore   = FavoritesStore();
  final _magazineSvc = MagazineService();
  final _subSvc      = SubscriptionService();

  // ── Perf: memoize favorite-status lookups per professional id ─────────
  // FutureBuilder re-invokes its `future:` callback on every rebuild of
  // the parent unless the Future instance itself is stable. Without this,
  // every visible ProfessionalCard would re-hit FavoritesStore's on-device
  // read on every unrelated setState() elsewhere on this screen (e.g. a
  // booking/wallet section refreshing). Purely a rebuild-cost fix — the
  // favorites feature itself (what counts as a favorite, how toggling
  // works) is completely unchanged; this cache is invalidated for exactly
  // the one id that changed, right when it changes.
  final Map<String, Future<bool>> _favFutureCache = {};
  Future<bool> _favFuture(String id) => _favFutureCache.putIfAbsent(id, () => _favStore.isFavorite(id));

  final GlobalKey _bookAgainKey = GlobalKey();

  // ── AI Recommendation + Recommended list ─────────────────
  List<Map<String, dynamic>> _recommendations = [];
  bool _recLoading = true;

  // ── Recent Searches ───────────────────────────────────────
  List<String> _recentSearches = [];
  bool _searchHistoryLoading   = true;

  // ── Book Again ────────────────────────────────────────────
  List<Map<String, dynamic>> _bookAgain = [];
  bool _bookAgainLoading = true;

  // ── Bookings (Upcoming / Recent) ──────────────────────────
  List<dynamic> _upcomingBookings = [];
  List<dynamic> _recentBookings   = [];
  bool _bookingsLoading = true;

  // ── Wallet / Payment Summary ──────────────────────────────
  double _totalSpent        = 0;
  int    _paymentsCount     = 0;
  int    _completedPayments = 0;
  int    _pendingPayments   = 0;
  bool   _isPremium         = false;
  String _planName          = 'Free';
  List<dynamic> _recentPayments = [];
  bool _walletLoading = true;

  // ── Notifications preview ─────────────────────────────────
  List<dynamic> _notifications = [];
  int  _unreadCount    = 0;
  bool _notifLoading   = true;

  // ── Magazine ───────────────────────────────────────────────
  List<Article> _articles         = [];
  List<Article> _featuredArticles = [];
  bool _articlesLoading = true;

  // ── AI Suggestions quota ──────────────────────────────────
  int  _aiUsed     = 0;
  int  _aiLimit    = 5;
  bool _aiPremium  = false;
  bool _aiQuotaLoading = true;
  final _aiPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNearbySections();
      _loadRecommendations();
      _loadSearchHistory();
      _loadBookAgainAndBookings();
      _loadWallet();
      _loadNotifications();
      _loadArticles();
      _loadAiQuota();
      showBannerForScreen('home');
      // ✅ NEW — load conversations once at app start so the Messages
      // tab's unread badge is accurate immediately, not just after the
      // tab has been opened once.
      context.read<ConversationListProvider>().load();
    });
  }

  @override
  void dispose() {
    _aiPromptController.dispose();
    super.dispose();
  }

  double _num(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  // 🐛 FIX: this is now the SAME location engine call guest_home_screen
  // makes — LocationService.getCurrentLocation() — so Customer gets the
  // identical live-GPS permission prompt/flow Guest already had. It
  // never throws or blocks the rest of Home from loading (returns null
  // on denial/timeout/error); saved profile city remains only a
  // backend-side fallback for when this returns null, never a
  // substitute the frontend reaches for on its own.
  Future<void> _loadNearbySections() async {
    final location = await LocationService.getCurrentLocation();
    if (!mounted) return;
    _liveLat = location?.lat;
    _liveLng = location?.lng;
    await Future.wait([
      _loadProfessionals(),
      context.read<HomeProvider>().loadHomeFeed(latitude: _liveLat, longitude: _liveLng),
    ]);
  }

  Future<void> _loadProfessionals() async {
    await context.read<HomeProvider>().loadHomeData(
      latitude:     _liveLat  ?? 0,
      longitude:    _liveLng  ?? 0,
      categoryId:   _selectedCategory,
      city:         _cityFilter,
      minPrice:     _minPrice,
      // 🐛 FIX: _maxPrice defaults to 1000 (the slider's max), which used to
      // be sent to the backend as a hard price ceiling on EVERY load — even
      // when the user never touched the filter sheet. That silently hid any
      // professional charging more than $1000/hr, which is why the customer
      // dashboard was showing only a handful of cards (sometimes just one)
      // while the guest dashboard — which never sends this param — showed
      // everyone. Slider-at-max now means "no cap", matching guest behaviour.
      maxPrice:     _maxPrice >= 1000 ? 999999 : _maxPrice,
      minRating:    _minRating,
      verifiedOnly: _verifiedOnly,
    );
  }

  // ── AI Recommendations — hydrate professional (photo/rating/price) ─
  Future<Map<String, dynamic>?> _hydrateProfessional(String id) async {
    try {
      final res = await _api.get('${AppConstants.professionalProfile}$id/');
      final d = Map<String, dynamic>.from(res.data as Map);
      return {
        'id':                id,
        'name':              d['name'] ?? '',
        'category_name':     d['category_name'] ?? '',
        'photo_url':         d['photo_url'],
        'average_rating':    d['average_rating'] ?? 0,
        'hourly_rate':       d['hourly_rate'] ?? 0,
        'experience_years':  d['experience_years'],
        'is_verified':       d['is_verified'] == true,
        'city':              d['city'] ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() => _recLoading = true);
    try {
      final res  = await _api.get(AppConstants.aiRecommendations);
      final list = res.data is List ? List<dynamic>.from(res.data) : [];
      final hydrated = <Map<String, dynamic>>[];
      // Bounded — same honest N+1 pattern used elsewhere in the app (see
      // my_reviews_screen.dart) since the list endpoint only returns FK ids.
      for (final r in list.take(8)) {
        final pid = r['professional']?.toString();
        if (pid == null) continue;
        final pro = await _hydrateProfessional(pid);
        if (pro != null) {
          hydrated.add({...pro, 'ai_reason': r['reason']?.toString() ?? ''});
        }
      }
      if (!mounted) return;
      setState(() {
        _recommendations = hydrated;
        _recLoading      = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _recLoading = false);
    }
  }

  Future<void> _loadSearchHistory() async {
    setState(() => _searchHistoryLoading = true);
    try {
      final res  = await _api.get(AppConstants.aiSearchHistory);
      final list = res.data is List ? List<dynamic>.from(res.data) : [];
      list.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
      final queries = <String>[];
      for (final h in list) {
        final q = h['query']?.toString() ?? '';
        if (q.isNotEmpty && !queries.contains(q)) queries.add(q);
        if (queries.length >= 6) break;
      }
      if (!mounted) return;
      setState(() {
        _recentSearches       = queries;
        _searchHistoryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchHistoryLoading = false);
    }
  }

  Future<void> _loadBookAgainAndBookings() async {
    setState(() => _bookAgainLoading = true);
    setState(() => _bookingsLoading  = true);
    try {
      final res = await _bookingSvc.getMyBookings();
      final all = res['success'] == true ? List<dynamic>.from(res['data'] ?? []) : [];

      final today = DateTime.now();
      final upcoming = all.where((b) {
        final st = b['status'];
        if (st != 'accepted' && st != 'pending') return false;
        final d = DateTime.tryParse('${b['date']}');
        return d == null || !d.isBefore(DateTime(today.year, today.month, today.day));
      }).toList()
        ..sort((a, b) => '${a['date']}'.compareTo('${b['date']}'));

      final recent = all.where((b) =>
          b['status'] == 'completed' || b['status'] == 'cancelled' || b['status'] == 'rejected')
          .toList()
        ..sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));

      // Book Again — dedupe completed bookings by professional, hydrate top few
      final completed = all.where((b) => b['status'] == 'completed').toList()
        ..sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
      final seenPro = <String>{};
      final bookAgainHydrated = <Map<String, dynamic>>[];
      for (final b in completed) {
        final pid = b['professional']?.toString();
        if (pid == null || seenPro.contains(pid)) continue;
        seenPro.add(pid);
        final pro = await _hydrateProfessional(pid);
        if (pro != null) bookAgainHydrated.add(pro);
        if (bookAgainHydrated.length >= 8) break;
      }

      if (!mounted) return;
      setState(() {
        _upcomingBookings = upcoming;
        _recentBookings   = recent;
        _bookingsLoading  = false;
        _bookAgain        = bookAgainHydrated;
        _bookAgainLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bookingsLoading  = false;
        _bookAgainLoading = false;
      });
    }
  }

  Future<void> _loadWallet() async {
    setState(() => _walletLoading = true);
    try {
      final res = await _api.get(AppConstants.payments);
      final list = res.data is List ? List<dynamic>.from(res.data) : [];
      list.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
      final completed = list.where((p) => p['status'] == 'completed').toList();
      final pending   = list.where((p) => p['status'] == 'pending').toList();
      final spent     = completed.fold(0.0, (s, p) => s + _num(p['amount']));

      final plan = await _subSvc.getMyPlan();

      if (!mounted) return;
      setState(() {
        _totalSpent        = spent;
        _paymentsCount      = list.length;
        _completedPayments = completed.length;
        _pendingPayments    = pending.length;
        _recentPayments      = list.take(4).toList();
        _isPremium           = plan?.isPremium ?? false;
        _planName            = plan?.planName ?? 'Free';
        _walletLoading        = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _walletLoading = false);
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _notifLoading = true);
    try {
      final res = await _api.get(AppConstants.notifications);
      // Backend may return a plain list OR a paginated object like
      // {results: [...], count: n} — handle both instead of silently
      // defaulting to an empty list.
      final raw = res.data;
      final list = raw is List
          ? List<dynamic>.from(raw)
          : (raw is Map && raw['results'] is List)
              ? List<dynamic>.from(raw['results'])
              : <dynamic>[];
      list.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
      bool isUnread(dynamic n) {
        final v = n['is_read'] ?? n['read'] ?? n['isRead'];
        if (v is bool) return !v;
        if (v is num) return v == 0;
        if (v is String) return v.toLowerCase() != 'true';
        return true; // no read flag at all → treat as unread
      }
      final unread = list.where(isUnread).length;
      if (!mounted) return;
      setState(() {
        _notifications = list;
        _unreadCount   = unread;
        _notifLoading  = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _notifLoading = false);
    }
  }

  Future<void> _loadArticles() async {
    setState(() => _articlesLoading = true);
    try {
      final list = await _magazineSvc.getArticles();
      final featured = [...list]..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
      if (!mounted) return;
      setState(() {
        _articles         = list;
        _featuredArticles = featured.take(4).toList();
        _articlesLoading  = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _articlesLoading = false);
    }
  }

  Future<void> _loadAiQuota() async {
    setState(() => _aiQuotaLoading = true);
    try {
      final res  = await _api.get(AppConstants.aiSearchStatus);
      final data = res.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _aiUsed        = data['searches_used']  ?? 0;
        _aiLimit       = data['searches_limit'] ?? 5;
        _aiPremium     = data['is_premium']     == true;
        _aiQuotaLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _aiQuotaLoading = false);
    }
  }

  Future<void> _refreshAll() => Future.wait([
        _loadNearbySections(),
        _loadRecommendations(),
        _loadSearchHistory(),
        _loadBookAgainAndBookings(),
        _loadWallet(),
        _loadNotifications(),
        _loadArticles(),
        _loadAiQuota(),
      ]);

  void _openSearch({int? categoryId, String? categoryName, String? query}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          isLoggedIn:          true,
          userRole:            'customer',
          initialCategoryId:   categoryId,
          initialCategoryName: categoryName,
          initialQuery:        query,
        ),
      ),
    ).then((_) => _loadSearchHistory());
  }

  void _openComingSoon({String? title, String? message}) {
    final t = AppLocalizations.of(context)!;
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => ComingSoonScreen(
            title: title ?? t.homeMessagingComingSoonTitle,
            message: message ?? t.homeMessagingComingSoonMessage,
            icon: Icons.chat_bubble_outline_rounded)));
  }

  void _showFilterSheet() {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: AppSizes.screenPadding, right: AppSizes.screenPadding,
            top: AppSizes.md, bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSizes.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: AppSizes.md),
              Text(t.homeFilter, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSizes.lg),
              Text(t.city, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSizes.xs),
              TextFormField(
                initialValue: _cityFilter,
                decoration: InputDecoration(hintText: t.homeCityHint, prefixIcon: const Icon(Icons.location_city_outlined)),
                onChanged: (v) => _cityFilter = v,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                t.homePrice('${_minPrice.toInt()}', _maxPrice >= 1000 ? t.homeNoLimit : '\$${_maxPrice.toInt()}/hr'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice), min: 0, max: 1000, divisions: 20,
                activeColor: context.colors.primary,
                onChanged: (v) => setSheet(() { _minPrice = v.start; _maxPrice = v.end; }),
              ),
              Text(t.homeMinRatingLabel(_minRating.toStringAsFixed(1)), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Slider(
                value: _minRating, min: 0, max: 5, divisions: 10, activeColor: context.colors.primary,
                onChanged: (v) => setSheet(() => _minRating = v),
              ),
              SwitchListTile(
                title: Text(t.homeVerifiedOnly, style: const TextStyle(fontSize: 13)),
                value: _verifiedOnly, activeColor: context.colors.primary, contentPadding: EdgeInsets.zero,
                onChanged: (v) => setSheet(() => _verifiedOnly = v),
              ),
              const SizedBox(height: AppSizes.sm),
              Row(children: [
                Expanded(child: OutlinedButton(
                    onPressed: () => setSheet(() { _minPrice = 0; _maxPrice = 1000; _minRating = 0; _verifiedOnly = false; _cityFilter = ''; }),
                    child: Text(t.homeResetButton))),
                const SizedBox(width: AppSizes.sm),
                Expanded(child: ElevatedButton(
                    onPressed: () { Navigator.pop(context); _loadProfessionals(); },
                    child: Text(t.homeApplyButton))),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final home      = context.watch<HomeProvider>();
    final t         = AppLocalizations.of(context)!;
    final fullName  = (home.userProfile?['name'] ?? 'there').toString();
    final city      = (home.userProfile?['city'] ?? '').toString();
    final photoUrl  = AppHelpers.getFullImageUrl(home.userProfile?['photo_url']?.toString());

    // ✅ FIX: same root-pop issue as guest_main_screen.dart — this screen
    // sits alone at the bottom of the Navigator stack after login, so a
    // back press here used to try popping past the root (blank/white
    // screen on web, stuck state on mobile). PopScope blocks that.
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.primary,
          onRefresh: _refreshAll,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(fullName, city, photoUrl)),
              SliverToBoxAdapter(child: _buildSearchTap()),
              SliverToBoxAdapter(child: _buildAiRecommendationCard()),
              SliverToBoxAdapter(child: _buildQuickActions()),
              SliverToBoxAdapter(key: _bookAgainKey, child: _buildBookAgain()),
              SliverToBoxAdapter(child: _buildRecentSearches()),

              // ── Discover ──────────────────────────────────
              SliverToBoxAdapter(child: _buildSectionHeader(title: t.homePopularCategories, onSeeAll: () => _showAllCategories(home.categories))),
              SliverToBoxAdapter(child: _buildCategories(home.categories)),

              // ── Category quick-filter (only when the customer actively
              // picked a category chip / applied the filter sheet — this is
              // an on-demand search view, separate from the fixed sections
              // below, so it doesn't get mixed in with them) ─────────────
              if (_selectedCategory != null)
                _buildProSection(
                  _selectedCategoryName ?? t.homeFilteredResults,
                  _nearby(home.nearbyProfessionals),
                  loading: home.isLoading,
                  section: ProSection.category,
                ),

              // ── Recommended For You ─────────────────────────────────
              // AI-personalized (search history / booking history / city)
              // with automatic fallback to top-rated-in-city, then nearby
              // cities, when there's no personalization signal yet.
              _buildProSection(
                t.homeRecommendedForYou,
                home.recommended,
                loading: home.feedLoading,
                tag: t.homeRecommendedLabel,
                tagIcon: Icons.auto_awesome_rounded,
                tagColor: AppColors.badgeRecommended,
                limit: 10,
                section: ProSection.recommended,
              ),

              // ── Nearby Professionals — customer's own city ONLY ──────
              _buildNearbySection(home),

              // ── Top Rated — rating → reviews → completed bookings ────
              // Only section with an explicit cap, per spec: Top 10.
              if (!home.feedLoading && home.topRatedFeed.isNotEmpty)
                _buildProSection(t.homeTopRatedProfessionals, home.topRatedFeed,
                    tag: t.homeTopRatedLabel, tagIcon: Icons.emoji_events_rounded, tagColor: AppColors.badgeTopRated, limit: 10,
                    section: ProSection.topRated),

              // ── Trending This Week — real weekly activity signals ────
              if (!home.feedLoading && home.trendingFeed.isNotEmpty)
                _buildProSection(t.homeTrendingThisWeek, home.trendingFeed, limit: 10,
                    tag: t.homeTrendingLabel, tagIcon: Icons.trending_up_rounded, tagColor: AppColors.badgeTrending,
                    section: ProSection.trending),

              // ── Recently Added — newest professional accounts, newest
              // first, backend already caps at 10; `limit: 10` here is just
              // a second safety net so this section can never grow past spec ──
              if (!home.feedLoading && home.recentlyAddedFeed.isNotEmpty)
                _buildProSection(t.homeRecentlyAdded, home.recentlyAddedFeed, limit: 10,
                    tag: t.homeNewLabel, tagIcon: Icons.fiber_new_rounded, tagColor: AppColors.badgeNew,
                    section: ProSection.recentlyAdded),

              // ── Bookings & Wallet ────────────────────────────
              SliverToBoxAdapter(child: _buildUpcomingBookings()),
              SliverToBoxAdapter(child: _buildRecentBookings()),
              SliverToBoxAdapter(child: _buildWalletCard()),
              SliverToBoxAdapter(child: _buildPaymentSummary()),
              SliverToBoxAdapter(child: _buildPaymentHistoryPreview()),

              // ── Engagement ───────────────────────────────────
              SliverToBoxAdapter(child: _buildRecentChats()),
              SliverToBoxAdapter(child: _buildNotificationsPreview()),
              SliverToBoxAdapter(child: _buildMagazineSection(t.homeTipsMagazineTitle, _articles, _articlesLoading)),
              SliverToBoxAdapter(child: _buildMagazineSection(t.homeFeaturedArticlesTitle, _featuredArticles, _articlesLoading, showViews: true)),
              SliverToBoxAdapter(child: _buildAiSuggestions()),
              SliverToBoxAdapter(child: _buildSupportBanner()),
              SliverToBoxAdapter(child: _buildHelpCenterRow()),

              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    ), // Scaffold
    );
  }

  /// Nearest first. Professionals with an unknown distance (no GPS on either
  /// side) are pushed to the end instead of being sorted arbitrarily.
  /// (Still used for the on-demand category-filter section — the fixed
  /// "Nearby Professionals" dashboard section gets its own strictly
  /// same-city list straight from the backend's home-feed.)
  List<dynamic> _nearby(List<dynamic> list) {
    final l = [...list]..sort((a, b) {
      final da = a['distance_km'];
      final db = b['distance_km'];
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return _num(da).compareTo(_num(db));
    });
    return l;
  }

  /// "Nearby Professionals" — the fixed dashboard section. Strictly the
  /// customer's own city (backend never mixes in other cities here), with
  /// the exact empty-state copy this section needs when the city has none.
  Widget _buildNearbySection(HomeProvider home) {
    final t = AppLocalizations.of(context)!;
    if (home.feedLoading) {
      return _buildProSection(t.nearbyProfessionals, const [], loading: true, tag: t.homeNearbyLabel, tagIcon: Icons.near_me_rounded, tagColor: context.colors.primary, section: ProSection.nearby);
    }
    if (home.nearbyInCity.isEmpty) {
      return SliverMainAxisGroup(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
          child: Text(t.nearbyProfessionals, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        )),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.divider)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.location_off_outlined, color: context.colors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text(t.homeNoProfessionalsAvailableCity, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _openSearch(),
                child: Text(t.homeTrySearchingNearbyCities, style: TextStyle(fontSize: 12.5, color: context.colors.primary, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ]);
    }
    return _buildProSection(t.nearbyProfessionals, home.nearbyInCity, tag: t.homeNearbyLabel, tagIcon: Icons.near_me_rounded, tagColor: context.colors.primary, section: ProSection.nearby);
  }

  void _showAllCategories(List<dynamic> categories) {
    showAllCategoriesSheet(
      context,
      categories: categories,
      isDark: false,
      onCategoryTap: _onCategoryTap,
    );
  }

  /// Toggle a category as the active filter and reload. Shared by the
  /// "Popular Categories" grid tap and the "view all" sheet tap.
  void _onCategoryTap(Map cat) {
    final selected = _selectedCategory == cat['id'];
    setState(() {
      _selectedCategory     = selected ? null : cat['id'];
      _selectedCategoryName = selected ? null : cat['name']?.toString();
    });
    _loadProfessionals();
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER — greeting, photo, notification bell+badge, location
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeader(String fullName, String city, String? photoUrl) {
    final t = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? t.homeGoodMorning : (hour < 17 ? t.homeGoodAfternoon : t.homeGoodEvening);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile').then((_) => _loadProfessionals()),
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                    image: (photoUrl != null && photoUrl.isNotEmpty)
                        ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                        : null,
                  ),
                  child: (photoUrl != null && photoUrl.isNotEmpty)
                      ? null
                      : Center(child: Text(AppHelpers.getInitials(fullName),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                    Text(t.homeHi(fullName),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())).then((_) => _loadNotifications()),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(13)),
                      child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: -2, top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          constraints: const BoxConstraints(minWidth: 18),
                          decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(9), border: Border.all(color: context.colors.primary, width: 1.5)),
                          child: Text(_unreadCount > 9 ? '9+' : '$_unreadCount', textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withOpacity(0.85)),
            const SizedBox(width: 4),
            Text(city.isNotEmpty ? city : t.homeSetYourLocation,
                style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSearchTap() {
    final t = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _openSearch(),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        height: 50,
        decoration: BoxDecoration(
          color: context.colors.surface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t.homeSearchDoctorsLawyersPlumbers,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B7280))),
          ),
          Container(
            margin: const EdgeInsets.all(6), padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.tune_outlined, size: 15, color: Colors.white),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // AI RECOMMENDATION CARD — single card, real /ai/recommendations/
  // ═══════════════════════════════════════════════════════════
  Widget _buildAiRecommendationCard() {
    final t = AppLocalizations.of(context)!;
    if (_recLoading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        height: 110,
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(18)),
      );
    }
    if (_recommendations.isEmpty) {
      // Cold-start — no history yet to recommend from
      return CtaBanner(
        isDark: false,
        title: t.homeGetPersonalizedPicks,
        subtitle: t.homeBookFirstServiceWeLlStart,
        ctaLabel: t.homeBrowse,
        icon: Icons.auto_awesome_rounded,
        accentStart: const Color(0xFFFCD34D),
        accentEnd: const Color(0xFFF59E0B),
        onTap: () => _openSearch(),
      );
    }

    final pick = _recommendations.first;
    final name   = pick['name']?.toString() ?? 'Professional';
    final cat    = pick['category_name']?.toString() ?? '';
    final reason = pick['ai_reason']?.toString() ?? '';
    final photo  = AppHelpers.getFullImageUrl(pick['photo_url']?.toString());
    final rating = _num(pick['average_rating']);
    final price  = _num(pick['hourly_rate']);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfessionalDetailScreen(professional: pick))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4C1D95), Color(0xFF6D28D9)]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFCD34D), size: 16),
              const SizedBox(width: 6),
              Text(t.homeAiPickForYou, style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
            ]),
            const SizedBox(height: 18),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  width: 52, height: 52, color: Colors.white24,
                  child: photo.isNotEmpty
                      ? Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(AppHelpers.getInitials(name), style: const TextStyle(color: Colors.white))))
                      : Center(child: Text(AppHelpers.getInitials(name), style: const TextStyle(color: Colors.white))),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: 0.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (cat.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(cat, style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 12.5, height: 1.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ]),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFCD34D), size: 16),
                  const SizedBox(width: 3),
                  Text(rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                Text('\$${price.toStringAsFixed(0)}/hr', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ]),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                reason,
                style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.6, letterSpacing: 0.15),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // QUICK ACTIONS — muscle-memory shortcuts, fixed order
  // ═══════════════════════════════════════════════════════════
  Widget _buildQuickActions() {
    final t = AppLocalizations.of(context)!;
    final items = [
      {'icon': Icons.replay_rounded,               'label': t.homeBookAgain,  'color': const Color(0xFF2563EB), 'onTap': () { final ctx = _bookAgainKey.currentContext; if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400)); }},
      {'icon': Icons.calendar_today_rounded,        'label': t.myBookings, 'color': const Color(0xFF10B981), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()))},
      {'icon': Icons.favorite_rounded,              'label': t.homeSavedQuickAction,       'color': const Color(0xFFEF4444), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedProfessionalsScreen()))},
      {'icon': Icons.account_balance_wallet_rounded,'label': t.homeWalletQuickAction,      'color': const Color(0xFFF59E0B), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))},
      {'icon': Icons.support_agent_rounded,         'label': t.homeHelpQuickAction,        'color': const Color(0xFF7C3AED), 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((it) => GestureDetector(
          onTap: it['onTap'] as VoidCallback,
          child: Column(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: (it['color'] as Color).withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(it['icon'] as IconData, color: it['color'] as Color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(it['label'] as String, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          ]),
        )).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BOOK AGAIN
  // ═══════════════════════════════════════════════════════════
  Widget _buildBookAgain() {
    final t = AppLocalizations.of(context)!;
    if (!_bookAgainLoading && _bookAgain.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title: t.homeBookAgain, onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()))),
        SizedBox(
          height: 150,
          child: _bookAgainLoading
              ? const Center(child: AppFullLoader())
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _bookAgain.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _bookAgainCard(_bookAgain[i]),
                ),
        ),
      ],
    );
  }

  Widget _bookAgainCard(Map<String, dynamic> pro) {
    final name  = pro['name']?.toString() ?? 'Professional';
    final cat   = pro['category_name']?.toString() ?? '';
    final photo = AppHelpers.getFullImageUrl(pro['photo_url']?.toString());
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(professional: pro))),
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.divider)),
        child: Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56, height: 56, color: context.colors.primaryLight,
              child: photo.isNotEmpty
                  ? Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(AppHelpers.getInitials(name), style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold))))
                  : Center(child: Text(AppHelpers.getInitials(name), style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold))),
            ),
          ),
          const SizedBox(height: 6),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          if (cat.isNotEmpty) Text(cat, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: context.colors.primary)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity, height: 28,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, textStyle: const TextStyle(fontSize: 11)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(professional: pro))),
              child: Text(AppLocalizations.of(context)!.homeBookAgain),
            ),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RECENT SEARCHES
  // ═══════════════════════════════════════════════════════════
  Widget _buildRecentSearches() {
    final t = AppLocalizations.of(context)!;
    if (!_searchHistoryLoading && _recentSearches.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(t.homeRecentSearches, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)))),
            if (_recentSearches.isNotEmpty)
              GestureDetector(onTap: () => setState(() => _recentSearches = []),
                  child: Text(t.homeClearAll, style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary))),
          ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _recentSearches.map((q) => GestureDetector(
              onTap: () => _openSearch(query: q),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: context.colors.divider)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.history_rounded, size: 13, color: context.colors.textSecondary),
                  const SizedBox(width: 5),
                  Text(q, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
                ]),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION HEADER (shared)
  // ═══════════════════════════════════════════════════════════
  Widget _buildSectionHeader({required String title, required VoidCallback onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(children: [
              Text(AppLocalizations.of(context)!.seeAll, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.colors.primary)),
              Icon(Icons.chevron_right_rounded, size: 16, color: context.colors.primary),
            ]),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CATEGORIES — shared with GuestHomeScreen (see PopularCategoriesGrid
  // + CategoryStyles), so customer & guest always show the same
  // icon/color per category instead of two separate hardcoded copies.
  // ═══════════════════════════════════════════════════════════
  Widget _buildCategories(List<dynamic> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PopularCategoriesGrid(
        categories: categories,
        isDark: false,
        limit: 8,
        selectedId: _selectedCategory,
        onCategoryTap: _onCategoryTap,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DISCOVER — shared professional section (Recommended/Nearby/TopRated/Trending)
  // ═══════════════════════════════════════════════════════════
  // 🐛 FIX: this used to hard-cap EVERY section to `.take(10)` regardless
  // of what the query actually returned — Nearby/Trending/Recommended
  // could have far more real matches and would silently lose them. Only
  // "Top Rated" is supposed to be capped (Top 10, per spec); every other
  // section must show everything the backend already decided to return.
  Widget _buildProSection(String title, List<dynamic> list, {bool loading = false, String? tag, IconData? tagIcon, Color? tagColor, int? limit, required ProSection section}) {
    if (!loading && list.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    final items = limit != null ? list.take(limit).toList() : list;
    return SliverMainAxisGroup(slivers: [
      SliverToBoxAdapter(child: _buildSectionHeader(title: title, onSeeAll: () => _showAllProfessionals(list, title, section))),
      SliverToBoxAdapter(
        child: loading
            ? const Padding(padding: EdgeInsets.only(top: 20), child: AppFullLoader())
            : SizedBox(
                // Responsive — always matches ProfessionalCard's own
                // computed height for this screen (see Prompt 2: no
                // hardcoded size, so cards are never clipped on any
                // device from 320px phones to tablets/foldables).
                height: ProfessionalCard.heightFor(context),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _buildProfessionalCard(items[i] as Map, tag: tag, tagIcon: tagIcon, tagColor: tagColor),
                ),
              ),
      ),
    ]);
  }

  void _showAllProfessionals(List<dynamic> list, String title, ProSection section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllProfessionalsScreen(title: title, professionals: list, section: section),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PROFESSIONAL CARD — Photo, Verified, Rating, Reviews, Experience,
  // Price, Distance, Favourite, Book Now, Message, View Profile
  // ═══════════════════════════════════════════════════════════
  Widget _buildProfessionalCard(Map pro, {String? tag, IconData? tagIcon, Color? tagColor, bool fullWidth = false}) {
    final id = pro['id']?.toString() ?? pro['user_id']?.toString() ?? '';
    return RepaintBoundary(
      child: FutureBuilder<bool>(
        future: _favFuture(id),
        builder: (context, snap) {
          return ProfessionalCard(
            pro:              pro,
            sectionTag:       tag,
            sectionTagIcon:   tagIcon,
            sectionTagColor:  tagColor,
            fullWidth:        fullWidth,
            isFavorite:       snap.data ?? false,
            onFavoriteToggle: () async {
              await _favStore.toggle(Map<String, dynamic>.from(pro));
              _favFutureCache.remove(id); // only this card's favorite status is now stale
              setState(() {});
            },
            onTap:            () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfessionalDetailScreen(professional: Map<String, dynamic>.from(pro)))),
            onBookNow:        () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(professional: Map<String, dynamic>.from(pro)))),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // UPCOMING BOOKINGS
  // ═══════════════════════════════════════════════════════════
  Widget _buildUpcomingBookings() {
    final t = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader(title: t.homeUpcomingBookings, onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()))),
      _bookingsLoading
          ? const Padding(padding: EdgeInsets.only(top: 10), child: AppFullLoader())
          : _upcomingBookings.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.divider)),
                    child: Column(children: [
                      const Icon(Icons.event_available_outlined, size: 32, color: Color(0xFFD1D5DB)),
                      const SizedBox(height: 8),
                      Text(t.homeNoUpcomingBookings, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                      const SizedBox(height: 10),
                      OutlinedButton(onPressed: () => _openSearch(), child: Text(t.homeBrowseProfessionals)),
                    ]),
                  ),
                )
              : SizedBox(
                  height: 158,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _upcomingBookings.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _upcomingBookingCard(_upcomingBookings[i]),
                  ),
                ),
    ]);
  }

  Widget _upcomingBookingCard(dynamic b) {
    final date = DateTime.tryParse('${b['date']}');
    final day  = date != null ? date.day.toString() : '--';
    final mon  = date != null ? _monthAbbr(date.month) : '';
    final name = b['professional_name']?.toString() ?? 'Professional';
    final time = b['time']?.toString() ?? '';
    final status = b['status']?.toString() ?? 'pending';

    return Container(
      width: 210, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: context.colors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(day, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.colors.primary, height: 1)),
              Text(mon, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: context.colors.primary)),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            if (time.isNotEmpty) Row(children: [
              Icon(Icons.access_time_rounded, size: 11, color: context.colors.textSecondary), const SizedBox(width: 2),
              Text(time, style: TextStyle(fontSize: 10.5, color: context.colors.textSecondary)),
            ]),
          ])),
          _statusPill(status),
        ]),
        const Spacer(),
        Row(children: [
          Expanded(child: TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
            child: Text(AppLocalizations.of(context)!.homeViewDetails, style: const TextStyle(fontSize: 11)),
          )),
          GestureDetector(onTap: () => _openComingSoon(), child: Icon(Icons.chat_bubble_outline_rounded, size: 16, color: context.colors.textSecondary)),
        ]),
      ]),
    );
  }

  String _monthAbbr(int m) => const ['', 'JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'][m];

  Widget _statusPill(String status) {
    final t = AppLocalizations.of(context)!;
    final map = {
      'pending':   [const Color(0xFFF59E0B), Icons.schedule_rounded, t.pending],
      'accepted':  [context.colors.primary, Icons.check_circle_outline_rounded, t.homeConfirmedStatus],
      'rejected':  [AppColors.error, Icons.cancel_outlined, t.homeDeclinedStatus],
      'completed': [context.colors.accent, Icons.check_circle_rounded, t.completed],
      'cancelled': [context.colors.textSecondary, Icons.block_rounded, t.homeCancelledStatus],
    };
    final v = map[status] ?? map['pending']!;
    final color = v[0] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(v[1] as IconData, size: 10, color: color),
        const SizedBox(width: 2),
        Text(v[2] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RECENT BOOKINGS
  // ═══════════════════════════════════════════════════════════
  Widget _buildRecentBookings() {
    final t = AppLocalizations.of(context)!;
    if (!_bookingsLoading && _recentBookings.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader(title: t.homeRecentBookingsTitle, onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()))),
      if (_bookingsLoading)
        const Padding(padding: EdgeInsets.only(top: 10), child: AppFullLoader())
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: _recentBookings.take(3).map((b) => _recentBookingRow(b)).toList()),
        ),
    ]);
  }

  Widget _recentBookingRow(dynamic b) {
    final name   = b['professional_name']?.toString() ?? 'Professional';
    final status = b['status']?.toString() ?? '';
    final date   = b['date']?.toString() ?? '';
    final cancelReason = b['cancel_reason']?.toString() ?? '';
    final cancelledBy  = b['cancelled_by']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.colors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 18, backgroundColor: context.colors.primaryLight, child: Text(AppHelpers.getInitials(name), style: TextStyle(fontSize: 11, color: context.colors.primary, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          Text(date, style: TextStyle(fontSize: 10.5, color: context.colors.textSecondary)),
          const SizedBox(width: 8),
          _statusPill(status),
        ]),
        if (status == 'cancelled' && cancelReason.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: 6, left: 46),
          child: Text(AppLocalizations.of(context)!.homeCancelledBy(cancelledBy.isNotEmpty ? cancelledBy : AppLocalizations.of(context)!.homeSystemLabel, cancelReason),
              style: TextStyle(fontSize: 10.5, color: context.colors.textSecondary, fontStyle: FontStyle.italic)),
        ),
        if (status == 'completed') Padding(
          padding: const EdgeInsets.only(top: 8, left: 46),
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
            child: Text(AppLocalizations.of(context)!.homeRateExperience, style: TextStyle(fontSize: 11.5, color: context.colors.primary, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WALLET
  // ═══════════════════════════════════════════════════════════
  Widget _buildWalletCard() {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF059669), Color(0xFF10B981)]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(t.homeTotalSpent, style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 10),
            _walletLoading
                ? const SizedBox(height: 30, child: AppFullLoader())
                : Text('\$${_totalSpent.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              _paymentsCount == 1
                  ? t.homeAcrossTransaction('$_paymentsCount')
                  : t.homeAcrossTransactions('$_paymentsCount'),
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
            ),
            const Divider(color: Colors.white30, height: 24),
            Row(children: [
              Icon(Icons.workspace_premium_rounded, color: _isPremium ? Colors.white : Colors.white38, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(t.homePlan(_planName), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600))),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen(userRole: 'customer'))),
                child: Text(_isPremium ? t.homeManageButton : t.homeUpgradeButton, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final t = AppLocalizations.of(context)!;
    if (_walletLoading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        Expanded(child: _statChip(t.completed, '$_completedPayments', context.colors.accent)),
        const SizedBox(width: 8),
        if (_pendingPayments > 0) Expanded(child: _statChip(t.pending, '$_pendingPayments', const Color(0xFFF59E0B))),
        if (_pendingPayments > 0) const SizedBox(width: 8),
        Expanded(child: _statChip(t.homeTotalLabel, '$_paymentsCount', context.colors.primary)),
      ]),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.colors.divider)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: context.colors.textSecondary)),
      ]),
    );
  }

  Widget _buildPaymentHistoryPreview() {
    final t = AppLocalizations.of(context)!;
    if (!_walletLoading && _recentPayments.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader(title: t.homePaymentHistoryTitle, onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsScreen()))),
      if (_walletLoading)
        const Padding(padding: EdgeInsets.only(top: 10), child: AppFullLoader())
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: _recentPayments.map((p) => _paymentRow(p)).toList()),
        ),
    ]);
  }

  Widget _paymentRow(dynamic p) {
    final amount   = _num(p['amount']);
    final currency = p['currency']?.toString() ?? 'USD';
    final status   = p['status']?.toString() ?? 'pending';
    final colors = {'completed': context.colors.accent, 'pending': const Color(0xFFF59E0B), 'failed': AppColors.error, 'refunded': const Color(0xFF6366F1)};
    final color = colors[status] ?? context.colors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.colors.divider)),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)), child: Icon(Icons.receipt_rounded, color: color, size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text('$currency ${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
        Text(AppHelpers.capitalize(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RECENT CHATS — real conversations (photo, name, last message,
  // timestamp, unread badge, online status), with the required empty state.
  // ═══════════════════════════════════════════════════════════
  Widget _buildRecentChats() {
    final t = AppLocalizations.of(context)!;
    final convoProvider = context.watch<ConversationListProvider>();
    // Not pinned/archived, most-recent first, top 3 for the dashboard preview.
    final recent = convoProvider.conversations
        .where((c) => !c.isArchived)
        .take(3)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(t.homeRecentChats, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)))),
          if (recent.isNotEmpty)
            GestureDetector(
              onTap: () {
                final myId = int.tryParse((_homeUserId ?? '').toString());
                if (myId == null) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => ConversationListScreen(currentUserId: myId)));
              },
              child: Row(children: [
                Text(t.homeViewAll, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.colors.primary)),
                Icon(Icons.chevron_right_rounded, size: 16, color: context.colors.primary),
              ]),
            ),
        ]),
        const SizedBox(height: 8),
        if (convoProvider.isLoading && convoProvider.conversations.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: AppFullLoader())
        else if (recent.isEmpty)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.divider)),
            child: Row(children: [
              Icon(Icons.chat_bubble_outline_rounded, color: context.colors.textSecondary, size: 26),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.homeNoMessagesYet, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(t.homeStartConversationAfterBookingProfessional, style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary)),
              ])),
            ]),
          )
        else
          Column(children: recent.map((c) => _recentChatRow(c)).toList()),
      ]),
    );
  }

  Widget _recentChatRow(ConversationEntity c) {
    return GestureDetector(
      onTap: () => _openChat(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.colors.divider)),
        child: Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            CircleAvatar(
              radius: 22, backgroundColor: context.colors.primaryLight,
              backgroundImage: (c.otherUserPhoto != null && c.otherUserPhoto!.isNotEmpty)
                  ? NetworkImage(AppHelpers.getFullImageUrl(c.otherUserPhoto)) as ImageProvider
                  : null,
              child: (c.otherUserPhoto == null || c.otherUserPhoto!.isEmpty)
                  ? Text(c.otherUserName.isNotEmpty ? c.otherUserName[0].toUpperCase() : '?', style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.primary))
                  : null,
            ),
            if (c.otherUserOnline)
              Positioned(right: 0, bottom: 0, child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: context.colors.surface, width: 2)),
              )),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.otherUserName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              c.lastMessage.isEmpty ? AppLocalizations.of(context)!.homeSayHello : c.lastMessage,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: c.unreadCount > 0 ? const Color(0xFF111827) : context.colors.textSecondary, fontWeight: c.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400),
            ),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_relativeTime(c.lastMessageAt ?? c.updatedAt), style: TextStyle(fontSize: 10.5, color: context.colors.textSecondary)),
            const SizedBox(height: 6),
            if (c.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(10)),
                child: Text('${c.unreadCount}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
          ]),
        ]),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    if (diff.inDays < 7)     return '${diff.inDays}d';
    return AppHelpers.formatDate(dt);
  }

  void _openChat(ConversationEntity c) {
    final myId = int.tryParse((_homeUserId ?? '').toString());
    if (myId == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatScreen(
        conversationId: c.id,
        currentUserId: myId,
        otherUserName: c.otherUserName,
        otherUserPhoto: c.otherUserPhoto,
        conversationSnapshot: c,
      ),
    )).then((_) => context.read<ConversationListProvider>().refresh());
  }

  /// Current customer's own id — reused from the already-loaded profile
  /// instead of an extra `/users/me/` call.
  String? get _homeUserId => context.read<HomeProvider>().userProfile?['id']?.toString();

  // ═══════════════════════════════════════════════════════════
  // NOTIFICATIONS PREVIEW
  // ═══════════════════════════════════════════════════════════
  Widget _buildNotificationsPreview() {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(t.homeNotifications(_unreadCount > 0 ? ' ($_unreadCount)' : ''), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)))),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())).then((_) => _loadNotifications()),
            child: Row(children: [Text(t.homeViewAll, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.colors.primary)), Icon(Icons.chevron_right_rounded, size: 16, color: context.colors.primary)]),
          ),
        ]),
        const SizedBox(height: 8),
        if (_notifLoading)
          const AppFullLoader()
        else if (_notifications.isEmpty)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.divider)),
            child: Text(t.noNotifications, style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary)),
          )
        else
          Column(children: (() {
            final unread = _notifications.where((n) => n['is_read'] != true).toList();
            final read   = _notifications.where((n) => n['is_read'] == true).toList();
            final combined = [...unread, ...read].take(3).toList();
            return combined.map((n) => _notificationRow(n)).toList();
          })()),
      ]),
    );
  }

  Widget _notificationRow(dynamic n) {
    final type = n['type']?.toString() ?? 'general';
    final map = {
      'payment':      [const Color(0xFF10B981), Icons.receipt_rounded],
      'review':       [const Color(0xFFF59E0B), Icons.star_rounded],
      'subscription': [const Color(0xFF7C3AED), Icons.workspace_premium_rounded],
      'general':      [context.colors.primary, Icons.notifications_rounded],
    };
    final v = map[type] ?? map['general']!;
    final color = v[0] as Color;
    final isRead = n['is_read'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.colors.divider)),
      child: Row(children: [
        if (!isRead) Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle)),
        Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(9)), child: Icon(v[1] as IconData, color: color, size: 15)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(n['title']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          Text(n['message']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
        ])),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MAGAZINE — Tips Magazine / Featured Articles (shared builder)
  // ═══════════════════════════════════════════════════════════
  Widget _buildMagazineSection(String title, List<Article> articles, bool loading, {bool showViews = false}) {
    if (!loading && articles.isEmpty) return const SizedBox.shrink();
    // Clamp text scaling for this horizontal strip — the card height below
    // already includes a safety buffer, but without a ceiling on scale a
    // large system/accessibility font size could still outgrow it on some
    // devices, which is exactly what was overflowing before.
    final textScaler = MediaQuery.textScalerOf(context).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15);
    final cardHeight = 178 + (textScaler.scale(1.0) - 1.0) * 60;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader(title: title, onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MagazineScreen()))),
      SizedBox(
        height: cardHeight,
        child: loading
            ? const Center(child: AppFullLoader())
            : MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _articleCard(articles[i], showViews: showViews),
                ),
              ),
      ),
    ]);
  }

  Widget _articleCard(Article a, {bool showViews = false}) {
    final cover = AppHelpers.getFullImageUrl(a.coverImage);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailScreen(slug: a.slug))),
      child: Container(
        width: showViews ? 240 : 210,
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.divider)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Container(
                height: 92, width: double.infinity, color: context.colors.primaryLight,
                child: cover.isNotEmpty
                    ? Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.menu_book_rounded, color: context.colors.primary))
                    : Icon(Icons.menu_book_rounded, color: context.colors.primary),
              ),
            ),
            if (showViews) Positioned(right: 8, top: 8, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 10), const SizedBox(width: 3),
                Text(_formatViews(a.viewsCount), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ]),
            )),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.25)),
              const SizedBox(height: 4),
              Text(a.editorialLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: context.colors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.access_time_rounded, size: 10, color: context.colors.textSecondary), const SizedBox(width: 2),
                  Text(AppLocalizations.of(context)!.magazineMinRead('${a.readTime}'), style: TextStyle(fontSize: 10, color: context.colors.textSecondary)),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  String _formatViews(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : '$v';

  // ═══════════════════════════════════════════════════════════
  // AI SUGGESTIONS — free 5/day, unlimited premium (real backend)
  // ═══════════════════════════════════════════════════════════
  Widget _buildAiSuggestions() {
    final t = AppLocalizations.of(context)!;
    final remaining = (_aiLimit - _aiUsed).clamp(0, _aiLimit);
    final exhausted  = !_aiPremium && _aiLimit > 0 && remaining <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colors.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED), size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(t.homeAiSuggestions, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
            if (_aiQuotaLoading)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            else if (_aiPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]), borderRadius: BorderRadius.circular(8)),
                child: Text(t.homeUnlimited, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
              )
            else
              Text(t.homeUsedToday('$_aiUsed', '$_aiLimit'), style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
          ]),
          const SizedBox(height: 4),
          Text(
            t.homeJustTellUsWhatNeedWe,
            style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (exhausted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(t.homeDailyLimitReachedResetsMidnight, style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E)))),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen(userRole: 'customer'))),
                  child: Text(t.homeUpgradeButton, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: context.colors.primary)),
                ),
              ]),
            )
          else
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _aiPromptController,
                  decoration: InputDecoration(
                    hintText: t.homeEGINeedPlumberLeaking,
                    hintStyle: const TextStyle(fontSize: 12.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.divider)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final q = _aiPromptController.text.trim();
                  if (q.isEmpty) return;
                  _openSearch(query: q);
                  _aiPromptController.clear();
                },
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(color: context.colors.primary, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CUSTOMER SUPPORT + HELP CENTER
  // ═══════════════════════════════════════════════════════════
  Widget _buildSupportBanner() {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.divider)),
        child: Row(children: [
          Icon(Icons.support_agent_rounded, color: context.colors.primary, size: 26),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.homeNeedHelpWeReHere, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(t.homeGetResponseWithin24Hours, style: TextStyle(fontSize: 10.5, color: context.colors.textSecondary)),
          ])),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 12)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
            child: Text(t.homeContactButton, style: const TextStyle(fontSize: 11.5)),
          ),
        ]),
      ),
    );
  }

  Widget _buildHelpCenterRow() {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.help_outline_rounded, color: context.colors.textSecondary, size: 20),
        title: Text(t.homeHelpCenter, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right_rounded, size: 18, color: context.colors.textSecondary),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BOTTOM NAV
  // ═══════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    final t = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.divider, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: context.colors.primary,
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          setState(() => _currentNavIndex = i);
          switch (i) {
            case 0: break;
            case 1: _openSearch(); break;
            case 2: Navigator.push(context, MaterialPageRoute(builder: (_) => const MagazineScreen())); break;
            case 3: Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationListEntry()))
                .then((_) => setState(() => _currentNavIndex = 0)); break;  // ✅ NEW — Messages
            case 4: Navigator.pushNamed(context, '/bookings'); break;
            case 5: Navigator.pushNamed(context, '/profile').then((_) {
              _loadProfessionals();
              setState(() => _currentNavIndex = 0);
            }); break;
          }
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home_rounded), label: t.home),
          BottomNavigationBarItem(icon: const Icon(Icons.search_outlined), activeIcon: const Icon(Icons.search_rounded), label: t.navSearch),
          BottomNavigationBarItem(icon: const Icon(Icons.menu_book_outlined), activeIcon: const Icon(Icons.menu_book_rounded), label: t.homeMagazineNavLabel),
          BottomNavigationBarItem(
            // ✅ NEW — Messages, with unread badge
            icon:       UnreadNavBadge(icon: const Icon(Icons.chat_bubble_outline_rounded)),
            activeIcon: UnreadNavBadge(icon: const Icon(Icons.chat_bubble_rounded)),
            label:      t.homeMessagesNavLabel,
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_today_outlined), activeIcon: const Icon(Icons.calendar_today_rounded), label: t.bookings),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), activeIcon: const Icon(Icons.person_rounded), label: t.profile),
        ],
      ),
    );
  }
}