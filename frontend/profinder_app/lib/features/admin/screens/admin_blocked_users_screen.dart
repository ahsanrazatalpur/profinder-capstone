// lib/features/admin/screens/admin_blocked_users_screen.dart
//
// Blocked Users — everyone currently is_active=False, with who blocked
// them, when, and why (pulled from the most recent 'ban' AdminLog entry).
//
// Backend endpoints:
//   GET   /api/admin-panel/blocked-users/     → list of blocked users
//   PATCH /api/admin-panel/users/<id>/ban/    → unblock a user
//     body: { "action": "unban" }

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';

// Responsive breakpoints for the card list: a single column on phones,
// a two-column grid from tablet width up.
const double _kTabletBreakpoint = 720;
const double _kDesktopBreakpoint = 1080;

class AdminBlockedUsersScreen extends StatefulWidget {
  const AdminBlockedUsersScreen({super.key});

  @override
  State<AdminBlockedUsersScreen> createState() => _AdminBlockedUsersScreenState();
}

class _AdminBlockedUsersScreenState extends State<AdminBlockedUsersScreen>
    with SingleTickerProviderStateMixin {
  final _api        = ApiService();
  final _searchCtrl = TextEditingController();

  bool          _loading  = true;
  String?       _error;
  List<dynamic> _all      = [];
  List<dynamic> _filtered = [];

  // Drives the staggered fade/slide-in of cards whenever the list reloads,
  // matching the entrance animation used on the other admin screens.
  late final AnimationController _listAnim;

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
      duration: const Duration(milliseconds: 500),
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
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.get('/admin-panel/blocked-users/');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _all     = r.data is List ? List<dynamic>.from(r.data) : [];
      });
      _applySearch();
      _listAnim.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load blocked users'; });
    }
  }

  // ── Search ────────────────────────────────────────────────
  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List<dynamic>.from(_all)
          : _all.where((u) {
              return (u['name']  ?? '').toString().toLowerCase().contains(q) ||
                     (u['email'] ?? '').toString().toLowerCase().contains(q) ||
                     (u['reason'] ?? '').toString().toLowerCase().contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearch(),
            Expanded(
              // Cross-fades between loading / error / content so switching
              // states doesn't feel like an abrupt jump-cut.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _loading
                    ? const Center(
                        key: ValueKey('loading'),
                        child: CircularProgressIndicator(
                            color: AppColors.adminColor, strokeWidth: 2.5))
                    : _error != null
                        ? _buildError()
                        : RefreshIndicator(
                            key: const ValueKey('content'),
                            onRefresh: _load,
                            color: AppColors.adminColor,
                            child: _filtered.isEmpty
                                ? ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: [_emptyState()],
                                  )
                                : _buildList(),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── List layout: single column on phones, responsive grid on wider
  // screens so the screen scales cleanly up to tablet/desktop widths ──
  Widget _buildList() {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _kTabletBreakpoint;
    final isDesktop = width >= _kDesktopBreakpoint;

    if (!isWide) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _animatedCard(_filtered[i], i),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
          ),
          itemCount: _filtered.length,
          itemBuilder: (_, i) => _animatedCard(_filtered[i], i),
        ),
      ),
    );
  }

  // Staggers each card's fade + slide-in based on its index, capped so the
  // whole list settles within the animation's duration regardless of length.
  Widget _animatedCard(dynamic u, int i) {
    return AnimatedBuilder(
      animation: _listAnim,
      builder: (context, child) {
        final delay = (i * 0.06).clamp(0.0, 0.7);
        final animation = CurvedAnimation(
          parent: _listAnim,
          curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 16),
            child: child,
          ),
        );
      },
      child: _userCard(u),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.adminColor, Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.block_rounded, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Blocked Users',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                // Count badge animates smoothly whenever the underlying
                // list changes (load, unblock, etc.).
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                  child: Text(
                    '${_all.length} currently blocked',
                    key: ValueKey(_all.length),
                    style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.88)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────
  Widget _buildSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => _applySearch(),
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          hintText: 'Search by name, email, or reason…',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9CA3AF)),
          // Clear button only shows once there is something to clear, and
          // re-applies the (now empty) search so filtering stays in sync.
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchCtrl.clear();
                    _applySearch();
                  },
                ),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.adminColor.withOpacity(0.4), width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── User Card ─────────────────────────────────────────────
  Widget _userCard(dynamic u) {
    final name      = (u['name'] ?? 'Unknown').toString();
    final email     = (u['email'] ?? '').toString();
    final role      = (u['role'] ?? '').toString();
    final reason    = (u['reason'] ?? '').toString();
    final blockedBy = (u['blocked_by'] ?? '').toString();
    final blockedAt = _formatDate(u['blocked_at']);

    final roleColor = role == 'professional'
        ? AppColors.professionalColor
        : role == 'customer'
            ? AppColors.customerColor
            : AppColors.adminColor;

    return _HoverLift(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: roleColor.withOpacity(0.12),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(fontWeight: FontWeight.w800, color: roleColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(email,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (role.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(role,
                          style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w800, color: roleColor)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.block_rounded, size: 13, color: AppColors.error),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reason.isNotEmpty ? reason : 'No reason recorded',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: AppColors.error, height: 1.3),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (blockedBy.isNotEmpty || blockedAt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (blockedBy.isNotEmpty) 'Blocked by $blockedBy',
                          if (blockedAt.isNotEmpty) blockedAt,
                        ].join(' · '),
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmUnblock(u),
                  icon: Icon(Icons.lock_open_rounded, size: 16, color: context.colors.accent),
                  label: Text('Unblock', style: TextStyle(color: context.colors.accent, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.colors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Unblock flow ──────────────────────────────────────────
  void _confirmUnblock(dynamic u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.accent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_open_rounded, color: context.colors.accent, size: 26),
        ),
        title: const Text('Unblock user?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        content: Text(
          'This will restore access for ${u['name'] ?? 'this user'}. They will be able to log in again.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              _unblock(u);
            },
            child: const Text('Unblock', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _unblock(dynamic u) async {
    try {
      await _api.patch('/admin-panel/users/${u['id']}/ban/', {'action': 'unban'});
      if (!mounted) return;
      _showSnack('${u['name'] ?? 'User'} has been unblocked.', context.colors.accent);
      _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to unblock user.', AppColors.error);
    }
  }

  // Consistent floating snackbar with a status icon, matching the styling
  // used elsewhere in the admin panel.
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppColors.error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.colors.accent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified_user_rounded, size: 40, color: context.colors.accent),
            ),
            const SizedBox(height: 14),
            const Text('No blocked users — all clear!',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
            const SizedBox(height: 4),
            Text('New blocks will show up here',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      key: const ValueKey('error'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
          ),
          const SizedBox(height: 14),
          const Text('Failed to load blocked users',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return '';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Small shared UI helper — subtle desktop/web hover lift for cards
// ═══════════════════════════════════════════════════════════════════════════

/// Wraps a card with a gentle hover "lift" (translate + deeper shadow) on
/// platforms that support a mouse cursor. No-ops on touch-only devices.
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
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: _hovering
            ? (Matrix4.identity()..translate(0.0, -2.0))
            : Matrix4.identity(),
        decoration: _hovering
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              )
            : null,
        child: widget.child,
      ),
    );
  }
}