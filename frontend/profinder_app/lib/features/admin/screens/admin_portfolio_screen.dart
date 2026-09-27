// lib/features/admin/screens/admin_portfolio_screen.dart
//
// Screen 4 of 6 — Portfolio Approval
// Features: list portfolio items by status, approve, reject with note
//
// Backend endpoints (UNCHANGED):
//   GET   /api/profiles/admin/portfolio/?status=pending   → pending items
//   GET   /api/profiles/admin/portfolio/?status=approved  → approved items
//   GET   /api/profiles/admin/portfolio/?status=rejected  → rejected items
//   PATCH /api/profiles/admin/portfolio/<id>/             → approve / reject
//     body: { "status": "approved" }
//     body: { "status": "rejected", "admin_note": "reason" }
//
// Changes reflect to professional:
//   approve → portfolio item visible to customers
//   reject  → portfolio item rejected with reason

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';

/// Responsive breakpoints shared across the screen.
class _Breakpoints {
  static const double tablet = 700;
  static const double desktop = 1100;
}

class AdminPortfolioScreen extends StatefulWidget {
  const AdminPortfolioScreen({super.key});

  @override
  State<AdminPortfolioScreen> createState() => _AdminPortfolioScreenState();
}

class _AdminPortfolioScreenState extends State<AdminPortfolioScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();

  bool _loading = true;
  String? _error;
  String _activeStatus = 'pending'; // pending | approved | rejected
  List<dynamic> _items = [];

  /// Drives the staggered entrance animation for list items whenever a new
  /// page of items is shown. Single-shot per load for low-end performance.
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

  // ── Load ──────────────────────────────────────────────────
  /// Fetches the portfolio list for the currently active status tab.
  /// Behavior identical to the original implementation.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api.get(
          '/profiles/admin/portfolio/?status=$_activeStatus');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = r.data is List ? List<dynamic>.from(r.data) : [];
      });
      _entranceController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load portfolio';
      });
    }
  }

  // ── Approve ───────────────────────────────────────────────
  /// Confirms and approves a single portfolio item. Removes it from the
  /// current list on success — behavior unchanged.
  Future<void> _approve(dynamic item) async {
    final title = item['title']?.toString() ?? 'this item';
    final confirmed = await _confirmDialog(
      title: 'Approve Portfolio?',
      message: '"$title" will be visible to all customers.',
      confirmLabel: 'Approve',
      confirmColor: context.colors.accent,
      icon: Icons.check_circle_outline_rounded,
    );
    if (!confirmed) return;

    try {
      await _api.patch(
        '/profiles/admin/portfolio/${item['id']}/',
        {'status': 'approved'},
      );
      // Remove from list immediately so the queue reflects the change.
      setState(() => _items.removeWhere((i) => i['id'] == item['id']));
      _showSnack('"$title" approved', context.colors.accent,
          icon: Icons.check_circle_outline_rounded);
    } catch (e) {
      _showSnack('Action failed. Try again.', AppColors.error,
          icon: Icons.error_outline_rounded);
    }
  }

  // ── Reject ────────────────────────────────────────────────
  /// Asks for a rejection reason (optional) and rejects the item.
  /// Behavior unchanged.
  Future<void> _reject(dynamic item) async {
    final title = item['title']?.toString() ?? 'this item';

    // Ask for rejection reason (optional — Skip returns empty string).
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
      _showSnack('"$title" rejected', AppColors.error,
          icon: Icons.cancel_outlined);
    } catch (e) {
      _showSnack('Action failed. Try again.', AppColors.error,
          icon: Icons.error_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildStatusTabs(),
            Expanded(
              // AnimatedSwitcher uses distinct keys per state so the fade
              // transition plays whenever loading/error/empty/list changes.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _loading
                    ? _buildLoader()
                    : _error != null
                        ? _buildError()
                        : _items.isEmpty
                            ? _buildEmpty()
                            : _buildList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  /// Title bar with a live count subtitle so admins see the size of the
  /// current queue at a glance.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.adminColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_library_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Portfolio Approval',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          // Count caption updates reactively with each tab change/load.
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 2),
            child: Text(
              '${_items.length} $_activeStatus',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Manual refresh button; dims while a load is in flight to signal
        // pending state without blocking the action.
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _loading ? 0.5 : 1.0,
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Status Tabs ───────────────────────────────────────────
  /// Segmented control for switching between pending / approved / rejected.
  /// Uses `AnimatedContainer` for a lightweight selection transition and
  /// enforces a min 48px touch target on each tab.
  Widget _buildStatusTabs() {
    final tabs = [
      ('pending', 'Pending', AppColors.warning, Icons.hourglass_top_rounded),
      ('approved', 'Approved', context.colors.accent,
          Icons.check_circle_outline_rounded),
      ('rejected', 'Rejected', AppColors.error, Icons.cancel_outlined),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: tabs.map((t) {
          final isActive = _activeStatus == t.$1;
          return Expanded(
            child: Semantics(
              button: true,
              selected: isActive,
              label: '${t.$2} tab',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _HoverLift(
                  borderRadius: BorderRadius.circular(12),
                  hoverScale: 1.015,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() => _activeStatus = t.$1);
                        _load();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? t.$3
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? t.$3
                                : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: t.$3.withOpacity(0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              t.$4,
                              size: 16,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                t.$2,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── List (responsive) ─────────────────────────────────────
  /// 1 column on mobile, 2 on tablet, 3 on wide desktop. Card height is
  /// adjusted per breakpoint so images + text + actions always fit without
  /// clipping, regardless of screen size.
  Widget _buildList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= _Breakpoints.tablet;
        final isDesktop = width >= _Breakpoints.desktop;

        final hPad = isDesktop ? 24.0 : (isTablet ? 20.0 : 14.0);
        final columns = isDesktop ? 3 : (isTablet ? 2 : 1);
        final maxWidth = isDesktop ? 1500.0 : 1200.0;

        // Card height tuned per breakpoint so the image header, text block,
        // professional row, and action buttons all fit without overflow.
        final cardExtent = isDesktop
            ? 500.0
            : (isTablet ? 500.0 : 460.0);

        return RefreshIndicator(
          onRefresh: _load,
          color: AppColors.adminColor,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: GridView.builder(
                // Distinct key per status replays the entrance animation
                // when the user switches tabs.
                key: ValueKey('grid_$_activeStatus'),
                padding: EdgeInsets.fromLTRB(hPad, hPad, hPad, hPad + 24),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: cardExtent,
                ),
                itemCount: _items.length,
                itemBuilder: (_, i) => _buildAnimatedCard(_items[i], i),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Wraps each card in a staggered fade + slide entrance driven by the
  /// shared `_entranceController`. Delay is capped so late items don't
  /// feel sluggish on long lists.
  Widget _buildAnimatedCard(dynamic item, int index) {
    // Cap the stagger so item #50 doesn't wait seconds to appear.
    final delayIndex = index.clamp(0, 8);
    final start = (delayIndex * 0.06).clamp(0.0, 0.48);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(anim),
        child: _buildPortfolioCard(item),
      ),
    );
  }

  // ── Portfolio Card ────────────────────────────────────────
  /// Displays a single portfolio item: image (with gradient + status pill),
  /// title/description, professional info, and admin-note block for
  /// rejected items. Approve / Reject buttons are shown on pending only.
  Widget _buildPortfolioCard(dynamic item) {
    final title = item['title']?.toString() ?? 'Untitled';
    final desc = item['description']?.toString() ?? '';
    final imageUrl = item['image_url']?.toString() ?? '';
    final proName = item['professional_name']?.toString() ?? 'Professional';
    final proEmail = item['professional_email']?.toString() ?? '';
    final adminNote = item['admin_note']?.toString() ?? '';
    final isPending = _activeStatus == 'pending';

    final statusColor = _activeStatus == 'approved'
        ? context.colors.accent
        : _activeStatus == 'rejected'
            ? AppColors.error
            : AppColors.warning;

    return _HoverLift(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Portfolio Image ────────────────────────
            if (imageUrl.isNotEmpty)
              _buildImageHeader(imageUrl, statusColor)
            else
              _buildPlaceholderHeader(statusColor),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title + Description ────────────
                    const Text(
                      '',
                      style: TextStyle(height: 0),
                    ).runtimeType == Text
                        ? const SizedBox.shrink()
                        : const SizedBox.shrink(),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // ── Professional Info ──────────────
                    _buildProfessionalRow(proName, proEmail),

                    // ── Admin Note (rejected items) ────
                    if (adminNote.isNotEmpty &&
                        _activeStatus == 'rejected') ...[
                      const SizedBox(height: 10),
                      _buildAdminNote(adminNote),
                    ],

                    const Spacer(),

                    // ── Approve / Reject (pending only) ─
                    if (isPending) ...[
                      const SizedBox(height: 12),
                      _buildActionButtons(item),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Image header with a soft bottom gradient so the status badge stays
  /// readable against bright photos.
  Widget _buildImageHeader(String imageUrl, Color statusColor) {
    return Stack(
      children: [
        SizedBox(
          height: 170,
          width: double.infinity,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 170,
              color: const Color(0xFFF3F4F6),
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFFD1D5DB),
                  size: 48,
                ),
              ),
            ),
            loadingBuilder: (_, child, prog) {
              if (prog == null) return child;
              return Container(
                height: 170,
                color: const Color(0xFFF3F4F6),
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      value: prog.expectedTotalBytes != null
                          ? prog.cumulativeBytesLoaded /
                              prog.expectedTotalBytes!
                          : null,
                      strokeWidth: 2.4,
                      color: AppColors.adminColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Bottom gradient veil for badge legibility.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.30),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: _statusPill(_activeStatus, statusColor),
        ),
      ],
    );
  }

  /// Fallback header used when the item has no image attached.
  Widget _buildPlaceholderHeader(Color statusColor) {
    return Stack(
      children: [
        Container(
          height: 96,
          width: double.infinity,
          color: context.colors.primaryLight,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              color: context.colors.primary.withOpacity(0.35),
              size: 42,
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: _statusPill(_activeStatus, statusColor),
        ),
      ],
    );
  }

  /// Small status pill shown on the item image.
  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Professional identity block (avatar initials + name/email).
  Widget _buildProfessionalRow(String proName, String proEmail) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFEDE9FE),
            child: Text(
              AppHelpers.getInitials(proName),
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (proEmail.isNotEmpty)
                  const SizedBox.shrink() == const SizedBox.shrink()
                      ? Text(
                          proEmail,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : const SizedBox.shrink(),
              ],
            ),
          ),
          const Icon(
            Icons.person_outline_rounded,
            size: 16,
            color: Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }

  /// Admin-note block shown for rejected items so reviewers can see why
  /// the item was rejected.
  Widget _buildAdminNote(String adminNote) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded,
                size: 14, color: AppColors.error),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              adminNote,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
                height: 1.45,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Approve / Reject action row. Wrapped in hover-lift so desktop/web
  /// users get subtle pointer feedback; handlers are unchanged.
  Widget _buildActionButtons(dynamic item) {
    return Row(
      children: [
        Expanded(
          child: _HoverLift(
            borderRadius: BorderRadius.circular(12),
            hoverScale: 1.02,
            child: ElevatedButton.icon(
              onPressed: () => _approve(item),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
              label: const Text(
                'Approve',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HoverLift(
            borderRadius: BorderRadius.circular(12),
            hoverScale: 1.02,
            child: OutlinedButton.icon(
              onPressed: () => _reject(item),
              icon: const Icon(Icons.cancel_outlined, size: 17),
              label: const Text(
                'Reject',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Empty State ───────────────────────────────────────────
  /// Icon-in-circle empty state. Uses status-specific copy + icon so the
  /// state is immediately recognizable from a glance.
  Widget _buildEmpty() {
    final label = switch (_activeStatus) {
      'pending' => 'No pending portfolios',
      'approved' => 'No approved portfolios yet',
      _ => 'No rejected portfolios',
    };
    final icon = switch (_activeStatus) {
      'pending' => Icons.celebration_rounded,
      'approved' => Icons.check_circle_outline_rounded,
      _ => Icons.cancel_outlined,
    };
    final accent = switch (_activeStatus) {
      'pending' => AppColors.warning,
      'approved' => context.colors.accent,
      _ => AppColors.error,
    };

    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: accent),
            ),
            const SizedBox(height: 18),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
                letterSpacing: -0.1,
              ),
            ),
            if (_activeStatus == 'pending') ...[
              const SizedBox(height: 6),
              const Text(
                'All portfolios reviewed!',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      key: ValueKey('loader'),
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          color: AppColors.adminColor,
          strokeWidth: 2.6,
        ),
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
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.09),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load portfolios',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 12),
                minimumSize: const Size(0, 46),
                elevation: 0,
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

  // ── Dialogs ───────────────────────────────────────────────
  /// Generic confirmation dialog. Returns true only when the user taps the
  /// confirm action — unchanged behavior.
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: confirmColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: confirmColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Rejection-reason dialog. Returns an empty string for Skip, the note
  /// text otherwise — behavior unchanged.
  Future<String?> _noteDialog(String title) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_outlined,
                  color: AppColors.error, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 13),
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Write reason (optional)…',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.error, width: 1.4),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text(
              'Reject',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Floating snackbar with an optional leading icon and brand color
  /// matching the action result. Behavior unchanged — only presentation.
  void _showSnack(String msg, Color color, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Reusable UI primitives ────────────────────────────────────────────────

/// Adds a subtle scale on hover (pointer devices only). Touch devices never
/// fire [MouseRegion] enter/exit, so this is a no-op there with zero cost.
class _HoverLift extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double hoverScale;

  const _HoverLift({
    required this.child,
    required this.borderRadius,
    this.hoverScale = 1.01,
  });

  @override
  State<_HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<_HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
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