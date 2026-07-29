// lib/features/admin/screens/admin_logs_screen.dart
//
// Screen 6 of 6 — Activity Logs
// Features: view all admin actions, filter by action type, search, clear logs
//
// Backend endpoints:
//   GET    /api/admin-panel/logs/              → all logs (newest first)
//   DELETE /api/admin-panel/logs/<id>/         → delete single log
//   DELETE /api/admin-panel/logs/clear/        → clear all logs

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  final _api        = ApiService();
  final _searchCtrl = TextEditingController();

  bool          _loading      = true;
  String?       _error;
  List<dynamic> _all          = [];
  List<dynamic> _filtered     = [];
  String        _activeFilter = 'all';

  static const _filters = [
    ('all',            'All',            Color(0xFF374151)),
    ('verify',         'Verify',         Color(0xFF10B981)),
    ('ban',            'Ban',            Color(0xFFEF4444)),
    ('unban',          'Unban',          Color(0xFF3B82F6)),
    ('approve',        'Approve',        Color(0xFF8B5CF6)),
    ('reject',         'Reject',         Color(0xFFF59E0B)),
    ('cancel_booking', 'Cancel',         Color(0xFF9CA3AF)),
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
      final r = await _api.get('/admin-panel/logs/');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _all     = r.data is List ? List<dynamic>.from(r.data) : [];
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load logs'; });
    }
  }

  // ── Filter + Search ───────────────────────────────────────
  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((log) {
        final matchFilter = _activeFilter == 'all' ||
            (log['action'] ?? '') == _activeFilter;

        final matchSearch = q.isEmpty ||
            (log['admin_name']        ?? '').toString().toLowerCase().contains(q) ||
            (log['admin_email']       ?? '').toString().toLowerCase().contains(q) ||
            (log['target_user_name']  ?? '').toString().toLowerCase().contains(q) ||
            (log['target_user_email'] ?? '').toString().toLowerCase().contains(q) ||
            (log['note']              ?? '').toString().toLowerCase().contains(q);

        return matchFilter && matchSearch;
      }).toList();
    });
  }

  // ── Delete single log ─────────────────────────────────────
  Future<void> _deleteLog(dynamic log) async {
    final confirmed = await _confirmDialog(
      title:   'Delete this log?',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
    );
    if (!confirmed) return;

    try {
      await _api.delete('/admin-panel/logs/${log['id']}/');
      setState(() => _all.removeWhere((l) => l['id'] == log['id']));
      _applyFilter();
      _showSnack('Log deleted', AppColors.error);
    } catch (e) {
      _showSnack('Delete failed. Try again.', AppColors.error);
    }
  }

  // ── Clear all logs ────────────────────────────────────────
  Future<void> _clearAll() async {
    final confirmed = await _confirmDialog(
      title:        'Clear All Logs?',
      message:      'All ${_all.length} activity logs will be permanently deleted.',
      confirmLabel: 'Clear All',
      confirmColor: AppColors.error,
    );
    if (!confirmed) return;

    try {
      await _api.delete('/admin-panel/logs/clear/');
      setState(() { _all.clear(); _filtered.clear(); });
      _showSnack('All logs cleared', AppColors.error);
    } catch (e) {
      _showSnack('Failed to clear. Try again.', AppColors.error);
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
                                  _buildLogCard(_filtered[i]),
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
          Icon(Icons.history_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('Activity Logs',
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
        if (_all.isNotEmpty)
          IconButton(
            icon:    const Icon(Icons.delete_sweep_rounded, color: Colors.white),
            onPressed: _clearAll,
            tooltip: 'Clear All',
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
        onChanged:  (_) => _applyFilter(),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText:   'Search by admin or target user…',
          hintStyle:  const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16,
                      color: Color(0xFF9CA3AF)),
                  onPressed: () { _searchCtrl.clear(); _applyFilter(); },
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
            // count per action
            final count = f.$1 == 'all'
                ? _all.length
                : _all.where((l) => l['action'] == f.$1).length;

            return GestureDetector(
              onTap: () {
                setState(() => _activeFilter = f.$1);
                _applyFilter();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? f.$3 : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(f.$2,
                        style: TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                            color:      isActive
                                ? Colors.white
                                : const Color(0xFF6B7280))),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withOpacity(0.25)
                            : f.$3.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$count',
                          style: TextStyle(
                              fontSize:   10,
                              fontWeight: FontWeight.w700,
                              color:      isActive ? Colors.white : f.$3)),
                    ),
                  ],
                ),
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
          Text('${_filtered.length} logs',
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

  // ── Log Card ──────────────────────────────────────────────
  Widget _buildLogCard(dynamic log) {
    final action        = log['action']?.toString()           ?? '';
    final adminName     = log['admin_name']?.toString()       ?? 'Admin';
    final targetName    = log['target_user_name']?.toString() ?? 'User';
    final targetEmail   = log['target_user_email']?.toString()?? '';
    final targetRole    = log['target_user_role']?.toString() ?? '';
    final note          = log['note']?.toString()             ?? '';
    final createdAt     = log['created_at']?.toString()       ?? '';

    final color = _actionColor(action);
    final icon  = _actionIcon(action);
    final label = _actionLabel(action);

    return Dismissible(
      key:        Key('log_${log['id']}'),
      direction:  DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding:   const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color:        AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 22),
      ),
      confirmDismiss: (_) => _confirmDialog(
        title:        'Delete this log?',
        message:      'This action cannot be undone.',
        confirmLabel: 'Delete',
        confirmColor: AppColors.error,
      ),
      onDismissed: (_) {
        setState(() => _all.removeWhere((l) => l['id'] == log['id']));
        _applyFilter();
        _showSnack('Log deleted', AppColors.error);
        _api.delete('/admin-panel/logs/${log['id']}/').catchError((_) {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset:     const Offset(0, 1)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Action Icon ─────────────────────────────
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.12),
                shape:        BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),

            // ── Details ──────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Action badge + timestamp
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:        color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                fontSize:   10,
                                fontWeight: FontWeight.w800,
                                color:      color)),
                      ),
                      const Spacer(),
                      Text(_formatDate(createdAt),
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFFCBD5E1))),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Admin → Target
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF374151)),
                      children: [
                        TextSpan(
                          text: adminName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827)),
                        ),
                        const TextSpan(text: '  →  '),
                        TextSpan(
                          text: targetName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Target email + role
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(targetEmail,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF9CA3AF)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (targetRole.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(targetRole.toUpperCase(),
                              style: const TextStyle(
                                  fontSize:   8,
                                  fontWeight: FontWeight.w700,
                                  color:      Color(0xFF9CA3AF))),
                        ),
                    ],
                  ),

                  // Note (if any)
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color:        const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes_rounded,
                              size: 12, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(note,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color:    Color(0xFF6B7280),
                                    height:   1.4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Delete Button ─────────────────────────────
            GestureDetector(
              onTap: () => _deleteLog(log),
              child: const Padding(
                padding: EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.close_rounded,
                    size: 16, color: Color(0xFFD1D5DB)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  Color _actionColor(String action) {
    return switch (action) {
      'verify'         => const Color(0xFF10B981),
      'ban'            => const Color(0xFFEF4444),
      'unban'          => const Color(0xFF3B82F6),
      'approve'        => const Color(0xFF8B5CF6),
      'reject'         => const Color(0xFFF59E0B),
      'cancel_booking' => const Color(0xFF9CA3AF),
      'delete'         => const Color(0xFFEF4444),
      _                => const Color(0xFF9CA3AF),
    };
  }

  IconData _actionIcon(String action) {
    return switch (action) {
      'verify'         => Icons.verified_rounded,
      'ban'            => Icons.block_rounded,
      'unban'          => Icons.lock_open_rounded,
      'approve'        => Icons.check_circle_outline_rounded,
      'reject'         => Icons.cancel_outlined,
      'cancel_booking' => Icons.event_busy_rounded,
      'delete'         => Icons.delete_outline_rounded,
      _                => Icons.info_outline_rounded,
    };
  }

  String _actionLabel(String action) {
    return switch (action) {
      'verify'         => 'VERIFIED',
      'ban'            => 'BANNED',
      'unban'          => 'UNBANNED',
      'approve'        => 'APPROVED',
      'reject'         => 'REJECTED',
      'cancel_booking' => 'CANCELLED',
      'delete'         => 'DELETED',
      _                => action.toUpperCase(),
    };
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1)  return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      if (diff.inDays < 7)     return '${diff.inDays}d ago';

      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_toggle_off_rounded,
              size: 64, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 14),
          Text(
            _activeFilter == 'all'
                ? 'No activity yet'
                : 'No "$_activeFilter" logs',
            style: const TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w600,
                color:      Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 6),
          const Text('Admin actions will appear here',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
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
          const Text('Failed to load logs',
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
    required String confirmLabel,
    required Color  confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
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
                    backgroundColor: confirmColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor:  color,
      behavior:         SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }
}