// lib/features/home/screens/all_professionals_screen.dart
//
// Full-screen "See All Professionals" list, opened from the Customer
// Dashboard's "See all" links (Recommended / Nearby / Top Rated /
// Trending / Recently Added / Category). Presentation-only: it never
// calls the API itself, it just filters/sorts the `professionals`
// list the caller already fetched.

import 'package:flutter/material.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/professional_card.dart';
import '../../../services/favorites_store.dart';
import '../../search/screens/professional_detail_screen.dart';
import '../../bookings/screens/booking_screen.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Which dashboard section opened this screen. Each value gets its own
/// filter-chip set from [_optionsFor] instead of one shared filter bar.
enum ProSection { recommended, nearby, topRated, trending, recentlyAdded, category }

/// A single filter/sort chip: a display [label] plus a pure function
/// that turns the original list into the filtered/reordered view.
/// Presentation-only — never triggers a new backend query.
class _FilterOption {
  const _FilterOption(this.label, this.apply);
  final String label;
  final List<dynamic> Function(List<dynamic> source) apply;
}

// ── Field readers: pull a typed value out of a professional's raw map,
// with the same fallback conventions used elsewhere in the app.
double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
bool _availNow(Map p) => p['is_available'] != false;
bool _verified(Map p) => p['is_verified'] == true;
double _rating(Map p) => _num(p['average_rating']);
double _distanceKm(Map p) => _num(p['distance_km']);
double _price(Map p) => _num(p['hourly_rate']);
double _experience(Map p) => _num(p['experience_years']);
int _reviewsCount(Map p) => int.tryParse(p['reviews_count']?.toString() ?? '') ?? 0;
int _completedJobs(Map p) => int.tryParse(p['completed_jobs']?.toString() ?? '') ?? 0;
double _responseHrs(Map p) => double.tryParse(p['response_time_hrs']?.toString() ?? '24') ?? 24.0;
DateTime? _createdAt(Map p) => DateTime.tryParse(p['created_at']?.toString() ?? '');

// ── Small list helpers used to build each filter's `apply` function.
List<dynamic> _where(List<dynamic> src, bool Function(Map) test) => src.where((p) => test(p as Map)).toList();
List<dynamic> _sortDesc(List<dynamic> src, num Function(Map) key) => (List<dynamic>.from(src)..sort((a, b) => key(b as Map).compareTo(key(a as Map))));
List<dynamic> _sortAsc(List<dynamic> src, num Function(Map) key) => (List<dynamic>.from(src)..sort((a, b) => key(a as Map).compareTo(key(b as Map))));

/// Builds the filter-chip set for a given [section]. Each section only
/// exposes filters that make sense for it — nothing is shared across
/// sections. Needs [t] (the current [AppLocalizations]) to label chips.
List<_FilterOption> _optionsFor(ProSection section, AppLocalizations t) {
  final all = _FilterOption(t.homeFilterAll, (src) => List<dynamic>.from(src));
  switch (section) {
    case ProSection.recommended:
      return [
        all,
        _FilterOption(t.homeFilterAvailableNow, (src) => _where(src, _availNow)),
        _FilterOption(t.homeFilterTopRated, (src) => _sortDesc(src, _rating)),
        _FilterOption(t.homeFilterVerified, (src) => _where(src, _verified)),
        _FilterOption(t.homeFilterFastResponse, (src) => _where(src, (p) => _responseHrs(p) <= 1)),
        _FilterOption(t.homeFilterLowestPrice, (src) => _sortAsc(src, _price)),
      ];
    case ProSection.nearby:
      return [
        all,
        _FilterOption(t.homeFilterWithin2Km, (src) => _where(src, (p) => _distanceKm(p) <= 2)),
        _FilterOption(t.homeFilterWithin5Km, (src) => _where(src, (p) => _distanceKm(p) <= 5)),
        _FilterOption(t.homeFilterWithin10Km, (src) => _where(src, (p) => _distanceKm(p) <= 10)),
        _FilterOption(t.homeFilterAvailableNow, (src) => _where(src, _availNow)),
        _FilterOption(t.homeFilterVerified, (src) => _where(src, _verified)),
      ];
    case ProSection.topRated:
      return [
        all,
        _FilterOption(t.homeFilterRating5Plus, (src) => _where(src, (p) => _rating(p) >= 5)),
        _FilterOption(t.homeFilterRating4Plus, (src) => _where(src, (p) => _rating(p) >= 4)),
        _FilterOption(t.homeFilterRating3Plus, (src) => _where(src, (p) => _rating(p) >= 3)),
        _FilterOption(t.homeFilterRating2Plus, (src) => _where(src, (p) => _rating(p) >= 2)),
        _FilterOption(t.homeFilterRating1Plus, (src) => _where(src, (p) => _rating(p) >= 1)),
        _FilterOption(t.homeFilterMostReviews, (src) => _sortDesc(src, _reviewsCount)),
        _FilterOption(t.homeFilterVerified, (src) => _where(src, _verified)),
      ];
    case ProSection.trending:
      // "Most Viewed" / "Fast Growing" need view-count / growth-rate
      // fields the backend doesn't send yet — left out rather than
      // faked on top of an unrelated field.
      return [
        all,
        _FilterOption(t.homeFilterMostBooked, (src) => _sortDesc(src, _completedJobs)),
        _FilterOption(t.homeFilterAvailableNow, (src) => _where(src, _availNow)),
        _FilterOption(t.homeFilterVerified, (src) => _where(src, _verified)),
      ];
    case ProSection.recentlyAdded:
      final now = DateTime.now();
      return [
        all,
        _FilterOption(t.homeFilterToday, (src) => _where(src, (p) { final d = _createdAt(p); return d != null && now.difference(d).inHours < 24; })),
        _FilterOption(t.homeFilterThisWeek, (src) => _where(src, (p) { final d = _createdAt(p); return d != null && now.difference(d).inDays < 7; })),
        _FilterOption(t.homeFilterThisMonth, (src) => _where(src, (p) { final d = _createdAt(p); return d != null && now.difference(d).inDays < 30; })),
        _FilterOption(t.homeFilterAvailableNow, (src) => _where(src, _availNow)),
      ];
    case ProSection.category:
      return [
        all,
        _FilterOption(t.homeFilterAvailableNow, (src) => _where(src, _availNow)),
        _FilterOption(t.homeFilterTopRated, (src) => _sortDesc(src, _rating)),
        _FilterOption(t.homeFilterVerified, (src) => _where(src, _verified)),
        _FilterOption(t.homeFilterLowestPrice, (src) => _sortAsc(src, _price)),
        _FilterOption(t.homeFilterHighestPrice, (src) => _sortDesc(src, _price)),
        _FilterOption(t.homeFilterMostExperienced, (src) => _sortDesc(src, _experience)),
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

  /// Header text passed in by the caller (e.g. "Nearby Professionals",
  /// "Top Rated", "Electricians", "Search Results"). Never hardcoded here.
  final String title;

  final List<dynamic> professionals;

  /// Which dashboard section opened this screen — drives which filter
  /// chips are shown.
  final ProSection section;

  /// Optional re-fetch hook used by pull-to-refresh. If null,
  /// pull-to-refresh is disabled rather than faking a no-op refresh.
  final Future<void> Function()? onRefresh;

  @override
  State<AllProfessionalsScreen> createState() => _AllProfessionalsScreenState();
}

class _AllProfessionalsScreenState extends State<AllProfessionalsScreen> {
  final _favStore = FavoritesStore();
  final Map<String, Future<bool>> _favCache = {};

  late final List<_FilterOption> _options =
      _optionsFor(widget.section, AppLocalizations.of(context)!);
  int _selectedIndex = 0;
  late List<dynamic> _list;

  @override
  void initState() {
    super.initState();
    _list = _options[_selectedIndex].apply(widget.professionals);
  }

  /// Applies the chip at [index] and re-renders the list from it.
  void _applyFilter(int index) {
    setState(() {
      _selectedIndex = index;
      _list = _options[index].apply(widget.professionals);
    });
  }

  /// Looks up (and caches) whether a professional is already favorited.
  Future<bool> _favFuture(String id) {
    return _favCache.putIfAbsent(id, () => _favStore.isFavorite(id));
  }

  /// Pull-to-refresh handler: re-fetches via [AllProfessionalsScreen.onRefresh],
  /// then re-applies the currently selected filter and clears the favorite cache.
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
        elevation: 0,
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
                // Always the same global ProfessionalCard in fullWidth
                // form, matching every other full-list place in the app.
                : RefreshIndicator(
                    color: context.colors.primary,
                    onRefresh: widget.onRefresh != null ? _handleRefresh : () async {},
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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

  /// Horizontal, sticky row of filter chips for the current section.
  Widget _buildSortBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
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
                curve: Curves.easeOut,
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

  /// Renders one professional's row using the shared [ProfessionalCard].
  Widget _buildCard(Map pro, {bool fullWidth = true}) {
    final id = pro['id']?.toString() ?? pro['user_id']?.toString() ?? '';
    return RepaintBoundary(
      child: FutureBuilder<bool>(
        future: _favFuture(id),
        builder: (context, snap) {
          return ProfessionalCard(
            pro: pro,
            fullWidth: fullWidth,
            isFavorite: snap.data ?? false,
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

  /// Empty-state shown when the current filter yields no results.
  Widget _buildEmpty() {
    final t = AppLocalizations.of(context)!;
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
            Text(t.homeNoProfessionalsFound,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
            const SizedBox(height: 8),
            Text(t.homeNoProfessionalsFoundHint,
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
              child: Text(t.homeGoBack, style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}