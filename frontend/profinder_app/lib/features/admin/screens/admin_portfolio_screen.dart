// lib/features/admin/screens/admin_portfolio_screen.dart
//
// Screen 4 of 6 — Portfolio Approval
// Features: list portfolio items by status, approve, reject with note
//
// Backend endpoints:
//   GET   /api/profiles/admin/portfolio/?status=pending   → pending items
//   GET   /api/profiles/admin/portfolio/?status=approved  → approved items
//   GET   /api/profiles/admin/portfolio/?status=rejected  → rejected items
//   PATCH /api/profiles/admin/portfolio/<id>/             → approve / reject
//     body: { "status": "approved" }
//     body: { "status": "rejected", "admin_note": "reason" }
//
// Changes reflect to professional:
//   approve → portfolio item dikhta hai customers ko
//   reject  → portfolio item rejected with reason

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';

class AdminPortfolioScreen extends StatefulWidget {
  const AdminPortfolioScreen({super.key});

  @override
  State<AdminPortfolioScreen> createState() => _AdminPortfolioScreenState();
}

class _AdminPortfolioScreenState extends State<AdminPortfolioScreen> {
  final _api = ApiService();

  bool          _loading      = true;
  String?       _error;
  String        _activeStatus = 'pending'; // pending | approved | rejected
  List<dynamic> _items        = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Load ──────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.get(
          '/profiles/admin/portfolio/?status=$_activeStatus');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items   = r.data is List ? List<dynamic>.from(r.data) : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load portfolio'; });
    }
  }

  // ── Approve ───────────────────────────────────────────────
  Future<void> _approve(dynamic item) async {
    final title = item['title']?.toString() ?? 'this item';
    final confirmed = await _confirmDialog(
      title:        'Approve Portfolio?',
      message:      '"$title" will be visible to all customers.',
      confirmLabel: 'Approve',
      confirmColor: context.colors.accent,
      icon:         Icons.check_circle_outline_rounded,
    );
    if (!confirmed) return;

    try {
      await _api.patch(
        '/profiles/admin/portfolio/${item['id']}/',
        {'status': 'approved'},
      );
      // ✅ Remove from list immediately
      setState(() => _items.removeWhere((i) => i['id'] == item['id']));
      _showSnack('"$title" approved ✓', context.colors.accent);
    } catch (e) {
      _showSnack('Action failed. Try again.', AppColors.error);
    }
  }

  // ── Reject ────────────────────────────────────────────────
  Future<void> _reject(dynamic item) async {
    final title = item['title']?.toString() ?? 'this item';

    // Ask for rejection reason
    final note = await _noteDialog('Rejection Reason (optional)');

    try {
      await _api.patch(
        '/profiles/admin/portfolio/${item['id']}/',
        {
          'status': 'rejected',
          if (note != null && note.isNotEmpty) 'admin_note': note,
        },
      );
      setState(() => _items.removeWhere((i) => i['id'] == item['id']));
      _showSnack('"$title" rejected', AppColors.error);
    } catch (e) {
      _showSnack('Action failed. Try again.', AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatusTabs(),
          Expanded(
            child: _loading
                ? _buildLoader()
                : _error != null
                    ? _buildError()
                    : _items.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppColors.adminColor,
                            child: ListView.builder(
                              padding:     const EdgeInsets.all(12),
                              itemCount:   _items.length,
                              itemBuilder: (_, i) =>
                                  _buildPortfolioCard(_items[i]),
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
          Icon(Icons.photo_library_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('Portfolio Approval',
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

  // ── Status Tabs ───────────────────────────────────────────
  Widget _buildStatusTabs() {
    final tabs = [
      ('pending',  'Pending',  AppColors.warning),
      ('approved', 'Approved', context.colors.accent),
      ('rejected', 'Rejected', AppColors.error),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: tabs.map((t) {
          final isActive = _activeStatus == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _activeStatus = t.$1);
                _load();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? t.$3 : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  t.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      color:      isActive
                          ? Colors.white
                          : const Color(0xFF6B7280)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Portfolio Card ────────────────────────────────────────
  Widget _buildPortfolioCard(dynamic item) {
    final title     = item['title']?.toString()              ?? 'Untitled';
    final desc      = item['description']?.toString()        ?? '';
    final imageUrl  = item['image_url']?.toString()          ?? '';
    final proName   = item['professional_name']?.toString()  ?? 'Professional';
    final proEmail  = item['professional_email']?.toString() ?? '';
    final adminNote = item['admin_note']?.toString()         ?? '';
    final isPending = _activeStatus == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset:     const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Portfolio Image ───────────────────────────
          if (imageUrl.isNotEmpty)
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color:  const Color(0xFFF3F4F6),
                      child:  const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Color(0xFFD1D5DB), size: 48),
                      ),
                    ),
                    loadingBuilder: (_, child, prog) {
                      if (prog == null) return child;
                      return Container(
                        height: 180,
                        color:  const Color(0xFFF3F4F6),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: prog.expectedTotalBytes != null
                                ? prog.cumulativeBytesLoaded /
                                    prog.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: AppColors.adminColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Status badge on image
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _activeStatus == 'approved'
                          ? context.colors.accent
                          : _activeStatus == 'rejected'
                              ? AppColors.error
                              : AppColors.warning,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _activeStatus.toUpperCase(),
                      style: const TextStyle(
                          fontSize:   10,
                          fontWeight: FontWeight.w700,
                          color:      Colors.white),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              height: 100,
              color: context.colors.primaryLight,
              child: Center(
                child: Icon(Icons.image_outlined,
                    color: context.colors.primary.withOpacity(0.3), size: 48),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Title + Description ───────────────────
                Text(title,
                    style: const TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.w700,
                        color:      Color(0xFF111827))),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 13,
                          color:    Color(0xFF6B7280),
                          height:   1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],

                const SizedBox(height: 12),

                // ── Professional Info ─────────────────────
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius:          16,
                        backgroundColor: const Color(0xFFEDE9FE),
                        child: Text(
                            AppHelpers.getInitials(proName),
                            style: const TextStyle(
                                fontSize:   9,
                                color:      Color(0xFF7C3AED),
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(proName,
                                style: const TextStyle(
                                    fontSize:   13,
                                    fontWeight: FontWeight.w600,
                                    color:      Color(0xFF374151))),
                            Text(proEmail,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color:    Color(0xFF9CA3AF))),
                          ],
                        ),
                      ),
                      const Icon(Icons.person_outline_rounded,
                          size: 16, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                ),

                // ── Admin Note (rejected items) ───────────
                if (adminNote.isNotEmpty &&
                    _activeStatus == 'rejected') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14, color: AppColors.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(adminNote,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color:    AppColors.error,
                                  height:   1.4)),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Approve / Reject Buttons (pending only) ─
                if (isPending) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approve(item),
                          icon:  const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16),
                          label: const Text('Approve',
                              style: TextStyle(
                                  fontSize:   13,
                                  fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _reject(item),
                          icon:  const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Reject',
                              style: TextStyle(
                                  fontSize:   13,
                                  fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(
                                color: AppColors.error, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────
  Widget _buildEmpty() {
    final msg = switch (_activeStatus) {
      'pending'  => 'No pending portfolios 🎉',
      'approved' => 'No approved portfolios yet',
      _          => 'No rejected portfolios',
    };
    final icon = switch (_activeStatus) {
      'pending'  => Icons.hourglass_empty_rounded,
      'approved' => Icons.check_circle_outline_rounded,
      _          => Icons.cancel_outlined,
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFD1D5DB)),
          const SizedBox(height: 14),
          Text(msg,
              style: const TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.w600,
                  color:      Color(0xFF9CA3AF))),
          if (_activeStatus == 'pending') ...[
            const SizedBox(height: 8),
            const Text('All portfolios reviewed!',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF9CA3AF))),
          ],
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
          const Text('Failed to load portfolios',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
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

  // ── Dialogs ───────────────────────────────────────────────
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(icon, color: confirmColor, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
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

  Future<String?> _noteDialog(String title) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined,
                color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText:  'Write reason (optional)…',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled:    true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:   BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Skip',
                style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Reject',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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