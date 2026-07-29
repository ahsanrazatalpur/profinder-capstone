// lib/features/admin/screens/admin_bookings_screen.dart
//
// Screen 5 of 6 — Bookings Management
// Features: view all bookings, filter by status, search, cancel any booking
//
// Backend endpoints:
//   GET   /api/admin-panel/bookings/                       → all bookings
//   GET   /api/admin-panel/bookings/?status=pending        → filtered
//   GET   /api/admin-panel/bookings/?search=name/email     → search
//   PATCH /api/admin-panel/bookings/<id>/cancel/           → force cancel
//
// Changes reflect:
//   cancel → customer + professional dono ki booking list mein 'cancelled' dikhta hai

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final _api        = ApiService();
  final _searchCtrl = TextEditingController();

  bool          _loading      = true;
  String?       _error;
  List<dynamic> _all          = [];
  List<dynamic> _filtered     = [];
  String        _activeFilter = 'all';

  // Status filter options
  static const _filters = [
    ('all',       'All',       Color(0xFF374151)),
    ('pending',   'Pending',   Color(0xFFF59E0B)),
    ('accepted',  'Accepted',  Color(0xFF3B82F6)),
    ('completed', 'Completed', Color(0xFF10B981)),
    ('rejected',  'Rejected',  Color(0xFFEF4444)),
    ('cancelled', 'Cancelled', Color(0xFF9CA3AF)),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final url = _activeFilter == 'all'
          ? '/admin-panel/bookings/'
          : '/admin-panel/bookings/?status=$_activeFilter';

      final r = await _api.get(url);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _all     = r.data is List ? List<dynamic>.from(r.data) : [];
      });
      _applySearch();
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load bookings'; });
    }
  }

  // ── Search (client side) ──────────────────────────────────
  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_all)
          : _all.where((b) {
              return (b['customer_name']      ?? '').toString().toLowerCase().contains(q) ||
                     (b['customer_email']     ?? '').toString().toLowerCase().contains(q) ||
                     (b['professional_name']  ?? '').toString().toLowerCase().contains(q) ||
                     (b['professional_email'] ?? '').toString().toLowerCase().contains(q);
            }).toList();
    });
  }

  // ── Cancel Booking ────────────────────────────────────────
  Future<void> _cancel(dynamic booking) async {
    final id         = booking['id'];
    final custName   = booking['customer_name']?.toString()    ?? 'Customer';
    final proName    = booking['professional_name']?.toString() ?? 'Professional';

    final confirmed = await _confirmDialog(
      title:   'Cancel Booking #$id?',
      message: '$custName → $proName\nThis will reflect to both customer and professional.',
    );
    if (!confirmed) return;

    try {
      await _api.patch('/admin-panel/bookings/$id/cancel/', {});

      // ✅ Reflect immediately
      setState(() {
        final idx = _all.indexWhere((b) => b['id'] == id);
        if (idx != -1) _all[idx]['status'] = 'cancelled';
      });
      _applySearch();

      _showSnack('Booking #$id cancelled', AppColors.error);
    } catch (e) {
      _showSnack('Failed to cancel. Try again.', AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          _buildCountBar(),
          Expanded(
            child: _loading
                ? _buildLoader()
                : _error != null
                    ? _buildError()
                    : _filtered.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppColors.adminColor,
                            child: ListView.builder(
                              padding:     const EdgeInsets.all(12),
                              itemCount:   _filtered.length,
                              itemBuilder: (_, i) =>
                                  _buildBookingCard(_filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.adminColor,
      elevation: 0,
      title: const Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('Bookings',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
      actions: [
        IconButton(
          icon:    const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _load,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  // ── Search Bar ────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged:  (_) => _applySearch(),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText:   'Search customer or professional…',
          hintStyle:  const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16,
                      color: Color(0xFF9CA3AF)),
                  onPressed: () { _searchCtrl.clear(); _applySearch(); },
                )
              : null,
          filled:         true,
          fillColor:      const Color(0xFFF3F4F6),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:   BorderSide.none),
        ),
      ),
    );
  }

  // ── Filter Chips ──────────────────────────────────────────
  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final isActive = _activeFilter == f.$1;
            return GestureDetector(
              onTap: () {
                setState(() => _activeFilter = f.$1);
                _load();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? f.$3 : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f.$2,
                    style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color:      isActive
                            ? Colors.white
                            : const Color(0xFF6B7280))),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Count Bar ─────────────────────────────────────────────
  Widget _buildCountBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('${_filtered.length} bookings',
              style: const TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color:      Color(0xFF374151))),
          const Spacer(),
          Text('Total: ${_all.length}',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  // ── Booking Card ──────────────────────────────────────────
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: statusColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset:     const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header row ─────────────────────────────────
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color:        statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('#$id',
                      style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w800,
                          color:      statusColor)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$custName → $proName',
                        style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w700,
                            color:      Color(0xFF111827)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (createdAt.isNotEmpty)
                      Text('Created $createdAt',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:        statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status.toUpperCase(),
                    style: TextStyle(
                        fontSize:   9,
                        fontWeight: FontWeight.w800,
                        color:      statusColor)),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 10),

          // ── Date / Time / Note row ──────────────────────
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _infoItem(Icons.calendar_today_outlined, date),
              _infoItem(Icons.access_time_rounded,     time),
              if (note.isNotEmpty)
                _infoItem(Icons.notes_rounded, note, maxWidth: 200),
            ],
          ),

          // ── Cancel Button ───────────────────────────────
          if (isCancellable) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancel(b),
                icon:  const Icon(Icons.cancel_outlined, size: 15),
                label: const Text('Force Cancel',
                    style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(
                      color: AppColors.error, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
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

  Widget _infoItem(IconData icon, String text,
      {double? maxWidth}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 120),
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF374151)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 60, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(
            _searchCtrl.text.isNotEmpty
                ? 'No results for "${_searchCtrl.text}"'
                : 'No $_activeFilter bookings',
            style: const TextStyle(
                fontSize:   14,
                fontWeight: FontWeight.w500,
                color:      Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() => const Center(
        child: CircularProgressIndicator(
            color: AppColors.adminColor, strokeWidth: 2.5),
      );

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          const Text('Failed to load bookings',
              style: TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.w600,
                  color:      Color(0xFF374151))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon:  const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.cancel_outlined,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            content: Text(message,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Cancel',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor:  color,
        behavior:         SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}