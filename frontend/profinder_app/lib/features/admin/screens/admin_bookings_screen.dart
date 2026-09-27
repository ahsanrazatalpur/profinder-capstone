// lib/features/admin/screens/admin_bookings_screen.dart
//
// Screen 5 of 6 — Bookings Management
// Features: view all bookings, filter by status (with live per-status
// counts on every chip), search, cancel any booking
//
// Backend endpoints (UNCHANGED):
//   GET   /api/admin-panel/bookings/                       → all bookings
//   PATCH /api/admin-panel/bookings/<id>/cancel/           → force cancel
//
// NOTE: the '?status=' query param is no longer used by this screen.
// We now fetch the FULL list once and filter it locally, so every filter
// chip can show its own live count (Pending (12), Completed (45), ...)
// without needing a separate API round-trip per tab. The backend endpoint
// still supports ?status= if some other screen needs it — untouched.
//
// Changes reflect:
//   cancel → customer + professional dono ki booking list mein 'cancelled' dikhta hai

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

// Responsive breakpoints for the booking list layout.
const double _kTabletBreakpoint = 720;
const double _kDesktopBreakpoint = 1080;

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _api        = ApiService();
  final _searchCtrl = TextEditingController();

  bool          _loading      = true;
  String?       _error;
  List<dynamic> _all          = [];   // full, unfiltered list from the API
  List<dynamic> _filtered     = [];   // _all after status + search applied
  String        _activeFilter = 'all';

  // Status filter options — label + accent color used for the chip, badge,
  // and card border. Kept alongside the status key so UI stays in sync.
  static const _filters = [
    ('all',       'All',       Color(0xFF374151)),
    ('pending',   'Pending',   Color(0xFFF59E0B)),
    ('accepted',  'Accepted',  Color(0xFF3B82F6)),
    ('completed', 'Completed', Color(0xFF10B981)),
    ('rejected',  'Rejected',  Color(0xFFEF4444)),
    ('cancelled', 'Cancelled', Color(0xFF9CA3AF)),
  ];

  /// Live count per status key, recomputed from [_all] every time it
  /// changes (initial load, refresh, or after a cancel). 'all' always
  /// equals _all.length. Chips read this to show "(count)" badges.
  Map<String, int> _counts = {
    for (final f in _filters) f.$1: 0,
  };

  /// Drives the staggered fade/slide-in of cards whenever the visible list
  /// changes (initial load, filter switch, search, or pull-to-refresh).
  /// Single controller keeps the animation cheap on low-end devices.
  late final AnimationController _listAnim;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
      duration: const Duration(milliseconds: 480),
      vsync: this,
    );
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _listAnim.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────
  /// Fetches the FULL booking list (no status filter — that's applied
  /// locally now so every chip can show a live count), recomputes counts,
  /// then re-applies the current filter + search.
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.get('/admin-panel/bookings/');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _all     = r.data is List ? List<dynamic>.from(r.data) : [];
      });
      _recomputeCounts();
      _applyFilter();
      _listAnim.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load bookings'; });
    }
  }

  /// Tallies how many bookings fall into each status, plus the 'all' total.
  /// Runs entirely on the already-fetched [_all] list — no network call.
  void _recomputeCounts() {
    final counts = {for (final f in _filters) f.$1: 0};
    counts['all'] = _all.length;
    for (final b in _all) {
      final s = (b['status'] ?? '').toString();
      if (counts.containsKey(s)) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    setState(() => _counts = counts);
  }

  // ── Filter + Search (both client side) ─────────────────────
  /// Applies the active status filter AND the search query together over
  /// [_all], producing [_filtered]. Called whenever either changes.
  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((b) {
        final matchesStatus = _activeFilter == 'all' ||
            (b['status']?.toString() ?? '') == _activeFilter;
        if (!matchesStatus) return false;
        if (q.isEmpty) return true;
        return (b['customer_name']      ?? '').toString().toLowerCase().contains(q) ||
               (b['customer_email']     ?? '').toString().toLowerCase().contains(q) ||
               (b['professional_name']  ?? '').toString().toLowerCase().contains(q) ||
               (b['professional_email'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    });
    _listAnim.forward(from: 0);
  }

  // ── Cancel Booking ────────────────────────────────────────
  /// Force-cancels a booking after confirmation. Updates local state so the
  /// card, the filtered list, and every chip's count reflect the change
  /// immediately — no reload needed.
  Future<void> _cancel(dynamic booking) async {
    final id       = booking['id'];
    final custName = booking['customer_name']?.toString()    ?? 'Customer';
    final proName  = booking['professional_name']?.toString() ?? 'Professional';

    final confirmed = await _confirmDialog(
      title:   'Cancel Booking #$id?',
      message: '$custName → $proName\nThis will reflect to both customer and professional.',
    );
    if (!confirmed) return;

    try {
      await _api.patch('/admin-panel/bookings/$id/cancel/', {});

      // Reflect the cancellation immediately in local state so the card,
      // the active filter's list, and every chip's badge all update
      // without waiting on a full reload.
      setState(() {
        final idx = _all.indexWhere((b) => b['id'] == id);
        if (idx != -1) _all[idx]['status'] = 'cancelled';
      });
      _recomputeCounts();
      _applyFilter();

      _showSnack('Booking #$id cancelled', AppColors.error,
          icon: Icons.cancel_rounded);
    } catch (e) {
      _showSnack('Failed to cancel. Try again.', AppColors.error,
          icon: Icons.error_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            _buildCountBar(),
            Expanded(
              // Cross-fades between loading / error / empty / content states
              // so switching between them reads as a smooth transition.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _loading
                    ? _buildLoader()
                    : _error != null
                        ? _buildError()
                        : _filtered.isEmpty
                            ? _buildEmpty()
                            : RefreshIndicator(
                                key: const ValueKey('content'),
                                onRefresh: _load,
                                color: AppColors.adminColor,
                                child: _buildList(),
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Single column on phones; 2 / 3 column grid on tablet / desktop.
  /// Uses [LayoutBuilder] so the layout responds to its parent constraints
  /// rather than the full window — critical inside split-view / sidebar apps.
  Widget _buildList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width     = constraints.maxWidth;
        final isTablet  = width >= _kTabletBreakpoint;
        final isDesktop = width >= _kDesktopBreakpoint;

        final hPad = isDesktop ? 20.0 : (isTablet ? 16.0 : 12.0);
        final columns = isDesktop ? 3 : (isTablet ? 2 : 1);
        final maxWidth = isDesktop ? 1500.0 : 1200.0;

        // Fixed card height per breakpoint so text + actions never clip and
        // all cards align visually even when content lengths differ.
        final cardExtent = isDesktop
            ? 260.0
            : (isTablet ? 260.0 : 240.0);

        final grid = GridView.builder(
          padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, hPad + 24),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: cardExtent,
          ),
          itemCount: _filtered.length,
          itemBuilder: (_, i) => _animatedCard(_filtered[i], i),
        );

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: grid,
          ),
        );
      },
    );
  }

  /// Staggers each card's fade + slide-in based on its index, capped so the
  /// whole list settles within the animation's duration regardless of length.
  Widget _animatedCard(dynamic b, int i) {
    return AnimatedBuilder(
      animation: _listAnim,
      builder: (context, child) {
        final delay = (i * 0.05).clamp(0.0, 0.6);
        final animation = CurvedAnimation(
          parent: _listAnim,
          curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 14),
            child: child,
          ),
        );
      },
      child: _buildBookingCard(b),
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  /// Title bar with an icon-paired label and a dim-while-loading refresh
  /// button so the user gets feedback when a request is in flight.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.adminColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: const Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            'Bookings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      actions: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _loading ? 0.5 : 1.0,
          child: _HoverIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ── Search Bar ────────────────────────────────────────────
  /// Client-side search field. The clear button appears only when there is
  /// text and resets both the controller and the filtered list.
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged:  (_) => _applyFilter(),
        style: const TextStyle(fontSize: 13.5),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText:   'Search customer or professional…',
          hintStyle:  const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: Color(0xFF9CA3AF)),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: Color(0xFF9CA3AF)),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchCtrl.clear();
                    _applyFilter();
                  },
                )
              : null,
          filled:         true,
          fillColor:      const Color(0xFFF3F4F6),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.adminColor.withOpacity(0.45),
              width: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  // ── Filter Chips ──────────────────────────────────────────
  /// Horizontally scrollable status filter row. Each chip now shows its own
  /// live count badge (e.g. "Pending 12") so the admin can see every
  /// status's total at a glance without switching tabs. Tapping a chip is
  /// a purely local re-filter — no API call.
  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _filters.map((f) {
            final isActive = _activeFilter == f.$1;
            final count = _counts[f.$1] ?? 0;
            return _FilterChip(
              label:    f.$2,
              count:    count,
              color:    f.$3,
              isActive: isActive,
              onTap: () {
                setState(() => _activeFilter = f.$1);
                _applyFilter();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Count Bar ─────────────────────────────────────────────
  /// Live counter that animates as the filtered list size changes, so the
  /// number never "snaps" while typing in the search field.
  Widget _buildCountBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              '${_filtered.length} bookings',
              key: ValueKey(_filtered.length),
              style: const TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF374151),
                letterSpacing: -0.1,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Total: ${_all.length}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Booking Card ──────────────────────────────────────────
  /// Renders a single booking: id, participants, timestamps, status badge,
  /// date/time/note meta, and the force-cancel action when applicable.
  Widget _buildBookingCard(dynamic b) {
    final id        = b['id'];
    final custName  = b['customer_name']?.toString()    ?? 'Customer';
    final proName   = b['professional_name']?.toString() ?? 'Professional';
    final date      = b['date']?.toString()             ?? '';
    final time      = b['time']?.toString()             ?? '';
    final note      = b['note']?.toString()             ?? '';
    final status    = b['status']?.toString()           ?? 'pending';
    final createdAt = b['created_at']?.toString()       ?? '';

    final statusColor = _statusColor(status);
    final isCancellable = status != 'cancelled' && status != 'completed';

    return _HoverLift(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withOpacity(0.22)),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: id badge, participants, status pill ─────
            Row(
              children: [
                // Compact id badge tinted by status color.
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color:        statusColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#$id',
                    style: TextStyle(
                      fontSize:   11.5,
                      fontWeight: FontWeight.w800,
                      color:      statusColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$custName → $proName',
                        style: const TextStyle(
                          fontSize:   13.5,
                          fontWeight: FontWeight.w700,
                          color:      Color(0xFF111827),
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (createdAt.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Created $createdAt',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(status, statusColor),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 10),

            // ── Meta: date / time / note ─────────────────────────
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                if (date.isNotEmpty)
                  _infoItem(Icons.calendar_today_outlined, date),
                if (time.isNotEmpty)
                  _infoItem(Icons.access_time_rounded, time),
                if (note.isNotEmpty)
                  _infoItem(Icons.notes_rounded, note, maxWidth: 200),
              ],
            ),

            const Spacer(),

            // ── Force Cancel (only when still cancellable) ───────
            if (isCancellable) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancel(b),
                  icon:  const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text(
                    'Force Cancel',
                    style: TextStyle(
                      fontSize:   12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(
                        color: AppColors.error, width: 1.4),
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  /// Maps a status string to its accent color. Unknown statuses fall back to
  /// a neutral grey so the UI never breaks on unexpected values.
  Color _statusColor(String s) {
    return switch (s) {
      'pending'   => const Color(0xFFF59E0B),
      'accepted'  => const Color(0xFF3B82F6),
      'completed' => const Color(0xFF10B981),
      'rejected'  => const Color(0xFFEF4444),
      'cancelled' => const Color(0xFF9CA3AF),
      _           => const Color(0xFF9CA3AF),
    };
  }

  /// Small colored pill in the card header with an icon matching the status.
  Widget _statusBadge(String status, Color color) {
    final icon = switch (status) {
      'pending'   => Icons.hourglass_top_rounded,
      'accepted'  => Icons.check_circle_outline_rounded,
      'completed' => Icons.task_alt_rounded,
      'rejected'  => Icons.cancel_outlined,
      'cancelled' => Icons.block_rounded,
      _           => Icons.info_outline_rounded,
    };

    return Semantics(
      label: 'Status: $status',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize:   9.5,
                fontWeight: FontWeight.w800,
                color:      color,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact icon + text pair used for date / time / note rows. Constrains
  /// text so long values ellipsize instead of overflowing the card.
  Widget _infoItem(IconData icon, String text, {double? maxWidth}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 140),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Empty state that adapts copy based on whether a search query or a
  /// filter is currently active.
  Widget _buildEmpty() {
    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB).withOpacity(0.20),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.calendar_today_outlined,
                  size: 40, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'No results for "${_searchCtrl.text}"'
                  : 'No $_activeFilter bookings',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF6B7280),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader() => const Center(
        key: ValueKey('loading'),
        child: SizedBox(
          width: 32, height: 32,
          child: CircularProgressIndicator(
            color: AppColors.adminColor,
            strokeWidth: 2.6,
          ),
        ),
      );

  /// Error state with a branded Retry button. Sized for a 44px min touch
  /// target and consistent with the empty-state visual language.
  Widget _buildError() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84, height: 84,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.09),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.error_outline_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load bookings',
              style: TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF374151),
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _load,
              icon:  const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirmation dialog for the force-cancel action. Returns true only when
  /// the user taps the destructive action — behavior unchanged.
  Future<bool> _confirmDialog({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel_outlined,
                  color: AppColors.error, size: 26),
            ),
            title: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
            content: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Cancel',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Floating snackbar with a leading icon and brand color matching the
  /// action result. Presentation only — behavior unchanged.
  void _showSnack(String msg, Color color,
      {IconData icon = Icons.check_circle_rounded}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Small shared UI helpers — visual polish only, no logic
// ═══════════════════════════════════════════════════════════════════════════

/// A single status filter chip with an animated selected state, a live
/// count badge, and a subtle hover background on desktop/web. Enforces a
/// 40px+ minimum tap height so the chip stays comfortably tappable on mobile.
class _FilterChip extends StatefulWidget {
  final String label;
  final int count;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.isActive,
      label: '${widget.label} filter, ${widget.count} bookings',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (!mounted) return;
          setState(() => _hovering = true);
        },
        onExit: (_) {
          if (!mounted) return;
          setState(() => _hovering = false);
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: 8),
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? widget.color
                  : (_hovering
                      ? const Color(0xFFE5E7EB)
                      : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(22),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize:   12.5,
                    fontWeight: FontWeight.w700,
                    color:      widget.isActive
                        ? Colors.white
                        : const Color(0xFF4B5563),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(width: 6),
                // Count badge — pill-in-pill, background contrasts with the
                // chip so it reads clearly whether the chip is active or not.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Container(
                    key: ValueKey('${widget.label}_${widget.count}'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? Colors.white.withOpacity(0.25)
                          : widget.color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.count}',
                      style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w800,
                        color:      widget.isActive
                            ? Colors.white
                            : widget.color,
                      ),
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
}

/// Icon button with a subtle hover background on desktop/web and a tooltip.
/// Kept stateful so the hover ring animates without triggering a rebuild of
/// the parent app bar.
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HoverIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!mounted) return;
        setState(() => _hovering = true);
      },
      onExit: (_) {
        if (!mounted) return;
        setState(() => _hovering = false);
      },
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _hovering
                ? Colors.white.withOpacity(0.15)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(widget.icon, color: Colors.white),
            onPressed: widget.onPressed,
            tooltip: null, // outer Tooltip handles the label
          ),
        ),
      ),
    );
  }
}

/// Wraps a card with a gentle hover "lift" (translate + deeper shadow) on
/// platforms that support a mouse cursor. No-ops on touch-only devices
/// because [MouseRegion] never fires enter/exit there.
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
            ? (Matrix4.identity()..translate(0.0, -2.0))
            : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}