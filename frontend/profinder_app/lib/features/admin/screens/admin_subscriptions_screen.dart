// lib/features/admin/screens/admin_subscriptions_screen.dart
//
// Business Management → Subscriptions (per-user subscription records —
// distinct from the Plan-catalog CRUD, which lives under Promo/Plans).
//
// Backend endpoints (UNCHANGED):
//   GET   /api/admin-panel/subscriptions/?status=active
//   PATCH /api/admin-panel/subscriptions/<id>/   { action: cancel|extend, days }

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../shared/widgets/universal_app_bar.dart';

/// Responsive breakpoints used by the list container and grid.
class _Breakpoints {
  static const double tablet = 700;
  static const double desktop = 1100;
}

class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _subs = [];
  String _statusFilter = 'active';

  /// Status filter definitions — keys match the backend contract.
  static const _statuses = [
    ('active', 'Active', Color(0xFF16A34A)),
    ('cancelled', 'Cancelled', Color(0xFF64748B)),
    ('expired', 'Expired', Color(0xFFEF4444)),
  ];

  /// Drives a staggered entrance animation for cards whenever the list
  /// reloads. Kept single-shot per load for low-end performance.
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  /// Fetches subscriptions for the active status filter. Behavior unchanged.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api.get(
          '/admin-panel/subscriptions/?status=$_statusFilter');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _subs = r.data is List ? List<dynamic>.from(r.data) : [];
      });
      _entranceController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load subscriptions';
      });
    }
  }

  /// Confirms and cancels a subscription. Behavior unchanged.
  Future<void> _cancel(dynamic sub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.cancel_rounded,
                  size: 18, color: AppColors.error),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Cancel Subscription?',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Cancel ${sub['user_name']}\'s ${sub['plan_name']} subscription?',
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              foregroundColor: const Color(0xFF6B7280),
            ),
            child: const Text('No',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text(
              'Cancel Subscription',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.patch(
          '/admin-panel/subscriptions/${sub['id']}/', {'action': 'cancel'});
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel.')),
      );
    }
  }

  /// Extends a subscription by 30 days. Behavior unchanged.
  Future<void> _extend(dynamic sub) async {
    try {
      await _api.patch(
        '/admin-panel/subscriptions/${sub['id']}/',
        {'action': 'extend', 'days': 30},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Extended by 30 days.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to extend.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _Breakpoints.desktop;
    final isTablet = width >= _Breakpoints.tablet;
    final hPad = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
    final maxWidth = isDesktop ? 1200.0 : (isTablet ? 900.0 : 720.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: UniversalAppBar(
        title: 'Subscriptions',
        subtitle: '${_subs.length} ${_statusFilter} subscription${_subs.length == 1 ? '' : 's'}',
        icon: Icons.workspace_premium_rounded,
        showBack: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildStatusFilter(hPad),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _loading
                    ? const Center(
                        key: ValueKey('loader'),
                        child: CircularProgressIndicator(
                            color: AppColors.adminColor, strokeWidth: 2.5),
                      )
                    : _error != null
                        ? _errorState()
                        : _buildList(maxWidth, hPad, isDesktop),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── List (responsive) ─────────────────────────────────────
  /// Single-column list on mobile/tablet, 2-column grid on desktop. Empty
  /// state renders inside the same `RefreshIndicator` so pull-to-refresh
  /// still works.
  Widget _buildList(double maxWidth, double hPad, bool isDesktop) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.adminColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _subs.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [_emptyState()],
                )
              : isDesktop
                  ? GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 260,
                      ),
                      itemCount: _subs.length,
                      itemBuilder: (_, i) =>
                          _buildAnimatedCard(_subs[i], i),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 20),
                      itemCount: _subs.length,
                      itemBuilder: (_, i) =>
                          _buildAnimatedCard(_subs[i], i),
                    ),
        ),
      ),
    );
  }

  /// Wraps each card in a staggered fade + slide entrance. Delay is capped
  /// so long lists don't feel sluggish.
  Widget _buildAnimatedCard(dynamic sub, int index) {
    final delayIndex = index.clamp(0, 8);
    final start = (delayIndex * 0.05).clamp(0.0, 0.4);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(anim),
        child: _subCard(sub),
      ),
    );
  }

  // ── Status filter chips ───────────────────────────────────
  /// Horizontally scrollable filter chips. Active chip uses its status
  /// color with a leading dot. Behavior unchanged.
  Widget _buildStatusFilter(double hPad) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 14),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _statuses.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => _buildStatusChip(_statuses[i]),
        ),
      ),
    );
  }

  Widget _buildStatusChip((String, String, Color) status) {
    final (key, label, color) = status;
    final isActive = _statusFilter == key;
    return Semantics(
      button: true,
      selected: isActive,
      label: '$label filter',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            setState(() => _statusFilter = key);
            _load();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isActive
                  ? color.withOpacity(0.12)
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isActive ? color : Colors.transparent,
                width: 1.4,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? color : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Subscription Card ─────────────────────────────────────
  /// Displays a single subscription: user identity, status pill, plan +
  /// price block, renewal/expiry row, and (for active) action buttons.
  Widget _subCard(dynamic s) {
    final status = s['status']?.toString() ?? 'active';
    final statusColor = _statuses
        .firstWhere((e) => e.$1 == status, orElse: () => _statuses[0])
        .$3;
    final isActive = status == 'active';

    final userName = s['user_name']?.toString() ?? '';
    final userEmail = s['user_email']?.toString() ?? '';
    final planName = s['plan_name']?.toString() ?? '';
    final price = s['price']?.toString() ?? '';
    final billing = s['billing']?.toString() ?? '';
    final endDate = s['end_date']?.toString() ?? '—';

    return _HoverLift(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Identity row ───────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.adminColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty
                          ? userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.adminColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        userEmail,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: 0.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Plan + price ───────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.adminColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        size: 14, color: AppColors.adminColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planName,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Rs $price / $billing',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Renewal date row ───────────────────
            Row(
              children: [
                Icon(
                  isActive
                      ? Icons.event_available_rounded
                      : Icons.event_busy_rounded,
                  size: 13,
                  color: isActive
                      ? AppColors.success
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? 'Renews: $endDate' : 'Ended: $endDate',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            // ── Actions (active only) ──────────────
            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _HoverLift(
                      borderRadius: BorderRadius.circular(10),
                      hoverScale: 1.02,
                      child: OutlinedButton.icon(
                        onPressed: () => _extend(s),
                        icon: const Icon(Icons.add_rounded, size: 15),
                        label: const Text(
                          'Extend 30d',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.adminColor,
                          side: const BorderSide(
                              color: AppColors.adminColor, width: 1.3),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HoverLift(
                      borderRadius: BorderRadius.circular(10),
                      hoverScale: 1.02,
                      child: OutlinedButton.icon(
                        onPressed: () => _cancel(s),
                        icon: const Icon(Icons.cancel_outlined, size: 15),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(
                              color: AppColors.error, width: 1.3),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Empty / Error states ────────────────────────────────────
  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.adminColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_outlined,
                    size: 42, color: AppColors.adminColor),
              ),
              const SizedBox(height: 16),
              const Text(
                'No subscriptions found',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                'Nothing in $_statusFilter.',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      );

  Widget _errorState() => Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    size: 40, color: AppColors.error),
              ),
              const SizedBox(height: 14),
              const Text(
                'Failed to load subscriptions',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151)),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Reusable UI primitives ────────────────────────────────────────────────

/// Subtle scale-on-hover for pointer devices. No-op on touch because
/// [MouseRegion] enter/exit never fire from touch input.
class _HoverLift extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double hoverScale;

  const _HoverLift({
    required this.child,
    required this.borderRadius,
    this.hoverScale = 1.012,
  });

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
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
      child: AnimatedScale(
        scale: _hovered ? widget.hoverScale : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}