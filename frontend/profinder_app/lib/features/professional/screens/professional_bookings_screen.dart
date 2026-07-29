// lib/features/professional/screens/professional_bookings_screen.dart
//
// Premium Booking Management dashboard — Pending / Rescheduled / Accepted /
// Completed / Cancelled, styled to match Urban Company / Fresha / Booksy /
// Google Calendar / Calendly.
//
// IMPORTANT — backend contract is untouched:
//   • _loadBookings, _updateStatus and _confirmCancel still call the exact
//     same endpoints as before: GET/PATCH AppConstants.professionalBookings
//     with the exact same body shape ({'status': ..., 'cancel_reason': ...}).
//     No new params, no new endpoint, no serializer/model changes.
//   • Booking.STATUS_CHOICES (backend/apps/bookings/models.py) has no
//     "rescheduled" state and no field for a professional's counter-offer
//     time. So "Suggest New Time" never touches booking status — it only
//     records the proposed date/time on-device (SharedPreferences), purely
//     to group the request under the "Rescheduled" section and show it back
//     to the professional. The booking itself stays 'pending' on the
//     backend exactly as before, and every existing status transition
//     (accept/decline/complete/cancel) is completely unchanged.
//   • "Service" has no backend field on Booking either. It is read once,
//     read-only, from the professional's own profile (`category_name`,
//     already returned by the existing GET AppConstants.professionalProfile
//     call used elsewhere in this app) — since a professional's service
//     offering is the same across all of their bookings, this is accurate
//     rather than invented.
//   • "Location" has no backend field on Booking either — exactly like the
//     customer booking flow already folds it into the free-text `note`
//     field, this screen simply *parses* a leading "Location: ..." line
//     back out of that same `note` for display. Nothing is written back.
//   • "Open Chat" reuses the exact same, already-shipped messaging flow
//     used elsewhere in this app (professional_detail_screen.dart
//     `_startConversation`): POST AppConstants.conversations with
//     {'other_user_id': ...}, then push the existing ChatScreen. No new
//     endpoint, no ChatProvider/ChatScreen changes.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../subscription/widgets/promo_banner_mixin.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../chat/presentation/screens/chat_screen.dart';
import '../../chat/data/models/conversation_model.dart';

class ProfessionalBookingsScreen extends StatefulWidget {
  final bool isVisible;

  const ProfessionalBookingsScreen({super.key, this.isVisible = true});

  @override
  State<ProfessionalBookingsScreen> createState() => _ProfessionalBookingsScreenState();
}

class _ProfessionalBookingsScreenState extends State<ProfessionalBookingsScreen>
    with SingleTickerProviderStateMixin, PromoBannerMixin {
  static const _suggestedTimesPrefsKey = 'pro_booking_suggested_times_v1';

  late TabController _tabController;
  final _api = ApiService();

  List<dynamic> _bookings = [];
  bool _isLoading = true;
  bool _bannerTriggered = false; // ek hi baar fire ho
  bool _isStartingChat = false;

  String _myServiceCategory = '';
  final Map<String, Map<String, String>> _suggestedTimes = {}; // bookingId -> {date,time}

  final _tabs = ['All', 'Pending', 'Rescheduled', 'Accepted', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadAll();
    if (widget.isVisible) {
      _bannerTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showBannerForScreen('booking');
      });
    }
  }

  @override
  void didUpdateWidget(covariant ProfessionalBookingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVisible && widget.isVisible && !_bannerTriggered) {
      _bannerTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showBannerForScreen('booking');
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadBookings(), _loadServiceCategory(), _loadSuggestedTimes()]);
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(AppConstants.professionalBookings);
      if (!mounted) return;
      // ✅ FIX: backend key 'bookings' hai, 'results' nahi — isi wajah se
      // bookings list hamesha khali aati thi.
      final data = res.data is List ? res.data : (res.data['bookings'] ?? []);
      setState(() {
        _bookings = data as List;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppHelpers.showError(context, 'Could not load bookings');
    }
  }

  // Read-only peek at the professional's own service category — already
  // returned by this same, unchanged endpoint elsewhere in the app.
  Future<void> _loadServiceCategory() async {
    try {
      final res = await _api.get(AppConstants.professionalProfile);
      final data = res.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _myServiceCategory = (data['category_name'] ?? '').toString());
    } catch (_) {
      // Non-critical — cards simply omit the Service row if unavailable.
    }
  }

  Future<void> _loadSuggestedTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('${_suggestedTimesPrefsKey}_'));
      final loaded = <String, Map<String, String>>{};
      for (final k in keys) {
        final raw = prefs.getString(k);
        if (raw == null) continue;
        final parts = raw.split('|'); // "yyyy-MM-dd|h:mm a"
        if (parts.length != 2) continue;
        loaded[k.substring('${_suggestedTimesPrefsKey}_'.length)] = {'date': parts[0], 'time': parts[1]};
      }
      if (!mounted) return;
      setState(() {
        _suggestedTimes
          ..clear()
          ..addAll(loaded);
      });
    } catch (_) {
      // Ignore corrupt local cache.
    }
  }

  Future<void> _saveSuggestedTime(String bookingId, DateTime date, TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final timeStr = time.format(context);
    await prefs.setString('${_suggestedTimesPrefsKey}_$bookingId', '$dateStr|$timeStr');
    if (!mounted) return;
    setState(() => _suggestedTimes[bookingId] = {'date': dateStr, 'time': timeStr});
  }

  Future<void> _clearSuggestedTime(String bookingId) async {
    if (!_suggestedTimes.containsKey(bookingId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_suggestedTimesPrefsKey}_$bookingId');
    if (!mounted) return;
    setState(() => _suggestedTimes.remove(bookingId));
  }

  // ── Helpers ──────────────────────────────────────────────
  String _statusOf(dynamic b) => (b['status']?.toString() ?? 'pending').toLowerCase();
  bool _isSuggested(dynamic b) => _suggestedTimes.containsKey(b['id'].toString());

  // The customer booking flow folds "Location: ..." as the first line of
  // the free-text `note`. Parse it back out for display only.
  Map<String, String> _splitNote(String rawNote) {
    final lines = rawNote.split('\n');
    if (lines.isNotEmpty && lines.first.trim().toLowerCase().startsWith('location:')) {
      final location = lines.first.trim().substring('location:'.length).trim();
      final rest = lines.skip(1).join('\n').trim();
      return {'location': location, 'note': rest};
    }
    return {'location': '', 'note': rawNote.trim()};
  }

  List<dynamic> _filtered(String tab) {
    switch (tab) {
      case 'All':
        return _bookings;
      case 'Pending':
        return _bookings.where((b) => _statusOf(b) == 'pending' && !_isSuggested(b)).toList();
      case 'Rescheduled':
        return _bookings.where((b) => _statusOf(b) == 'pending' && _isSuggested(b)).toList();
      case 'Accepted':
        return _bookings.where((b) => _statusOf(b) == 'accepted').toList();
      case 'Completed':
        return _bookings.where((b) => _statusOf(b) == 'completed').toList();
      case 'Cancelled':
        return _bookings.where((b) => _statusOf(b) == 'cancelled' || _statusOf(b) == 'rejected').toList();
      default:
        return _bookings;
    }
  }

  // ── Accept / Reject / Complete / Cancel booking — unchanged endpoint ──
  Future<void> _updateStatus(dynamic booking, String newStatus, {String? reason}) async {
    try {
      final id = booking['id'];
      final body = <String, dynamic>{'status': newStatus};
      if (reason != null) body['cancel_reason'] = reason;
      await _api.patch('${AppConstants.professionalBookings}$id/', body);
      if (!mounted) return;
      await _clearSuggestedTime(id.toString());
      AppHelpers.showSuccess(context, 'Booking ${AppHelpers.capitalize(newStatus)}');
      _loadBookings();
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showError(context, 'Failed to update booking');
    }
  }

  // ── Cancel with reason dialog ───────────────────────────
  Future<void> _confirmCancel(dynamic booking) async {
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text('Cancel Booking?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this booking?',
              style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
            ),
            const SizedBox(height: 14),
            Text('Reason for cancelling (optional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. not available that day, emergency came up...',
                hintStyle: TextStyle(fontSize: 12, color: context.colors.textSecondary),
                filled: true,
                fillColor: context.colors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.divider)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Go Back', style: TextStyle(color: context.colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel It', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _updateStatus(booking, 'cancelled', reason: reasonCtrl.text.trim());
  }

  // ── Suggest New Time — local-only, backend status stays 'pending' ──
  Future<void> _suggestNewTime(dynamic booking) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;

    await _saveSuggestedTime(booking['id'].toString(), date, time);
    if (!mounted) return;
    AppHelpers.showSuccess(context, 'New time suggested — moved to Rescheduled');

    final openChat = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Let the customer know?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Text(
          'Open chat to share the new time — ${DateFormat('EEE, MMM d').format(date)} at ${time.format(context)}.',
          style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Later')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.professionalColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Chat'),
          ),
        ],
      ),
    );
    if (openChat == true) await _openChat(booking);
  }

  // ── Open Chat — reuses the exact existing messaging flow ───
  Future<void> _openChat(dynamic booking) async {
    if (_isStartingChat) return;
    setState(() => _isStartingChat = true);
    try {
      final customerId = booking['customer'];
      final customerName = (booking['customer_name'] ?? booking['customer'] ?? 'Customer').toString();
      final results = await Future.wait([
        _api.post(AppConstants.conversations, {'other_user_id': customerId}),
        _api.get(AppConstants.me),
      ]);
      if (!mounted) return;
      final data = results[0].data as Map<String, dynamic>;
      final myId = int.parse((results[1].data as Map<String, dynamic>)['id'].toString());

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: data['id'] is int ? data['id'] as int : int.parse(data['id'].toString()),
            currentUserId: myId,
            otherUserName: data['other_user_name']?.toString() ?? customerName,
            otherUserPhoto: data['other_user_photo']?.toString(),
            conversationSnapshot: ConversationModel.fromJson(data),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showError(context, 'Could not open chat');
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  // ── Status presentation ─────────────────────────────────
  Color _statusColor(dynamic b) {
    if (_isSuggested(b)) return AppColors.info;
    switch (_statusOf(b)) {
      case 'accepted':
        return context.colors.accent;
      case 'completed':
        return context.colors.primary;
      case 'rejected':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning; // pending
    }
  }

  IconData _statusIcon(dynamic b) {
    if (_isSuggested(b)) return Icons.update_rounded;
    switch (_statusOf(b)) {
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'cancelled':
        return Icons.event_busy_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  String _statusLabel(dynamic b) {
    if (_isSuggested(b)) return 'Rescheduled';
    return AppHelpers.capitalize(_statusOf(b));
  }

  // ── Booking detail sheet ────────────────────────────────
  void _showBookingDetail(dynamic b) {
    final status = _statusOf(b);
    final isPending = status == 'pending';
    final isAccepted = status == 'accepted';
    final isCancellable = isPending || isAccepted;
    final customerName = (b['customer_name'] ?? b['customer'] ?? 'Customer').toString();
    final date = b['date']?.toString() ?? 'Not set';
    final time = b['time']?.toString() ?? '';
    final split = _splitNote(b['note']?.toString() ?? '');
    final location = split['location'] ?? '';
    final notes = split['note'] ?? '';
    final cancelReason = b['cancel_reason']?.toString() ?? '';
    final cancelledBy = b['cancelled_by']?.toString() ?? '';
    final suggested = _suggestedTimes[b['id'].toString()];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Booking Details',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.colors.textPrimary),
                    ),
                  ),
                  _statusChip(b, large: true),
                ],
              ),
              const SizedBox(height: 18),
              _detailRow(Icons.person_outline_rounded, 'Customer', customerName),
              if (_myServiceCategory.isNotEmpty) _detailRow(Icons.design_services_rounded, 'Service', _myServiceCategory),
              _detailRow(Icons.calendar_today_outlined, 'Date', date),
              if (time.isNotEmpty) _detailRow(Icons.access_time_rounded, 'Time', time),
              _detailRow(Icons.location_on_outlined, 'Location', location.isNotEmpty ? location : 'Not specified'),
              if (notes.isNotEmpty) _detailRow(Icons.notes_rounded, 'Notes', notes),
              if (suggested != null)
                _detailRow(Icons.update_rounded, 'Suggested Time', '${suggested['date']} · ${suggested['time']}'),
              if (status == 'cancelled' && cancelReason.isNotEmpty)
                _detailRow(
                  Icons.info_outline_rounded,
                  cancelledBy == 'customer' ? 'Cancelled by customer' : 'Cancelled by you',
                  cancelReason,
                ),
              const SizedBox(height: 18),
              if (isPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateStatus(b, 'rejected');
                        },
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Decline'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateStatus(b, 'accepted');
                        },
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _suggestNewTime(b);
                    },
                    icon: const Icon(Icons.update_rounded, size: 16),
                    label: const Text('Suggest New Time'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: BorderSide(color: AppColors.info.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else if (isAccepted) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateStatus(b, 'completed');
                    },
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark as Completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openChat(b);
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Open Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.professionalColor,
                    side: BorderSide(color: AppColors.professionalColor.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (isCancellable) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmCancel(b);
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancel Booking'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.textSecondary,
                      side: BorderSide(color: context.colors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.colors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(label, style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(dynamic b, {bool large = false}) {
    final color = _statusColor(b);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 9, vertical: large ? 7 : 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(large ? 10 : 8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(b), size: large ? 14 : 11, color: color),
          SizedBox(width: large ? 6 : 4),
          Text(
            _statusLabel(b),
            style: TextStyle(fontSize: large ? 12.5 : 10.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text(
          'Booking Management',
          style: TextStyle(
            fontSize: isTablet ? 19 : 17,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.professionalColor,
          unselectedLabelColor: context.colors.textSecondary,
          indicatorColor: AppColors.professionalColor,
          indicatorWeight: 2.6,
          labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
          tabs: _tabs.map((t) {
            final count = _filtered(t).length;
            return Tab(text: count > 0 ? '$t ($count)' : t);
          }).toList(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.professionalColor, strokeWidth: 3))
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: AppColors.professionalColor,
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  final list = _filtered(tab);
                  if (list.isEmpty) {
                    return _emptyState(tab);
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(isTablet ? 20 : 14),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _buildBookingCard(list[i], isTablet),
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _emptyState(String tab) {
    IconData icon;
    switch (tab) {
      case 'Rescheduled':
        icon = Icons.update_rounded;
        break;
      case 'Accepted':
        icon = Icons.event_available_rounded;
        break;
      case 'Completed':
        icon = Icons.task_alt_rounded;
        break;
      case 'Cancelled':
        icon = Icons.event_busy_rounded;
        break;
      default:
        icon = Icons.calendar_today_outlined;
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
        Icon(icon, size: 48, color: context.colors.textDisabled),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'No ${tab == 'All' ? '' : tab.toLowerCase()} bookings',
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ── Booking card ─────────────────────────────────────────
  Widget _buildBookingCard(dynamic b, bool isTablet) {
    final status = _statusOf(b);
    final customerName = (b['customer_name'] ?? b['customer'] ?? 'Customer').toString();
    final date = b['date']?.toString() ?? '';
    final time = b['time']?.toString() ?? '';
    final split = _splitNote(b['note']?.toString() ?? '');
    final location = split['location'] ?? '';
    final isPending = status == 'pending';
    final isAccepted = status == 'accepted';
    final isCompleted = status == 'completed';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showBookingDetail(b),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(isTablet ? 18 : 15),
          decoration: BoxDecoration(
            color: isCompleted ? context.colors.background : context.colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.12) : Colors.grey.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: isTablet ? 24 : 21,
                    backgroundColor: context.colors.primaryLight,
                    child: Text(
                      AppHelpers.getInitials(customerName),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isCompleted ? context.colors.textSecondary : context.colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isTablet ? 15.5 : 14.5,
                            fontWeight: FontWeight.w700,
                            color: isCompleted ? context.colors.textSecondary : context.colors.textPrimary,
                          ),
                        ),
                        if (_myServiceCategory.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _myServiceCategory,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: isTablet ? 12 : 11, color: context.colors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _statusChip(b),
                ],
              ),
              SizedBox(height: isTablet ? 14 : 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 12, vertical: isTablet ? 12 : 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _infoChip(
                            Icons.calendar_today_outlined,
                            date.isNotEmpty ? date : 'Not set',
                            isTablet,
                          ),
                        ),
                        if (time.isNotEmpty) Expanded(child: _infoChip(Icons.access_time_rounded, time, isTablet)),
                      ],
                    ),
                    if (location.isNotEmpty) ...[
                      SizedBox(height: isTablet ? 8 : 6),
                      _infoChip(Icons.location_on_outlined, location, isTablet, fullWidth: true),
                    ],
                  ],
                ),
              ),

              // ── Actions — Pending: Accept / Decline primary, Suggest New
              // Time + Open Chat secondary. Accepted: complete + chat.
              if (isPending) ...[
                SizedBox(height: isTablet ? 14 : 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStatus(b, 'rejected'),
                        icon: const Icon(Icons.close_rounded, size: 15),
                        label: const Text('Decline', style: TextStyle(fontSize: 12.5)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error.withOpacity(0.35)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(b, 'accepted'),
                        icon: const Icon(Icons.check_rounded, size: 15),
                        label: const Text('Accept', style: TextStyle(fontSize: 12.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 8 : 6),
                Row(
                  children: [
                    Expanded(
                      child: _secondaryActionButton(
                        icon: Icons.update_rounded,
                        label: 'Suggest Time',
                        color: AppColors.info,
                        onTap: () => _suggestNewTime(b),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _secondaryActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Open Chat',
                        color: AppColors.professionalColor,
                        onTap: () => _openChat(b),
                      ),
                    ),
                  ],
                ),
              ] else if (isAccepted) ...[
                SizedBox(height: isTablet ? 14 : 12),
                Row(
                  children: [
                    Expanded(
                      child: _secondaryActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Open Chat',
                        color: AppColors.professionalColor,
                        onTap: () => _openChat(b),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(b, 'completed'),
                        icon: const Icon(Icons.done_all_rounded, size: 15),
                        label: const Text('Mark Completed', style: TextStyle(fontSize: 12.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, bool isTablet, {bool fullWidth = false}) {
    return Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: context.colors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isTablet ? 12.5 : 11.5,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _secondaryActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}