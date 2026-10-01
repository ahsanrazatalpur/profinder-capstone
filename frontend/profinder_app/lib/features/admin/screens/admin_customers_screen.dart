// lib/features/admin/screens/admin_customers_screen.dart
//
// Customers Management — dedicated financial/behavior view for customers
// (distinct from the combined Users master table).
// Features: search, status filter, sorting (spend/bookings/name/date),
// multi-select + bulk block/unblock/export, Total Spent + Total Bookings
// columns, customer details bottom sheet, single ban/unban.
//
// Backend endpoints:
//   GET   /api/users/?role=customer          → list all customers
//   PATCH /api/admin-panel/users/<id>/ban/    → ban / unban

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../shared/widgets/universal_app_bar.dart';

enum _StatusFilter { all, active, blocked }
enum _SortOption { spentHigh, bookingsHigh, nameAsc, dateNew }

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final _api        = ApiService();
  final _searchCtrl = TextEditingController();

  bool          _loading  = true;
  String?       _error;
  List<dynamic> _all      = [];
  List<dynamic> _filtered = [];

  _StatusFilter _statusFilter = _StatusFilter.all;
  _SortOption   _sortOption   = _SortOption.dateNew;

  bool _selectionMode = false;
  final Set<dynamic> _selectedIds = {};

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
      final r = await _api.get('/users/?role=customer');
      if (!mounted) return;
      final list = r.data is List ? List<dynamic>.from(r.data) : <dynamic>[];
      setState(() { _loading = false; _all = list; });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load customers'; });
    }
  }

  double _spentOf(dynamic u) => double.tryParse(u['total_spent']?.toString() ?? '0') ?? 0;
  int _bookingsOf(dynamic u) => int.tryParse(u['total_bookings']?.toString() ?? '0') ?? 0;

  // ── Filter + Search + Sort ─────────────────────────────────
  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();

    var result = _all.where((u) {
      final matchSearch = q.isEmpty ||
          (u['name']  ?? '').toString().toLowerCase().contains(q) ||
          (u['email'] ?? '').toString().toLowerCase().contains(q);

      final isActive = u['is_active'] != false;
      final matchStatus = switch (_statusFilter) {
        _StatusFilter.all     => true,
        _StatusFilter.active  => isActive,
        _StatusFilter.blocked => !isActive,
      };

      return matchSearch && matchStatus;
    }).toList();

    result.sort((a, b) {
      switch (_sortOption) {
        case _SortOption.spentHigh:
          return _spentOf(b).compareTo(_spentOf(a));
        case _SortOption.bookingsHigh:
          return _bookingsOf(b).compareTo(_bookingsOf(a));
        case _SortOption.nameAsc:
          return (a['name'] ?? '').toString().toLowerCase()
              .compareTo((b['name'] ?? '').toString().toLowerCase());
        case _SortOption.dateNew:
          return (b['joined'] ?? '').toString().compareTo((a['joined'] ?? '').toString());
      }
    });

    setState(() => _filtered = result);
  }

  // ── Single Ban / Unban ────────────────────────────────────
  Future<void> _toggleBan(dynamic user) async {
    final isBanned = user['is_active'] == false;
    final name     = user['name']?.toString() ?? 'this customer';

    final confirmed = await _confirmDialog(
      title:   isBanned ? 'Unblock Customer?' : 'Block Customer?',
      message: isBanned
          ? '$name will be able to login and book again.'
          : '$name will not be able to login until unblocked.',
      confirmLabel: isBanned ? 'Unblock' : 'Block',
      confirmColor: isBanned ? context.colors.accent : AppColors.error,
      icon: isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
    );
    if (!confirmed) return;

    try {
      await _api.patch('/admin-panel/users/${user['id']}/ban/', {'action': isBanned ? 'unban' : 'ban'});
      setState(() {
        final idx = _all.indexWhere((u) => u['id'] == user['id']);
        if (idx != -1) _all[idx]['is_active'] = isBanned;
      });
      _applyFilters();
      _showSnack(
        isBanned ? '$name unblocked' : '$name blocked',
        isBanned ? context.colors.accent : AppColors.error,
        icon: isBanned ? Icons.check_circle_rounded : Icons.block_rounded,
      );
    } catch (e) {
      _showSnack('Action failed. Try again.', AppColors.error, icon: Icons.error_outline_rounded);
    }
  }

  // ── Bulk Block / Unblock ──────────────────────────────────
  Future<void> _bulkSetStatus({required bool block}) async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await _confirmDialog(
      title:   block ? 'Block ${_selectedIds.length} customers?' : 'Unblock ${_selectedIds.length} customers?',
      message: block
          ? 'Selected customers will not be able to login until unblocked.'
          : 'Selected customers will be able to login again.',
      confirmLabel: block ? 'Block All' : 'Unblock All',
      confirmColor: block ? AppColors.error : context.colors.accent,
      icon: block ? Icons.block_rounded : Icons.lock_open_rounded,
    );
    if (!confirmed) return;

    int success = 0;
    for (final id in _selectedIds.toList()) {
      final idx = _all.indexWhere((u) => u['id'] == id);
      if (idx == -1) continue;
      final isBanned = _all[idx]['is_active'] == false;
      if (block && isBanned) continue;
      if (!block && !isBanned) continue;
      try {
        await _api.patch('/admin-panel/users/$id/ban/', {'action': block ? 'ban' : 'unban'});
        setState(() => _all[idx]['is_active'] = !block);
        success++;
      } catch (_) {}
    }
    _applyFilters();
    setState(() { _selectionMode = false; _selectedIds.clear(); });
    _showSnack(
      '$success customer(s) ${block ? 'blocked' : 'unblocked'}',
      block ? AppColors.error : context.colors.accent,
      icon: block ? Icons.block_rounded : Icons.lock_open_rounded,
    );
  }

  // ── Export (CSV → clipboard) ──────────────────────────────
  void _exportCsv() {
    final rows = _selectedIds.isNotEmpty
        ? _all.where((u) => _selectedIds.contains(u['id'])).toList()
        : _filtered;

    if (rows.isEmpty) {
      _showSnack('Nothing to export', AppColors.warning, icon: Icons.info_outline_rounded);
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Name,Email,City,Total Bookings,Total Spent,Status,Joined');
    for (final u in rows) {
      final name     = (u['name'] ?? '').toString().replaceAll(',', ' ');
      final email    = (u['email'] ?? '').toString();
      final city     = (u['city'] ?? '').toString().replaceAll(',', ' ');
      final bookings = (u['total_bookings'] ?? '0').toString();
      final spent    = (u['total_spent'] ?? '0.00').toString();
      final status   = (u['is_active'] != false) ? 'Active' : 'Blocked';
      final joined   = (u['joined'] ?? '').toString();
      buffer.writeln('$name,$email,$city,$bookings,$spent,$status,$joined');
    }

    // NOTE: Converted from a custom Dialog(Column(...)) to AlertDialog.
    // The old custom Dialog + unconstrained Row/ElevatedButton layout
    // caused "BoxConstraints forces an infinite width" crashes on
    // Flutter Web, which silently broke button taps (and therefore the
    // whole block/unban flow triggered from this screen).
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.adminColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.download_rounded, color: AppColors.adminColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Export (${rows.length} customers)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          height: 260,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(buffer.toString(),
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.5)),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: buffer.toString()));
              Navigator.pop(context);
              _showSnack('CSV copied to clipboard — paste into Excel/Sheets', AppColors.success,
                  icon: Icons.check_circle_rounded);
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelect(dynamic id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Wide layout (tablet/desktop) shows text labels beside action
          // icons and centers content with a readable max width.
          final isWide = constraints.maxWidth >= 900;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _loading
                ? _buildLoader(key: const ValueKey('loading'))
                : _error != null
                    ? _buildError(key: const ValueKey('error'))
                    : Column(
                        key: const ValueKey('content'),
                        children: [
                          _buildSearchBar(),
                          _buildStatusChips(),
                          _buildCountBar(),
                          // Bulk action bar animates in/out with selection mode
                          // instead of abruptly appearing.
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            child: _selectionMode ? _buildBulkActionBar() : const SizedBox(width: double.infinity),
                          ),
                          Expanded(child: _buildList(isWide)),
                        ],
                      ),
          );
        },
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return UniversalAppBar(
      title: 'Customers',
      icon: Icons.person_outline_rounded,
      showBack: false,
      actions: [
        AppBarPopupButton<_SortOption>(
          icon: Icons.sort_rounded,
          tooltip: 'Sort',
          onSelected: (v) {
            setState(() => _sortOption = v);
            _applyFilters();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: _SortOption.spentHigh,    child: Text('Total Spent (High-Low)')),
            PopupMenuItem(value: _SortOption.bookingsHigh, child: Text('Most Bookings')),
            PopupMenuItem(value: _SortOption.nameAsc,      child: Text('Name (A-Z)')),
            PopupMenuItem(value: _SortOption.dateNew,      child: Text('Newest First')),
          ],
        ),
        const SizedBox(width: 8),
        AppBarIconButton(
          icon: _selectionMode ? Icons.close_rounded : Icons.checklist_rounded,
          tooltip: _selectionMode ? 'Cancel selection' : 'Select multiple',
          onPressed: _toggleSelectionMode,
          onGradient: true,
        ),
        const SizedBox(width: 8),
        AppBarIconButton(icon: Icons.download_rounded, tooltip: 'Export', onPressed: _exportCsv, onGradient: true),
        const SizedBox(width: 8),
        AppBarIconButton(icon: Icons.refresh_rounded, tooltip: 'Refresh', onPressed: _load, onGradient: true),
      ],
    );
  }

  // ── Search Bar ────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _applyFilters(),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText:   'Search by name or email…',
              hintStyle:  const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: Color(0xFF9CA3AF)),
                      onPressed: () {
                        _searchCtrl.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              filled:         true,
              fillColor:      const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.adminColor, width: 1.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Status Filter Chips ───────────────────────────────────
  Widget _buildStatusChips() {
    final filters = [
      (_StatusFilter.all,     'All',     const Color(0xFF374151)),
      (_StatusFilter.active,  'Active',  context.colors.accent),
      (_StatusFilter.blocked, 'Blocked', AppColors.error),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: filters.map((f) {
          final isActive = _statusFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _StatusChip(
              label: f.$2,
              color: f.$3,
              isActive: isActive,
              onTap: () {
                setState(() => _statusFilter = f.$1);
                _applyFilters();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Count Bar ─────────────────────────────────────────────
  Widget _buildCountBar() {
    final total  = _all.length;
    final active = _all.where((u) => u['is_active'] != false).length;
    final blocked = _all.where((u) => u['is_active'] == false).length;
    final totalSpent = _all.fold<double>(0, (sum, u) => sum + _spentOf(u));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _countPill(Icons.groups_rounded, '$total Total',     const Color(0xFF374151)),
            const SizedBox(width: 8),
            _countPill(Icons.check_circle_outline_rounded, '$active Active',   context.colors.accent),
            const SizedBox(width: 8),
            _countPill(Icons.block_rounded, '$blocked Blocked', AppColors.error),
            const SizedBox(width: 8),
            _countPill(Icons.payments_rounded, 'Rs ${totalSpent.toStringAsFixed(0)} Spent', const Color(0xFF16A34A)),
          ],
        ),
      ),
    );
  }

  Widget _countPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ── Bulk Action Bar ───────────────────────────────────────
  Widget _buildBulkActionBar() {
    return Container(
      width: double.infinity,
      color: AppColors.adminColor.withOpacity(0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        children: [
          Text('${_selectedIds.length} selected',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.adminColor)),
          Wrap(
            children: [
              TextButton.icon(
                onPressed: _selectedIds.isEmpty ? null : () => _bulkSetStatus(block: true),
                icon: const Icon(Icons.block_rounded, size: 16, color: AppColors.error),
                label: const Text('Block', style: TextStyle(color: AppColors.error, fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: _selectedIds.isEmpty ? null : () => _bulkSetStatus(block: false),
                icon: Icon(Icons.lock_open_rounded, size: 16, color: context.colors.accent),
                label: Text('Unblock', style: TextStyle(color: context.colors.accent, fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: _selectedIds.isEmpty ? null : _exportCsv,
                icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF6B7280)),
                label: const Text('Export', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────
  Widget _buildList(bool isWide) {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 60, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text(
              _searchCtrl.text.isNotEmpty ? 'No results for "${_searchCtrl.text}"' : 'No customers found',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.adminColor,
      child: Center(
        child: ConstrainedBox(
          // Keeps rows readable on very wide desktop windows instead of
          // stretching each card edge to edge.
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _filtered.length,
            itemBuilder: (_, i) => _AnimatedListEntry(
              index: i,
              child: _CustomerCard(
                user: _filtered[i],
                selectionMode: _selectionMode,
                isSelected: _selectedIds.contains(_filtered[i]['id']),
                onTap: _selectionMode
                    ? () => _toggleSelect(_filtered[i]['id'])
                    : () => _showCustomerDetails(_filtered[i]),
                onLongPress: () {
                  if (!_selectionMode) {
                    setState(() { _selectionMode = true; _selectedIds.add(_filtered[i]['id']); });
                  }
                },
                onToggleSelect: () => _toggleSelect(_filtered[i]['id']),
                onToggleBan: () => _toggleBan(_filtered[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Customer Details Bottom Sheet ─────────────────────────
  void _showCustomerDetails(dynamic user) {
    final name     = user['name']?.toString()      ?? 'Customer';
    final email    = user['email']?.toString()     ?? '';
    final city     = user['city']?.toString()      ?? '';
    final joined   = user['joined']?.toString()    ?? '';
    final photoUrl = user['photo_url']?.toString() ?? '';
    final bookings = user['total_bookings']?.toString() ?? '0';
    final spent    = user['total_spent']?.toString()    ?? '0.00';
    final isBanned = user['is_active'] == false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: context.colors.primaryLight,
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(AppHelpers.getInitials(name),
                            style: TextStyle(
                                color: context.colors.primary, fontWeight: FontWeight.bold, fontSize: 18))
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(email, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        const SizedBox(height: 6),
                        isBanned
                            ? statusBadge('BLOCKED', AppColors.error)
                            : statusBadge('ACTIVE', context.colors.accent),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              detailRow(Icons.event_available_rounded, 'Total Bookings', bookings),
              detailRow(Icons.payments_rounded, 'Total Spent', 'Rs $spent'),
              detailRow(Icons.location_on_outlined, 'City', city.isEmpty ? '—' : city),
              detailRow(Icons.calendar_today_outlined, 'Joined', joined.isEmpty ? '—' : joined),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBanned ? context.colors.accent : AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _toggleBan(user);
                  },
                  icon: Icon(isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
                      color: Colors.white, size: 18),
                  label: Text(isBanned ? 'Unblock Customer' : 'Block Customer',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoader({Key? key}) {
    return Center(key: key, child: const CircularProgressIndicator(color: AppColors.adminColor, strokeWidth: 2.5));
  }

  Widget _buildError({Key? key}) {
    return Center(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.error),
          ),
          const SizedBox(height: 14),
          const Text('Failed to load customers',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
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

  // ── Confirm Dialog ─────────────────────────────────────────
  // NOTE: This was previously a custom `Dialog` widget with a manual
  // `Column` -> `Row` -> `ElevatedButton` layout. On Flutter Web that
  // layout threw "BoxConstraints forces an infinite width" because the
  // ElevatedButton inside the unconstrained Row had no bounded width.
  // The crash silently broke the dialog's render tree, so tapping
  // Block/Unblock never actually completed the Navigator.pop(true) —
  // meaning _toggleBan() / _bulkSetStatus() never ran and the API call
  // never fired. Switching to AlertDialog (same as admin_users_screen.dart,
  // which works fine) fixes this because AlertDialog handles its own
  // width/height constraints correctly.
  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required IconData icon,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: confirmColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: confirmColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                ),
              ],
            ),
            content: Text(message,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4)),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, Color color, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Shared small-piece helpers (no state dependency) ─────────

Widget statusBadge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
  );
}

Widget infoChip(IconData icon, String text, {Color color = const Color(0xFF9CA3AF)}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 2),
      Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
    ],
  );
}

Widget detailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      ],
    ),
  );
}

/// Status filter chip with an animated selection transition.
class _StatusChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;
  const _StatusChip({required this.label, required this.color, required this.isActive, required this.onTap});

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.color
                : (_hovered ? const Color(0xFFEAECEF) : const Color(0xFFF3F4F6)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(widget.label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.isActive ? Colors.white : const Color(0xFF6B7280))),
        ),
      ),
    );
  }
}

/// A single customer row card. Presentation only — tap/long-press/checkbox
/// and the ban/unban trailing button all forward to the parent's existing
/// handlers; selection highlighting mirrors the original conditions.
class _CustomerCard extends StatefulWidget {
  final dynamic user;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleSelect;
  final VoidCallback onToggleBan;

  const _CustomerCard({
    required this.user,
    required this.selectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleSelect,
    required this.onToggleBan,
  });

  @override
  State<_CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<_CustomerCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final name     = user['name']?.toString()      ?? 'Customer';
    final email    = user['email']?.toString()     ?? '';
    final city     = user['city']?.toString()      ?? '';
    final joined   = user['joined']?.toString()    ?? '';
    final photoUrl = user['photo_url']?.toString() ?? '';
    final bookings = user['total_bookings']?.toString() ?? '0';
    final spent    = user['total_spent']?.toString()    ?? '0.00';
    final isBanned = user['is_active'] == false;
    final isSelected = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.adminColor.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.adminColor
                  : isBanned
                      ? AppColors.error.withOpacity(0.3)
                      : (_hovered ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB)),
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered ? Colors.black.withOpacity(0.06) : Colors.black.withOpacity(0.03),
                blurRadius: _hovered ? 12 : 6,
                offset: Offset(0, _hovered ? 3 : 1),
              ),
            ],
          ),
          child: Row(
            children: [
              if (widget.selectionMode) ...[
                Checkbox(
                  value: isSelected,
                  activeColor: AppColors.adminColor,
                  onChanged: (_) => widget.onToggleSelect(),
                ),
                const SizedBox(width: 4),
              ],
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: context.colors.primaryLight,
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(AppHelpers.getInitials(name),
                            style: TextStyle(
                                color: context.colors.primary, fontWeight: FontWeight.bold, fontSize: 13))
                        : null,
                  ),
                  if (isBanned)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5)),
                        child: const Icon(Icons.block, color: Colors.white, size: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        isBanned
                            ? statusBadge('BLOCKED', AppColors.error)
                            : statusBadge('ACTIVE', context.colors.accent),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(email,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        infoChip(Icons.event_available_rounded, '$bookings bookings'),
                        infoChip(Icons.payments_rounded, 'Rs $spent spent', color: const Color(0xFF16A34A)),
                        if (city.isNotEmpty) infoChip(Icons.location_on_outlined, city),
                        if (joined.isNotEmpty) infoChip(Icons.calendar_today_outlined, 'Joined $joined'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!widget.selectionMode)
                _BanToggleButton(isBanned: isBanned, onTap: widget.onToggleBan),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trailing Block/Unban button. Hover-tints on desktop/web; the tap
/// forwards straight to the parent's `_toggleBan`.
class _BanToggleButton extends StatefulWidget {
  final bool isBanned;
  final VoidCallback onTap;
  const _BanToggleButton({required this.isBanned, required this.onTap});

  @override
  State<_BanToggleButton> createState() => _BanToggleButtonState();
}

class _BanToggleButtonState extends State<_BanToggleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isBanned ? context.colors.accent : AppColors.error;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(_hovered ? 0.16 : 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(_hovered ? 0.5 : 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.isBanned ? Icons.lock_open_rounded : Icons.block_rounded, size: 16, color: color),
              const SizedBox(height: 2),
              Text(widget.isBanned ? 'Unban' : 'Block',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Staggered fade + slide-up entrance for list items. Purely visual — runs
/// once per build using the item's index to offset its start delay, so the
/// list feels populated rather than static.
class _AnimatedListEntry extends StatelessWidget {
  final int index;
  final Widget child;
  const _AnimatedListEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 12)) * 30;
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