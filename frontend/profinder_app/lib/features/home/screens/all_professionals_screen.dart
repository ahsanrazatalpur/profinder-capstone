// lib/features/home/screens/all_professionals_screen.dart
//
// Full-screen "See All Professionals" — replaces the old 85%-height
// DraggableScrollableSheet used from the Customer Dashboard's section
// "See all" links (Recommended / Nearby / Top Rated / Trending /
// Recently Added / Category).
//
// 🚨 UI/UX ONLY. This screen does NOT call any API, does NOT change what
// data a section shows, and does NOT touch favourites/booking/detail
// logic — it renders exactly the `professionals` list the caller already
// fetched (same as the old sheet did), using the same ProfessionalCard,
// FavoritesStore, ProfessionalDetailScreen, and BookingScreen the rest
// of the app already uses.
//
// FILTER CHIPS ARE CONTEXT-AWARE (see `ProSection` + `_optionsFor` below):
// each section (Recommended / Nearby / Top Rated / Trending / Recently
// Added / Category) gets its own relevant chip set instead of one
// universal filter bar shared by every screen. All filtering/sorting is
// still a client-side, presentation-only transform of the already-fetched
// `professionals` list — never a new backend query.

import 'package:flutter/material.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/professional_card.dart';
import '../../../services/favorites_store.dart';
import '../../search/screens/professional_detail_screen.dart';
import '../../bookings/screens/booking_screen.dart';

// ── Which dashboard section opened this "See all" page. Every value here
// gets its OWN filter-chip set in `_optionsFor()` below — a marketplace
// never shows one universal filter bar on every screen (Fiverr / Airbnb /
// Thumbtack all scope filters to what the section actually means), so this
// is the single source of truth the chip bar reads from instead of
// guessing from which data fields happen to be present.
enum ProSection { recommended, nearby, topRated, trending, recentlyAdded, category }

// ── One filter/sort chip: a label plus a pure function that turns the
// original (already-fetched) list into the filtered/reordered view. This
// is presentation only — same as the sort this screen already did before —
// no new query, no backend call, nothing here changes what data exists.
class _FilterOption {
  const _FilterOption(this.label, this.apply);
  final String label;
  final List<dynamic> Function(List<dynamic> source) apply;
}

double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
bool _availNow(Map p)  => p['is_available'] != false; // same default-true convention as professional_detail_screen
bool _verified(Map p)  => p['is_verified'] == true;
double _rating(Map p)   => _num(p['average_rating']);
double _distanceKm(Map p) => _num(p['distance_km']);
double _price(Map p)    => _num(p['hourly_rate']);
double _experience(Map p) => _num(p['experience_years']);
int _reviewsCount(Map p) => int.tryParse(p['reviews_count']?.toString() ?? '') ?? 0;
int _completedJobs(Map p) => int.tryParse(p['completed_jobs']?.toString() ?? '') ?? 0;
// Same "fast responder" threshold professional_detail_screen already uses
// (<=1hr), and the same 24hr fallback when the backend hasn't sent a value.
double _responseHrs(Map p) => double.tryParse(p['response_time_hrs']?.toString() ?? '24') ?? 24.0;
DateTime? _createdAt(Map p) => DateTime.tryParse(p['created_at']?.toString() ?? '');

List<dynamic> _where(List<dynamic> src, bool Function(Map) test) => src.where((p) => test(p as Map)).toList();
List<dynamic> _sortDesc(List<dynamic> src, num Function(Map) key) => (List<dynamic>.from(src)..sort((a, b) => key(b as Map).compareTo(key(a as Map))));
List<dynamic> _sortAsc(List<dynamic> src, num Function(Map) key)  => (List<dynamic>.from(src)..sort((a, b) => key(a as Map).compareTo(key(b as Map))));

// ── Context-aware filter chips, one set per section — this is the actual
// fix. Each section only exposes filters that make sense for *that*
// section's purpose; nothing is shared or reused across sections.
List<_FilterOption> _optionsFor(ProSection section) {
  final all = _FilterOption('All', (src) => List<dynamic>.from(src));
  switch (section) {
    case ProSection.recommended:
      return [
        all,
        _FilterOption('Available Now', (src) => _where(src, _availNow)),
        _FilterOption('Top Rated', (src) => _sortDesc(src, _rating)),
        _FilterOption('Verified', (src) => _where(src, _verified)),
        _FilterOption('Fast Response', (src) => _where(src, (p) => _responseHrs(p) <= 1)),
        _FilterOption('Lowest Price', (src) => _sortAsc(src, _price)),
      ];
    case ProSection.nearby:
      return [
        all,
        _FilterOption('Within 2 km', (src) => _where(src, (p) => _distanceKm(p) <= 2)),
        _FilterOption('Within 5 km', (src) => _where(src, (p) => _distanceKm(p) <= 5)),
        _FilterOption('Within 10 km', (src) => _where(src, (p) => _distanceKm(p) <= 10)),
        _FilterOption('Available Now', (src) => _where(src, _availNow)),
        _FilterOption('Verified', (src) => _where(src, _verified)),
      ];
    case ProSection.topRated:
      return [
        all,
        _FilterOption('5+', (src) => _where(src, (p) => _rating(p) >= 5)),
        _FilterOption('4+', (src) => _where(src, (p) => _rating(p) >= 4)),
        _FilterOption('3+', (src) => _where(src, (p) => _rating(p) >= 3)),
        _FilterOption('2+', (src) => _where(src, (p) => _rating(p) >= 2)),
        _FilterOption('1+', (src) => _where(src, (p) => _rating(p) >= 1)),
        _FilterOption('Most Reviews', (src) => _sortDesc(src, _reviewsCount)),
        _FilterOption('Verified', (src) => _where(src, _verified)),
      ];
    case ProSection.trending:
      // NOTE: "Most Viewed" / "Fast Growing" from the spec need view-count
      // / growth-rate fields the backend doesn't send today. Per the "no
      // backend changes" constraint, these are left out rather than faked
      // on top of an unrelated field — flag this to backend if you want
      // them wired up for real.
      return [
        all,
        _FilterOption('Most Booked', (src) => _sortDesc(src, _completedJobs)),
        _FilterOption('Available Now', (src) => _where(src, _availNow)),
        _FilterOption('Verified', (src) => _where(src, _verified)),
      ];
    case ProSection.recentlyAdded:
      final now = DateTime.now();
      return [
        all,
        _FilterOption('Today', (src) => _where(src, (p) { final d = _createdAt(p); return d != null && now.difference(d).inHours < 24; })),
        _FilterOption('This Week', (src) => _where(src, (p) { final d = _createdAt(p); return d != null && now.difference(d).inDays < 7; })),
        _FilterOption('This Month', (src) => _where(src, (p) { final d = _createdAt(p); return d != null && now.difference(d).inDays < 30; })),
        _FilterOption('Available Now', (src) => _where(src, _availNow)),
      ];
    case ProSection.category:
      return [
        all,
        _FilterOption('Available Now', (src) => _where(src, _availNow)),
        _FilterOption('Top Rated', (src) => _sortDesc(src, _rating)),
        _FilterOption('Verified', (src) => _where(src, _verified)),
        _FilterOption('Lowest Price', (src) => _sortAsc(src, _price)),
        _FilterOption('Highest Price', (src) => _sortDesc(src, _price)),
        _FilterOption('Most Experienced', (src) => _sortDesc(src, _experience)),
      ];
  }
}

class AllProfessionalsScreen extends StatefulWidget {
  const AllProfessionalsScreen({
    super.key,
    required this.title,
    required this.professionals,
    required this.section,
    this.onRefresh,
  });

  /// Dynamic — whatever section header the caller passed in
  /// ("Nearby Professionals", "Top Rated", "Electricians", "Search
  /// Results", etc). Never hardcoded here.
  final String title;

  final List<dynamic> professionals;

  /// Which dashboard section opened this screen — drives which filter
  /// chips get shown. Required so a caller can never forget to say which
  /// section this is and accidentally fall back to a generic chip set.
  final ProSection section;

  /// Optional — if the caller can re-fetch (e.g. from a live search),
  /// pull-to-refresh calls this. If null, pull-to-refresh is disabled
  /// rather than faking a refresh that does nothing.
  final Future<void> Function()? onRefresh;

  @override
  State<AllProfessionalsScreen> createState() => _AllProfessionalsScreenState();
}

class _AllProfessionalsScreenState extends State<AllProfessionalsScreen> {
  final _favStore = FavoritesStore();
  final Map<String, Future<bool>> _favCache = {};

  late final List<_FilterOption> _options = _optionsFor(widget.section);
  int _selectedIndex = 0;
  late List<dynamic> _list;

  @override
  void initState() {
    super.initState();
    _list = _options[_selectedIndex].apply(widget.professionals);
  }

  void _applyFilter(int index) {
    setState(() {
      _selectedIndex = index;
      _list = _options[index].apply(widget.professionals);
    });
  }

  Future<bool> _favFuture(String id) {
    return _favCache.putIfAbsent(id, () => _favStore.isFavorite(id));
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh == null) return;
    await widget.onRefresh!();
    if (!mounted) return;
    setState(() {
      _list = _options[_selectedIndex].apply(widget.professionals);
      _favCache.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation:       0,
        scrolledUnderElevation: 1,
        surfaceTintColor: context.colors.surface,
        title: Text(widget.title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                letterSpacing: -0.2, color: context.colors.textPrimary)),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSortBar(),
          Expanded(
            child: _list.isEmpty
                ? _buildEmpty()
                // 🔧 FIX: always the SAME global ProfessionalCard, in the
                // same fullWidth form it already uses in every other
                // full-list place in the app (old "See all" sheet,
                // Saved Professionals, etc). Previously this switched to
                // a 2-column GridView with fullWidth:false on wide
                // screens — that's the card's narrow *carousel* mode
                // (fixed ~230px width), which doesn't stretch to fill a
                // grid cell, so it visually read as a different card.
                // One card, one rendering, everywhere.
                : RefreshIndicator(
                    color:     context.colors.primary,
                    onRefresh: widget.onRefresh != null ? _handleRefresh : () async {},
                    child: ListView.separated(
                      padding:  const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _buildCard(_list[i] as Map),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Sticky filter bar — chips are entirely driven by `widget.section`
  // (see `_optionsFor`), so Recommended / Nearby / Top Rated / Trending /
  // Recently Added / Category each show their own relevant chips instead
  // of one shared universal set. Still presentation-only reorder/filter
  // of the already-fetched list — no new query.
  Widget _buildSortBar() {
    return Container(
      decoration: BoxDecoration(
        color:  context.colors.surface,
        border: Border(bottom: BorderSide(color: context.colors.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_options.length, (i) {
            final selected = _selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve:    Curves.easeOut,
                child: ChoiceChip(
                  label: Text(_options[i].label,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : context.colors.textPrimary)),
                  selected: selected,
                  onSelected: (_) => _applyFilter(i),
                  selectedColor: context.colors.primary,
                  backgroundColor: context.colors.background,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(color: selected ? context.colors.primary : context.colors.divider),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCard(Map pro, {bool fullWidth = true}) {
    final id = pro['id']?.toString() ?? pro['user_id']?.toString() ?? '';
    return RepaintBoundary(
      child: FutureBuilder<bool>(
        future: _favFuture(id),
        builder: (context, snap) {
          return ProfessionalCard(
            pro:              pro,
            fullWidth:        fullWidth,
            isFavorite:       snap.data ?? false,
            onFavoriteToggle: () async {
              await _favStore.toggle(Map<String, dynamic>.from(pro));
              _favCache.remove(id);
              setState(() {});
            },
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ProfessionalDetailScreen(professional: Map<String, dynamic>.from(pro)))),
            onBookNow: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => BookingScreen(professional: Map<String, dynamic>.from(pro)))),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84, height: 84,
              decoration: BoxDecoration(color: context.colors.primaryLight, shape: BoxShape.circle),
              child: Icon(Icons.person_search_rounded, size: 40, color: context.colors.primary),
            ),
            const SizedBox(height: 20),
            Text('No professionals found',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
            const SizedBox(height: 8),
            Text('Try a different category or check back later',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: context.colors.textSecondary)),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: context.colors.primary),
              ),
              child: Text('Go Back', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}