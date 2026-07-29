// lib/features/bookings/screens/booking_screen.dart
//
// Premium multi-step booking flow — Service Summary → Select Date →
// Select Time → Location → Additional Notes → Booking Summary → Confirm.
// Styled to match Urban Company / Fresha / Booksy / Google Calendar / Calendly.
//
// IMPORTANT — backend contract is untouched:
//   • BookingService.createBooking(...) still sends exactly the same four
//     fields the backend Booking model supports: professional, date, time,
//     note. No new params, no new endpoint, no serializer/model changes.
//   • Booking.STATUS_CHOICES has no per-slot "taken" concept and there is
//     no available-slots endpoint, so "available" time slots are derived
//     from data already fetched for this screen: the professional's own
//     working_hours_start / working_hours_end (already exposed by
//     ProfessionalProfileSerializer and already merged into the
//     `professional` map before this screen is pushed — see
//     professional_detail_screen.dart `_buildBookBar`). Slots outside that
//     window, and any slot already in the past for today, are shown
//     disabled rather than hidden.
//   • The "Location" step has no backend field to write to either — the
//     Booking model only has `note`. Exactly like the availability
//     screens, the chosen location is folded as a small prefix into the
//     same free-text `note` the backend already accepts, so the API and
//     model stay 100% unchanged while the professional still sees it.
//   • booking_limit_reached handling, the success dialog navigation, and
//     PromoBannerMixin usage are all preserved exactly as before.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/booking_service.dart';
import '../../subscription/widgets/booking_limit_dialog.dart';
import '../../subscription/widgets/promo_banner_mixin.dart';

enum _LocationChoice { professional, custom }

const List<String> _kStepTitles = [
  'Service Summary',
  'Select Date',
  'Select Time',
  'Location',
  'Additional Notes',
  'Booking Summary',
];

// Short labels shown under each stepper circle.
const List<String> _kStepShortLabels = ['Service', 'Date', 'Time', 'Location', 'Details', 'Summary'];

const List<IconData> _kStepIcons = [
  Icons.person_outline_rounded,
  Icons.calendar_today_rounded,
  Icons.access_time_rounded,
  Icons.location_on_outlined,
  Icons.description_outlined,
  Icons.fact_check_rounded,
];

const List<String> _kStepDescriptions = [
  "Review the professional's details before you continue.",
  'Choose a date that works best for your appointment.',
  'Pick an available time slot for your visit.',
  'Let the professional know where to provide the service.',
  'Add any details that help the professional prepare.',
  'Review everything carefully before confirming your booking.',
];

const List<String> _kWeekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> professional;
  const BookingScreen({super.key, required this.professional});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with PromoBannerMixin {
  final _noteController = TextEditingController();
  final _customLocationController = TextEditingController();
  final _service = BookingService();

  int _currentStep = 0;
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _selectedSlot;
  _LocationChoice _locationChoice = _LocationChoice.professional;
  late DateTime _visibleMonth;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _maxDate => _today.add(const Duration(days: 60));

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(_today.year, _today.month, 1);
    // Booking page pe banner dikhao — 3s delay taake page load ho jaye pehle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showBannerForScreen('booking', delaySeconds: 3);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _customLocationController.dispose();
    super.dispose();
  }

  // ── Business logic — unchanged from the original screen ────────────────
  String _convertTime(String slot) {
    final parts = slot.split(' ');
    final time = parts[0];
    final period = parts[1];
    final hm = time.split(':');
    int hour = int.parse(hm[0]);
    final min = hm[1];
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:$min:00';
  }

  // Folds the (new) Location step into the existing free-text `note` field
  // — the backend Booking model has nowhere else to put it.
  String _buildCombinedNote() {
    final buffer = StringBuffer();
    final location = _locationChoice == _LocationChoice.custom
        ? _customLocationController.text.trim()
        : _professionalLocationLabel();
    if (location.isNotEmpty) {
      buffer.writeln('Location: $location');
    }
    final note = _noteController.text.trim();
    if (note.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(note);
    }
    return buffer.toString().trim();
  }

  String _professionalLocationLabel() {
    final pro = widget.professional;
    final area = (pro['area'] ?? '').toString().trim();
    final city = (pro['city'] ?? '').toString().trim();
    if (area.isNotEmpty && city.isNotEmpty) return '$area, $city';
    if (city.isNotEmpty) return city;
    if (area.isNotEmpty) return area;
    return "Professional's registered location";
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null) {
      AppHelpers.showError(context, 'Please select a date');
      return;
    }
    if (_selectedSlot == null) {
      AppHelpers.showError(context, 'Please select a time slot');
      return;
    }

    setState(() => _isLoading = true);

    final rawId = widget.professional['user_id'] ?? widget.professional['id'];
    final professionalUserId = int.parse(rawId.toString());

    final result = await _service.createBooking(
      professionalId: professionalUserId,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      time: _convertTime(_selectedSlot!),
      note: _buildCombinedNote(),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccessDialog();
      return;
    }

    // ── Booking limit reached → dialog dikhao ──────────────────────────
    if (result['error_type'] == 'booking_limit_reached') {
      BookingLimitDialog.show(
        context,
        limit: result['limit'] ?? 5,
        usedThisMonth: result['used_this_month'] ?? 0,
        subscriptionEnd: result['subscription_end'],
        userRole: 'professional',
      );
      return;
    }

    // ── General error ────────────────────────────────────────────────
    AppHelpers.showError(context, result['message'] ?? 'Booking failed');
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: context.colors.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: context.colors.accentLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, size: 38, color: context.colors.accent),
              ),
              const SizedBox(height: 16),
              Text(
                'Booking Sent',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Request sent to ${widget.professional['name']}. You will be notified once they respond.',
                style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  Navigator.pushNamed(context, '/bookings');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View My Bookings', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: Text('Back to Home', style: TextStyle(color: context.colors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Time slot generation — derived from the professional's own hours ──
  TimeOfDay? _parseHHmm(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  List<TimeOfDay> _generateSlots() {
    final startStr = (widget.professional['working_hours_start'] ?? '09:00').toString();
    final endStr = (widget.professional['working_hours_end'] ?? '18:00').toString();
    final start = _parseHHmm(startStr) ?? const TimeOfDay(hour: 9, minute: 0);
    final end = _parseHHmm(endStr) ?? const TimeOfDay(hour: 18, minute: 0);

    final slots = <TimeOfDay>[];
    int cur = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    while (cur < endMinutes) {
      slots.add(TimeOfDay(hour: cur ~/ 60, minute: cur % 60));
      cur += 30;
    }
    return slots;
  }

  String _slotLabel(TimeOfDay t) {
    final d = DateTime(2020, 1, 1, t.hour, t.minute);
    return DateFormat('hh:mm a').format(d);
  }

  bool _isSlotPast(TimeOfDay t) {
    if (_selectedDate == null) return false;
    final now = DateTime.now();
    final isToday = _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;
    if (!isToday) return false;
    final slotMinutes = t.hour * 60 + t.minute;
    final nowMinutes = now.hour * 60 + now.minute;
    return slotMinutes <= nowMinutes;
  }

  // ── Step navigation ──────────────────────────────────────────────────
  bool _canProceed(int step) {
    switch (step) {
      case 1:
        return _selectedDate != null;
      case 2:
        return _selectedSlot != null;
      default:
        return true;
    }
  }

  void _goToStep(int step) {
    if (step < 0 || step > 5) return;
    setState(() => _currentStep = step);
  }

  void _onBackPressed() {
    if (_currentStep == 0) {
      Navigator.pop(context);
    } else {
      _goToStep(_currentStep - 1);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = width > 600;
    final padding = isTablet ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.colors.textPrimary),
          onPressed: _onBackPressed,
        ),
        title: Text(
          'Book Appointment',
          style: TextStyle(
            fontSize: isTablet ? 19 : 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: context.colors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildProgressHeader(isDark, isTablet, padding),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: SingleChildScrollView(
                key: ValueKey(_currentStep),
                padding: EdgeInsets.fromLTRB(padding, 24, padding, 32),
                child: _buildStepContent(isDark, isTablet),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavBar(isTablet),
    );
  }

  // ── Booking header — stepper + hero heading ──────────────────────────
  Widget _buildProgressHeader(bool isDark, bool isTablet, double padding) {
    return Container(
      color: context.colors.surface,
      padding: EdgeInsets.fromLTRB(padding, isTablet ? 20 : 16, padding, isTablet ? 24 : 20),
      child: Column(
        children: [
          _buildStepper(isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: _buildHeroHeading(isDark, isTablet, key: ValueKey(_currentStep)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(bool isTablet) {
    final circleSize = isTablet ? 40.0 : 34.0;
    final count = _kStepShortLabels.length;

    return SizedBox(
      height: isTablet ? 70 : 62,
      child: Stack(
        children: [
          Positioned(
            top: circleSize / 2 - 1.5,
            left: circleSize / 2,
            right: circleSize / 2,
            child: Row(
              children: List.generate(count - 1, (i) {
                final completed = i < _currentStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: completed ? context.colors.accent : context.colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Row(
            children: List.generate(count, (i) => Expanded(child: _stepperItem(i, circleSize, isTablet))),
          ),
        ],
      ),
    );
  }

  Widget _stepperItem(int index, double circleSize, bool isTablet) {
    final completed = index < _currentStep;
    final current = index == _currentStep;

    Color circleColor;
    Widget inner;
    if (completed) {
      circleColor = context.colors.accent;
      inner = Icon(Icons.check_rounded, size: circleSize * 0.52, color: Colors.white);
    } else if (current) {
      circleColor = context.colors.primary;
      inner = Text(
        '${index + 1}',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: circleSize * 0.4),
      );
    } else {
      circleColor = context.colors.surface;
      inner = Text(
        '${index + 1}',
        style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.w700, fontSize: circleSize * 0.4),
      );
    }

    return GestureDetector(
      // Only completed steps are jump-to-able — this still only calls the
      // existing _goToStep(...), never skips ahead of validated steps.
      onTap: completed ? () => _goToStep(index) : null,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: (!completed && !current) ? Border.all(color: context.colors.divider, width: 1.6) : null,
              boxShadow: current
                  ? [BoxShadow(color: context.colors.primary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))]
                  : null,
            ),
            alignment: Alignment.center,
            child: inner,
          ),
          const SizedBox(height: 7),
          Text(
            _kStepShortLabels[index],
            style: TextStyle(
              fontSize: isTablet ? 12 : 11,
              fontWeight: current ? FontWeight.w700 : FontWeight.w500,
              color: current ? context.colors.primary : context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeading(bool isDark, bool isTablet, {Key? key}) {
    return Column(
      key: key,
      children: [
        Container(
          width: isTablet ? 68 : 58,
          height: isTablet ? 68 : 58,
          decoration: BoxDecoration(
            color: context.colors.primary.withOpacity(isDark ? 0.18 : 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(_kStepIcons[_currentStep], size: isTablet ? 32 : 27, color: context.colors.primary),
        ),
        SizedBox(height: isTablet ? 16 : 14),
        Text(
          _kStepTitles[_currentStep],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 27 : 23,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        SizedBox(height: isTablet ? 8 : 6),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 56 : 24),
          child: Text(
            _kStepDescriptions[_currentStep],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 15 : 13.5,
              color: context.colors.textSecondary,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // Universal security/trust banner — appended to the bottom of every
  // step's content. Purely presentational, no data of any kind is sent
  // anywhere; it just reiterates existing app behaviour (booking requests
  // already go straight to the professional as before).
  Widget _buildSecurityBanner(bool isDark, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 17),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: isTablet ? 22 : 20, color: context.colors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your information is safe and secure',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'We only share your booking details with the professional you choose.',
                  style: TextStyle(fontSize: isTablet ? 13 : 12, color: context.colors.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step content router — appends the universal security banner ────
  Widget _buildStepContent(bool isDark, bool isTablet) {
    Widget content;
    switch (_currentStep) {
      case 0:
        content = _buildServiceSummaryStep(isDark, isTablet);
        break;
      case 1:
        content = _buildDateStep(isDark, isTablet);
        break;
      case 2:
        content = _buildTimeStep(isDark, isTablet);
        break;
      case 3:
        content = _buildLocationStep(isDark, isTablet);
        break;
      case 4:
        content = _buildNotesStep(isDark, isTablet);
        break;
      default:
        content = _buildSummaryStep(isDark, isTablet);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        content,
        SizedBox(height: isTablet ? 20 : 16),
        _buildSecurityBanner(isDark, isTablet),
      ],
    );
  }

  Widget _cardShell({required Widget child, required bool isDark, required bool isTablet}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.12) : Colors.grey.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Shared supporting-content helpers ───────────────────────────────
  Widget _sectionLabel(String text, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: isTablet ? 13 : 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }

  Widget _tipCard({required IconData icon, required String text, required bool isDark, required bool isTablet}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 17),
      decoration: BoxDecoration(
        color: context.colors.primary.withOpacity(isDark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isTablet ? 22 : 20, color: context.colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isTablet ? 14 : 13,
                fontWeight: FontWeight.w500,
                color: context.colors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyCard({
    required String title,
    required List<String> points,
    required bool isDark,
    required bool isTablet,
  }) {
    return _cardShell(
      isDark: isDark,
      isTablet: isTablet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: isTablet ? 20 : 18, color: context.colors.textSecondary),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14.5,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 14),
          ...points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(Icons.check_circle_rounded, size: 15, color: context.colors.accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 13,
                          color: context.colors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // Running "so far" summary — shown on steps after the professional/date/
  // time have started being chosen, purely presentational (reads the same
  // state already used elsewhere on this screen).
  Widget _miniProgressCard(bool isDark, bool isTablet) {
    final pro = widget.professional;
    final name = (pro['name'] ?? 'Professional').toString();
    final chips = <Widget>[];

    chips.add(_miniChip(Icons.person_outline_rounded, name, isTablet));
    if (_selectedDate != null) {
      chips.add(_miniChip(Icons.calendar_today_rounded, DateFormat('MMM d').format(_selectedDate!), isTablet));
    }
    if (_selectedSlot != null) {
      chips.add(_miniChip(Icons.access_time_rounded, _selectedSlot!, isTablet));
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 17),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your booking so far',
            style: TextStyle(
              fontSize: isTablet ? 13 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 10),
          Wrap(spacing: 10, runSpacing: 10, children: chips),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 15 : 13, vertical: isTablet ? 10 : 9),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: context.colors.primary),
          const SizedBox(width: 7),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isTablet ? 13.5 : 12.5,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 0: Service Summary ─────────────────────────────────────────
  Widget _buildServiceSummaryStep(bool isDark, bool isTablet) {
    final pro = widget.professional;
    final name = (pro['name'] ?? 'Professional').toString();
    final rate = pro['hourly_rate'] ?? 0;
    final category = (pro['category_name'] ?? '').toString();
    final isVerified = pro['is_verified'] == true;
    final rating = double.tryParse(pro['average_rating']?.toString() ?? '');
    final startStr = (pro['working_hours_start'] ?? '09:00').toString();
    final endStr = (pro['working_hours_end'] ?? '18:00').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardShell(
          isDark: isDark,
          isTablet: isTablet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: isTablet ? 34 : 30,
                    backgroundColor: context.colors.primaryLight,
                    backgroundImage: (pro['photo_url'] != null && pro['photo_url'].toString().isNotEmpty)
                        ? NetworkImage(pro['photo_url'].toString())
                        : null,
                    child: (pro['photo_url'] == null || pro['photo_url'].toString().isEmpty)
                        ? Text(
                            AppHelpers.getInitials(name),
                            style: TextStyle(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: isTablet ? 17 : 15,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isTablet ? 19.5 : 18,
                                  fontWeight: FontWeight.w800,
                                  color: context.colors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified_rounded, color: context.colors.accent, size: 18),
                            ],
                          ],
                        ),
                        if (category.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: isTablet ? 14.5 : 13.5,
                                color: context.colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (rating != null && rating > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 17, color: AppColors.badgeTopRated),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 18 : 14),
              Divider(color: context.colors.divider.withOpacity(0.6), height: 1),
              SizedBox(height: isTablet ? 16 : 12),
              _summaryInfoRow(Icons.payments_rounded, 'Hourly rate', '\$$rate/hr', isTablet),
              const SizedBox(height: 10),
              _summaryInfoRow(Icons.schedule_rounded, 'Working hours', '$startStr – $endStr', isTablet),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _sectionLabel('Why book here', isTablet),
        Row(
          children: [
            Expanded(child: _trustBadge(Icons.chat_bubble_outline_rounded, 'Direct chat', isDark, isTablet)),
            const SizedBox(width: 10),
            Expanded(child: _trustBadge(Icons.event_available_rounded, 'Flexible timing', isDark, isTablet)),
            const SizedBox(width: 10),
            Expanded(child: _trustBadge(Icons.cancel_schedule_send_rounded, 'Free to cancel', isDark, isTablet)),
          ],
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _tipCard(
          icon: Icons.lightbulb_outline_rounded,
          text: 'Continue through each step to pick a date, time and location — you can review everything before confirming.',
          isDark: isDark,
          isTablet: isTablet,
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _policyCard(
          title: 'Good to know',
          points: const [
            'Sending a request is free and only takes a minute.',
            "You'll be notified as soon as the professional responds.",
            'You can cancel at no cost while your request is still pending.',
          ],
          isDark: isDark,
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _trustBadge(IconData icon, String label, bool isDark, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12, horizontal: 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: isTablet ? 20 : 18, color: context.colors.primary),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 12 : 11,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryInfoRow(IconData icon, String label, String value, bool isTablet) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: isTablet ? 19 : 17, color: context.colors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: isTablet ? 14 : 13, color: context.colors.textSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 15.5 : 14.5,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── Step 1: Select Date ─────────────────────────────────────────────
  List<DateTime> _gridDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final startOffset = (first.weekday + 6) % 7;
    final gridStart = first.subtract(Duration(days: startOffset));
    return List.generate(42, (i) => gridStart.add(Duration(days: i)));
  }

  Widget _buildDateStep(bool isDark, bool isTablet) {
    final days = _gridDays(_visibleMonth);
    final canGoPrev = DateTime(_visibleMonth.year, _visibleMonth.month, 1)
        .isAfter(DateTime(_today.year, _today.month, 1));
    final canGoNext = DateTime(_visibleMonth.year, _visibleMonth.month, 1)
        .isBefore(DateTime(_maxDate.year, _maxDate.month, 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardShell(
          isDark: isDark,
          isTablet: isTablet,
          child: Column(
            children: [
              Row(
                children: [
                  _navButton(Icons.chevron_left_rounded, canGoPrev, () {
                    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1));
                  }),
                  Expanded(
                    child: Center(
                      child: Text(
                        DateFormat('MMMM yyyy').format(_visibleMonth),
                        style: TextStyle(
                          fontSize: isTablet ? 17 : 15.5,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  _navButton(Icons.chevron_right_rounded, canGoNext, () {
                    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1));
                  }),
                ],
              ),
              SizedBox(height: isTablet ? 14 : 10),
              Row(
                children: _kWeekdayShort
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 6),
              ...List.generate(6, (row) {
                return Row(
                  children: List.generate(7, (col) {
                    final day = days[row * 7 + col];
                    return Expanded(child: _buildDateCell(day, isDark, isTablet));
                  }),
                );
              }),
              SizedBox(height: isTablet ? 14 : 10),
              Divider(color: context.colors.divider.withOpacity(0.6), height: 1),
              SizedBox(height: isTablet ? 12 : 10),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _calendarLegendItem(context.colors.primary, 'Selected', isTablet),
                  _calendarLegendItem(Colors.transparent, 'Today', isTablet, outline: context.colors.primary),
                  _calendarLegendItem(
                    context.colors.textSecondary.withOpacity(0.25),
                    'Unavailable',
                    isTablet,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _miniProgressCard(isDark, isTablet),
        SizedBox(height: isTablet ? 20 : 16),
        _tipCard(
          icon: Icons.event_available_rounded,
          text: 'You can book any date up to 60 days in advance. Past dates and dates beyond that window are disabled.',
          isDark: isDark,
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _calendarLegendItem(Color fill, String label, bool isTablet, {Color? outline}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: outline != null ? Border.all(color: outline, width: 1.6) : null,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(fontSize: isTablet ? 12.5 : 11.5, color: context.colors.textSecondary),
        ),
      ],
    );
  }

  Widget _navButton(IconData icon, bool enabled, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 24,
            color: enabled ? context.colors.textSecondary : context.colors.textSecondary.withOpacity(0.25),
          ),
        ),
      ),
    );
  }

  Widget _buildDateCell(DateTime day, bool isDark, bool isTablet) {
    final inMonth = day.month == _visibleMonth.month;
    final isToday = day == _today;
    final isSelected = _selectedDate != null &&
        day.year == _selectedDate!.year &&
        day.month == _selectedDate!.month &&
        day.day == _selectedDate!.day;
    final isPast = day.isBefore(_today);
    final isTooFar = day.isAfter(_maxDate);
    final disabled = isPast || isTooFar || !inMonth;

    Color bg = Colors.transparent;
    Color fg = context.colors.textPrimary;
    Border? border;

    if (disabled) {
      fg = context.colors.textSecondary.withOpacity(0.28);
    }
    if (isSelected) {
      bg = context.colors.primary;
      fg = Colors.white;
    } else if (isToday && !disabled) {
      border = Border.all(color: context.colors.primary, width: 1.4);
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: disabled
                ? null
                : () {
                    setState(() {
                      _selectedDate = DateTime(day.year, day.month, day.day);
                      _selectedSlot = null;
                    });
                    Future.delayed(const Duration(milliseconds: 180), () {
                      if (mounted) _goToStep(2);
                    });
                  },
            child: Container(
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13), border: border),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14,
                  fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 2: Select Time ─────────────────────────────────────────────
  Widget _buildTimeStep(bool isDark, bool isTablet) {
    if (_selectedDate == null) {
      return _emptyStateCard(isDark, isTablet, 'Please select a date first', Icons.event_busy_rounded);
    }

    final slots = _generateSlots();
    if (slots.isEmpty) {
      return _emptyStateCard(
        isDark,
        isTablet,
        'This professional has no working hours configured yet',
        Icons.schedule_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 17, color: context.colors.primary),
              const SizedBox(width: 10),
              Text(
                DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!),
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        _cardShell(
          isDark: isDark,
          isTablet: isTablet,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: slots.map((t) => _timeChip(t, isDark, isTablet)).toList(),
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _miniProgressCard(isDark, isTablet),
        SizedBox(height: isTablet ? 20 : 16),
        _tipCard(
          icon: Icons.timer_outlined,
          text: 'Each slot is 30 minutes long and shown in your local time.',
          isDark: isDark,
          isTablet: isTablet,
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _policyCard(
          title: 'Time slots',
          points: const [
            'Only slots within the professional\'s working hours are shown.',
            'Slots already passed for today are automatically disabled.',
            'You can change your selected time at any point before confirming.',
          ],
          isDark: isDark,
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _timeChip(TimeOfDay t, bool isDark, bool isTablet) {
    final label = _slotLabel(t);
    final disabled = _isSlotPast(t);
    final selected = _selectedSlot == label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: disabled
            ? null
            : () {
                setState(() => _selectedSlot = label);
                Future.delayed(const Duration(milliseconds: 180), () {
                  if (mounted) _goToStep(3);
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 19 : 17, vertical: isTablet ? 14 : 13),
          decoration: BoxDecoration(
            color: disabled
                ? (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.06))
                : selected
                    ? context.colors.primary
                    : (isDark ? Colors.white.withOpacity(0.04) : context.colors.background),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? context.colors.primary
                  : (isDark ? Colors.white.withOpacity(0.08) : context.colors.divider),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: disabled
                    ? context.colors.textSecondary.withOpacity(0.4)
                    : selected
                        ? Colors.white
                        : context.colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: FontWeight.w600,
                  color: disabled
                      ? context.colors.textSecondary.withOpacity(0.4)
                      : selected
                          ? Colors.white
                          : context.colors.textPrimary,
                  decoration: disabled ? TextDecoration.lineThrough : null,
                  decorationColor: context.colors.textSecondary.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyStateCard(bool isDark, bool isTablet, String message, IconData icon) {
    return _cardShell(
      isDark: isDark,
      isTablet: isTablet,
      child: Column(
        children: [
          Icon(icon, size: 38, color: context.colors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.colors.textSecondary, fontWeight: FontWeight.w500, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Location ────────────────────────────────────────────────
  Widget _buildLocationStep(bool isDark, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _locationOptionCard(
          isDark: isDark,
          isTablet: isTablet,
          selected: _locationChoice == _LocationChoice.professional,
          icon: Icons.storefront_rounded,
          title: "At Professional's Location",
          subtitle: _professionalLocationLabel(),
          onTap: () => setState(() => _locationChoice = _LocationChoice.professional),
        ),
        SizedBox(height: isTablet ? 14 : 10),
        _locationOptionCard(
          isDark: isDark,
          isTablet: isTablet,
          selected: _locationChoice == _LocationChoice.custom,
          icon: Icons.edit_location_alt_rounded,
          title: 'Custom Location',
          subtitle: 'Enter a specific address',
          onTap: () => setState(() => _locationChoice = _LocationChoice.custom),
        ),
        if (_locationChoice == _LocationChoice.custom) ...[
          SizedBox(height: isTablet ? 14 : 10),
          TextField(
            controller: _customLocationController,
            maxLines: 2,
            style: TextStyle(fontSize: isTablet ? 15 : 14, color: context.colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter full address',
              hintStyle: TextStyle(fontSize: 14, color: context.colors.textSecondary),
              prefixIcon: Icon(Icons.location_on_rounded, color: context.colors.textSecondary, size: 22),
              filled: true,
              fillColor: context.colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : context.colors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : context.colors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.colors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
        SizedBox(height: isTablet ? 20 : 16),
        _miniProgressCard(isDark, isTablet),
        SizedBox(height: isTablet ? 20 : 16),
        _tipCard(
          icon: Icons.privacy_tip_outlined,
          text: 'This location is shared with the professional along with your request so they know where to meet you.',
          isDark: isDark,
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _locationOptionCard({
    required bool isDark,
    required bool isTablet,
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: selected
                ? context.colors.primary.withOpacity(isDark ? 0.16 : 0.08)
                : context.colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? context.colors.primary.withOpacity(0.55)
                  : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1)),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (selected ? context.colors.primary : context.colors.textSecondary).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 22, color: selected ? context.colors.primary : context.colors.textSecondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isTablet ? 15.5 : 14.5,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: isTablet ? 13.5 : 12.5, color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected ? context.colors.primary : context.colors.textSecondary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 4: Additional Notes ────────────────────────────────────────
  static const List<String> _kQuickNoteTags = [
    'First-time customer',
    'Urgent request',
    'Follow-up visit',
    'Please call before arriving',
  ];

  // Purely a typing convenience — appends onto the same TextEditingController
  // already wired to _noteController / _buildCombinedNote(). No new state,
  // no new field, nothing sent anywhere new.
  void _appendQuickTag(String tag) {
    final current = _noteController.text;
    final needsSeparator = current.trim().isNotEmpty;
    final updated = needsSeparator ? '$current${current.endsWith('\n') ? '' : '\n'}$tag' : tag;
    _noteController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
    );
    setState(() {});
  }

  Widget _buildNotesStep(bool isDark, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _noteController,
          maxLines: 5,
          style: TextStyle(fontSize: isTablet ? 15 : 14, color: context.colors.textPrimary, height: 1.4),
          decoration: InputDecoration(
            hintText: 'Describe your issue or requirements (optional)...',
            hintStyle: TextStyle(fontSize: 14, color: context.colors.textSecondary),
            filled: true,
            fillColor: context.colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : context.colors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : context.colors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.colors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: context.colors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sharing details helps the professional prepare for your appointment.',
                style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _sectionLabel('Quick add', isTablet),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _kQuickNoteTags
              .map((tag) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _appendQuickTag(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : context.colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : context.colors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 15, color: context.colors.primary),
                            const SizedBox(width: 6),
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: isTablet ? 13 : 12,
                                fontWeight: FontWeight.w600,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _miniProgressCard(isDark, isTablet),
        SizedBox(height: isTablet ? 20 : 16),
        _tipCard(
          icon: Icons.checklist_rounded,
          text: 'Good things to mention: specific concerns, preferences, allergies, or access instructions for your location.',
          isDark: isDark,
          isTablet: isTablet,
        ),
      ],
    );
  }

  // ── Step 5: Booking Summary + Confirm ───────────────────────────────
  Widget _buildSummaryStep(bool isDark, bool isTablet) {
    final pro = widget.professional;
    final name = (pro['name'] ?? 'Professional').toString();
    final location = _locationChoice == _LocationChoice.custom
        ? (_customLocationController.text.trim().isEmpty
            ? 'Not specified'
            : _customLocationController.text.trim())
        : _professionalLocationLabel();
    final note = _noteController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Review your booking', isTablet),
        _cardShell(
          isDark: isDark,
          isTablet: isTablet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow(Icons.person_outline_rounded, 'Professional', name, isTablet),
              _summaryRow(
                Icons.calendar_today_rounded,
                'Date',
                _selectedDate != null ? DateFormat('EEE, MMM d, yyyy').format(_selectedDate!) : '—',
                isTablet,
              ),
              _summaryRow(Icons.access_time_rounded, 'Time', _selectedSlot ?? '—', isTablet),
              _summaryRow(Icons.location_on_outlined, 'Location', location, isTablet),
              if (note.isNotEmpty) _summaryRow(Icons.notes_rounded, 'Notes', note, isTablet, isLast: true),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _sectionLabel('What happens next', isTablet),
        _cardShell(
          isDark: isDark,
          isTablet: isTablet,
          child: Column(
            children: [
              _nextStepRow(1, Icons.send_rounded, 'Request sent',
                  'Your booking request goes straight to $name.', isTablet, isLast: false),
              _nextStepRow(2, Icons.hourglass_top_rounded, 'Professional reviews it',
                  'They confirm or suggest a different time.', isTablet, isLast: false),
              _nextStepRow(3, Icons.notifications_active_outlined, "You're notified",
                  "You'll get notified the moment they respond.", isTablet, isLast: true),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _policyCard(
          title: 'Cancellation policy',
          points: const [
            'Free cancellation any time while your request is pending.',
            "Once accepted, you can coordinate changes directly with the professional via chat.",
          ],
          isDark: isDark,
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _nextStepRow(int number, IconData icon, String title, String subtitle, bool isTablet, {required bool isLast}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 16, color: context.colors.primary),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.colors.surface, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 14.5 : 13.5,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: isTablet ? 13 : 12, color: context.colors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value, bool isTablet, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: context.colors.primary),
          const SizedBox(width: 14),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(fontSize: isTablet ? 13.5 : 12.5, color: context.colors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 14.5 : 13.5,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav bar ───────────────────────────────────────────────────
  Widget _buildNavBar(bool isTablet) {
    final isLastStep = _currentStep == 5;
    final canProceed = _canProceed(_currentStep);

    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(isTablet ? 24 : 16, 12, isTablet ? 24 : 16, 12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => _goToStep(_currentStep - 1),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: context.colors.divider, width: 1.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Back',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : !canProceed
                            ? null
                            : isLastStep
                                ? _submitBooking
                                : () => _goToStep(_currentStep + 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: context.colors.primary.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : Text(
                            isLastStep ? 'Confirm Booking' : 'Next',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
            if (isLastStep) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 12, color: context.colors.textSecondary),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Your information is secure and only shared after confirmation.',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: context.colors.textSecondary),
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
}