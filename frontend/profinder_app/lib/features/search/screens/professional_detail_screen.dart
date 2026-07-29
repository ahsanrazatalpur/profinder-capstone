// PATH: lib/features/search/screens/professional_detail_screen.dart
// lib/features/search/screens/professional_detail_screen.dart
//
// Premium professional profile screen — Fiverr/Upwork/Thumbtack/Urban
// Company style, redesigned so "Message" and "Book Now" appear in exactly
// ONE place: the sticky bottom bar. No API/model/provider/route changes —
// every new section below reads fields the backend already returns:
//   • Stats & quick-info cards  → completed_jobs, reviews_count (from the
//     dedicated reviews endpoint), response_time_hrs, created_at,
//     is_available, languages, experience_years — all already present on
//     the search-result map / ProfessionalProfileSerializer.
//   • Certifications           → GET /profiles/certificates/user/<id>/,
//     an existing, already-shipped public endpoint (CertificateView).
//   • Related Professionals    → GET /search/nearby/?category_id=<id>,
//     the same existing SearchView/NearbyProfessionalsView used
//     everywhere else in the app, filtered to this professional's own
//     category and excluding themselves.
//   • Save/bookmark            → the existing FavoritesStore (used
//     elsewhere by ProfessionalCard), no new persistence layer.
// "Top Rated" / "Fast Response" badges are UI thresholds computed from the
// real average_rating / response_time_hrs numbers already on the profile —
// no new field is invented.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../services/auth_provider.dart';
import '../../../services/professional_service.dart';
import '../../../services/favorites_store.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../shared/widgets/professional_card.dart';
import '../../bookings/screens/booking_screen.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/api_service.dart';
import '../../chat/presentation/screens/chat_screen.dart';
import '../../chat/data/models/conversation_model.dart';
import '../../../core/theme/theme_context_ext.dart';

class ProfessionalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> professional;

  const ProfessionalDetailScreen({
    super.key,
    required this.professional,
  });

  @override
  State<ProfessionalDetailScreen> createState() =>
      _ProfessionalDetailScreenState();
}

class _ProfessionalDetailScreenState extends State<ProfessionalDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfessionalService _service = ProfessionalService();
  final ApiService _api = ApiService();
  final FavoritesStore _favStore = FavoritesStore();
  bool _isStartingChat = false;

  Map<String, dynamic>? _fullProfile;
  List<dynamic> _reviews      = [];
  List<dynamic> _portfolio    = [];
  List<dynamic> _certificates = [];
  List<dynamic> _related      = [];
  bool _isLoading             = true;
  String? _loadError;
  bool _isFavorite            = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    _loadFavoriteStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteStatus() async {
    final id = widget.professional['id']?.toString();
    if (id == null || id.isEmpty) return;
    final fav = await _favStore.isFavorite(id);
    if (!mounted) return;
    setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite); // optimistic
    await _favStore.toggle(Map<String, dynamic>.from(widget.professional));
  }

  // Reads the certificates for this professional — same safe
  // {'success','data'} shape as ProfessionalService, just kept local since
  // it's only used on this one screen.
  Future<Map<String, dynamic>> _fetchCertificates(String id) async {
    try {
      final res = await _api.get('/profiles/certificates/user/$id/');
      return {'success': true, 'data': res.data};
    } catch (e) {
      debugPrint('[ProfessionalDetail] certificates fetch failed: $e');
      return {'success': false, 'data': []};
    }
  }

  // Same-category professionals via the existing nearby/search endpoint —
  // no new backend route, just an existing query param (`category_id`).
  Future<Map<String, dynamic>> _fetchRelated(String? categoryId, String excludeId) async {
    if (categoryId == null || categoryId.isEmpty) return {'success': false, 'data': []};
    try {
      final res = await _api.get('/search/nearby/?category_id=$categoryId');
      final raw = res.data;
      List list = (raw is Map && raw['results'] is List) ? List<dynamic>.from(raw['results']) : [];
      // Exclude the professional being viewed AND dedupe by id — a
      // professional should never appear twice in "Related Professionals".
      final seenIds = <String>{};
      list = list.where((p) {
        if (p is! Map) return false;
        final pid = p['id']?.toString();
        if (pid == null || pid.isEmpty || pid == excludeId) return false;
        if (seenIds.contains(pid)) return false;
        seenIds.add(pid);
        return true;
      }).toList();
      return {'success': true, 'data': list};
    } catch (e) {
      debugPrint('[ProfessionalDetail] related fetch failed: $e');
      return {'success': false, 'data': []};
    }
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _loadError = null; });

    final id = widget.professional['id']?.toString();
    if (id == null || id.isEmpty) {
      setState(() { _isLoading = false; _loadError = 'Invalid professional ID'; });
      return;
    }
    final categoryId = widget.professional['category_id']?.toString();

    try {
      final results = await Future.wait([
        _service.getProfessionalProfile(id),
        _service.getReviews(id),
        _service.getPortfolio(id),
        _fetchCertificates(id),
        _fetchRelated(categoryId, id),
      ]);

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        try {
          if (results[0]['success'] == true) {
            final data = results[0]['data'];
            if (data is Map) _fullProfile = Map<String, dynamic>.from(data);
          }
        } catch (e, st) {
          debugPrint('[ProfessionalDetail] profile parse error: $e\n$st');
        }

        try {
          if (results[1]['success'] == true) {
            final data = results[1]['data'];
            _reviews = data is List ? data : [];
          }
        } catch (e, st) {
          debugPrint('[ProfessionalDetail] reviews parse error: $e\n$st');
        }

        try {
          if (results[2]['success'] == true) {
            final data = results[2]['data'];
            _portfolio = data is List ? data : [];
          }
        } catch (e, st) {
          debugPrint('[ProfessionalDetail] portfolio parse error: $e\n$st');
        }

        try {
          if (results[3]['success'] == true) {
            final data = results[3]['data'];
            _certificates = data is List ? data : [];
          }
        } catch (e, st) {
          debugPrint('[ProfessionalDetail] certificates parse error: $e\n$st');
        }

        try {
          if (results[4]['success'] == true) {
            final data = results[4]['data'];
            _related = data is List ? data : [];
          }
        } catch (e, st) {
          debugPrint('[ProfessionalDetail] related parse error: $e\n$st');
        }
      });

      if (results[0]['success'] != true && _fullProfile == null) {
        setState(() { _loadError = 'Failed to load data'; });
      }
    } catch (e, st) {
      debugPrint('[ProfessionalDetail] _loadData failed for id=$id: $e\n$st');
      if (!mounted) return;
      setState(() { _isLoading = false; _loadError = 'Failed to load data'; });
    }
  }

  // ── Merged data helper — fullProfile overrides widget.professional ──────────
  dynamic _get(String key) =>
      _fullProfile?[key] ?? widget.professional[key];

  String get _name      => _get('name')?.toString()      ?? 'Professional';
  String get _photoUrl  => (_get('photo_url') ?? '').toString();
  bool   get _verified  => _get('is_verified') == true;
  double get _rating    => double.tryParse(_get('average_rating')?.toString() ?? '0') ?? 0.0;
  bool   get _isTopRated => _rating >= 4.5 && _reviews.length >= 5;
  int    get _completedJobs => int.tryParse(_get('completed_jobs')?.toString() ?? '0') ?? 0;
  bool   get _isAvailable   => _get('is_available') != false;
  // ✅ Real-time presence from the chat WebSocket (UserPresence), NOT the
  // "available for bookings" toggle above — this is the actual live
  // Online/Offline status shown next to the location in the header.
  bool   get _isOnline      => _get('is_online') == true;

  double get _responseTimeHrs => double.tryParse(_get('response_time_hrs')?.toString() ?? '24') ?? 24.0;
  bool   get _isFastResponder => _responseTimeHrs > 0 && _responseTimeHrs <= 1;

  String get _responseTimeLabel {
    final hrs = _responseTimeHrs;
    if (hrs <= 0) return 'Instant';
    if (hrs < 1) return '${(hrs * 60).round()} min';
    if (hrs == hrs.roundToDouble()) return '${hrs.round()} hr${hrs.round() == 1 ? '' : 's'}';
    return '${hrs.toStringAsFixed(1)} hrs';
  }

  String get _memberSinceLabel {
    final raw = _get('created_at')?.toString();
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '—';
    }
  }

  List<String> _splitCsv(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty) return [];
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  List<String> get _languagesList => _splitCsv(_get('languages'));
  List<String> get _skillsList    => _splitCsv(_get('skills'));
  List<String> get _servicesList  => _splitCsv(_get('services'));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const AppFullLoader()
          : _loadError != null
              ? _buildErrorState()
              : CustomScrollView(
                  slivers: [
                    _buildHeader(),
                    _buildQuickInfoRow(),
                    _buildTabBar(),
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildPortfolioTab(),
                          _buildReviewsTab(),
                          _buildServicesTab(),
                          _buildAvailabilityTab(),
                        ],
                      ),
                    ),
                  ],
                ),

      bottomNavigationBar: _isLoading
          ? null
          : auth.isGuest
              ? _buildGuestBar()
              : _buildBookBar(),
    );
  }

  // ── Error State ───────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text(_loadError ?? 'Something went wrong',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    final photo = _photoUrl;
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);
    final avatarR = ResponsiveUtils.sp(46, scale, min: 42, max: 60);
    // Extra headroom for the stats row now embedded inside the hero
    // (avatar + badges + name + category + rating + location + stats).
    final expandedHeight = ResponsiveUtils.sp(420, scale, min: 400, max: 480);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: context.colors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      // ✅ Save moved here — a single bookmark icon in the AppBar instead
      // of taking up space as a button row inside the page.
      actions: [
        IconButton(
          onPressed: _toggleFavorite,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              key: ValueKey<bool>(_isFavorite),
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end:   Alignment.bottomCenter,
              colors: [context.colors.primaryDark, context.colors.primary],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // ── Avatar with verified badge ──────────
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: avatarR,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                        onBackgroundImageError: photo.isNotEmpty
                            ? (_, __) {}
                            : null,
                        child: photo.isEmpty
                            ? Text(
                                AppHelpers.getInitials(_name),
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.sp(30, scale, min: 27, max: 38),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    // ✅ Avatar corner now shows the REAL online/offline
                    // presence dot (like the mockup) instead of a static
                    // verified badge — verified moves next to the name below.
                    Positioned(
                      right: 4, bottom: 4,
                      child: Container(
                        width: ResponsiveUtils.sp(18, scale, min: 16, max: 22),
                        height: ResponsiveUtils.sp(18, scale, min: 16, max: 22),
                        decoration: BoxDecoration(
                          color:  _isOnline ? const Color(0xFF34D399) : const Color(0xFF9CA3AF),
                          shape:  BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Verified / Top Rated badge row ──────
                if (_verified || _isTopRated)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_verified) _headerBadge(Icons.verified_rounded, 'Verified', context.colors.accent),
                        if (_verified && _isTopRated) const SizedBox(width: 8),
                        if (_isTopRated) _headerBadge(Icons.star_rounded, 'Top Rated', AppColors.badgeTopRated),
                      ],
                    ),
                  ),

                // ── Name (+ inline verified checkmark, like the mockup) ──
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.screenPadding(width)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sp(23, scale, min: 20, max: 29),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (_verified) ...[
                        SizedBox(width: ResponsiveUtils.sp(6, scale, min: 5, max: 8)),
                        Container(
                          width: ResponsiveUtils.sp(20, scale, min: 18, max: 24),
                          height: ResponsiveUtils.sp(20, scale, min: 18, max: 24),
                          decoration: BoxDecoration(color: context.colors.accent, shape: BoxShape.circle),
                          child: Icon(Icons.check, color: Colors.white, size: ResponsiveUtils.sp(12, scale, min: 11, max: 15)),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                if (_get('category_name') != null && _get('category_name').toString().isNotEmpty)
                  Text(
                    _get('category_name').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: ResponsiveUtils.sp(14, scale, min: 12.5, max: 17), color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500),
                  ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.badgeTopRated, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_rating.toStringAsFixed(1)} (${_reviews.length} Reviews)',
                      style: TextStyle(fontSize: ResponsiveUtils.sp(12.5, scale, min: 11.5, max: 15), color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                if ((_get('city') ?? '').toString().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.screenPadding(width)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.white.withOpacity(0.8), size: ResponsiveUtils.sp(13, scale, min: 12, max: 16)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            _get('city').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: ResponsiveUtils.sp(12, scale, min: 11, max: 15), color: Colors.white.withOpacity(0.8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Container(width: 7, height: 7, decoration: BoxDecoration(color: _isOnline ? const Color(0xFF34D399) : Colors.white.withOpacity(0.4), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(
                          _isOnline ? 'Online' : 'Offline',
                          style: TextStyle(fontSize: ResponsiveUtils.sp(12, scale, min: 11, max: 15), color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 18),

                // ── Stats — embedded in the hero, translucent pills, like
                // the mockup. Uses only real fields already on the profile
                // (rating, reviews, completed jobs, response time) — no
                // fabricated metrics.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.screenPadding(width, base: 16)),
                  child: Row(
                    children: [
                      Expanded(child: _heroStatPill(Icons.star_rounded, _rating.toStringAsFixed(1), 'Rating', scale)),
                      SizedBox(width: ResponsiveUtils.sp(10, scale, min: 8, max: 12)),
                      Expanded(child: _heroStatPill(Icons.forum_outlined, '${_reviews.length}', 'Reviews', scale)),
                      SizedBox(width: ResponsiveUtils.sp(10, scale, min: 8, max: 12)),
                      Expanded(child: _heroStatPill(Icons.work_outline_rounded, '$_completedJobs', 'Jobs Done', scale)),
                      SizedBox(width: ResponsiveUtils.sp(10, scale, min: 8, max: 12)),
                      Expanded(child: _heroStatPill(Icons.bolt_rounded, _responseTimeLabel, 'Response', scale)),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroStatPill(IconData icon, String value, String label, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.sp(10, scale, min: 8, max: 13)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: ResponsiveUtils.sp(16, scale, min: 14, max: 20)),
          SizedBox(height: ResponsiveUtils.sp(4, scale, min: 3, max: 6)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: ResponsiveUtils.sp(13, scale, min: 11.5, max: 16), fontWeight: FontWeight.w800, color: Colors.white),
          ),
          SizedBox(height: ResponsiveUtils.sp(1, scale, min: 1, max: 2)),
          Text(label, style: TextStyle(fontSize: ResponsiveUtils.sp(10, scale, min: 9, max: 12.5), color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _headerBadge(IconData icon, String label, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── Quick Information Cards (replaces the old CTA button row) ──────
  Widget _buildQuickInfoRow() {
    final items = <Map<String, dynamic>>[
      {'icon': Icons.calendar_today_outlined, 'label': 'Member Since', 'value': _memberSinceLabel},
      {'icon': Icons.event_available_outlined, 'label': 'Availability', 'value': _isAvailable ? 'Available now' : 'Currently busy'},
      {'icon': Icons.language_rounded, 'label': 'Languages', 'value': _languagesList.isNotEmpty ? _languagesList.join(', ') : 'Not specified'},
      {'icon': Icons.work_history_outlined, 'label': 'Experience', 'value': '${_get('experience_years') ?? 0} years'},
    ];

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: items.map((it) => _quickInfoCard(it['icon'] as IconData, it['label'] as String, it['value'] as String)).toList(),
        ),
      ),
    );
  }

  Widget _quickInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: context.colors.primaryLight, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: context.colors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────
  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller:           _tabController,
          isScrollable:         true,
          labelColor:           context.colors.primary,
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor:       context.colors.primary,
          indicatorWeight:      2.5,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            const Tab(text: 'Overview'),
            Tab(text: 'Portfolio (${_portfolio.length})'),
            Tab(text: 'Reviews (${_reviews.length})'),
            const Tab(text: 'Services'),
            const Tab(text: 'Availability'),
          ],
        ),
      ),
    );
  }

  // ── Overview Tab (About + Details + Skills + Certifications + Related) ──
  Widget _buildOverviewTab() {
    final bio = (_get('bio') ?? '').toString();
    final exp = _get('experience_years') ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bio.isNotEmpty) ...[
            _sectionTitle('About'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(bio,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],

          _sectionTitle('Details'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _detailRow(Icons.work_outline_rounded, 'Experience', '$exp years'),
                const Divider(height: 20),
                _detailRow(Icons.attach_money_rounded, 'Hourly Rate',
                    '\$${_get('hourly_rate') ?? 0}/hr'),
                const Divider(height: 20),
                _detailRow(Icons.location_on_outlined, 'City',
                    (_get('city') ?? 'N/A').toString()),
                const Divider(height: 20),
                _detailRow(
                  Icons.verified_outlined,
                  'Verification',
                  _verified ? 'Verified Professional' : 'Not Verified',
                  valueColor: _verified ? context.colors.accent : AppColors.warning,
                ),
                if ((_get('category_name') ?? '').toString().isNotEmpty) ...[
                  const Divider(height: 20),
                  _detailRow(Icons.category_outlined, 'Category',
                      _get('category_name').toString()),
                ],
              ],
            ),
          ),

          if (_skillsList.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle('Skills'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skillsList.map((s) => _pillChip(s)).toList(),
            ),
          ],

          if (_verified || _isTopRated || _isFastResponder || _certificates.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle('Certifications & Badges'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (_verified) _badgeTile(Icons.verified_user_rounded, 'ID Verified', context.colors.accent),
                if (_isTopRated) _badgeTile(Icons.workspace_premium_rounded, 'Top Rated', AppColors.badgeTopRated),
                if (_isFastResponder) _badgeTile(Icons.bolt_rounded, 'Fast Response', AppColors.info),
              ],
            ),
            if (_certificates.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._certificates.map((c) => _certificateRow(c)),
            ],
          ],

          if (_related.isNotEmpty) ...[
            const SizedBox(height: 24),
            _sectionTitle('Related Professionals'),
            const SizedBox(height: 10),
            SizedBox(
              height: ProfessionalCard.heightFor(context),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final item = Map<String, dynamic>.from(_related[i] as Map);
                  return SizedBox(
                    width: ProfessionalCard.widthFor(context),
                    child: ProfessionalCard(
                      pro: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfessionalDetailScreen(professional: item)),
                      ),
                      onBookNow: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BookingScreen(professional: item)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: context.colors.primary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.primary)),
        ],
      ),
    );
  }

  Widget _badgeTile(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _certificateRow(dynamic cert) {
    final title = cert['title']?.toString() ?? 'Certificate';
    final org   = cert['issuing_organization']?.toString() ?? '';
    final date  = cert['issue_date'] != null ? _formatDate(cert['issue_date'].toString()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: context.colors.primaryLight, borderRadius: BorderRadius.circular(9)),
            child: Icon(Icons.school_outlined, size: 17, color: context.colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                if (org.isNotEmpty)
                  Text(org, style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          if (date.isNotEmpty)
            Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  // ── Services Tab ─────────────────────────────────────────
  Widget _buildServicesTab() {
    if (_servicesList.isEmpty) {
      return _emptyTabState(Icons.design_services_outlined, 'No services listed', 'This professional hasn\'t listed specific services yet');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _servicesList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: context.colors.accentLight, borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.check_rounded, size: 17, color: context.colors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_servicesList[i], style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            ),
          ],
        ),
      ),
    );
  }

  // ── Availability Tab ─────────────────────────────────────
  Widget _buildAvailabilityTab() {
    final start = (_get('working_hours_start') ?? '09:00').toString();
    final end   = (_get('working_hours_end') ?? '18:00').toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isAvailable ? context.colors.accentLight : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  _isAvailable ? Icons.check_circle_rounded : Icons.pause_circle_outline_rounded,
                  color: _isAvailable ? context.colors.accent : const Color(0xFF9CA3AF),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isAvailable ? 'Currently accepting new bookings' : 'Not accepting bookings right now',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _isAvailable ? context.colors.accent : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Working Hours'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: _detailRow(Icons.schedule_rounded, 'Daily Hours', '$start – $end'),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Response Time'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: _detailRow(Icons.bolt_rounded, 'Typically replies within', _responseTimeLabel),
          ),
        ],
      ),
    );
  }

  Widget _emptyTabState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ),
        ],
      ),
    );
  }

  // ── Reviews Tab ──────────────────────────────────────────
  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return _emptyTabState(Icons.rate_review_outlined, 'No reviews yet', 'Be the first to review!');
    }

    return ListView.builder(
      padding:     const EdgeInsets.all(16),
      itemCount:   _reviews.length,
      itemBuilder: (ctx, i) {
        final review = _reviews[i];
        final rating = (review['rating'] ?? 0).toInt();
        final date   = review['created_at'] != null
            ? _formatDate(review['created_at'].toString())
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['reviewer_name']?.toString() ?? 'User',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                        ),
                        if (date.isNotEmpty)
                          Text(date,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) => Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size:  14,
                    )),
                  ),
                ],
              ),
              if ((review['comment'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(review['comment'].toString(),
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280), height: 1.5)),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Portfolio Tab ─────────────────────────────────────────
  Widget _buildPortfolioTab() {
    if (_portfolio.isEmpty) {
      return _emptyTabState(Icons.photo_library_outlined, 'No portfolio yet', 'This professional has no approved work yet');
    }

    final width = MediaQuery.sizeOf(context).width;
    final columns = ResponsiveUtils.gridColumns(width, base: 2, targetCellWidth: 170);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   columns,
        crossAxisSpacing: 10,
        mainAxisSpacing:  10,
        childAspectRatio: 0.85,
      ),
      itemCount:   _portfolio.length,
      itemBuilder: (ctx, i) {
        final item     = _portfolio[i];
        final imageUrl = item['image_url']?.toString() ?? '';
        final title    = item['title']?.toString() ?? '';
        final desc     = item['description']?.toString() ?? '';

        return GestureDetector(
          onTap: () => _showPortfolioDetail(item),
          child: Container(
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset:     const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Expanded(
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width:      double.infinity,
                          fit:        BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: Color(0xFFD1D5DB), size: 32),
                            ),
                          ),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: const Color(0xFFF3F4F6),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: context.colors.primary,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: context.colors.primaryLight,
                          child: Center(
                            child: Icon(Icons.image_outlined,
                                color: context.colors.primary.withOpacity(0.4), size: 36),
                          ),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827)),
                        ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Portfolio Detail Bottom Sheet ─────────────────────────
  void _showPortfolioDetail(Map<String, dynamic> item) {
    final imageUrl = item['image_url']?.toString() ?? '';
    final title    = item['title']?.toString() ?? 'Portfolio Item';
    final desc     = item['description']?.toString() ?? '';
    final date     = item['created_at'] != null
        ? _formatDate(item['created_at'].toString())
        : '';

    showModalBottomSheet(
      context:         context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color:        const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (imageUrl.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color:        const Color(0xFFF3F4F6),
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.network(
                  imageUrl,
                  width:  double.infinity,
                  fit:    BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Color(0xFFD1D5DB), size: 48),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827))),
                      ),
                      if (date.isNotEmpty)
                        Text(date,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF9CA3AF))),
                    ],
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(desc,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            height: 1.6)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sticky Bottom Bar — the ONLY place Message + Book Now appear ───
  Widget _buildBookBar() {
    final originalUserId = widget.professional['id'];

    final pro = {
      ...widget.professional,
      if (_fullProfile != null) ..._fullProfile!,
      'id':      originalUserId,
      'user_id': originalUserId,
    };

    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);
    final btnSize = ResponsiveUtils.sp(50, scale, min: 48, max: 62);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset:     const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(ResponsiveUtils.screenPadding(width, base: 16), 12, ResponsiveUtils.screenPadding(width, base: 16), 12),
          child: Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width * 0.28),
                child: Column(
                  mainAxisSize:     MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hourly Rate',
                        style: TextStyle(fontSize: ResponsiveUtils.sp(11, scale, min: 10, max: 14), color: const Color(0xFF9CA3AF))),
                    Text(
                      '\$${pro['hourly_rate'] ?? 0}/hr',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize:   ResponsiveUtils.sp(20, scale, min: 18, max: 25),
                          fontWeight: FontWeight.w800,
                          color:      context.colors.primary),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveUtils.sp(16, scale, min: 12, max: 20)),
              // Message — secondary outlined action.
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _isStartingChat ? null : () => _startConversation(pro),
                  child: Container(
                    width: btnSize, height: btnSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: context.colors.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isStartingChat
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.chat_bubble_outline_rounded, color: context.colors.primary, size: ResponsiveUtils.sp(22, scale, min: 20, max: 27)),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUtils.sp(10, scale, min: 8, max: 14)),
              // Book Now — primary filled, the strongest CTA on the screen.
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingScreen(
                        professional: Map<String, dynamic>.from(pro),
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(0, btnSize),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(AppStrings.bookNow,
                        style: TextStyle(
                            fontSize: ResponsiveUtils.sp(15, scale, min: 14, max: 18), fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Guest Bar ─────────────────────────────────────────────
  Widget _buildGuestBar() {
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(ResponsiveUtils.screenPadding(width, base: 16), 12, ResponsiveUtils.screenPadding(width, base: 16), 12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9CA3AF),
              minimumSize:     Size(double.infinity, ResponsiveUtils.sp(50, scale, min: 48, max: 62)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text('Login to Book',
                style: TextStyle(fontSize: ResponsiveUtils.sp(15, scale, min: 14, max: 18), fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  // ── Start (or open existing) conversation with this professional ────
  Future<void> _startConversation(Map<String, dynamic> pro) async {
    if (_isStartingChat) return;
    setState(() => _isStartingChat = true);
    try {
      final results = await Future.wait([
        _api.post(AppConstants.conversations, {'other_user_id': pro['user_id']}),
        _api.get(AppConstants.me),
      ]);
      if (!mounted) return;
      final data = results[0].data as Map<String, dynamic>;
      final myId = int.parse((results[1].data as Map<String, dynamic>)['id'].toString());

      await Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatScreen(
              conversationId: data['id'] is int ? data['id'] as int : int.parse(data['id'].toString()),
              currentUserId: myId,
              otherUserName: data['other_user_name']?.toString() ?? pro['name']?.toString() ?? 'Professional',
              otherUserPhoto: data['other_user_photo']?.toString(),
              conversationSnapshot: ConversationModel.fromJson(data),
            )));
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showError(context, 'Could not start conversation');
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)));
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color:        context.colors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: context.colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF))),
              Text(value,
                  style: TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color:      valueColor ?? const Color(0xFF374151),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab Bar Delegate ──────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => true;
}