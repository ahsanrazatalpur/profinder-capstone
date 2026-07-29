// lib/features/professional/screens/professional_availability_screen.dart
//
// Premium "Availability & Schedule" screen — Urban Company / Fresha / Booksy /
// Google Calendar / Calendly inspired UX.
//
// IMPORTANT — backend contract is untouched:
//   • Reads/writes ONLY the existing `is_available`, `working_hours_start`
//     and `working_hours_end` fields on AppConstants.professionalProfile,
//     through the same ApiService.patchForm(...) call already used across
//     the app. No new endpoints, models, providers or routes are added.
//   • The current backend model only stores a single boolean (available /
//     not available) and a single global start/end time — it has no field
//     for a 4-way status (Available Now / Busy / Offline / On Leave) or a
//     per-day weekly schedule. Those richer states are the natural UX for
//     a booking product, so they are kept locally on-device (SharedPreferences,
//     already used elsewhere in this app) purely for presentation:
//       - "Available Now"                → is_available = true  (synced to API)
//       - "Busy" / "Offline" / "On Leave" → is_available = false (synced to API)
//       - The weekly per-day grid lets a professional fine-tune hours per
//         day; the earliest enabled start and latest enabled end are synced
//         back to the existing working_hours_start / working_hours_end
//         fields so the single source of truth on the backend stays
//         meaningful without requiring a schema change.
//     Persisting a true per-day schedule server-side would need a small
//     backend addition (e.g. a JSON field) — intentionally out of scope
//     here since backend/API/model changes were explicitly not requested.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────
// Status model
// ─────────────────────────────────────────────────────────────────────────

enum AvailabilityStatus { availableNow, busy, offline, onLeave }

extension _AvailabilityStatusX on AvailabilityStatus {
  String get label {
    switch (this) {
      case AvailabilityStatus.availableNow:
        return 'Available Now';
      case AvailabilityStatus.busy:
        return 'Busy';
      case AvailabilityStatus.offline:
        return 'Offline';
      case AvailabilityStatus.onLeave:
        return 'On Leave';
    }
  }

  String get description {
    switch (this) {
      case AvailabilityStatus.availableNow:
        return 'Customers can book you right now';
      case AvailabilityStatus.busy:
        return 'You are working — new requests are paused';
      case AvailabilityStatus.offline:
        return 'You won\'t appear in new booking requests';
      case AvailabilityStatus.onLeave:
        return 'Marked as on leave until you return';
    }
  }

  IconData get icon {
    switch (this) {
      case AvailabilityStatus.availableNow:
        return Icons.check_circle_rounded;
      case AvailabilityStatus.busy:
        return Icons.watch_later_rounded;
      case AvailabilityStatus.offline:
        return Icons.power_settings_new_rounded;
      case AvailabilityStatus.onLeave:
        return Icons.flight_takeoff_rounded;
    }
  }

  // Maps the richer 4-way status down onto the single boolean the backend
  // understands. Only "Available Now" is bookable.
  bool get mapsToBackendAvailable => this == AvailabilityStatus.availableNow;

  static AvailabilityStatus fromName(String? name) {
    return AvailabilityStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => AvailabilityStatus.availableNow,
    );
  }
}

Color _statusColor(BuildContext context, AvailabilityStatus status) {
  switch (status) {
    case AvailabilityStatus.availableNow:
      return context.colors.accent;
    case AvailabilityStatus.busy:
      return const Color(0xFFF59E0B);
    case AvailabilityStatus.offline:
      return context.colors.textSecondary;
    case AvailabilityStatus.onLeave:
      return const Color(0xFF8B5CF6);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Weekly schedule model
// ─────────────────────────────────────────────────────────────────────────

class _DaySchedule {
  bool enabled;
  TimeOfDay start;
  TimeOfDay end;

  _DaySchedule({required this.enabled, required this.start, required this.end});

  _DaySchedule copyWith({bool? enabled, TimeOfDay? start, TimeOfDay? end}) {
    return _DaySchedule(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'start': '${start.hour}:${start.minute}',
        'end': '${end.hour}:${end.minute}',
      };

  factory _DaySchedule.fromJson(Map<String, dynamic> json, _DaySchedule fallback) {
    TimeOfDay parse(String raw, TimeOfDay fb) {
      final parts = raw.split(':');
      if (parts.length != 2) return fb;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return fb;
      return TimeOfDay(hour: h, minute: m);
    }

    return _DaySchedule(
      enabled: json['enabled'] as bool? ?? fallback.enabled,
      start: parse(json['start']?.toString() ?? '', fallback.start),
      end: parse(json['end']?.toString() ?? '', fallback.end),
    );
  }
}

const List<String> _kDayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _kDayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// ─────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────

class ProfessionalAvailabilityScreen extends StatefulWidget {
  const ProfessionalAvailabilityScreen({super.key});

  @override
  State<ProfessionalAvailabilityScreen> createState() =>
      _ProfessionalAvailabilityScreenState();
}

class _ProfessionalAvailabilityScreenState
    extends State<ProfessionalAvailabilityScreen> with SingleTickerProviderStateMixin {
  static const _prefsStatusKey = 'pro_availability_status_v1';
  static const _prefsScheduleKey = 'pro_weekly_schedule_v1';

  final _api = ApiService();

  bool _isLoading = true;
  bool _isSavingStatus = false;
  bool _isSavingSchedule = false;
  bool _scheduleDirty = false;

  AvailabilityStatus _status = AvailabilityStatus.availableNow;
  late List<_DaySchedule> _week; // index 0 = Monday .. 6 = Sunday
  late List<_DaySchedule> _weekOriginal;

  @override
  void initState() {
    super.initState();
    _week = List.generate(
      7,
      (i) => _DaySchedule(
        enabled: i < 5,
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 18, minute: 0),
      ),
    );
    _weekOriginal = _week.map((d) => d.copyWith()).toList();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(AppConstants.professionalProfile);
      final data = res.data as Map<String, dynamic>;
      final isAvailable = data['is_available'] ?? true;
      final start = _parseTime(data['working_hours_start']?.toString()) ??
          const TimeOfDay(hour: 9, minute: 0);
      final end = _parseTime(data['working_hours_end']?.toString()) ??
          const TimeOfDay(hour: 18, minute: 0);

      final prefs = await SharedPreferences.getInstance();
      final savedStatusName = prefs.getString(_prefsStatusKey);
      final savedScheduleRaw = prefs.getString(_prefsScheduleKey);

      List<_DaySchedule> week = List.generate(
        7,
        (i) => _DaySchedule(enabled: i < 5, start: start, end: end),
      );

      if (savedScheduleRaw != null) {
        try {
          final decoded = jsonDecode(savedScheduleRaw) as List;
          for (var i = 0; i < 7 && i < decoded.length; i++) {
            week[i] = _DaySchedule.fromJson(
              decoded[i] as Map<String, dynamic>,
              week[i],
            );
          }
        } catch (_) {
          // Ignore corrupt local cache, fall back to defaults derived above.
        }
      }

      if (!mounted) return;
      setState(() {
        _status = savedStatusName != null
            ? _AvailabilityStatusX.fromName(savedStatusName)
            : (isAvailable ? AvailabilityStatus.availableNow : AvailabilityStatus.offline);
        _week = week;
        _weekOriginal = week.map((d) => d.copyWith()).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppHelpers.showError(context, 'Could not load availability');
    }
  }

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Status change ──────────────────────────────────────
  Future<void> _setStatus(AvailabilityStatus status) async {
    if (status == _status || _isSavingStatus) return;
    final previous = _status;
    setState(() {
      _status = status;
      _isSavingStatus = true;
    });
    try {
      // Same call the existing toggle used — only is_available is touched.
      await _api.patchForm(
        AppConstants.professionalProfile,
        FormData.fromMap({'is_available': status.mapsToBackendAvailable.toString()}),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsStatusKey, status.name);
      if (!mounted) return;
      AppHelpers.showSuccess(context, 'Status updated to ${status.label}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = previous);
      AppHelpers.showError(context, 'Could not update status');
    } finally {
      if (mounted) setState(() => _isSavingStatus = false);
    }
  }

  // ── Weekly schedule editing ────────────────────────────
  void _toggleDay(int index, bool enabled) {
    setState(() {
      _week[index] = _week[index].copyWith(enabled: enabled);
      _scheduleDirty = true;
    });
  }

  Future<void> _pickTime(int index, {required bool isStart}) async {
    final day = _week[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? day.start : day.end,
    );
    if (picked == null) return;
    setState(() {
      _week[index] = isStart
          ? day.copyWith(start: picked)
          : day.copyWith(end: picked);
      _scheduleDirty = true;
    });
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSavingSchedule = true);
    try {
      final enabledDays = _week.where((d) => d.enabled).toList();

      // Keep the existing single start/end backend fields meaningful:
      // earliest start and latest end among the enabled days.
      TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
      TimeOfDay end = const TimeOfDay(hour: 18, minute: 0);
      if (enabledDays.isNotEmpty) {
        start = enabledDays
            .map((d) => d.start)
            .reduce((a, b) => (a.hour * 60 + a.minute) <= (b.hour * 60 + b.minute) ? a : b);
        end = enabledDays
            .map((d) => d.end)
            .reduce((a, b) => (a.hour * 60 + a.minute) >= (b.hour * 60 + b.minute) ? a : b);
      }

      await _api.patchForm(
        AppConstants.professionalProfile,
        FormData.fromMap({
          'working_hours_start': _formatTime(start),
          'working_hours_end': _formatTime(end),
        }),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsScheduleKey,
        jsonEncode(_week.map((d) => d.toJson()).toList()),
      );

      if (!mounted) return;
      setState(() {
        _weekOriginal = _week.map((d) => d.copyWith()).toList();
        _scheduleDirty = false;
        _isSavingSchedule = false;
      });
      AppHelpers.showSuccess(context, 'Weekly schedule saved');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingSchedule = false);
      AppHelpers.showError(context, 'Could not save schedule');
    }
  }

  void _discardScheduleChanges() {
    setState(() {
      _week = _weekOriginal.map((d) => d.copyWith()).toList();
      _scheduleDirty = false;
    });
  }

  // ── Grouped summary (Calendly-style "Mon – Fri, 9:00 AM – 5:00 PM") ───
  List<_ScheduleGroup> _groupedSchedule() {
    final groups = <_ScheduleGroup>[];
    for (var i = 0; i < 7; i++) {
      final day = _week[i];
      final key = day.enabled ? '${day.start.hour}:${day.start.minute}-${day.end.hour}:${day.end.minute}' : 'closed';
      if (groups.isNotEmpty && groups.last.key == key) {
        groups.last.dayIndices.add(i);
      } else {
        groups.add(_ScheduleGroup(key: key, dayIndices: [i], enabled: day.enabled, start: day.start, end: day.end));
      }
    }
    return groups;
  }

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
        title: Text(
          'Availability & Schedule',
          style: TextStyle(
            fontSize: isTablet ? 19.0 : 17.0,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.professionalColor,
                strokeWidth: 3,
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.professionalColor,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 120),
                children: [
                  _buildStatusCard(isDark, isTablet),
                  SizedBox(height: isTablet ? 24 : 20),
                  _sectionHeader(
                    icon: Icons.calendar_view_week_rounded,
                    title: 'Weekly Working Schedule',
                    subtitle: 'Set the hours you take bookings, day by day',
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 12),
                  _buildWeeklyScheduleCard(isDark, isTablet),
                  SizedBox(height: isTablet ? 24 : 20),
                  _sectionHeader(
                    icon: Icons.event_available_rounded,
                    title: 'Working Hours Summary',
                    subtitle: 'How your week currently looks to customers',
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(isDark, isTablet),
                ],
              ),
            ),
      bottomNavigationBar: (_scheduleDirty && !_isLoading)
          ? _buildSaveBar(isTablet)
          : null,
    );
  }

  // ── Section header helper ──────────────────────────────
  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isTablet,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.professionalColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: isTablet ? 20 : 18, color: AppColors.professionalColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 17 : 16,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isTablet ? 13 : 12,
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Status Card ─────────────────────────────────────────
  Widget _buildStatusCard(bool isDark, bool isTablet) {
    final color = _statusColor(context, _status);

    return Container(
      padding: EdgeInsets.all(isTablet ? 22 : 18),
      decoration: BoxDecoration(
        color: context.colors.surface,
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
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(_status.icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _status.label,
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16.5,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (_isSavingStatus) ...[
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _status.description,
                      style: TextStyle(
                        fontSize: isTablet ? 13.5 : 12.5,
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 520 ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: crossAxisCount == 4 ? 2.6 : 2.9,
                children: AvailabilityStatus.values
                    .map((s) => _buildStatusChip(s, isDark, isTablet))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AvailabilityStatus status, bool isDark, bool isTablet) {
    final selected = status == _status;
    final color = _statusColor(context, status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _setStatus(status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(isDark ? 0.18 : 0.12)
                : (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color.withOpacity(0.55) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(status.icon, size: isTablet ? 18 : 16, color: selected ? color : context.colors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  status.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? color : context.colors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Weekly Schedule Card ────────────────────────────────
  Widget _buildWeeklyScheduleCard(bool isDark, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
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
        children: List.generate(7, (i) {
          final isLast = i == 6;
          return Column(
            children: [
              _buildDayRow(i, isDark, isTablet),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: isTablet ? 20 : 16,
                  endIndent: isTablet ? 20 : 16,
                  color: context.colors.divider.withOpacity(0.6),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDayRow(int index, bool isDark, bool isTablet) {
    final day = _week[index];
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 14 : 12,
      ),
      child: Row(
        children: [
          SizedBox(
            width: isTablet ? 110 : 92,
            child: Text(
              _kDayNames[index],
              style: TextStyle(
                fontSize: isTablet ? 15 : 14,
                fontWeight: FontWeight.w600,
                color: day.enabled ? context.colors.textPrimary : context.colors.textSecondary,
                letterSpacing: 0.1,
              ),
            ),
          ),
          Expanded(
            child: day.enabled
                ? Row(
                    children: [
                      Expanded(child: _buildTimeChip(index, isStart: true, isDark: isDark, isTablet: isTablet)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: context.colors.textSecondary.withOpacity(0.6),
                        ),
                      ),
                      Expanded(child: _buildTimeChip(index, isStart: false, isDark: isDark, isTablet: isTablet)),
                    ],
                  )
                : Text(
                    'Closed',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textSecondary.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: isTablet ? 1.0 : 0.85,
            child: Switch(
              value: day.enabled,
              onChanged: (v) => _toggleDay(index, v),
              activeColor: context.colors.accent,
              activeTrackColor: context.colors.accent.withOpacity(0.3),
              inactiveTrackColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(int index, {required bool isStart, required bool isDark, required bool isTablet}) {
    final day = _week[index];
    final time = isStart ? day.start : day.end;
    return GestureDetector(
      onTap: () => _pickTime(index, isStart: isStart),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 10, vertical: isTablet ? 9 : 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : context.colors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : context.colors.divider,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time_rounded, size: isTablet ? 15 : 14, color: context.colors.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                time.format(context),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isTablet ? 13 : 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary Card ────────────────────────────────────────
  Widget _buildSummaryCard(bool isDark, bool isTablet) {
    final groups = _groupedSchedule();

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
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
        children: groups.asMap().entries.map((entry) {
          final isLast = entry.key == groups.length - 1;
          final g = entry.value;
          final label = g.dayIndices.length == 1
              ? _kDayNames[g.dayIndices.first]
              : '${_kDayShort[g.dayIndices.first]} – ${_kDayShort[g.dayIndices.last]}';

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : (isTablet ? 14 : 12)),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (g.enabled ? context.colors.accent : context.colors.textSecondary)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    g.enabled ? Icons.event_available_rounded : Icons.event_busy_rounded,
                    size: 17,
                    color: g.enabled ? context.colors.accent : context.colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isTablet ? 14.5 : 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                Text(
                  g.enabled ? '${g.start.format(context)} – ${g.end.format(context)}' : 'Closed',
                  style: TextStyle(
                    fontSize: isTablet ? 13.5 : 12.5,
                    fontWeight: FontWeight.w500,
                    color: g.enabled ? context.colors.textPrimary : context.colors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Sticky Save Bar ─────────────────────────────────────
  Widget _buildSaveBar(bool isTablet) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 24 : 16,
          12,
          isTablet ? 24 : 16,
          12,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSavingSchedule ? null : _discardScheduleChanges,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: context.colors.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Discard',
                  style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSavingSchedule ? null : _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.professionalColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSavingSchedule
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Text('Save Schedule', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleGroup {
  final String key;
  final List<int> dayIndices;
  final bool enabled;
  final TimeOfDay start;
  final TimeOfDay end;

  _ScheduleGroup({
    required this.key,
    required this.dayIndices,
    required this.enabled,
    required this.start,
    required this.end,
  });
}