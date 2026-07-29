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
        isBanned ? '$name unblocked ✓' : '$name blocked',
        isBanned ? context.colors.accent : AppColors.error,
      );
    } catch (e) {
      _showSnack('Action failed. Try again.', AppColors.error);
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
    _showSnack('$success customer(s) ${block ? 'blocked' : 'unblocked'}',
        block ? AppColors.error : context.colors.accent);
  }

  // ── Export (CSV → clipboard) ──────────────────────────────
  void _exportCsv() {
    final rows = _selectedIds.isNotEmpty
        ? _all.where((u) => _selectedIds.contains(u['id'])).toList()
        : _filtered;

    if (rows.isEmpty) {
      _showSnack('Nothing to export', AppColors.warning);
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Export (${rows.length} customers)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          height: 260,
          child: SingleChildScrollView(
            child: SelectableText(buffer.toString(),
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: buffer.toString()));
              Navigator.pop(context);
              _showSnack('CSV copied to clipboard — paste into Excel/Sheets', AppColors.success);
            },
            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
            label: const Text('Copy to Clipboard', style: TextStyle(color: Colors.white)),
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
      body: _loading
          ? _buildLoader()
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    _buildSearchBar(),
                    _buildStatusChips(),
                    _buildCountBar(),
                    if (_selectionMode) _buildBulkActionBar(),
                    Expanded(child: _buildList()),
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
          Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('Customers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
      actions: [
        PopupMenuButton<_SortOption>(
          icon: const Icon(Icons.sort_rounded, color: Colors.white),
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
        IconButton(
          icon: Icon(_selectionMode ? Icons.close_rounded : Icons.checklist_rounded, color: Colors.white),
          tooltip: _selectionMode ? 'Cancel selection' : 'Select multiple',
          onPressed: _toggleSelectionMode,
        ),
        IconButton(
          icon: const Icon(Icons.download_rounded, color: Colors.white),
          tooltip: 'Export',
          onPressed: _exportCsv,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
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
            child: GestureDetector(
              onTap: () {
                setState(() => _statusFilter = f.$1);
                _applyFilters();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? f.$3 : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f.$2,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : const Color(0xFF6B7280))),
              ),
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
            _countPill('$total Total',     const Color(0xFF374151)),
            const SizedBox(width: 8),
            _countPill('$active Active',   context.colors.accent),
            const SizedBox(width: 8),
            _countPill('$blocked Blocked', AppColors.error),
            const SizedBox(width: 8),
            _countPill('Rs ${totalSpent.toStringAsFixed(0)} Spent', const Color(0xFF16A34A)),
          ],
        ),
      ),
    );
  }

  Widget _countPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ── Bulk Action Bar ───────────────────────────────────────
  Widget _buildBulkActionBar() {
    return Container(
      color: AppColors.adminColor.withOpacity(0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text('${_selectedIds.length} selected',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.adminColor)),
          const Spacer(),
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
    );
  }

  // ── List ──────────────────────────────────────────────────
  Widget _buildList() {
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
      child: ListView.builder(
        padding:     const EdgeInsets.all(12),
        itemCount:   _filtered.length,
        itemBuilder: (_, i) => _buildCustomerCard(_filtered[i]),
      ),
    );
  }

  // ── Customer Card ─────────────────────────────────────────
  Widget _buildCustomerCard(dynamic user) {
    final id       = user['id'];
    final name     = user['name']?.toString()      ?? 'Customer';
    final email    = user['email']?.toString()     ?? '';
    final city     = user['city']?.toString()      ?? '';
    final joined   = user['joined']?.toString()    ?? '';
    final photoUrl = user['photo_url']?.toString() ?? '';
    final bookings = user['total_bookings']?.toString() ?? '0';
    final spent    = user['total_spent']?.toString()    ?? '0.00';
    final isBanned = user['is_active'] == false;
    final isSelected = _selectedIds.contains(id);

    return GestureDetector(
      onTap: _selectionMode ? () => _toggleSelect(id) : () => _showCustomerDetails(user),
      onLongPress: () {
        if (!_selectionMode) {
          setState(() { _selectionMode = true; _selectedIds.add(id); });
        }
      },
      child: Container(
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
                    : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            if (_selectionMode) ...[
              Checkbox(
                value: isSelected,
                activeColor: AppColors.adminColor,
                onChanged: (_) => _toggleSelect(id),
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
                          ? _statusBadge('BLOCKED', AppColors.error)
                          : _statusBadge('ACTIVE', context.colors.accent),
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
                      _infoChip(Icons.event_available_rounded, '$bookings bookings'),
                      _infoChip(Icons.payments_rounded, 'Rs $spent spent', color: const Color(0xFF16A34A)),
                      if (city.isNotEmpty) _infoChip(Icons.location_on_outlined, city),
                      if (joined.isNotEmpty) _infoChip(Icons.calendar_today_outlined, 'Joined $joined'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!_selectionMode)
              GestureDetector(
                onTap: () => _toggleBan(user),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isBanned ? context.colors.accent.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isBanned ? context.colors.accent.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
                          size: 16, color: isBanned ? context.colors.accent : AppColors.error),
                      const SizedBox(height: 2),
                      Text(isBanned ? 'Unban' : 'Block',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isBanned ? context.colors.accent : AppColors.error)),
                    ],
                  ),
                ),
              ),
          ],
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
                            ? _statusBadge('BLOCKED', AppColors.error)
                            : _statusBadge('ACTIVE', context.colors.accent),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _detailRow(Icons.event_available_rounded, 'Total Bookings', bookings),
              _detailRow(Icons.payments_rounded, 'Total Spent', 'Rs $spent'),
              _detailRow(Icons.location_on_outlined, 'City', city.isEmpty ? '—' : city),
              _detailRow(Icons.calendar_today_outlined, 'Joined', joined.isEmpty ? '—' : joined),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBanned ? context.colors.accent : AppColors.error,
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

  Widget _detailRow(IconData icon, String label, String value) {
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

  // ── Helpers ───────────────────────────────────────────────
  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _infoChip(IconData icon, String text, {Color color = const Color(0xFF9CA3AF)}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 2),
        Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.adminColor, strokeWidth: 2.5),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          const Text('Failed to load customers',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 16),
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

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            content: Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}