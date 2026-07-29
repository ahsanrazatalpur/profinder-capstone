// lib/features/admin/screens/admin_reported_users_screen.dart
//
// Reported Users — Trust & Safety
// Features: view all user reports, filter by status, search, resolve a
// report (mark reviewed / dismiss / take action + optional one-tap ban).
//
// Backend endpoints:
//   GET   /api/admin-panel/reports/            → all reports (newest first)
//   GET   /api/admin-panel/reports/?status=X   → filter by status
//   PATCH /api/admin-panel/reports/<id>/       → resolve a report
//     body: { "status": "reviewed"|"dismissed"|"action_taken",
//             "admin_note": "...", "ban_user": true }

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

class AdminReportedUsersScreen extends StatefulWidget {
  const AdminReportedUsersScreen({super.key});

  @override
  State<AdminReportedUsersScreen> createState() => _AdminReportedUsersScreenState();
}

class _AdminReportedUsersScreenState extends State<AdminReportedUsersScreen> {
  final _api        = ApiService();
  final _searchCtrl = TextEditingController();

  bool          _loading  = true;
  String?       _error;
  List<dynamic> _all      = [];
  List<dynamic> _filtered = [];
  String        _activeFilter = 'pending'; // default: show what needs attention

  static const _filters = [
    ('pending',      'Pending',      Color(0xFFF59E0B)),
    ('reviewed',     'Reviewed',     Color(0xFF3B82F6)),
    ('action_taken', 'Action Taken', Color(0xFFEF4444)),
    ('dismissed',    'Dismissed',    Color(0xFF9CA3AF)),
    ('all',          'All',          Color(0xFF374151)),
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
      final r = await _api.get('/admin-panel/reports/');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _all     = r.data is List ? List<dynamic>.from(r.data) : [];
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load reports'; });
    }
  }

  // ── Filter + Search ───────────────────────────────────────
  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((r) {
        final matchFilter = _activeFilter == 'all' ||
            (r['status'] ?? '') == _activeFilter;

        final matchSearch = q.isEmpty ||
            (r['reported_user_name']  ?? '').toString().toLowerCase().contains(q) ||
            (r['reported_user_email'] ?? '').toString().toLowerCase().contains(q) ||
            (r['reporter_name']       ?? '').toString().toLowerCase().contains(q) ||
            (r['reporter_email']      ?? '').toString().toLowerCase().contains(q) ||
            (r['reason_display']      ?? '').toString().toLowerCase().contains(q);

        return matchFilter && matchSearch;
      }).toList();
    });
  }

  int _countFor(String status) {
    if (status == 'all') return _all.length;
    return _all.where((r) => (r['status'] ?? '') == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilters(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.adminColor, strokeWidth: 2.5))
                  : _error != null
                      ? _buildError()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.adminColor,
                          child: _filtered.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [_emptyState()],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                  itemCount: _filtered.length,
                                  itemBuilder: (_, i) => _reportCard(_filtered[i]),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.adminColor, Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reported Users',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('${_countFor('pending')} pending review',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search + Filter chips ───────────────────────────────────
  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => _applyFilter(),
            decoration: InputDecoration(
              hintText: 'Search by user, reporter, or reason…',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (key, label, color) = _filters[i];
                final isActive = _activeFilter == key;
                final count = _countFor(key);
                return GestureDetector(
                  onTap: () {
                    setState(() => _activeFilter = key);
                    _applyFilter();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isActive ? color.withOpacity(0.12) : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? color : Colors.transparent),
                    ),
                    alignment: Alignment.center,
                    child: Text('$label ($count)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? color : const Color(0xFF6B7280))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Report Card ──────────────────────────────────────────
  Widget _reportCard(dynamic report) {
    final status  = report['status']?.toString() ?? 'pending';
    final color   = _filters.firstWhere((f) => f.$1 == status,
        orElse: () => _filters[0]).$3;
    final reportedName  = report['reported_user_name']?.toString()  ?? 'Unknown';
    final reportedEmail = report['reported_user_email']?.toString() ?? '';
    final reportedRole  = report['reported_user_role']?.toString()  ?? '';
    final reporterName  = report['reporter_name']?.toString()  ?? 'Unknown';
    final reporterEmail = report['reporter_email']?.toString() ?? '';
    final reasonDisplay = report['reason_display']?.toString() ?? '';
    final description   = report['description']?.toString() ?? '';
    final statusDisplay = report['status_display']?.toString() ?? status;
    final isActive       = report['reported_user_active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openReportSheet(report),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 18, color: AppColors.error),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(reportedName,
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w700),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              if (!isActive)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF64748B).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: const Text('BLOCKED',
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800,
                                          color: Color(0xFF64748B))),
                                ),
                            ],
                          ),
                          Text('$reportedEmail · $reportedRole',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusDisplay,
                          style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w800, color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag_outlined, size: 13, color: AppColors.error),
                          const SizedBox(width: 6),
                          Text(reasonDisplay,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: AppColors.error)),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(description,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Reported by $reporterName ($reporterEmail)',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty / Error states ────────────────────────────────────
  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.shield_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(_activeFilter == 'pending'
                    ? 'No pending reports — all clear! 🎉'
                    : 'No reports in this category',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 10),
          const Text('Failed to load reports',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
          ),
        ],
      ),
    );
  }

  // ── Resolve-Report bottom sheet ─────────────────────────────
  void _openReportSheet(dynamic report) {
    final noteCtrl = TextEditingController(text: report['admin_note']?.toString() ?? '');
    bool banUser = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report on ${report['reported_user_name']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(report['reason_display']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.error,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Admin note (optional)…',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: banUser,
                  onChanged: (v) => setSheetState(() => banUser = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Also ban this user',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _resolve(report, 'dismissed', noteCtrl.text, false),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text('Dismiss'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _resolve(report, 'reviewed', noteCtrl.text, false),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text('Mark Reviewed'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        _resolve(report, 'action_taken', noteCtrl.text, banUser),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Take Action', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resolve(
      dynamic report, String status, String note, bool banUser) async {
    Navigator.pop(context); // close sheet
    try {
      await _api.patch('/admin-panel/reports/${report['id']}/', {
        'status': status,
        'admin_note': note,
        'ban_user': banUser,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(banUser
            ? 'Report resolved and user banned.'
            : 'Report marked as ${status.replaceAll('_', ' ')}.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update report.')),
      );
    }
  }
}