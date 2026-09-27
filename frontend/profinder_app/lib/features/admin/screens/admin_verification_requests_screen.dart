// lib/features/admin/screens/admin_verification_requests_screen.dart
//
// Verification Requests — professionals awaiting document verification,
// shown FIFO (oldest signup first) so nobody's request is skipped.
//
// Backend endpoints (UNCHANGED):
//   GET  /api/admin-panel/verification-requests/
//     → [{ user_id, name, email, category, experience_years, bio,
//          cnic_url, license_url, submitted_at }, ...]
//   POST /api/admin-panel/verification-requests/<user_id>/action/
//     Body: { "action": "approve" | "reject", "reason": "optional text" }

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';

/// Responsive breakpoints used by the list container and grid.
class _Breakpoints {
  static const double tablet = 700;
  static const double desktop = 1100;
}

class AdminVerificationRequestsScreen extends StatefulWidget {
  const AdminVerificationRequestsScreen({super.key});

  @override
  State<AdminVerificationRequestsScreen> createState() =>
      _AdminVerificationRequestsScreenState();
}

class _AdminVerificationRequestsScreenState
    extends State<AdminVerificationRequestsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];

  /// Tracks per-user in-flight actions so their buttons can show a spinner
  /// and be disabled until the request completes. Behavior unchanged.
  final Set<int> _processingIds = {};

  /// Drives a staggered entrance for cards whenever the list reloads.
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
    _searchCtrl.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────
  /// Fetches pending verification requests (FIFO) and applies the current
  /// search query. Behavior unchanged.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api.get('/admin-panel/verification-requests/');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _all = r.data is List ? List<dynamic>.from(r.data) : [];
      });
      _applySearch();
      _entranceController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load verification requests';
      });
    }
  }

  /// Filters `_all` by name / email / category. Same field coverage and
  /// case-insensitive matching as before.
  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List<dynamic>.from(_all)
          : _all.where((r) {
              return (r['name'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(q) ||
                  (r['email'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(q) ||
                  (r['category'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(q);
            }).toList();
    });
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearch(hPad),
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
                        ? _buildError()
                        : _buildList(maxWidth, hPad, isDesktop),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── List (responsive) ─────────────────────────────────────
  /// Single-column list on mobile, 2-column grid on desktop. Empty state is
  /// rendered inside the same `RefreshIndicator` so pull-to-refresh works.
  Widget _buildList(double maxWidth, double hPad, bool isDesktop) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.adminColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _filtered.isEmpty
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
                        mainAxisExtent: 400,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) =>
                          _buildAnimatedCard(_filtered[i], i),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 20),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) =>
                          _buildAnimatedCard(_filtered[i], i),
                    ),
        ),
      ),
    );
  }

  /// Wraps each request card in a staggered fade + slide entrance. Delay is
  /// capped so long lists don't feel sluggish.
  Widget _buildAnimatedCard(dynamic req, int index) {
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
        child: _requestCard(req, index),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  /// Gradient header with icon, title, and a live pending count.
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.adminColor, Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.28)),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verification Requests',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _all.isEmpty
                            ? Colors.greenAccent
                            : Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_all.length} pending · oldest first',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────
  /// Search field. Includes a clear (✕) affordance only when text exists —
  /// it just clears the controller and re-applies the filter.
  Widget _buildSearch(double hPad) {
    final hasText = _searchCtrl.text.isNotEmpty;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 14),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => _applySearch(),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search by name, email, or category…',
          hintStyle:
              const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: Color(0xFF9CA3AF)),
          suffixIcon: hasText
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: const Color(0xFF9CA3AF),
                  onPressed: () {
                    _searchCtrl.clear();
                    _applySearch();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.adminColor, width: 1.4),
          ),
        ),
      ),
    );
  }

  // ── Request Card ──────────────────────────────────────────
  /// Renders a single verification request: identity, info chips, bio,
  /// document thumbnails, and Approve / Reject actions.
  Widget _requestCard(dynamic req, int index) {
    final userId = req['user_id'] as int;
    final name = (req['name'] ?? 'Unknown').toString();
    final email = (req['email'] ?? '').toString();
    final category = (req['category'] ?? 'Uncategorized').toString();
    final years = req['experience_years'];
    final bio = (req['bio'] ?? '').toString();
    final cnicUrl = req['cnic_url']?.toString();
    final licenseUrl = req['license_url']?.toString();
    final submittedAt = _formatDate(req['submitted_at']);
    final isProcessing = _processingIds.contains(userId);

    return _HoverLift(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Identity row ───────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        AppColors.professionalColor.withOpacity(0.12),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.professionalColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (index == 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFFF59E0B)
                                          .withOpacity(0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.schedule_rounded,
                                        size: 9,
                                        color: Color(0xFFF59E0B)),
                                    SizedBox(width: 3),
                                    Text('OLDEST',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFF59E0B),
                                            letterSpacing: 0.3)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                              fontSize: 11.5, color: Color(0xFF9CA3AF)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Info chips ─────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoChip(Icons.category_outlined, category),
                  if (years != null)
                    _infoChip(Icons.work_history_outlined, '$years yrs exp'),
                  if (submittedAt.isNotEmpty)
                    _infoChip(Icons.calendar_today_outlined, submittedAt),
                ],
              ),

              // ── Bio ────────────────────────────
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                  ),
                  child: Text(
                    bio,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF374151),
                        height: 1.45),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              // ── Document thumbnails ────────────
              if (cnicUrl != null || licenseUrl != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (cnicUrl != null)
                      Expanded(child: _docThumb('CNIC', cnicUrl)),
                    if (cnicUrl != null && licenseUrl != null)
                      const SizedBox(width: 10),
                    if (licenseUrl != null)
                      Expanded(child: _docThumb('License', licenseUrl)),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // ── Actions ────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _HoverLift(
                      borderRadius: BorderRadius.circular(10),
                      hoverScale: 1.02,
                      child: OutlinedButton.icon(
                        onPressed: isProcessing
                            ? null
                            : () => _rejectDialog(userId, name),
                        icon: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.error),
                        label: const Text(
                          'Reject',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.error, width: 1.4),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 46),
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
                      child: ElevatedButton.icon(
                        onPressed: isProcessing
                            ? null
                            : () => _confirmApprove(userId, name),
                        icon: isProcessing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white),
                        label: const Text(
                          'Approve',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.accent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Metadata chip: icon + label. Restyled for the new card design.
  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6B7280)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Tappable document thumbnail with a label chip. Opens the in-app viewer.
  Widget _docThumb(String label, String url) {
    return GestureDetector(
      onTap: () => _openDocViewer(label, url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 12, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                color: const Color(0xFFF3F4F6),
                child: const Center(
                  child: Icon(Icons.insert_drive_file_outlined,
                      color: Color(0xFFD1D5DB), size: 28),
                ),
              ),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      height: 100,
                      color: const Color(0xFFF3F4F6),
                      child: const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full-screen document viewer. Behavior unchanged — same `Dialog`, same
  /// `Image.network`, same error fallback.
  void _openDocViewer(String label, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.adminColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_outlined,
                            size: 18, color: AppColors.adminColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(30),
                        child: Icon(Icons.broken_image_outlined,
                            size: 48, color: Color(0xFFD1D5DB)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Approve / Reject flow ────────────────────────────────
  /// Confirmation dialog for approving a request. Behavior unchanged.
  void _confirmApprove(int userId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
                color: context.colors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.verified_rounded,
                  size: 18, color: context.colors.accent),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Approve verification?',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          '$name will be marked as a verified professional.',
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.accent,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _submitAction(userId, 'approve', null);
            },
            child: const Text('Approve',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Rejection reason dialog. Behavior unchanged — same controller, same
  /// `_submitAction` call, same Cancel semantics.
  void _rejectDialog(int userId, String name) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
              child: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.error),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reject $name\'s request?',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This reason will be sent to the professional so they can resubmit.',
              style: TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. CNIC image is blurry, please re-upload…',
                hintStyle: const TextStyle(
                    fontSize: 12.5, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _submitAction(userId, 'reject', reasonCtrl.text.trim());
            },
            child: const Text('Reject',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Submits an approve / reject action and removes the request from the
  /// local list on success. Behavior unchanged.
  Future<void> _submitAction(
      int userId, String action, String? reason) async {
    setState(() => _processingIds.add(userId));
    try {
      await _api.post('/admin-panel/verification-requests/$userId/action/', {
        'action': action,
        if (reason != null) 'reason': reason,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve'
                ? 'Professional verified successfully.'
                : 'Request rejected and professional notified.',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor:
              action == 'approve' ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _processingIds.remove(userId);
        _all.removeWhere((r) => r['user_id'] == userId);
      });
      _applySearch();
    } catch (e) {
      if (!mounted) return;
      setState(() => _processingIds.remove(userId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${action == 'approve' ? 'approve' : 'reject'} request.',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Empty / Error states ────────────────────────────────────
  /// Empty state with icon-in-circle treatment. Celebration emoji replaced
  /// with a proper Flutter icon; copy otherwise unchanged.
  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded,
                  size: 42, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text(
              'No pending verification requests',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 6),
            const Text(
              'All caught up on verifications.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
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
              'Failed to load verification requests',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151)),
              textAlign: TextAlign.center,
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
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  /// Formats an ISO timestamp into `MMM d, yyyy`. Returns an empty string
  /// when the input can't be parsed. Behavior unchanged.
  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec',
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return '';
    }
  }
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