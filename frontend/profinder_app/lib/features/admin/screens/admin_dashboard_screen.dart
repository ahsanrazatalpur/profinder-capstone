// lib/features/admin/screens/admin_dashboard_screen.dart
//
// Enhanced Admin Dashboard Home
// Header (profile / search / notifications) + Quick Actions + 8 stat cards
// + Pending Approvals + Recent Payments + Latest Registrations + Activity Logs
//
// Backend endpoint:
//   GET /api/admin-panel/dashboard/  → all stats + recent_payments +
//                                       latest_registrations + pending_approvals
//   GET /api/admin-panel/logs/       → recent activity
//   GET /api/notifications/          → unread count for bell badge
//   GET /api/users/me/               → admin name/email for profile sheet

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../../core/theme/theme_context_ext.dart';

class AdminDashboardScreen extends StatefulWidget {
  // Optional — lets Quick Action buttons jump to other tabs in
  // AdminMainScreen's IndexedStack without this screen knowing about
  // AdminMainScreen directly.
  final void Function(int tabIndex)? onNavigateToTab;

  const AdminDashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _api = ApiService();

  bool _loading = true;
  String? _error;

  // ── Stats ──────────────────────────────────────────────────
  int _totalUsers        = 0;
  int _totalCustomers    = 0;
  int _totalPros         = 0;
  int _totalRevenue      = 0; // stored as int for display; raw string kept below
  String _revenueDisplay = '0';
  int _todayBookings     = 0;
  int _pendingVerification = 0;
  int _reportedUsers     = 0;
  int _blockedUsers      = 0;

  List<dynamic> _recentLogs         = [];
  List<dynamic> _recentPayments     = [];
  List<dynamic> _latestRegistrations = [];
  List<dynamic> _pendingApprovals    = [];

  int _unreadNotifications = 0;
  String _adminName  = 'Admin';
  String _adminEmail = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.get('/admin-panel/dashboard/'),
        _api.get('/admin-panel/logs/'),
        _api.get('/notifications/'),
        _api.get('/users/me/'),
      ]);

      final dashboard = results[0].data as Map<String, dynamic>;
      final logs       = results[1].data is List ? results[1].data as List : [];
      final notifs     = results[2].data is List ? results[2].data as List : [];
      final me          = results[3].data is Map ? results[3].data as Map : {};

      if (!mounted) return;
      setState(() {
        _loading              = false;
        _totalUsers           = dashboard['total_users'] ?? 0;
        _totalCustomers       = dashboard['total_customers'] ?? 0;
        _totalPros            = dashboard['total_professionals'] ?? 0;
        _revenueDisplay       = dashboard['total_revenue']?.toString() ?? '0';
        _todayBookings        = dashboard['today_bookings'] ?? 0;
        _pendingVerification  = dashboard['pending_verification'] ?? 0;
        _reportedUsers        = dashboard['reported_users'] ?? 0;
        _blockedUsers         = dashboard['blocked_users'] ?? 0;
        _recentPayments       = dashboard['recent_payments'] ?? [];
        _latestRegistrations  = dashboard['latest_registrations'] ?? [];
        _pendingApprovals     = dashboard['pending_approvals'] ?? [];
        _recentLogs           = logs.take(8).toList();
        _unreadNotifications  = notifs.where((n) => n['is_read'] != true).length;
        _adminName            = me['name']?.toString()  ?? 'Admin';
        _adminEmail           = me['email']?.toString() ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load dashboard'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: _loading
            ? _buildLoader()
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.adminColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 16),
                          _buildQuickActions(),
                          const SizedBox(height: 20),
                          _buildSectionTitle('Overview'),
                          const SizedBox(height: 12),
                          _buildStatsGrid(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Pending Approvals'),
                          const SizedBox(height: 12),
                          _buildPendingApprovals(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Recent Payments'),
                          const SizedBox(height: 12),
                          _buildRecentPayments(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Latest Registrations'),
                          const SizedBox(height: 12),
                          _buildLatestRegistrations(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Latest Activities'),
                          const SizedBox(height: 12),
                          _buildActivityLogs(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // ── Header: Profile + Search + Notifications ────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.adminColor, Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showProfileSheet,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, $_adminName 👋',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '$_totalCustomers customers · $_totalPros professionals',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showSearchSheet,
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            tooltip: 'Search',
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NotificationScreen()));
                },
                icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                tooltip: 'Notifications',
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.amber, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.black),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProfileSheet() {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                        color: AppColors.adminColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        color: AppColors.adminColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_adminName,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        if (_adminEmail.isNotEmpty)
                          Text(_adminEmail,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF9CA3AF))),
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
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('Logout',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.error)),
                  onTap: () async {
                    Navigator.pop(context);
                    await auth.logout();
                    if (!mounted) return;
                    // ✅ FIX: pushNamedAndRemoveUntil clears the whole stack.
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Search',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search users, professionals, bookings…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _handleSearchSubmit(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminColor,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _handleSearchSubmit,
                child: const Text('Search', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSearchSubmit() {
    Navigator.pop(context);
    // NOTE: A unified cross-module global search (users + bookings +
    // payments in one query) will be wired once the User Management
    // module screens are rebuilt in a later checkpoint. For now this
    // confirms the UI is in place end-to-end.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(
          'Global search UI is ready — will connect to Users/Bookings once that module is rebuilt.')),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction('Review Approvals', Icons.fact_check_rounded, () => widget.onNavigateToTab?.call(4)),
      _QuickAction('View Bookings',    Icons.calendar_month_rounded, () => widget.onNavigateToTab?.call(5)),
      _QuickAction('Reported Users',   Icons.flag_rounded, () => widget.onNavigateToTab?.call(9)),
      _QuickAction('Analytics',        Icons.insights_rounded, () => widget.onNavigateToTab?.call(10)),
      _QuickAction('Manage Banners',   Icons.campaign_rounded, () => widget.onNavigateToTab?.call(7)),
      _QuickAction('View Logs',        Icons.history_rounded, () => widget.onNavigateToTab?.call(6)),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final a = actions[i];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: a.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a.icon, size: 16, color: AppColors.adminColor),
                    const SizedBox(width: 6),
                    Text(a.label,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151))),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Stats Grid (8 cards) ───────────────────────────────────
  Widget _buildStatsGrid() {
    final cards = [
      _StatCard(label: 'Total Users', value: '$_totalUsers',
          icon: Icons.groups_rounded, color: context.colors.primary,
          onTap: () => widget.onNavigateToTab?.call(1)),
      _StatCard(label: 'Professionals', value: '$_totalPros',
          icon: Icons.work_outline_rounded, color: const Color(0xFF7C3AED),
          onTap: () => widget.onNavigateToTab?.call(3)),
      _StatCard(label: 'Customers', value: '$_totalCustomers',
          icon: Icons.person_outline_rounded, color: const Color(0xFF0EA5E9),
          onTap: () => widget.onNavigateToTab?.call(2)),
      _StatCard(label: 'Revenue', value: 'Rs $_revenueDisplay',
          icon: Icons.payments_rounded, color: const Color(0xFF16A34A)),
      _StatCard(label: "Today's Bookings", value: '$_todayBookings',
          icon: Icons.event_available_rounded, color: context.colors.accent,
          onTap: () => widget.onNavigateToTab?.call(5)),
      _StatCard(label: 'Pending Verification', value: '$_pendingVerification',
          icon: Icons.hourglass_top_rounded, color: AppColors.warning,
          onTap: () => widget.onNavigateToTab?.call(4)),
      _StatCard(label: 'Reported Users', value: '$_reportedUsers',
          icon: Icons.flag_rounded, color: AppColors.error,
          note: _reportedUsers > 0 ? '$_reportedUsers need review' : null,
          onTap: () => widget.onNavigateToTab?.call(9)),
      _StatCard(label: 'Blocked Users', value: '$_blockedUsers',
          icon: Icons.block_rounded, color: const Color(0xFF64748B),
          onTap: () => widget.onNavigateToTab?.call(1)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (_, i) => _buildStatCard(cards[i]),
        );
      },
    );
  }

  Widget _buildStatCard(_StatCard card) {
    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: card.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(card.icon, color: card.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: card.color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(card.label,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (card.note != null) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: card.note!,
                      child: const Icon(Icons.info_outline_rounded,
                          size: 12, color: Color(0xFFCBD5E1)),
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

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: card.onTap,
        child: content,
      ),
    );
  }

  // ── Pending Approvals ──────────────────────────────────────
  Widget _buildPendingApprovals() {
    if (_pendingApprovals.isEmpty) return _emptyCard('No pending approvals', Icons.fact_check_rounded);
    return Column(
      children: _pendingApprovals.map((item) {
        final name  = item['professional_name']?.toString() ?? 'Professional';
        final title = item['title']?.toString() ?? '';
        final date  = item['created_at']?.toString() ?? '';
        return _rowCard(
          leadingIcon: Icons.photo_library_rounded,
          leadingColor: AppColors.warning,
          title: name,
          subtitle: title,
          trailing: TextButton(
            onPressed: () => widget.onNavigateToTab?.call(4),
            child: const Text('Review'),
          ),
          dateStr: date,
        );
      }).toList(),
    );
  }

  // ── Recent Payments ────────────────────────────────────────
  Widget _buildRecentPayments() {
    if (_recentPayments.isEmpty) return _emptyCard('No payments yet', Icons.payments_rounded);
    return Column(
      children: _recentPayments.map((p) {
        final name   = p['user_name']?.toString() ?? p['user_email']?.toString() ?? 'User';
        final amount = p['amount']?.toString() ?? '0';
        final curr   = p['currency']?.toString() ?? '';
        final status = p['status']?.toString() ?? '';
        final date   = p['created_at']?.toString() ?? '';

        Color statusColor;
        switch (status) {
          case 'completed': statusColor = AppColors.success; break;
          case 'failed':    statusColor = AppColors.error;   break;
          case 'refunded':  statusColor = AppColors.info;    break;
          default:          statusColor = AppColors.warning;
        }

        return _rowCard(
          leadingIcon: Icons.payment_rounded,
          leadingColor: statusColor,
          title: name,
          subtitle: '$curr $amount',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status.toUpperCase(),
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
          ),
          dateStr: date,
        );
      }).toList(),
    );
  }

  // ── Latest Registrations ───────────────────────────────────
  Widget _buildLatestRegistrations() {
    if (_latestRegistrations.isEmpty) return _emptyCard('No registrations yet', Icons.person_add_rounded);
    return Column(
      children: _latestRegistrations.map((u) {
        final name = u['name']?.toString() ?? 'User';
        final role = u['role']?.toString() ?? '';
        final date = u['created_at']?.toString() ?? '';

        Color roleColor = role == 'professional'
            ? const Color(0xFF7C3AED)
            : role == 'admin'
                ? AppColors.adminColor
                : context.colors.primary;

        return _rowCard(
          leadingIcon: Icons.person_rounded,
          leadingColor: roleColor,
          title: name,
          subtitle: u['email']?.toString() ?? '',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(role.toUpperCase(),
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: roleColor)),
          ),
          dateStr: date,
        );
      }).toList(),
    );
  }

  // ── Shared row card for the 3 list sections above ──────────
  Widget _rowCard({
    required IconData leadingIcon,
    required Color leadingColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required String dateStr,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: leadingColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(leadingIcon, size: 16, color: leadingColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                if (dateStr.isNotEmpty)
                  Text(_formatDate(dateStr),
                      style: const TextStyle(fontSize: 10, color: Color(0xFFCBD5E1))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _emptyCard(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFFD1D5DB)),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }

  // ── Activity Logs ─────────────────────────────────────────
  Widget _buildActivityLogs() {
    if (_recentLogs.isEmpty) return _emptyCard('No activity yet', Icons.history_rounded);
    return Column(
      children: _recentLogs.map((log) => _buildLogTile(log)).toList(),
    );
  }

  Widget _buildLogTile(dynamic log) {
    final action = log['action']?.toString() ?? '';
    final Color color;
    final IconData icon;

    switch (action) {
      case 'verify':
        color = context.colors.accent;
        icon  = Icons.verified_rounded;
        break;
      case 'ban':
        color = AppColors.error;
        icon  = Icons.block_rounded;
        break;
      case 'unban':
        color = AppColors.info;
        icon  = Icons.lock_open_rounded;
        break;
      case 'approve':
        color = AppColors.success;
        icon  = Icons.check_circle_outline_rounded;
        break;
      case 'reject':
        color = AppColors.warning;
        icon  = Icons.cancel_outlined;
        break;
      default:
        color = const Color(0xFF9CA3AF);
        icon  = Icons.info_outline_rounded;
    }

    final adminEmail  = log['admin_email']?.toString()       ?? 'Admin';
    final targetEmail = log['target_user_email']?.toString() ?? 'a user';
    final note        = log['note']?.toString()              ?? '';
    final createdAt   = log['created_at']?.toString()        ?? '';

    return _rowCard(
      leadingIcon: icon,
      leadingColor: color,
      title: '$adminEmail → $targetEmail',
      subtitle: note,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(action.toUpperCase(),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
      ),
      dateStr: createdAt,
    );
  }

  // ── Section Title ─────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)));
  }

  // ── Loader ────────────────────────────────────────────────
  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.adminColor, strokeWidth: 2.5),
    );
  }

  // ── Error ─────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
          const SizedBox(height: 12),
          const Text('Failed to load dashboard',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
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

// ── Data models ────────────────────────────────────────────────────────────
class _StatCard {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  final String?  note;
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
  final String        label;
  final IconData      icon;
  final VoidCallback  onTap;
  const _QuickAction(this.label, this.icon, this.onTap);
}