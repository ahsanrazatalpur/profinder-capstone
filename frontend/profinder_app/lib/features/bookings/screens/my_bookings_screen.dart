// lib/features/bookings/screens/my_bookings_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/booking_service.dart';
import 'write_review_screen.dart';
import '../../subscription/widgets/promo_banner_mixin.dart';
import '../../../core/theme/theme_context_ext.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin,
         PromoBannerMixin {
  late TabController _tabController;
  final _service = BookingService();

  List<dynamic> _bookings = [];
  bool          _isLoading = true;

  final List<String> _tabs = ['All', 'Pending', 'Accepted', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadBookings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBannerForScreen('booking'); // Banner — booking trigger
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final result = await _service.getMyBookings();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _bookings  = result['data'] is List ? result['data'] : [];
    });
  }

  List<dynamic> _filtered(String status) {
    if (status == 'All') return _bookings;
    return _bookings.where((b) =>
        b['status']?.toString().toLowerCase() == status.toLowerCase()
    ).toList();
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'accepted':  return context.colors.accent;
      case 'rejected':  return AppColors.error;
      case 'completed': return context.colors.primary;
      case 'cancelled': return context.colors.textSecondary;
      default:          return const Color(0xFFF59E0B); // pending
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':  return Icons.check_circle_outline;
      case 'rejected':  return Icons.cancel_outlined;
      case 'completed': return Icons.task_alt_outlined;
      case 'cancelled': return Icons.block_outlined;
      default:          return Icons.schedule_outlined;
    }
  }

  // ── Raw "2026-07-29" / "12:30:00" → readable strings ─────────────
  String _prettyDate(String raw) {
    if (raw.isEmpty) return '—';
    try {
      return AppHelpers.formatDate(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _weekday(String raw) {
    if (raw.isEmpty) return '';
    try {
      final d = DateTime.parse(raw);
      const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
      return days[d.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  String _prettyTime(String raw) {
    if (raw.isEmpty) return '—';
    try {
      final parts = raw.split(':');
      final d = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return AppHelpers.formatTime(d);
    } catch (_) {
      return raw;
    }
  }

  String _prettyBookedAt(String raw) {
    if (raw.isEmpty) return '';
    try {
      return AppHelpers.formatDateTime(DateTime.parse(raw).toLocal());
    } catch (_) {
      return '';
    }
  }

  List<String> _noteLines(String note) {
    return note
        .split(RegExp(r'[\n•\-]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation:       0,
        toolbarHeight:   56,
        title: Text('My Bookings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                letterSpacing: -0.3, color: context.colors.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller:          _tabController,
            labelColor:          context.colors.primary,
            unselectedLabelColor: context.colors.textSecondary,
            indicatorColor:      context.colors.primary,
            indicatorWeight:     2.6,
            isScrollable:        true,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            labelStyle:   const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
            tabs:        _tabs.map((t) => Tab(height: 48, text: t)).toList(),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: context.colors.primary))
          : RefreshIndicator(
              color:     context.colors.primary,
              onRefresh: _loadBookings,
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  final list = _filtered(tab);
                  if (list.isEmpty) return _buildEmpty(tab);
                  return ListView.builder(
                    padding:     const EdgeInsets.fromLTRB(16, 20, 16, 28),
                    itemCount:   list.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _buildCard(list[i]),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildEmpty(String tab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: context.colors.textDisabled),
          const SizedBox(height: 16),
          Text(
            tab == 'All' ? 'No bookings yet' : 'No $tab bookings',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text('Book a professional from home screen',
              style: TextStyle(fontSize: 14, color: context.colors.textSecondary)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  CARD
  // ══════════════════════════════════════════════════════════════════
  Widget _buildCard(dynamic booking) {
    final proName    = booking['professional_name']?.toString() ?? 'Professional';
    final profession = booking['profession']?.toString() ?? '';
    final rating      = double.tryParse(booking['professional_rating']?.toString() ?? '') ?? 0.0;
    final reviewCount = int.tryParse(booking['professional_reviews']?.toString() ?? '') ?? 0;
    final location    = booking['location']?.toString() ?? '';
    final verified    = booking['professional_verified'] == true;

    final status   = booking['status']?.toString() ?? 'pending';
    final date     = booking['date']?.toString() ?? '';
    final time     = booking['time']?.toString() ?? '';
    final note     = booking['note']?.toString() ?? '';
    final bookedAt = booking['created_at']?.toString() ?? '';
    final cancelReason = booking['cancel_reason']?.toString() ?? '';
    final cancelledBy  = booking['cancelled_by']?.toString() ?? '';

    final sColor = _statusColor(context, status);
    final sIcon  = _statusIcon(status);
    final isCancelledOrRejected = status == 'cancelled' || status == 'rejected';

    return Container(
      decoration: BoxDecoration(
        color:        context.colors.surface,
        borderRadius: BorderRadius.circular(22),
        border:       Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset:     const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius:          28,
                  backgroundColor: context.colors.primaryLight,
                  child: Text(
                    AppHelpers.getInitials(proName),
                    style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(proName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2, color: context.colors.textPrimary)),
                          ),
                          if (verified) ...[
                            const SizedBox(width: 5),
                            Icon(Icons.verified_rounded, size: 17, color: context.colors.primary),
                          ],
                        ],
                      ),
                      if (profession.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(profession,
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500,
                                color: context.colors.textSecondary)),
                      ],
                      if (rating > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(rating.toStringAsFixed(1),
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
                                    color: context.colors.textPrimary)),
                            if (reviewCount > 0) ...[
                              const SizedBox(width: 4),
                              Text('($reviewCount reviews)',
                                  style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary)),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(status, sColor, sIcon),
              ],
            ),

            const SizedBox(height: 20),
            _thinDivider(context),
            const SizedBox(height: 20),

            // ── Booking Details ────────────────────────────────────
            _sectionLabel('BOOKING DETAILS'),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _infoTile(Icons.calendar_today_outlined, 'DATE',
                      _prettyDate(date), sub: _weekday(date)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoTile(Icons.access_time_rounded, 'TIME', _prettyTime(time)),
                ),
              ],
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 16),
              _infoTile(Icons.location_on_outlined, 'LOCATION', location),
            ],

            // ── Service ─────────────────────────────────────────────
            if (profession.isNotEmpty) ...[
              const SizedBox(height: 20),
              _thinDivider(context),
              const SizedBox(height: 20),
              _sectionLabel('SERVICE'),
              const SizedBox(height: 14),
              _infoTile(Icons.build_outlined, 'CATEGORY', profession),
            ],

            // ── Notes ────────────────────────────────────────────────
            if (note.isNotEmpty) ...[
              const SizedBox(height: 20),
              _thinDivider(context),
              const SizedBox(height: 20),
              _sectionLabel('CUSTOMER NOTES'),
              const SizedBox(height: 12),
              _notesCard(_noteLines(note)),
            ],

            // ── Cancellation info ──────────────────────────────────
            if (isCancelledOrRejected && cancelReason.isNotEmpty) ...[
              const SizedBox(height: 20),
              _thinDivider(context),
              const SizedBox(height: 20),
              _infoTile(
                Icons.info_outline_rounded,
                cancelledBy == 'professional' ? 'CANCELLED BY PROFESSIONAL' : 'CANCELLED BY YOU',
                cancelReason,
                accent: AppColors.error,
              ),
            ],

            // ── Timeline ────────────────────────────────────────────
            const SizedBox(height: 20),
            _thinDivider(context),
            const SizedBox(height: 20),
            _sectionLabel('BOOKING TIMELINE'),
            const SizedBox(height: 16),
            isCancelledOrRejected
                ? _cancelledTimeline(status, sColor)
                : _stepperTimeline(status, bookedAt, sColor),

            // ── Action button ───────────────────────────────────────
            if (status == 'pending' || status == 'accepted' || status == 'completed') ...[
              const SizedBox(height: 20),
              _thinDivider(context),
              const SizedBox(height: 20),
              _actionButton(booking, status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _thinDivider(BuildContext context) => Divider(height: 1, thickness: 1, color: context.colors.divider);

  Widget _sectionLabel(String text) {
    return Text(text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            letterSpacing: 0.9, color: context.colors.textSecondary));
  }

  Widget _statusBadge(String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border:       Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            AppHelpers.capitalize(status),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {String? sub, Color? accent}) {
    final iconColor = accent ?? context.colors.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width:  36,
          height: 36,
          decoration: BoxDecoration(
            color:        iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 0.7, color: context.colors.textSecondary)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600,
                      height: 1.4, color: context.colors.textPrimary)),
              if (sub != null && sub.isNotEmpty)
                Text(sub,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500,
                        color: context.colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _notesCard(List<String> lines) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        context.colors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: context.colors.textSecondary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(line,
                      style: TextStyle(fontSize: 14.5, height: 1.5,
                          color: context.colors.textPrimary)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Booked → Accepted → Completed stepper, filled up to current status
  Widget _stepperTimeline(String status, String bookedAt, Color sColor) {
    const stages = ['Booked', 'Accepted', 'Completed'];
    int current;
    switch (status) {
      case 'accepted':  current = 1; break;
      case 'completed': current = 2; break;
      default:          current = 0; // pending
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftStage = i ~/ 2;
          final filled = leftStage < current;
          return Expanded(
            child: Container(
              height:  2,
              margin:  const EdgeInsets.only(top: 11),
              color:   filled ? sColor : context.colors.divider,
            ),
          );
        }
        final stageIndex = i ~/ 2;
        final isDone   = stageIndex < current;
        final isActive = stageIndex == current;
        final dotColor = (isDone || isActive) ? sColor : context.colors.divider;

        return Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                color:  isDone ? dotColor : Colors.transparent,
                border: Border.all(color: dotColor, width: 2),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : (isActive ? Center(child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                    )) : null),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 66,
              child: Text(stages[stageIndex],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: (isDone || isActive) ? context.colors.textPrimary : context.colors.textSecondary)),
            ),
            if (stageIndex == 0 && bookedAt.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 90,
                  child: Text(_prettyBookedAt(bookedAt),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: context.colors.textSecondary)),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _cancelledTimeline(String status, Color sColor) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: sColor.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(status == 'rejected' ? Icons.cancel_outlined : Icons.block_outlined,
              size: 18, color: sColor),
        ),
        const SizedBox(width: 12),
        Text(status == 'rejected' ? 'Booking was rejected' : 'Booking was cancelled',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
      ],
    );
  }

  Widget _actionButton(dynamic booking, String status) {
    if (status == 'pending') {
      return SizedBox(
        width:  double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: () => _confirmCancel((booking['id'] as num).toInt()),
          icon:  const Icon(Icons.cancel_outlined, size: 19, color: AppColors.error),
          label: const Text('Cancel Booking',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.error)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error, width: 1.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    // accepted || completed → Write a Review
    // ⚠️ TODO: remove `status == 'accepted' ||` once payment/completion flow is live.
    return SizedBox(
      width:  double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          final proId   = int.parse(booking['professional'].toString());
          final proName = booking['professional_name']?.toString() ?? 'Professional';
          final bookId  = (booking['id'] as num).toInt();
          final result  = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WriteReviewScreen(
                professionalId:   proId,
                professionalName: proName,
                bookingId:        bookId,
              ),
            ),
          );
          if (result == true) _loadBookings();
        },
        icon:  const Icon(Icons.star_rounded, size: 19, color: Colors.white),
        label: const Text('Write a Review',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ── Cancel with Reason Dialog ──────────────────────────────
  Future<void> _confirmCancel(int bookingId) async {
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text('Cancel Booking?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this booking?',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),
            const Text('Reason for cancelling (optional)',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              maxLines:   3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText:  'e.g. schedule changed, no longer needed...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                filled:    true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:   const BorderSide(
                        color: AppColors.error, width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go Back',
                style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel It',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final reason = reasonCtrl.text.trim();
    final result = await _service.cancelBooking(bookingId, reason: reason);
    if (!mounted) return;

    if (result['success']) {
      AppHelpers.showSuccess(context, 'Booking cancelled');
      _loadBookings();
    } else {
      AppHelpers.showError(context, result['message'] ?? 'Could not cancel, please try again');
    }
  }
}