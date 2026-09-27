// lib/features/admin/screens/admin_dashboard_screen.dart
//
// Enhanced Admin Dashboard Home — UI/UX polished.
// Header (profile / search / notifications) + Quick Actions + 8 stat cards
// + Pending Approvals + Recent Payments + Latest Registrations + Activity Logs.
//
// Backend endpoints (UNCHANGED):
//   GET /api/admin-panel/dashboard/  → stats + recent_payments +
//                                       latest_registrations + pending_approvals
//   GET /api/admin-panel/logs/       → recent activity
//   GET /api/notifications/          → unread count for bell badge
//   GET /api/users/me/               → admin name/email for profile sheet

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_provider.dart';
import '../../notifications/screens/notification_screen.dart';

/// Responsive breakpoints used throughout the dashboard for adaptive layout.
class _Breakpoints {
  static const double tablet = 700;
  static const double desktop = 1100;
}

class AdminDashboardScreen extends StatefulWidget {
  /// Optional callback that lets Quick Action buttons jump to other tabs in
  /// `AdminMainScreen`'s IndexedStack without this screen knowing about it.
  final void Function(int tabIndex)? onNavigateToTab;

  const AdminDashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();

  bool _loading = true;
  String? _error;

  // ── Stats (unchanged) ──────────────────────────────────────
  int _totalUsers = 0;
  int _totalCustomers = 0;
  int _totalPros = 0;
  int _totalRevenue = 0;
  String _revenueDisplay = '0';
  int _todayBookings = 0;
  int _pendingVerification = 0;
  int _reportedUsers = 0;
  int _blockedUsers = 0;

  List<dynamic> _recentLogs = [];
  List<dynamic> _recentPayments = [];
  List<dynamic> _latestRegistrations = [];
  List<dynamic> _pendingApprovals = [];

  int _unreadNotifications = 0;
  String _adminName = 'Admin';
  String _adminEmail = '';

  /// Drives a subtle entrance animation for the main content once data
  /// arrives. Kept single-shot & lightweight for low-end devices.
  late final AnimationController _entrance;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeIn = CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);
    _load();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Fetches dashboard, logs, notifications, and admin profile in parallel.
  /// Behavior identical to the original implementation.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.get('/admin-panel/dashboard/'),
        _api.get('/admin-panel/logs/'),
        _api.get('/notifications/'),
        _api.get('/users/me/'),
      ]);

      final dashboard = results[0].data as Map<String, dynamic>;
      final logs = results[1].data is List ? results[1].data as List : [];
      final notifs = results[2].data is List ? results[2].data as List : [];
      final me = results[3].data is Map ? results[3].data as Map : {};

      if (!mounted) return;
      setState(() {
        _loading = false;
        _totalUsers = dashboard['total_users'] ?? 0;
        _totalCustomers = dashboard['total_customers'] ?? 0;
        _totalPros = dashboard['total_professionals'] ?? 0;
        _revenueDisplay = dashboard['total_revenue']?.toString() ?? '0';
        _todayBookings = dashboard['today_bookings'] ?? 0;
        _pendingVerification = dashboard['pending_verification'] ?? 0;
        _reportedUsers = dashboard['reported_users'] ?? 0;
        _blockedUsers = dashboard['blocked_users'] ?? 0;
        _recentPayments = dashboard['recent_payments'] ?? [];
        _latestRegistrations = dashboard['latest_registrations'] ?? [];
        _pendingApprovals = dashboard['pending_approvals'] ?? [];
        _recentLogs = logs.take(8).toList();
        _unreadNotifications = notifs.where((n) => n['is_read'] != true).length;
        _adminName = me['name']?.toString() ?? 'Admin';
        _adminEmail = me['email']?.toString() ?? '';
      });
      if (mounted) _entrance.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load dashboard';
      });
    }
  }

  /// Lightweight re-fetch of just the unread notification count — used
  /// after returning from NotificationScreen so the bell badge reflects
  /// reads/mark-all-read immediately, without re-running the whole
  /// dashboard `_load()` (stats, payments, logs, etc. don't need to
  /// refetch just because notifications changed).
  Future<void> _refreshUnreadCount() async {
    try {
      final r = await _api.get('/notifications/');
      if (!mounted) return;
      final notifs = r.data is List ? r.data as List : [];
      setState(() {
        _unreadNotifications = notifs.where((n) => n['is_read'] != true).length;
      });
    } catch (_) {
      // Silent — badge just keeps its last known value on failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _Breakpoints.desktop;
    final isTablet = width >= _Breakpoints.tablet;
    final hPad = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _loading
              ? _buildLoader()
              : _error != null
                  ? _buildError()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.adminColor,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, 24),
                        child: Center(
                          child: ConstrainedBox(
                            // Keeps content readable on ultra-wide displays.
                            constraints: const BoxConstraints(maxWidth: 1280),
                            child: FadeTransition(
                              opacity: _fadeIn,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeader(),
                                  const SizedBox(height: 18),
                                  _buildQuickActions(),
                                  const SizedBox(height: 22),
                                  _buildSectionTitle('Overview'),
                                  const SizedBox(height: 12),
                                  _buildStatsGrid(
                                    isDesktop: isDesktop,
                                    isTablet: isTablet,
                                  ),
                                  const SizedBox(height: 26),
                                  _buildSectionTitle('Pending Approvals'),
                                  const SizedBox(height: 12),
                                  _buildPendingApprovals(),
                                  const SizedBox(height: 26),
                                  _buildSectionTitle('Recent Payments'),
                                  const SizedBox(height: 12),
                                  _buildRecentPayments(),
                                  const SizedBox(height: 26),
                                  _buildSectionTitle('Latest Registrations'),
                                  const SizedBox(height: 12),
                                  _buildLatestRegistrations(),
                                  const SizedBox(height: 26),
                                  _buildSectionTitle('Latest Activities'),
                                  const SizedBox(height: 12),
                                  _buildActivityLogs(),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────
  /// Top gradient banner: profile avatar, greeting, inline mini-stats,
  /// search, and notifications with a badge. Hover adds a slight lift on
  /// pointer devices.
  Widget _buildHeader() {
    return _HoverLift(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.adminColor, Color(0xFFB91C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.adminColor.withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final compact = c.maxWidth < 520;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar / profile trigger
                    Semantics(
                      button: true,
                      label: 'Open admin profile',
                      child: InkWell(
                        onTap: _showProfileSheet,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Welcome, $_adminName',
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Emoji replaced with a proper Flutter icon.
                              const Icon(
                                Icons.waving_hand_rounded,
                                size: 16,
                                color: Colors.amber,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$_totalCustomers customers · $_totalPros professionals',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withOpacity(0.88),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Search + Notifications
                    _headerIconButton(
                      tooltip: 'Search',
                      icon: Icons.search_rounded,
                      onTap: _showSearchSheet,
                      dense: compact,
                    ),
                    const SizedBox(width: 4),
                    _buildNotificationBell(dense: compact),
                  ],
                ),
                if (!compact) const SizedBox(height: 14),
                if (!compact)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _headerChip(
                        icon: Icons.groups_rounded,
                        label: 'Users',
                        value: '$_totalUsers',
                      ),
                      _headerChip(
                        icon: Icons.event_available_rounded,
                        label: 'Today',
                        value: '$_todayBookings',
                      ),
                      _headerChip(
                        icon: Icons.payments_rounded,
                        label: 'Revenue',
                        value: 'Rs $_revenueDisplay',
                      ),
                      _headerChip(
                        icon: Icons.hourglass_top_rounded,
                        label: 'Pending',
                        value: '$_pendingVerification',
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Small translucent icon button used inside the gradient header.
  Widget _headerIconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
    bool dense = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: dense ? 40 : 44,
            height: dense ? 40 : 44,
            child: Icon(icon, color: Colors.white, size: dense ? 20 : 22),
          ),
        ),
      ),
    );
  }

  /// Notifications bell with an unread-count badge. Badge is hidden when 0.
  Widget _buildNotificationBell({bool dense = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _headerIconButton(
          tooltip: 'Notifications',
          icon: Icons.notifications_rounded,
          // ✅ FIX: badge used to go stale — admin opens the bell, reads
          // / marks notifications as read inside NotificationScreen, comes
          // back, and the header still shows the OLD unread count until
          // the next full dashboard reload (pull-to-refresh). Awaiting the
          // push and re-fetching just the unread count on return keeps the
          // badge honest immediately.
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            );
            _refreshUnreadCount();
          },
          dense: dense,
        ),
        if (_unreadNotifications > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Translucent chip showing a single KPI inside the header.
  Widget _headerChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withOpacity(0.95)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet with admin identity + logout. Behavior unchanged.
  void _showProfileSheet() {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.adminColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.adminColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _adminName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_adminEmail.isNotEmpty)
                          Text(
                            _adminEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await auth.logout();
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet containing the global search UI.
  ///
  /// ✅ FIX: this used to be a pure placeholder — the "Search" button just
  /// closed the sheet and showed a SnackBar saying the module wasn't
  /// connected yet. It now actually queries the backend (Users +
  /// Professionals via `/users/?search=`, Bookings via
  /// `/admin-panel/bookings/?search=`) and shows real, tappable results —
  /// see `_AdminSearchSheet` below.
  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AdminSearchSheet(api: _api),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────
  /// Horizontally scrollable pills on mobile, wrapping row on desktop.
  /// Hover state on pointer devices gives a subtle elevation.
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction('Review Approvals', Icons.fact_check_rounded,
          () => widget.onNavigateToTab?.call(4), AppColors.warning),
      _QuickAction('View Bookings', Icons.calendar_month_rounded,
          () => widget.onNavigateToTab?.call(5), const Color(0xFF0EA5E9)),
      _QuickAction('Reported Users', Icons.flag_rounded,
          () => widget.onNavigateToTab?.call(9), AppColors.error),
      _QuickAction('Analytics', Icons.insights_rounded,
          () => widget.onNavigateToTab?.call(10), const Color(0xFF16A34A)),
      _QuickAction('Manage Banners', Icons.campaign_rounded,
          () => widget.onNavigateToTab?.call(7), const Color(0xFF7C3AED)),
      _QuickAction('View Logs', Icons.history_rounded,
          () => widget.onNavigateToTab?.call(6), const Color(0xFF64748B)),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _buildQuickActionChip(actions[i]),
      ),
    );
  }

  Widget _buildQuickActionChip(_QuickAction a) {
    return _HoverLift(
      borderRadius: BorderRadius.circular(22),
      hoverScale: 1.02,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: a.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: a.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(a.icon, size: 13, color: a.color),
                ),
                const SizedBox(width: 8),
                Text(
                  a.label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Stats Grid ─────────────────────────────────────────────
  /// Builds the 8 KPI tiles. Column count adapts to the breakpoint:
  /// 4 columns on desktop, 3 on tablet, 2 on mobile.
  Widget _buildStatsGrid({required bool isDesktop, required bool isTablet}) {
    final cards = [
      _StatCard(
        label: 'Total Users',
        value: '$_totalUsers',
        icon: Icons.groups_rounded,
        color: context.colors.primary,
        onTap: () => widget.onNavigateToTab?.call(1),
      ),
      _StatCard(
        label: 'Professionals',
        value: '$_totalPros',
        icon: Icons.work_outline_rounded,
        color: const Color(0xFF7C3AED),
        onTap: () => widget.onNavigateToTab?.call(3),
      ),
      _StatCard(
        label: 'Customers',
        value: '$_totalCustomers',
        icon: Icons.person_outline_rounded,
        color: const Color(0xFF0EA5E9),
        onTap: () => widget.onNavigateToTab?.call(2),
      ),
      _StatCard(
        label: 'Revenue',
        value: 'Rs $_revenueDisplay',
        icon: Icons.payments_rounded,
        color: const Color(0xFF16A34A),
      ),
      _StatCard(
        label: "Today's Bookings",
        value: '$_todayBookings',
        icon: Icons.event_available_rounded,
        color: context.colors.accent,
        onTap: () => widget.onNavigateToTab?.call(5),
      ),
      _StatCard(
        label: 'Pending Verification',
        value: '$_pendingVerification',
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warning,
        onTap: () => widget.onNavigateToTab?.call(4),
      ),
      _StatCard(
        label: 'Reported Users',
        value: '$_reportedUsers',
        icon: Icons.flag_rounded,
        color: AppColors.error,
        note: _reportedUsers > 0 ? '$_reportedUsers need review' : null,
        onTap: () => widget.onNavigateToTab?.call(9),
      ),
      _StatCard(
        label: 'Blocked Users',
        value: '$_blockedUsers',
        icon: Icons.block_rounded,
        color: const Color(0xFF64748B),
        onTap: () => widget.onNavigateToTab?.call(1),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = isDesktop
            ? 4
            : isTablet
                ? 3
                : 2;
        // Aspect ratio tuned per breakpoint to prevent cramped tiles.
        final ratio = isDesktop
            ? 1.55
            : isTablet
                ? 1.45
                : 1.30;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: ratio,
          ),
          itemBuilder: (_, i) => _buildStatCard(cards[i]),
        );
      },
    );
  }

  /// Individual KPI card. Wrapped with hover lift when tappable.
  Widget _buildStatCard(_StatCard card) {
    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF1F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: card.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(card.icon, color: card.color, size: 19),
              ),
              const Spacer(),
              if (card.onTap != null)
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 14,
                  color: card.color.withOpacity(0.55),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: card.color,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      card.label,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (card.note != null) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: card.note!,
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 12,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );

    if (card.onTap == null) return content;

    // Only tappable cards get the hover-lift affordance.
    return _HoverLift(
      borderRadius: BorderRadius.circular(16),
      hoverScale: 1.015,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: card.onTap,
          child: content,
        ),
      ),
    );
  }

  // ── Pending Approvals ──────────────────────────────────────
  Widget _buildPendingApprovals() {
    if (_pendingApprovals.isEmpty) {
      return _emptyCard('No pending approvals', Icons.fact_check_rounded);
    }
    return Column(
      children: _pendingApprovals.map((item) {
        final name = item['professional_name']?.toString() ?? 'Professional';
        final title = item['title']?.toString() ?? '';
        final date = item['created_at']?.toString() ?? '';
        return _rowCard(
          leadingIcon: Icons.photo_library_rounded,
          leadingColor: AppColors.warning,
          title: name,
          subtitle: title,
          trailing: TextButton(
            onPressed: () => widget.onNavigateToTab?.call(4),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.adminColor,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            child: const Text('Review'),
          ),
          dateStr: date,
        );
      }).toList(),
    );
  }

  // ── Recent Payments ────────────────────────────────────────
  Widget _buildRecentPayments() {
    if (_recentPayments.isEmpty) {
      return _emptyCard('No payments yet', Icons.payments_rounded);
    }
    return Column(
      children: _recentPayments.map((p) {
        final name =
            p['user_name']?.toString() ?? p['user_email']?.toString() ?? 'User';
        final amount = p['amount']?.toString() ?? '0';
        final curr = p['currency']?.toString() ?? '';
        final status = p['status']?.toString() ?? '';
        final date = p['created_at']?.toString() ?? '';

        Color statusColor;
        switch (status) {
          case 'completed':
            statusColor = AppColors.success;
            break;
          case 'failed':
            statusColor = AppColors.error;
            break;
          case 'refunded':
            statusColor = AppColors.info;
            break;
          default:
            statusColor = AppColors.warning;
        }

        return _rowCard(
          leadingIcon: Icons.payment_rounded,
          leadingColor: statusColor,
          title: name,
          subtitle: '$curr $amount',
          trailing: _statusPill(status.toUpperCase(), statusColor),
          dateStr: date,
        );
      }).toList(),
    );
  }

  // ── Latest Registrations ───────────────────────────────────
  Widget _buildLatestRegistrations() {
    if (_latestRegistrations.isEmpty) {
      return _emptyCard('No registrations yet', Icons.person_add_rounded);
    }
    return Column(
      children: _latestRegistrations.map((u) {
        final name = u['name']?.toString() ?? 'User';
        final role = u['role']?.toString() ?? '';
        final date = u['created_at']?.toString() ?? '';

        final roleColor = role == 'professional'
            ? const Color(0xFF7C3AED)
            : role == 'admin'
                ? AppColors.adminColor
                : context.colors.primary;

        return _rowCard(
          leadingIcon: Icons.person_rounded,
          leadingColor: roleColor,
          title: name,
          subtitle: u['email']?.toString() ?? '',
          trailing: _statusPill(role.toUpperCase(), roleColor),
          dateStr: date,
        );
      }).toList(),
    );
  }

  /// Shared status pill used across payments/registrations/logs.
  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Shared row card ────────────────────────────────────────
  /// Generic list row used by Approvals, Payments, Registrations and Logs.
  /// Hover highlight on pointer devices.
  Widget _rowCard({
    required IconData leadingIcon,
    required Color leadingColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required String dateStr,
  }) {
    final row = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF1F4)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: leadingColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(leadingIcon, size: 17, color: leadingColor),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (dateStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _formatDate(dateStr),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFCBD5E1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );

    // Non-interactive rows still get a soft hover tint for visual feedback.
    return _HoverTint(child: row);
  }

  /// Consistent empty state card.
  Widget _emptyCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF1F4)),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: const Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Activity Logs ─────────────────────────────────────────
  Widget _buildActivityLogs() {
    if (_recentLogs.isEmpty) {
      return _emptyCard('No activity yet', Icons.history_rounded);
    }
    return Column(
      children: _recentLogs.map((log) => _buildLogTile(log)).toList(),
    );
  }

  /// Maps a log action → (icon, color) pair, then renders a shared row card.
  Widget _buildLogTile(dynamic log) {
    final action = log['action']?.toString() ?? '';
    final Color color;
    final IconData icon;

    switch (action) {
      case 'verify':
        color = context.colors.accent;
        icon = Icons.verified_rounded;
        break;
      case 'ban':
        color = AppColors.error;
        icon = Icons.block_rounded;
        break;
      case 'unban':
        color = AppColors.info;
        icon = Icons.lock_open_rounded;
        break;
      case 'approve':
        color = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'reject':
        color = AppColors.warning;
        icon = Icons.cancel_outlined;
        break;
      default:
        color = const Color(0xFF9CA3AF);
        icon = Icons.info_outline_rounded;
    }

    final adminEmail = log['admin_email']?.toString() ?? 'Admin';
    final targetEmail = log['target_user_email']?.toString() ?? 'a user';
    final note = log['note']?.toString() ?? '';
    final createdAt = log['created_at']?.toString() ?? '';

    return _rowCard(
      leadingIcon: icon,
      leadingColor: color,
      title: '$adminEmail → $targetEmail',
      subtitle: note,
      trailing: _statusPill(action.toUpperCase(), color),
      dateStr: createdAt,
    );
  }

  // ── Section Title ─────────────────────────────────────────
  /// Section header with a small accent bar for stronger visual hierarchy.
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.adminColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  // ── Loader / Error ────────────────────────────────────────
  Widget _buildLoader() {
    return const Center(
      key: ValueKey('loader'),
      child: CircularProgressIndicator(
        color: AppColors.adminColor,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildError() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Failed to load dashboard',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats an ISO date string to `dd/MM/yyyy HH:mm` in local time.
  /// Returns an empty string when the input can't be parsed.
  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

// ── Reusable UI primitives ─────────────────────────────────────────────────

/// Adds a subtle scale + cursor change on hover.
/// Touch devices never fire [MouseRegion] enter/exit events, so this is a
/// no-op there with zero overhead — no capability check required.
class _HoverLift extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double hoverScale;

  const _HoverLift({
    required this.child,
    required this.borderRadius,
    this.hoverScale = 1.02,
  });

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!mounted || _hovered) return;
        setState(() => _hovered = true);
      },
      onExit: (_) {
        if (!mounted || !_hovered) return;
        setState(() => _hovered = false);
      },
      child: AnimatedScale(
        scale: _hovered ? widget.hoverScale : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Applies a soft background tint on hover. Used for non-interactive rows
/// to give visual feedback without implying clickability.
/// Touch devices never fire hover events, so this is naturally inert there.
class _HoverTint extends StatefulWidget {
  final Widget child;
  const _HoverTint({required this.child});

  @override
  State<_HoverTint> createState() => _HoverTintState();
}

class _HoverTintState extends State<_HoverTint> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!mounted || _hovered) return;
        setState(() => _hovered = true);
      },
      onExit: (_) {
        if (!mounted || !_hovered) return;
        setState(() => _hovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF9FAFB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.child,
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────
class _StatCard {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? note;
  final VoidCallback? onTap;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.note,
    this.onTap,
  });
}

class _QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _QuickAction(this.label, this.icon, this.onTap, this.color);
}

// ── Global Search Sheet ──────────────────────────────────────────────────
//
// Real backend-backed search — replaces the old placeholder that always
// showed a "not connected yet" SnackBar.
//
// Queries, in parallel:
//   GET /users/?search=<q>              → matching customers + professionals
//   GET /admin-panel/bookings/?search=<q> → matching bookings (by id, or
//                                            customer/professional name/email)
//
// Debounced (350ms) search-as-you-type, plus the same query re-runs on
// submit. Tapping a result opens a compact detail sheet built straight
// from the fields the search endpoints already return — no extra network
// round-trip needed.
class _AdminSearchSheet extends StatefulWidget {
  final ApiService api;
  const _AdminSearchSheet({required this.api});

  @override
  State<_AdminSearchSheet> createState() => _AdminSearchSheetState();
}

class _AdminSearchSheetState extends State<_AdminSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;

  bool _loading = false;
  bool _searched = false;
  String? _error;
  List<dynamic> _users = [];
  List<dynamic> _bookings = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(q));
  }

  Future<void> _runSearch(String rawQuery) async {
    final q = rawQuery.trim();
    if (q.length < 2) {
      setState(() {
        _searched = false;
        _users = [];
        _bookings = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.get('/users/?search=${Uri.encodeQueryComponent(q)}'),
        widget.api.get('/admin-panel/bookings/?search=${Uri.encodeQueryComponent(q)}'),
      ]);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _searched = true;
        _users = results[0].data is List ? results[0].data as List : [];
        _bookings = results[1].data is List ? results[1].data as List : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _searched = true;
        _error = 'Search failed. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.adminColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.adminColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Search',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search users, professionals, bookings…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) {
                setState(() {}); // refresh clear-button visibility
                _onChanged(v);
              },
              onSubmitted: _runSearch,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.adminColor,
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(_error!,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        ),
      );
    }
    if (!_searched) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Type at least 2 characters to search',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
        ),
      );
    }
    if (_users.isEmpty && _bookings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No matching users or bookings',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_users.isNotEmpty) ...[
          _sectionLabel('Users & Professionals (${_users.length})'),
          ..._users.map(_userTile),
          const SizedBox(height: 8),
        ],
        if (_bookings.isNotEmpty) ...[
          _sectionLabel('Bookings (${_bookings.length})'),
          ..._bookings.map(_bookingTile),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: Color(0xFF9CA3AF),
          ),
        ),
      );

  Widget _userTile(dynamic u) {
    final name = u['name']?.toString() ?? '';
    final email = u['email']?.toString() ?? '';
    final role = u['role']?.toString() ?? '';
    final isVerified = u['is_verified'] == true;
    final roleColor = role == 'professional'
        ? const Color(0xFF7C3AED)
        : const Color(0xFF0EA5E9);

    return _resultCard(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: roleColor.withOpacity(0.12),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(color: roleColor, fontWeight: FontWeight.w700),
        ),
      ),
      title: name,
      subtitle: email,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVerified)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.verified_rounded,
                  size: 15, color: Color(0xFF10B981)),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w700, color: roleColor),
            ),
          ),
        ],
      ),
      onTap: () => _showUserDetail(u),
    );
  }

  Widget _bookingTile(dynamic b) {
    final id = b['id']?.toString() ?? '';
    final customer = b['customer_name']?.toString() ?? 'Customer';
    final professional = b['professional_name']?.toString() ?? 'Professional';
    final status = b['status']?.toString() ?? '';
    final statusColor = switch (status) {
      'completed' => const Color(0xFF10B981),
      'cancelled' => const Color(0xFFEF4444),
      'pending' => const Color(0xFFF59E0B),
      _ => const Color(0xFF0EA5E9),
    };

    return _resultCard(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.calendar_month_rounded, size: 18, color: statusColor),
      ),
      title: '$customer → $professional',
      subtitle: 'Booking #$id',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor),
        ),
      ),
      onTap: () => _showBookingDetail(b),
    );
  }

  Widget _resultCard({
    required Widget leading,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827))),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetail(dynamic u) {
    final name = u['name']?.toString() ?? 'User';
    final email = u['email']?.toString() ?? '';
    final role = u['role']?.toString() ?? '';
    final city = u['city']?.toString() ?? '';
    final joined = u['joined']?.toString() ?? '';
    final isBanned = u['is_active'] == false;
    final isPro = role == 'professional';
    final category = u['category_name']?.toString() ?? '';
    final hourlyRate = u['hourly_rate']?.toString() ?? '';
    final isVerified = u['is_verified'] == true;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                if (isBanned)
                  _pill('BANNED', const Color(0xFFEF4444))
                else if (isVerified)
                  _pill('VERIFIED', const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 6),
            _detailRow(Icons.email_outlined, email),
            if (city.isNotEmpty) _detailRow(Icons.location_on_outlined, city),
            if (joined.isNotEmpty)
              _detailRow(Icons.calendar_today_outlined, 'Joined $joined'),
            if (isPro && category.isNotEmpty)
              _detailRow(Icons.work_outline_rounded, category),
            if (isPro && hourlyRate.isNotEmpty)
              _detailRow(Icons.payments_outlined, 'Rs $hourlyRate/hr'),
            const SizedBox(height: 4),
            _pill(role.toUpperCase(),
                isPro ? const Color(0xFF7C3AED) : const Color(0xFF0EA5E9)),
          ],
        ),
      ),
    );
  }

  void _showBookingDetail(dynamic b) {
    final id = b['id']?.toString() ?? '';
    final customer = b['customer_name']?.toString() ?? '';
    final professional = b['professional_name']?.toString() ?? '';
    final profession = b['profession']?.toString() ?? '';
    final status = b['status']?.toString() ?? '';
    final date = b['date']?.toString() ?? '';
    final time = b['time']?.toString() ?? '';
    final location = b['location']?.toString() ?? '';
    final note = b['note']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking #$id',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            _detailRow(Icons.person_outline_rounded, 'Customer: $customer'),
            _detailRow(Icons.badge_outlined,
                'Professional: $professional${profession.isNotEmpty ? ' ($profession)' : ''}'),
            if (date.isNotEmpty || time.isNotEmpty)
              _detailRow(Icons.calendar_today_outlined, '$date  $time'.trim()),
            if (location.isNotEmpty)
              _detailRow(Icons.location_on_outlined, location),
            if (note.isNotEmpty) _detailRow(Icons.notes_rounded, note),
            const SizedBox(height: 4),
            _pill(status.toUpperCase(), switch (status) {
              'completed' => const Color(0xFF10B981),
              'cancelled' => const Color(0xFFEF4444),
              'pending' => const Color(0xFFF59E0B),
              _ => const Color(0xFF0EA5E9),
            }),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF374151))),
            ),
          ],
        ),
      );

  Widget _pill(String text, Color color) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
      );
}