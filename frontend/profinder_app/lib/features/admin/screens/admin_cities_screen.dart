// lib/features/admin/screens/admin_cities_screen.dart
//
// Content Management → Cities (nested under a Country — a city without
// its country context is meaningless, per design spec).
//
// Backend:
//   GET    /api/admin-panel/cities/?country=<id>
//   POST   /api/admin-panel/cities/            { name, country, status }
//   PATCH  /api/admin-panel/cities/<id>/        { status }
//   DELETE /api/admin-panel/cities/<id>/
//   POST   /api/admin-panel/cities/<id>/merge/  { variants: [...] }
//
// NOTE (UI/UX pass): endpoints, request payloads, and success-path control
// flow are unchanged from the original implementation. The only functional
// change is in error handling for Add/Merge — failures now surface the
// backend's actual message (via _friendlyError) inline in the dialog
// instead of a generic string, and the submit buttons show a loading state
// and are disabled mid-request to prevent double-submits. If Add/Merge
// still fail after this, the dialog will now show the real backend reason
// (e.g. a validation error) instead of hiding it.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../shared/widgets/universal_app_bar.dart';

// Responsive breakpoints for switching between a single-column list
// (mobile) and a multi-column grid (tablet/desktop).
const double _kTabletBreakpoint = 700;
const double _kDesktopBreakpoint = 1100;
// Caps content width on very wide desktop windows so cards don't stretch
// edge-to-edge and become hard to scan.
const double _kMaxContentWidth = 1400;

class AdminCitiesScreen extends StatefulWidget {
  final dynamic country; // {id, name, ...} — null means "all cities"
  const AdminCitiesScreen({super.key, this.country});

  @override
  State<AdminCitiesScreen> createState() => _AdminCitiesScreenState();
}

class _AdminCitiesScreenState extends State<AdminCitiesScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _cities = [];

  // True when this screen is scoped to a single country (opened from a
  // Country's detail page) rather than showing every city in the system.
  bool get isNested => widget.country != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final query = widget.country != null ? '?country=${widget.country['id']}' : '';
      final r = await _api.get('/admin-panel/cities/$query');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _cities = r.data is List ? List<dynamic>.from(r.data) : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load cities'; });
    }
  }

  Future<void> _toggleStatus(dynamic c) async {
    final newStatus = c['status'] == 'active' ? 'coming_soon' : 'active';
    try {
      await _api.patch('/admin-panel/cities/${c['id']}/', {'status': newStatus});
      _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack(_friendlyError(e, 'Failed to update.'));
    }
  }

  Future<void> _delete(dynamic c) async {
    try {
      await _api.delete('/admin-panel/cities/${c['id']}/');
      _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack(_friendlyError(e, 'Failed to delete.'));
    }
  }

  // Pulls the actual validation/error message out of a failed API call
  // instead of always showing a generic string. DRF-style backends return
  // errors as {"detail": "..."} or {"field": ["msg"]} — surfacing the real
  // reason (e.g. "This city already exists", "country: this field is
  // required") is what actually lets Add/Merge failures be diagnosed from
  // the UI instead of silently failing with no clue why.
  String _friendlyError(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final direct = data['message'] ?? data['detail'] ?? data['error'];
        if (direct != null && direct.toString().trim().isNotEmpty) {
          return direct.toString();
        }
        for (final value in data.values) {
          if (value is List && value.isNotEmpty) return value.first.toString();
          if (value is String && value.trim().isNotEmpty) return value;
        }
      } else if (data is String && data.trim().isNotEmpty) {
        return data;
      }
    }
    return fallback;
  }

  // Centralised snackbar so every failure path looks consistent instead of
  // the default Material SnackBar styling.
  void _showSnack(String message, {IconData icon = Icons.error_outline_rounded}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  void _addDialog(dynamic targetCountry) async {
    // ✅ FIX: showDialog() called synchronously from a button's onPressed,
    // while the grid behind it still has many hover-tracking MouseRegion
    // cards mounted, crashes Flutter's MouseTracker on web/desktop
    // ("BoxConstraints forces an infinite width" + cascading "Assertion
    // failed" errors — the dialog then never actually renders, just the
    // dark barrier). Waiting one frame lets the click's pointer-up event
    // fully settle before the new route's own MouseRegions get pushed.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      // `submitting`/`errorText` live in THIS outer builder, which Flutter
      // calls only once per showDialog(). They must NOT be declared inside
      // the StatefulBuilder's own builder below — that one re-runs on every
      // setDialogState call, which would silently reset them back to their
      // initial values on every rebuild and make the loading/error state
      // never actually appear.
      builder: (dialogContext) {
        bool submitting = false;
        String? errorText;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              setDialogState(() { submitting = true; errorText = null; });
              try {
                await _api.post('/admin-panel/cities/', {
                  'name': name, 'country': targetCountry['id'],
                });
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                _load();
              } catch (e) {
                // Keep the dialog open on failure and show the real reason
                // inline, rather than closing and leaving the user guessing
                // why nothing was added.
                setDialogState(() {
                  submitting = false;
                  errorText = _friendlyError(e, 'Failed to add — may already exist.');
                });
              }
            }

            return _StyledDialog(
              icon: Icons.add_location_alt_rounded,
              iconColor: AppColors.adminColor,
              title: 'Add City to ${targetCountry['name']}',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StyledTextField(
                    controller: nameCtrl,
                    hintText: 'City name',
                    autofocus: true,
                    enabled: !submitting,
                    onSubmitted: (_) => submit(),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    _InlineFormError(message: errorText!),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B7280)),
                  onPressed: submitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.adminColor.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // FAB entry point. When this screen is scoped to a country, add directly
  // into it; otherwise (the global "All Cities" view) the country isn't
  // known yet, so a picker runs first and then hands off to the same
  // _addDialog above.
  void _addFabPressed() {
    if (isNested) {
      _addDialog(widget.country);
    } else {
      _pickCountryThenAdd();
    }
  }

  // Fetches the country list and lets the admin pick one before adding a
  // city, for the case where this screen has no single-country context
  // (opened from the global "All Cities" tab rather than from a Country's
  // detail page).
  void _pickCountryThenAdd() async {
    // ✅ FIX: see _addDialog above — same MouseTracker crash fix.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final searchCtrl = TextEditingController();
    bool loading = true;
    String? error;
    List<dynamic> countries = [];
    bool fetchStarted = false;

    Future<void> fetchCountries(void Function(void Function()) setDialogState) async {
      try {
        final r = await _api.get('/admin-panel/countries/');
        countries = r.data is List ? List<dynamic>.from(r.data) : [];
      } catch (e) {
        error = _friendlyError(e, 'Failed to load countries.');
      }
      loading = false;
      setDialogState(() {});
    }

    showDialog(
      context: context,
      // Same rule as _addDialog: all mutable state above lives in this
      // outer builder (called once), not inside StatefulBuilder's builder.
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          // Kick off the fetch exactly once, the first time this dialog
          // is built, using the fetchStarted guard from the outer scope.
          if (!fetchStarted) {
            fetchStarted = true;
            fetchCountries(setDialogState);
          }

          final query = searchCtrl.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? countries
              : countries.where((c) => c['name'].toString().toLowerCase().contains(query)).toList();

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.adminColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.public_rounded, color: AppColors.adminColor, size: 22),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Which country is this city in?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 14),
                    _StyledTextField(
                      controller: searchCtrl,
                      hintText: 'Search countries...',
                      onChanged: () => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: loading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.adminColor),
                                ),
                              ),
                            )
                          : error != null
                              ? _InlineFormError(message: error!)
                              : filtered.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 24),
                                      child: Center(
                                        child: Text('No countries found.', style: TextStyle(color: Color(0xFF9CA3AF))),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: filtered.length,
                                      itemBuilder: (_, i) {
                                        final country = filtered[i];
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: const Icon(Icons.flag_rounded, size: 18, color: Color(0xFF6B7280)),
                                          title: Text(
                                            country['name']?.toString() ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                          onTap: () {
                                            Navigator.pop(dialogContext);
                                            _addDialog(country);
                                          },
                                        );
                                      },
                                    ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B7280)),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _mergeDialog(dynamic city) async {
    // ✅ FIX: see _addDialog above — same MouseTracker crash fix.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final variantsCtrl = TextEditingController();
    showDialog(
      context: context,
      // See _addDialog: this state must live in the outer (once-called)
      // builder, not inside StatefulBuilder's own builder.
      builder: (dialogContext) {
        bool submitting = false;
        String? errorText;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final variants = variantsCtrl.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              if (variants.isEmpty) return;
              setDialogState(() { submitting = true; errorText = null; });
              try {
                final r = await _api.post('/admin-panel/cities/${city['id']}/merge/', {'variants': variants});
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                _showSnack(r.data['message']?.toString() ?? 'Merged.', icon: Icons.check_circle_outline_rounded);
                _load(); // Refresh — merge succeeds on the backend but the list
                         // needs a reload to stop showing the now-merged variant.
              } catch (e) {
                // Stay open and show the real reason (e.g. a variant that
                // doesn't exist, or belongs to another city) instead of just
                // closing with a generic "Merge failed."
                setDialogState(() {
                  submitting = false;
                  errorText = _friendlyError(e, 'Merge failed.');
                });
              }
            }

            return _StyledDialog(
              icon: Icons.merge_type_rounded,
              iconColor: AppColors.adminColor,
              title: 'Merge into "${city['name']}"',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter typo/variant spellings, comma-separated.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  _StyledTextField(
                    controller: variantsCtrl,
                    hintText: 'variant1, variant2, ...',
                    autofocus: true,
                    enabled: !submitting,
                    onSubmitted: (_) => submit(),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    _InlineFormError(message: errorText!),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B7280)),
                  onPressed: submitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.adminColor.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Merge', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: UniversalAppBar(
        title: isNested ? 'Cities — ${widget.country['name']}' : 'All Cities',
        icon: Icons.location_city_rounded,
        showBack: isNested,
      ),
      // FAB is available on both the nested (single-country) and global
      // "All Cities" screens. When there's no country context yet, pressing
      // it opens a country picker first (see _addFabPressed).
      floatingActionButton: _EntranceScale(
        child: FloatingActionButton.extended(
          // Unique tag prevents "multiple heroes share the same tag"
          // crashes when this screen stays mounted alongside other
          // admin screens that also have a FAB (e.g. behind a
          // bottom-nav IndexedStack that keeps tabs alive).
          heroTag: 'admin_cities_fab',
          backgroundColor: AppColors.adminColor,
          elevation: 3,
          onPressed: _addFabPressed,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add City', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width >= _kDesktopBreakpoint ? 3 : (width >= _kTabletBreakpoint ? 2 : 1);

            return Column(
              children: [
                Expanded(
                  // Cross-fades between loading/error/empty/content instead
                  // of an abrupt jump when the API call resolves.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _loading
                        ? const Center(
                            key: ValueKey('loading'),
                            child: CircularProgressIndicator(color: AppColors.adminColor, strokeWidth: 2.5),
                          )
                        : _error != null
                            ? _ErrorState(key: const ValueKey('error'), onRetry: _load)
                            : _cities.isEmpty
                                ? const _EmptyState(key: ValueKey('empty'))
                                : _CitiesList(
                                    key: const ValueKey('content'),
                                    cities: _cities,
                                    isNested: isNested,
                                    crossAxisCount: crossAxisCount,
                                    onRefresh: _load,
                                    onToggle: _toggleStatus,
                                    onMerge: _mergeDialog,
                                    onDelete: _delete,
                                  ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Renders the city collection as either a single-column list (mobile) or
/// a multi-column grid (tablet/desktop), sharing the same refresh/scroll
/// behaviour and card widget either way.
///
/// IMPORTANT: card content here is sized by its own intrinsic height (no
/// Expanded/Spacer inside a scroll view) — mixing a flexible child with an
/// unbounded-height parent is what previously caused a RenderFlex layout
/// exception and a blank/broken screen.
class _CitiesList extends StatelessWidget {
  final List<dynamic> cities;
  final bool isNested;
  final int crossAxisCount;
  final Future<void> Function() onRefresh;
  final ValueChanged<dynamic> onToggle;
  final ValueChanged<dynamic> onMerge;
  final ValueChanged<dynamic> onDelete;

  const _CitiesList({
    super.key,
    required this.cities,
    required this.isNested,
    required this.crossAxisCount,
    required this.onRefresh,
    required this.onToggle,
    required this.onMerge,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.adminColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          // "All Cities" (isNested == false) mixes every country's cities
          // together — 60-70 rows back to back is unreadable, so group by
          // country there. A single-country view is already scoped, so it
          // keeps the plain flat list/grid.
          child: !isNested
              ? _GroupedCitiesList(
                  cities: cities,
                  crossAxisCount: crossAxisCount,
                  onToggle: onToggle,
                  onMerge: onMerge,
                  onDelete: onDelete,
                )
              : crossAxisCount == 1
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                      itemCount: cities.length,
                      itemBuilder: (_, i) => _AnimatedListEntry(
                        index: i,
                        child: _CityCard(
                          city: cities[i],
                          isNested: isNested,
                          onToggle: onToggle,
                          onMerge: onMerge,
                          onDelete: onDelete,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        // A fixed extent (rather than an aspect ratio) keeps
                        // card height predictable regardless of content length.
                        mainAxisExtent: isNested ? 168 : 190,
                      ),
                      itemCount: cities.length,
                      itemBuilder: (_, i) => _AnimatedListEntry(
                        index: i,
                        child: _CityCard(
                          city: cities[i],
                          isNested: isNested,
                          onToggle: onToggle,
                          onMerge: onMerge,
                          onDelete: onDelete,
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}

/// Groups the "All Cities" list by country so a flat run of 60-70 cities
/// becomes readable sections — each country gets a header (name + city
/// count) followed by just its own cities, sorted alphabetically by
/// country. City records already carry `country_name` from CitySerializer.
class _GroupedCitiesList extends StatelessWidget {
  final List<dynamic> cities;
  final int crossAxisCount;
  final ValueChanged<dynamic> onToggle;
  final ValueChanged<dynamic> onMerge;
  final ValueChanged<dynamic> onDelete;

  const _GroupedCitiesList({
    required this.cities,
    required this.crossAxisCount,
    required this.onToggle,
    required this.onMerge,
    required this.onDelete,
  });

  Map<String, List<dynamic>> _grouped() {
    final map = <String, List<dynamic>>{};
    for (final c in cities) {
      final country = (c['country_name'] ?? 'Unknown').toString();
      map.putIfAbsent(country, () => []).add(c);
    }
    final sortedKeys = map.keys.toList()..sort((a, b) => a.compareTo(b));
    return {for (final k in sortedKeys) k: map[k]!};
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped();
    final countryNames = groups.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      itemCount: countryNames.length,
      itemBuilder: (_, i) {
        final country = countryNames[i];
        final list = groups[country]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CountryGroupHeader(name: country, count: list.length),
              const SizedBox(height: 10),
              crossAxisCount == 1
                  ? Column(
                      children: [
                        for (final c in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CityCard(
                              city: c,
                              isNested: false,
                              onToggle: onToggle,
                              onMerge: onMerge,
                              onDelete: onDelete,
                            ),
                          ),
                      ],
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 190,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, j) => _CityCard(
                        city: list[j],
                        isNested: false,
                        onToggle: onToggle,
                        onMerge: onMerge,
                        onDelete: onDelete,
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}

/// Section header for one country's group of cities: a small accent bar,
/// the country name, and a count pill for how many cities it has.
class _CountryGroupHeader extends StatelessWidget {
  final String name;
  final int count;
  const _CountryGroupHeader({required this.name, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(color: AppColors.adminColor, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
          child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      ],
    );
  }
}

/// A single city record card. Presentation only — every callback forwards
/// straight to the parent's existing API-backed handlers.
class _CityCard extends StatefulWidget {
  final dynamic city;
  final bool isNested;
  final ValueChanged<dynamic> onToggle;
  final ValueChanged<dynamic> onMerge;
  final ValueChanged<dynamic> onDelete;

  const _CityCard({
    required this.city,
    required this.isNested,
    required this.onToggle,
    required this.onMerge,
    required this.onDelete,
  });

  @override
  State<_CityCard> createState() => _CityCardState();
}

class _CityCardState extends State<_CityCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.city;
    final isActive = c['status'] == 'active';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        // Subtle lift-on-hover for desktop/web; a no-op on touch devices
        // since MouseRegion never fires enter/exit there.
        transform: _hovered ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hovered ? AppColors.adminColor.withOpacity(0.35) : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: _hovered ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.03),
              blurRadius: _hovered ? 16 : 6,
              offset: Offset(0, _hovered ? 6 : 2),
            ),
          ],
        ),
        // mainAxisSize.min keeps the card's height dictated by its content,
        // which is required since this widget is reused inside both an
        // unbounded ListView and a fixed-extent GridView.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['name']?.toString() ?? '',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!widget.isNested) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.public_rounded, size: 11, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                c['country_name']?.toString() ?? '',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _StatusSwitch(isActive: isActive, onChanged: (_) => widget.onToggle(c)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _StatChip(icon: Icons.people_outline_rounded, label: '${c['user_count']} users'),
                _StatChip(icon: Icons.work_outline_rounded, label: '${c['professional_count']} pros'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _HoverOutlinedButton(
                    icon: Icons.merge_type_rounded,
                    label: 'Merge',
                    onPressed: () => widget.onMerge(c),
                  ),
                ),
                const SizedBox(width: 8),
                _HoverIconButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.error,
                  background: AppColors.error.withOpacity(0.08),
                  onPressed: () => widget.onDelete(c),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Active/coming-soon toggle with a status label underneath so the switch
/// state is legible at a glance rather than relying on colour alone.
class _StatusSwitch extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;
  const _StatusSwitch({required this.isActive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Transform.scale(
          scale: 0.85,
          child: Switch(value: isActive, activeColor: context.colors.accent, onChanged: onChanged),
        ),
        Text(
          isActive ? 'Active' : 'Coming soon',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: isActive ? context.colors.accent : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

/// Outlined "Merge" button with a hover tint on desktop/web; falls back to
/// standard press feedback on touch devices.
class _HoverOutlinedButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _HoverOutlinedButton({required this.icon, required this.label, required this.onPressed});

  @override
  State<_HoverOutlinedButton> createState() => _HoverOutlinedButtonState();
}

class _HoverOutlinedButtonState extends State<_HoverOutlinedButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        height: 40, // Meets the ~40px minimum comfortable touch target.
        child: OutlinedButton.icon(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.adminColor,
            backgroundColor: _hovered ? AppColors.adminColor.withOpacity(0.06) : Colors.transparent,
            side: BorderSide(color: AppColors.adminColor.withOpacity(_hovered ? 0.6 : 0.35)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: Icon(widget.icon, size: 15),
          label: Text(widget.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// Circular icon button (used for back/delete) with a min 40x40 tap target
/// and a hover background on desktop/web.
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final Color? color;
  final Color? background;
  final VoidCallback onPressed;
  const _HoverIconButton({required this.icon, required this.onPressed, this.color, this.background});

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? Colors.white;
    final baseBg = widget.background ?? Colors.white.withOpacity(0.16);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _hovered ? baseBg.withOpacity((baseBg.opacity + 0.10).clamp(0.0, 1.0)) : baseBg,
          borderRadius: BorderRadius.circular(11),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(widget.icon, size: 18, color: baseColor),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onChanged;
  const _StyledTextField({
    required this.controller,
    required this.hintText,
    this.autofocus = false,
    this.enabled = true,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      enabled: enabled,
      onSubmitted: onSubmitted,
      onChanged: onChanged == null ? null : (_) => onChanged!(),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.adminColor, width: 1.4),
        ),
      ),
    );
  }
}

/// Inline error banner shown inside a dialog when a submit fails, so the
/// user sees exactly why (e.g. a duplicate name) without the dialog
/// closing and without hunting for a snackbar.
class _InlineFormError extends StatelessWidget {
  final String message;
  const _InlineFormError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 15, color: AppColors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared dialog chrome (icon + title + rounded card) so Add/Merge dialogs
/// look consistent; the actions/content passed in are unchanged.
class _StyledDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget content;
  final List<Widget> actions;
  const _StyledDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // This screen's text/fill colors (e.g. Color(0xFF111827) titles on a
      // Color(0xFFF9FAFB) field) are hardcoded for a light surface. Material
      // 3's Dialog defaults its background to Theme.of(context).colorScheme
      // .surface, which is a dark near-black slate in this app's dark theme
      // — that combination made the dialog render as an unreadable black
      // box in dark mode. Forcing white here keeps it legible regardless of
      // the active app theme.
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
              const SizedBox(height: 14),
              content,
              const SizedBox(height: 20),
              OverflowBar(alignment: MainAxisAlignment.end, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      // AlwaysScrollable so RefreshIndicator's pull-to-refresh still works
      // even when there's no content to naturally make the list scrollable.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 90),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                  child: Icon(Icons.location_city_rounded, size: 44, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 14),
                const Text(
                  'No cities added yet',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                ),
                const SizedBox(height: 4),
                const Text('Tap "Add City" to get started', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
          ),
          const SizedBox(height: 14),
          const Text('Failed to load cities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

/// One-shot scale-in used for the FAB so it doesn't just pop into place
/// when the screen first builds.
class _EntranceScale extends StatelessWidget {
  final Widget child;
  const _EntranceScale({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: child,
    );
  }
}

/// Staggered fade + slide-up entrance for list/grid items. Purely visual —
/// runs once per item build using its index to offset the start delay so
/// the list feels populated rather than static. Does not affect layout
/// sizing, so it is safe inside both the ListView and GridView above.
class _AnimatedListEntry extends StatelessWidget {
  final int index;
  final Widget child;
  const _AnimatedListEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 12)) * 35;
    return TweenAnimationBuilder<double>(
      key: ValueKey('entry_$index'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 280 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child),
      ),
      child: child,
    );
  }
}