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
import '../../../l10n/generated/app_localizations.dart';

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
  // ✅ FIX: /reviews/professionals/<id>/reviews/ returns a paginated object
  // ({summary, results, page, has_more}), not a bare list — _reviews only
  // ever holds the current page (max 10), so the true total (used for the
  // header/tab/pill counts and the Top Rated badge) is tracked separately.
  int _reviewsTotal = 0;
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
            if (data is Map) {
              // Paginated shape: {summary: {total_reviews, ...}, results: [...]}
              final list = data['results'];
              _reviews = list is List ? list : [];
              final summary = data['summary'];
              _reviewsTotal = summary is Map
                  ? (int.tryParse(summary['total_reviews']?.toString() ?? '') ?? _reviews.length)
                  : _reviews.length;
            } else if (data is List) {
              // Backward-compat, in case an older/unpaginated response shape is ever hit
              _reviews = data;
              _reviewsTotal = data.length;
            } else {
              _reviews = [];
              _reviewsTotal = 0;
            }
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

  String get _name      => _get('name')?.toString()      ?? AppLocalizations.of(context)!.professionalDefaultName;
  String get _photoUrl  => (_get('photo_url') ?? '').toString();
  bool   get _verified  => _get('is_verified') == true;
  double get _rating    => double.tryParse(_get('average_rating')?.toString() ?? '0') ?? 0.0;
  bool   get _isTopRated => _rating >= 4.5 && _reviewsTotal >= 5;
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
    if (hrs <= 0) return AppLocalizations.of(context)!.instantLabel;
    if (hrs < 1) return AppLocalizations.of(context)!.minutesLabel((hrs * 60).round());
    if (hrs == hrs.roundToDouble()) return AppLocalizations.of(context)!.hoursLabel(hrs.round());
    return AppLocalizations.of(context)!.hoursDecimalLabel(hrs.toStringAsFixed(1));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF5F7FA),
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
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _loadError ?? AppLocalizations.of(context)!.professionalDetailLoadError,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                AppLocalizations.of(context)!.retryCta,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.customerColor,
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
                        if (_verified) _headerBadge(Icons.verified_rounded, AppLocalizations.of(context)!.verifiedLabel, context.colors.accent),
                        if (_verified && _isTopRated) const SizedBox(width: 8),
                        if (_isTopRated) _headerBadge(Icons.star_rounded, AppLocalizations.of(context)!.topRatedLabel, AppColors.badgeTopRated),
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
                      '${_rating.toStringAsFixed(1)} (${_reviewsTotal} ${AppLocalizations.of(context)!.reviewsLabel})',
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
                          _isOnline ? AppLocalizations.of(context)!.onlineLabel : AppLocalizations.of(context)!.offlineLabel,
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
                      Expanded(child: _heroStatPill(Icons.star_rounded, _rating.toStringAsFixed(1), AppLocalizations.of(context)!.ratingLabel, scale)),
                      SizedBox(width: ResponsiveUtils.sp(10, scale, min: 8, max: 12)),
                      Expanded(child: _heroStatPill(Icons.forum_outlined, '${_reviewsTotal}', AppLocalizations.of(context)!.reviewsLabel, scale)),
                      SizedBox(width: ResponsiveUtils.sp(10, scale, min: 8, max: 12)),
                      Expanded(child: _heroStatPill(Icons.work_outline_rounded, '$_completedJobs', AppLocalizations.of(context)!.jobsDoneLabel, scale)),
                      SizedBox(width: ResponsiveUtils.sp(10, scale, min: 8, max: 12)),
                      Expanded(child: _heroStatPill(Icons.bolt_rounded, _responseTimeLabel, AppLocalizations.of(context)!.responseLabel, scale)),
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
      {'icon': Icons.calendar_today_outlined, 'label': AppLocalizations.of(context)!.memberSinceLabel, 'value': _memberSinceLabel},
      {'icon': Icons.event_available_outlined, 'label': AppLocalizations.of(context)!.availabilityLabel, 'value': _isAvailable ? AppLocalizations.of(context)!.availableNowLabel : AppLocalizations.of(context)!.currentlyBusyLabel},
      {'icon': Icons.language_rounded, 'label': AppLocalizations.of(context)!.languagesLabel, 'value': _languagesList.isNotEmpty ? _languagesList.join(', ') : AppLocalizations.of(context)!.notSpecifiedLabel},
      {'icon': Icons.work_history_outlined, 'label': AppLocalizations.of(context)!.experienceLabel, 'value': AppLocalizations.of(context)!.yearsLabel(_get('experience_years') ?? 0)},
    ];

    return SliverToBoxAdapter(
      child: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A)
            : Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.customerColor.withOpacity(0.15)
                  : context.colors.primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.customerColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
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
          labelColor:           AppColors.customerColor,
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor:       AppColors.customerColor,
          indicatorWeight:      2.5,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            const Tab(text: 'Overview'),
            Tab(text: 'Portfolio (${_portfolio.length})'),
            Tab(text: 'Reviews (${_reviewsTotal})'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bio.isNotEmpty) ...[
            _sectionTitle(AppLocalizations.of(context)!.aboutLabel),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                bio,
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.textPrimary,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          _sectionTitle(AppLocalizations.of(context)!.detailsLabel),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              children: [
                _detailRow(Icons.work_outline_rounded, AppLocalizations.of(context)!.experienceLabel, AppLocalizations.of(context)!.yearsLabel(exp)),
                const Divider(height: 20),
                _detailRow(Icons.attach_money_rounded, AppLocalizations.of(context)!.hourlyRateLabel,
                    '\$${_get('hourly_rate') ?? 0}/hr'),
                const Divider(height: 20),
                _detailRow(Icons.location_on_outlined, AppLocalizations.of(context)!.cityLabel,
                    (_get('city') ?? 'N/A').toString()),
                const Divider(height: 20),
                _detailRow(
                  Icons.verified_outlined,
                  AppLocalizations.of(context)!.verificationLabel,
                  _verified ? AppLocalizations.of(context)!.verifiedProfessionalLabel : AppLocalizations.of(context)!.notVerifiedLabel,
                  valueColor: _verified ? context.colors.accent : AppColors.warning,
                ),
                if ((_get('category_name') ?? '').toString().isNotEmpty) ...[
                  const Divider(height: 20),
                  _detailRow(Icons.category_outlined, AppLocalizations.of(context)!.categoryLabel,
                      _get('category_name').toString()),
                ],
              ],
            ),
          ),

          if (_skillsList.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle(AppLocalizations.of(context)!.skillsLabel),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skillsList.map((s) => _pillChip(s)).toList(),
            ),
          ],

          if (_verified || _isTopRated || _isFastResponder || _certificates.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionTitle(AppLocalizations.of(context)!.certificationsLabel),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (_verified) _badgeTile(Icons.verified_user_rounded, AppLocalizations.of(context)!.idVerifiedLabel, context.colors.accent),
                if (_isTopRated) _badgeTile(Icons.workspace_premium_rounded, AppLocalizations.of(context)!.topRatedLabel, AppColors.badgeTopRated),
                if (_isFastResponder) _badgeTile(Icons.bolt_rounded, AppLocalizations.of(context)!.fastResponseLabel, AppColors.info),
              ],
            ),
            if (_certificates.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._certificates.map((c) => _certificateRow(c)),
            ],
          ],

          if (_related.isNotEmpty) ...[
            const SizedBox(height: 24),
            _sectionTitle(AppLocalizations.of(context)!.relatedProfessionalsLabel),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.customerColor.withOpacity(0.15)
            : context.colors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppColors.customerColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.customerColor,
            ),
          ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _certificateRow(dynamic cert) {
    final title = cert['title']?.toString() ?? 'Certificate';
    final org   = cert['issuing_organization']?.toString() ?? '';
    final date  = cert['issue_date'] != null ? _formatDate(cert['issue_date'].toString()) : '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.customerColor.withOpacity(0.15)
                  : context.colors.primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.school_outlined,
              size: 17,
              color: AppColors.customerColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
                if (org.isNotEmpty)
                  Text(
                    org,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (date.isNotEmpty)
            Text(
              date,
              style: TextStyle(
                fontSize: 11,
                color: context.colors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  // ── Services Tab ─────────────────────────────────────────
  Widget _buildServicesTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_servicesList.isEmpty) {
      return _emptyTabState(
        Icons.design_services_outlined,
        AppLocalizations.of(context)!.noServicesTitle,
        AppLocalizations.of(context)!.noServicesSubtitle,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _servicesList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.customerColor.withOpacity(0.15)
                    : context.colors.accentLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 17,
                color: AppColors.customerColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _servicesList[i],
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isAvailable
                  ? (isDark
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : context.colors.accentLight)
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF3F4F6)),
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
                    _isAvailable
                        ? AppLocalizations.of(context)!.acceptingBookingsLabel
                        : AppLocalizations.of(context)!.notAcceptingBookingsLabel,
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
          _sectionTitle(AppLocalizations.of(context)!.workingHoursLabel),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: _detailRow(Icons.schedule_rounded, AppLocalizations.of(context)!.dailyHoursLabel, '$start – $end'),
          ),
          const SizedBox(height: 16),
          _sectionTitle(AppLocalizations.of(context)!.responseTimeLabel),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: _detailRow(Icons.bolt_rounded, AppLocalizations.of(context)!.typicallyRepliesLabel, _responseTimeLabel),
          ),
        ],
      ),
    );
  }

  Widget _emptyTabState(IconData icon, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: isDark
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.colors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reviews Tab ──────────────────────────────────────────
  Widget _buildReviewsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_reviews.isEmpty) {
      return _emptyTabState(
        Icons.rate_review_outlined,
        AppLocalizations.of(context)!.noReviewsTitle,
        AppLocalizations.of(context)!.noReviewsSubtitle,
      );
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
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE5E7EB),
            ),
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
                          review['reviewer_name']?.toString() ?? AppLocalizations.of(context)!.userLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        if (date.isNotEmpty)
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.textSecondary,
                            ),
                          ),
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
                Text(
                  review['comment'].toString(),
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Portfolio Tab ─────────────────────────────────────────
  Widget _buildPortfolioTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_portfolio.isEmpty) {
      return _emptyTabState(
        Icons.photo_library_outlined,
        AppLocalizations.of(context)!.noPortfolioTitle,
        AppLocalizations.of(context)!.noPortfolioSubtitle,
      );
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.15)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : const Color(0xFFF3F4F6),
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  color: Color(0xFFD1D5DB), size: 32),
                            ),
                          ),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : const Color(0xFFF3F4F6),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: AppColors.customerColor,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : context.colors.primaryLight,
                          child: Center(
                            child: Icon(Icons.image_outlined,
                                color: isDark
                                    ? Colors.white.withOpacity(0.3)
                                    : context.colors.primary.withOpacity(0.4),
                                size: 36),
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
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.textSecondary,
                          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context:         context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (imageUrl.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF3F4F6),
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.network(
                  imageUrl,
                  width:  double.infinity,
                  fit:    BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: isDark
                            ? Colors.white.withOpacity(0.3)
                            : const Color(0xFFD1D5DB),
                        size: 48),
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
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                      if (date.isNotEmpty)
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textSecondary,
                        height: 1.6,
                      ),
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

  // ── Sticky Bottom Bar — the ONLY place Message + Book Now appear ───
  Widget _buildBookBar() {
    final originalUserId = widget.professional['id'];
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);
    final btnSize = ResponsiveUtils.sp(50, scale, min: 48, max: 62);

    final pro = {
      ...widget.professional,
      if (_fullProfile != null) ..._fullProfile!,
      'id':      originalUserId,
      'user_id': originalUserId,
    };

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
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
                    Text(
                      AppLocalizations.of(context)!.hourlyRateLabel,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.sp(11, scale, min: 10, max: 14),
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
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
                    child: Text(
                      AppLocalizations.of(context)!.bookNowCta,
                      style: TextStyle(
                          fontSize: ResponsiveUtils.sp(15, scale, min: 14, max: 18),
                          fontWeight: FontWeight.w700),
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

  // ── Guest Bar ─────────────────────────────────────────────
  Widget _buildGuestBar() {
    final width = MediaQuery.sizeOf(context).width;
    final scale = ResponsiveUtils.scaleForWidth(width);

    return Container(
      color: context.colors.surface,
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
            child: Text(
              AppLocalizations.of(context)!.loginToBookCta,
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(15, scale, min: 14, max: 18),
                fontWeight: FontWeight.w700,
              ),
            ),
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
              otherUserName: data['other_user_name']?.toString() ?? pro['name']?.toString() ?? AppLocalizations.of(context)!.professionalDefaultName,
              otherUserPhoto: data['other_user_photo']?.toString(),
              conversationSnapshot: ConversationModel.fromJson(data),
            )));
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showError(context, AppLocalizations.of(context)!.startConversationError);
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
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: context.colors.textPrimary,
        letterSpacing: -0.1,
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.customerColor.withOpacity(0.15)
                : context.colors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 17,
            color: AppColors.customerColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : const Color(0xFF9CA3AF),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? context.colors.textPrimary,
                ),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark
          ? const Color(0xFF0F172A)
          : Colors.white,
      child: tabBar,
    );
  }

  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => true;
}