// lib/features/admin/screens/admin_professionals_screen.dart
//
// Professionals Management
// Features: search, verification/status filter, category filter, sorting
// (rating/bookings/name/date), multi-select + bulk verify/remind/export,
// rating + total-bookings display, single verify/ban actions.
//
// Backend endpoints:
//   GET   /api/users/?role=professional          → list all professionals
//   PATCH /api/admin-panel/users/<id>/verify/     → give verified badge
//   PATCH /api/admin-panel/users/<id>/ban/        → ban / unban
//   POST  /api/admin-panel/users/<id>/remind/     → send profile-completion reminder

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';

enum _StatusFilter { all, verified, unverified, banned }
enum _SortOption { ratingHigh, bookingsHigh, nameAsc, dateNew }

class AdminProfessionalsScreen extends StatefulWidget {
  const AdminProfessionalsScreen({super.key});

  @override
  State<AdminProfessionalsScreen> createState() =>
      _AdminProfessionalsScreenState();
}

class _AdminProfessionalsScreenState extends State<AdminProfessionalsScreen> {
  final _api        = ApiService();
  final _searchCtrl = TextEditingController();

  bool          _loading  = true;
  String?       _error;
  List<dynamic> _all      = [];
  List<dynamic> _filtered = [];

  _StatusFilter _statusFilter = _StatusFilter.all;
  String        _categoryFilter = 'All';
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
      final r = await _api.get('/users/?role=professional');
      if (!mounted) return;
      final list = r.data is List ? List<dynamic>.from(r.data) : <dynamic>[];
      setState(() { _loading = false; _all = list; });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load professionals'; });
    }
  }

  List<String> get _categories {
    final set = <String>{'All'};
    for (final u in _all) {
      final c = (u['category_name'] ?? '').toString();
      if (c.isNotEmpty) set.add(c);
    }
    return set.toList();
  }

  // ── Filter + Search + Sort ─────────────────────────────────
  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();

    var result = _all.where((u) {
      final matchSearch = q.isEmpty ||
          (u['name']          ?? '').toString().toLowerCase().contains(q) ||
          (u['email']         ?? '').toString().toLowerCase().contains(q) ||
          (u['category_name'] ?? '').toString().toLowerCase().contains(q);

      final isVerified = u['is_verified'] == true;
      final isBanned   = u['is_active']   == false;

      final matchStatus = switch (_statusFilter) {
        _StatusFilter.all        => true,
        _StatusFilter.verified   => isVerified && !isBanned,
        _StatusFilter.unverified => !isVerified && !isBanned,
        _StatusFilter.banned     => isBanned,
      };

      final matchCategory = _categoryFilter == 'All' ||
          (u['category_name']?.toString() ?? '') == _categoryFilter;

      return matchSearch && matchStatus && matchCategory;
    }).toList();

    result.sort((a, b) {
      switch (_sortOption) {
        case _SortOption.ratingHigh:
          final ra = double.tryParse(a['average_rating']?.toString() ?? '0') ?? 0;
          final rb = double.tryParse(b['average_rating']?.toString() ?? '0') ?? 0;
          return rb.compareTo(ra);
        case _SortOption.bookingsHigh:
          final ba = int.tryParse(a['total_bookings']?.toString() ?? '0') ?? 0;
          final bb = int.tryParse(b['total_bookings']?.toString() ?? '0') ?? 0;
          return bb.compareTo(ba);
        case _SortOption.nameAsc:
          return (a['name'] ?? '').toString().toLowerCase()
              .compareTo((b['name'] ?? '').toString().toLowerCase());
        case _SortOption.dateNew:
          return (b['joined'] ?? '').toString().compareTo((a['joined'] ?? '').toString());
      }
    });

    setState(() => _filtered = result);
  }

  // ── Verify ────────────────────────────────────────────────
  Future<void> _verify(dynamic user) async {
    final name = user['name']?.toString() ?? 'this professional';

    final confirmed = await _confirmDialog(
      title:        'Verify Professional?',
      message:      '$name will get a verified badge visible to all customers.',
      confirmLabel: 'Verify',
      confirmColor: context.colors.accent,
      icon:         Icons.verified_rounded,
    );
    if (!confirmed) return;

    try {
      await _api.patch('/admin-panel/users/${user['id']}/verify/', {});
      setState(() {
        final idx = _all.indexWhere((u) => u['id'] == user['id']);
        if (idx != -1) _all[idx]['is_verified'] = true;
      });
      _applyFilters();
      _showSnack('$name verified ✓', context.colors.accent);
    } catch (e) {
      _showSnack('Verification failed. Try again.', AppColors.error);
    }
  }

  // ── Ban / Unban ───────────────────────────────────────────
  Future<void> _toggleBan(dynamic user) async {
    final isBanned = user['is_active'] == false;
    final name     = user['name']?.toString() ?? 'this professional';

    final confirmed = await _confirmDialog(
      title:        isBanned ? 'Unban Professional?' : 'Ban Professional?',
      message:      isBanned
          ? '$name will be able to login and receive bookings again.'
          : '$name will be blocked from logging in.',
      confirmLabel: isBanned ? 'Unban' : 'Ban',
      confirmColor: isBanned ? context.colors.accent : AppColors.error,
      icon:         isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
    );
    if (!confirmed) return;

    try {
      await _api.patch(
        '/admin-panel/users/${user['id']}/ban/',
        {'action': isBanned ? 'unban' : 'ban'},
      );
      setState(() {
        final idx = _all.indexWhere((u) => u['id'] == user['id']);
        if (idx != -1) _all[idx]['is_active'] = isBanned;
      });
      _applyFilters();
      _showSnack(
        isBanned ? '$name unbanned ✓' : '$name banned',
        isBanned ? context.colors.accent : AppColors.error,
      );
    } catch (e) {
      _showSnack('Action failed. Try again.', AppColors.error);
    }
  }

  // ── Single Reminder ────────────────────────────────────────
  Future<void> _sendReminder(dynamic user) async {
    final name = user['name']?.toString() ?? 'this professional';
    try {
      await _api.post('/admin-panel/users/${user['id']}/remind/', {});
      _showSnack('Reminder sent to $name', AppColors.info);
    } catch (e) {
      _showSnack('Failed to send reminder.', AppColors.error);
    }
  }

  // ── Bulk actions ──────────────────────────────────────────
  Future<void> _bulkVerify() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await _confirmDialog(
      title:        'Verify ${_selectedIds.length} professionals?',
      message:      'All selected professionals will get a verified badge.',
      confirmLabel: 'Verify All',
      confirmColor: context.colors.accent,
      icon:         Icons.verified_rounded,
    );
    if (!confirmed) return;

    int success = 0;
    for (final id in _selectedIds.toList()) {
      final idx = _all.indexWhere((u) => u['id'] == id);
      if (idx == -1 || _all[idx]['is_verified'] == true) continue;
      try {
        await _api.patch('/admin-panel/users/$id/verify/', {});
        setState(() => _all[idx]['is_verified'] = true);
        success++;
      } catch (_) {}
    }
    _applyFilters();
    setState(() { _selectionMode = false; _selectedIds.clear(); });
    _showSnack('$success professional(s) verified', context.colors.accent);
  }

  Future<void> _bulkRemind() async {
    if (_selectedIds.isEmpty) return;
    int success = 0;
    for (final id in _selectedIds.toList()) {
      try {
        await _api.post('/admin-panel/users/$id/remind/', {});
        success++;
      } catch (_) {}
    }
    setState(() { _selectionMode = false; _selectedIds.clear(); });
    _showSnack('Reminder sent to $success professional(s)', AppColors.info);
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
    buffer.writeln('Name,Email,Category,Rating,Bookings,Status,Joined');
    for (final u in rows) {
      final name     = (u['name'] ?? '').toString().replaceAll(',', ' ');
      final email    = (u['email'] ?? '').toString();
      final category = (u['category_name'] ?? '').toString().replaceAll(',', ' ');
      final rating   = (u['average_rating'] ?? '0.0').toString();
      final bookings = (u['total_bookings'] ?? '0').toString();
      final isBanned = u['is_active'] == false;
      final isVerified = u['is_verified'] == true;
      final status   = isBanned ? 'Banned' : (isVerified ? 'Verified' : 'Unverified');
      final joined   = (u['joined'] ?? '').toString();
      buffer.writeln('$name,$email,$category,$rating,$bookings,$status,$joined');
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Export (${rows.length} professionals)',
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
                    _buildCategoryDropdown(),
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
          Icon(Icons.work_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('Professionals',
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
            PopupMenuItem(value: _SortOption.ratingHigh,   child: Text('Rating (High-Low)')),
            PopupMenuItem(value: _SortOption.bookingsHigh, child: Text('Most Bookings')),
            PopupMenuItem(value: _SortOption.nameAsc,      child: Text('Name (A-Z)')),
            PopupMenuItem(value: _SortOption.dateNew,      child: Text('Newest First')),
          ],
        ),
        IconButton(
          icon: Icon(_selectionMode ? Icons.close_rounded : Icons.checklist_rounded,
              color: Colors.white),
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
        onChanged:  (_) => _applyFilters(),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText:   'Search by name, email, category…',
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
      (_StatusFilter.all,        'All',        const Color(0xFF374151)),
      (_StatusFilter.verified,   'Verified',   context.colors.accent),
      (_StatusFilter.unverified, 'Unverified', AppColors.warning),
      (_StatusFilter.banned,     'Banned',     AppColors.error),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isActive = _statusFilter == f.$1;
            return GestureDetector(
              onTap: () {
                setState(() => _statusFilter = f.$1);
                _applyFilters();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? f.$3 : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f.$2,
                    style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : const Color(0xFF6B7280))),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Category Dropdown Filter ──────────────────────────────
  Widget _buildCategoryDropdown() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, size: 16, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _categories.contains(_categoryFilter) ? _categoryFilter : 'All',
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF9CA3AF)),
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w600),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c == 'All' ? 'All Categories' : c)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _categoryFilter = v);
                  _applyFilters();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Count Bar ─────────────────────────────────────────────
  Widget _buildCountBar() {
    final total      = _all.length;
    final verified   = _all.where((u) => u['is_verified'] == true).length;
    final unverified = _all.where((u) =>
        u['is_verified'] != true && u['is_active'] != false).length;
    final banned = _all.where((u) => u['is_active'] == false).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _countPill('$total Total',       const Color(0xFF374151)),
            const SizedBox(width: 8),
            _countPill('$verified Verified', context.colors.accent),
            const SizedBox(width: 8),
            _countPill('$unverified Pending',AppColors.warning),
            const SizedBox(width: 8),
            _countPill('$banned Banned',     AppColors.error),
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
            onPressed: _selectedIds.isEmpty ? null : _bulkVerify,
            icon: Icon(Icons.verified_rounded, size: 16, color: context.colors.accent),
            label: Text('Verify', style: TextStyle(color: context.colors.accent, fontSize: 12)),
          ),
          TextButton.icon(
            onPressed: _selectedIds.isEmpty ? null : _bulkRemind,
            icon: const Icon(Icons.notifications_active_outlined, size: 16, color: AppColors.info),
            label: const Text('Remind', style: TextStyle(color: AppColors.info, fontSize: 12)),
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
            const Icon(Icons.work_outline, size: 60, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'No results for "${_searchCtrl.text}"'
                  : 'No professionals found',
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
        itemBuilder: (_, i) => _buildProCard(_filtered[i]),
      ),
    );
  }

  // ── Professional Card ─────────────────────────────────────
  Widget _buildProCard(dynamic user) {
    final id           = user['id'];
    final name         = user['name']?.toString()          ?? 'Professional';
    final email        = user['email']?.toString()         ?? '';
    final city         = user['city']?.toString()          ?? '';
    final joined       = user['joined']?.toString()        ?? '';
    final category     = user['category_name']?.toString() ?? '';
    final rate         = user['hourly_rate']?.toString()   ?? '0';
    final rating       = user['average_rating']?.toString() ?? '0.0';
    final bookings     = user['total_bookings']?.toString() ?? '0';
    final photoUrl     = user['photo_url']?.toString()     ?? '';
    final isVerified   = user['is_verified'] == true;
    final isBanned     = user['is_active']   == false;
    final isSelected   = _selectedIds.contains(id);

    final Color borderColor = isSelected
        ? AppColors.adminColor
        : isBanned
            ? AppColors.error.withOpacity(0.3)
            : isVerified
                ? context.colors.accent.withOpacity(0.3)
                : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: _selectionMode ? () => _toggleSelect(id) : null,
      onLongPress: () {
        if (!_selectionMode) {
          setState(() { _selectionMode = true; _selectedIds.add(id); });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        isSelected ? AppColors.adminColor.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          children: [
            // ── Top Row ────────────────────────────────────
            Row(
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
                      radius:          26,
                      backgroundColor: const Color(0xFFEDE9FE),
                      backgroundImage:
                          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty
                          ? Text(AppHelpers.getInitials(name),
                              style: const TextStyle(
                                  color:      Color(0xFF7C3AED),
                                  fontWeight: FontWeight.bold,
                                  fontSize:   14))
                          : null,
                    ),
                    if (isVerified)
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                              color:  context.colors.accent,
                              shape:  BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.check, color: Colors.white, size: 9),
                        ),
                      ),
                    if (isBanned)
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                              color:  AppColors.error,
                              shape:  BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.block, color: Colors.white, size: 9),
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
                                    fontSize:   14,
                                    fontWeight: FontWeight.w700,
                                    color:      Color(0xFF111827)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (isBanned)
                            _badge('BANNED', AppColors.error)
                          else if (isVerified)
                            _badge('VERIFIED', context.colors.accent)
                          else
                            _badge('UNVERIFIED', AppColors.warning),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(email,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _infoChip(Icons.star_rounded, rating, color: const Color(0xFFF59E0B)),
                          _infoChip(Icons.event_available_rounded, '$bookings bookings'),
                          if (category.isNotEmpty) _infoChip(Icons.category_outlined, category),
                          if (rate != '0') _infoChip(Icons.attach_money_rounded, 'Rs $rate/hr'),
                          if (city.isNotEmpty) _infoChip(Icons.location_on_outlined, city),
                          if (joined.isNotEmpty)
                            _infoChip(Icons.calendar_today_outlined, 'Joined $joined'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),

            // ── Action Buttons (hidden in selection mode) ──
            if (!_selectionMode)
              Row(
                children: [
                  if (!isVerified && !isBanned) ...[
                    Expanded(
                      child: _actionBtn(
                        label: 'Verify',
                        icon:  Icons.verified_rounded,
                        color: context.colors.accent,
                        onTap: () => _verify(user),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionBtn(
                        label:    'Remind',
                        icon:     Icons.notifications_active_outlined,
                        color:    AppColors.info,
                        onTap:    () => _sendReminder(user),
                        outlined: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: _actionBtn(
                      label:    isBanned ? 'Unban' : 'Ban',
                      icon:     isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
                      color:    isBanned ? context.colors.accent : AppColors.error,
                      onTap:    () => _toggleBan(user),
                      outlined: true,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Small Helpers ─────────────────────────────────────────
  Widget _badge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
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

  Widget _actionBtn({
    required String    label,
    required IconData  icon,
    required Color     color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:        outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: outlined ? 1.5 : 0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: outlined ? color : Colors.white),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    color:      outlined ? color : Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader() => const Center(
        child: CircularProgressIndicator(color: AppColors.adminColor, strokeWidth: 2.5),
      );

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          const Text('Failed to load professionals',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon:  const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDialog({
    required String   title,
    required String   message,
    required String   confirmLabel,
    required Color    confirmColor,
    required IconData icon,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(icon, color: confirmColor, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
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
        backgroundColor:  color,
        behavior:         SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}