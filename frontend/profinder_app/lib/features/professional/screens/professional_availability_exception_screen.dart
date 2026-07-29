// lib/features/professional/screens/professional_availability_exception_screen.dart
//
// Premium "Availability Exceptions" screen — date overrides, multiple time
// ranges per date, and vacation mode, styled to match Urban Company / Fresha
// / Booksy / Google Calendar / Calendly.
//
// IMPORTANT — backend contract is untouched:
//   • ProfessionalProfile (backend/apps/profiles/models.py) only stores a
//     single global `is_available` flag and a single `working_hours_start`
//     / `working_hours_end` pair. There is no schema for per-date overrides
//     or vacation ranges, and adding one would require a new backend
//     model/endpoint — explicitly out of scope since no backend/API/model
//     changes were requested for this screen.
//   • So, exactly like professional_availability_screen.dart, every
//     exception (date overrides + vacation) is kept on-device
//     (SharedPreferences, already used elsewhere in this app) purely for
//     presentation. This screen makes ZERO network calls — zero risk to
//     existing business logic, providers, controllers, APIs or routes.
//   • It *reads* (never writes) the weekly-schedule cache already saved by
//     professional_availability_screen.dart, only to shade a date's
//     "regular closed weekday" on the calendar for context. That other
//     screen, its keys, and its backend sync are completely untouched.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────

TimeOfDay? _parseTOD(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h, minute: m);
}

int _todMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

class _TimeRange {
  TimeOfDay start;
  TimeOfDay end;
  _TimeRange({required this.start, required this.end});

  _TimeRange copyWith({TimeOfDay? start, TimeOfDay? end}) =>
      _TimeRange(start: start ?? this.start, end: end ?? this.end);

  Map<String, dynamic> toJson() => {
        'start': '${start.hour}:${start.minute}',
        'end': '${end.hour}:${end.minute}',
      };

  factory _TimeRange.fromJson(Map<String, dynamic> j) => _TimeRange(
        start: _parseTOD(j['start']?.toString()) ?? const TimeOfDay(hour: 9, minute: 0),
        end: _parseTOD(j['end']?.toString()) ?? const TimeOfDay(hour: 17, minute: 0),
      );
}

enum _OverrideType { unavailable, customHours }

class _DateOverride {
  final DateTime date; // date-only (no time component)
  _OverrideType type;
  List<_TimeRange> ranges;

  _DateOverride({required this.date, required this.type, required this.ranges});

  _DateOverride copyWith({_OverrideType? type, List<_TimeRange>? ranges}) => _DateOverride(
        date: date,
        type: type ?? this.type,
        ranges: ranges ?? this.ranges,
      );

  Map<String, dynamic> toJson() => {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'type': type.name,
        'ranges': ranges.map((r) => r.toJson()).toList(),
      };

  factory _DateOverride.fromJson(Map<String, dynamic> j) {
    final d = DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now();
    final rawRanges = (j['ranges'] as List?) ?? const [];
    return _DateOverride(
      date: DateTime(d.year, d.month, d.day),
      type: j['type'] == 'customHours' ? _OverrideType.customHours : _OverrideType.unavailable,
      ranges: rawRanges.isEmpty
          ? [_TimeRange(start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 17, minute: 0))]
          : rawRanges.map((r) => _TimeRange.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }
}

class _VacationPeriod {
  DateTime start;
  DateTime end;
  String reason;
  _VacationPeriod({required this.start, required this.end, this.reason = ''});

  Map<String, dynamic> toJson() => {
        'start': DateFormat('yyyy-MM-dd').format(start),
        'end': DateFormat('yyyy-MM-dd').format(end),
        'reason': reason,
      };

  factory _VacationPeriod.fromJson(Map<String, dynamic> j) {
    final s = DateTime.tryParse(j['start']?.toString() ?? '') ?? DateTime.now();
    final e = DateTime.tryParse(j['end']?.toString() ?? '') ?? DateTime.now();
    return _VacationPeriod(
      start: DateTime(s.year, s.month, s.day),
      end: DateTime(e.year, e.month, e.day),
      reason: j['reason']?.toString() ?? '',
    );
  }

  bool covers(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}

const List<String> _kWeekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// ─────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────

class ProfessionalAvailabilityExceptionScreen extends StatefulWidget {
  const ProfessionalAvailabilityExceptionScreen({super.key});

  @override
  State<ProfessionalAvailabilityExceptionScreen> createState() =>
      _ProfessionalAvailabilityExceptionScreenState();
}

class _ProfessionalAvailabilityExceptionScreenState
    extends State<ProfessionalAvailabilityExceptionScreen> {
  static const _prefsExceptionsKey = 'pro_availability_exceptions_v1';
  // Read-only reference to the key already written by
  // professional_availability_screen.dart — never written from here.
  static const _prefsWeeklyScheduleKey = 'pro_weekly_schedule_v1';

  bool _isLoading = true;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  final Map<String, _DateOverride> _overrides = {}; // key = yyyy-MM-dd
  _VacationPeriod? _vacation;
  List<bool> _weeklyEnabled = [true, true, true, true, true, false, false]; // Mon..Sun

  DateTime? _vacationStart;
  DateTime? _vacationEnd;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // Read-only peek at the weekly schedule saved elsewhere, just to
      // shade "regular closed" weekdays on this calendar for context.
      final weeklyRaw = prefs.getString(_prefsWeeklyScheduleKey);
      if (weeklyRaw != null) {
        try {
          final decoded = jsonDecode(weeklyRaw) as List;
          final enabled = List<bool>.from(_weeklyEnabled);
          for (var i = 0; i < 7 && i < decoded.length; i++) {
            final day = decoded[i] as Map<String, dynamic>;
            enabled[i] = day['enabled'] as bool? ?? enabled[i];
          }
          _weeklyEnabled = enabled;
        } catch (_) {
          // Ignore corrupt cache — keep defaults.
        }
      }

      final raw = prefs.getString(_prefsExceptionsKey);
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final overridesRaw = (decoded['overrides'] as List?) ?? const [];
          for (final o in overridesRaw) {
            final ov = _DateOverride.fromJson(o as Map<String, dynamic>);
            _overrides[_key(ov.date)] = ov;
          }
          final vacationRaw = decoded['vacation'] as Map<String, dynamic>?;
          if (vacationRaw != null) {
            _vacation = _VacationPeriod.fromJson(vacationRaw);
            _vacationStart = _vacation!.start;
            _vacationEnd = _vacation!.end;
            _reasonController.text = _vacation!.reason;
          }
        } catch (_) {
          // Ignore corrupt local cache.
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppHelpers.showError(context, 'Could not load exceptions');
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsExceptionsKey,
      jsonEncode({
        'overrides': _overrides.values.map((o) => o.toJson()).toList(),
        'vacation': _vacation?.toJson(),
      }),
    );
  }

  // ── Calendar helpers ────────────────────────────────────
  List<DateTime> _gridDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final startOffset = (first.weekday + 6) % 7; // Monday = 0
    final gridStart = first.subtract(Duration(days: startOffset));
    return List.generate(42, (i) => gridStart.add(Duration(days: i)));
  }

  bool _isClosedWeekday(DateTime d) => !_weeklyEnabled[(d.weekday - 1) % 7];

  // ── Date override editing ───────────────────────────────
  Future<void> _openDateEditor(DateTime date) async {
    final key = _key(date);
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OverrideEditorSheet(
        date: date,
        existing: _overrides[key],
      ),
    );
    if (result == null) return;
    if (result == 'DELETE') {
      setState(() => _overrides.remove(key));
      await _persist();
      if (!mounted) return;
      AppHelpers.showSuccess(context, 'Override removed');
      return;
    }
    if (result is _DateOverride) {
      setState(() => _overrides[key] = result);
      await _persist();
      if (!mounted) return;
      AppHelpers.showSuccess(context, 'Override saved for ${DateFormat('d MMMM').format(date)}');
    }
  }

  // ── Vacation mode ───────────────────────────────────────
  Future<void> _pickVacationDate({required bool isStart}) async {
    final initial = isStart ? (_vacationStart ?? _today) : (_vacationEnd ?? (_vacationStart ?? _today));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isStart ? _today : (_vacationStart ?? _today),
      lastDate: DateTime(_today.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _vacationStart = DateTime(picked.year, picked.month, picked.day);
        if (_vacationEnd != null && _vacationEnd!.isBefore(_vacationStart!)) {
          _vacationEnd = _vacationStart;
        }
      } else {
        _vacationEnd = DateTime(picked.year, picked.month, picked.day);
      }
    });
  }

  Future<void> _saveVacation() async {
    if (_vacationStart == null || _vacationEnd == null) {
      AppHelpers.showError(context, 'Please select a start and end date');
      return;
    }
    setState(() {
      _vacation = _VacationPeriod(
        start: _vacationStart!,
        end: _vacationEnd!,
        reason: _reasonController.text.trim(),
      );
    });
    await _persist();
    if (!mounted) return;
    AppHelpers.showSuccess(context, 'Vacation mode set');
  }

  Future<void> _clearVacation() async {
    setState(() {
      _vacation = null;
      _vacationStart = null;
      _vacationEnd = null;
      _reasonController.clear();
    });
    await _persist();
    if (!mounted) return;
    AppHelpers.showSuccess(context, 'Vacation mode cleared');
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
  }

  // ─────────────────────────────────────────────────────────
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
          'Availability Exceptions',
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
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 32),
                children: [
                  _buildIntroBanner(isDark, isTablet),
                  SizedBox(height: isTablet ? 24 : 20),
                  _sectionHeader(
                    icon: Icons.calendar_month_rounded,
                    title: 'Calendar',
                    subtitle: 'Tap any date to set an override',
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 12),
                  _buildCalendarCard(isDark, isTablet),
                  SizedBox(height: isTablet ? 24 : 20),
                  _sectionHeader(
                    icon: Icons.flight_takeoff_rounded,
                    title: 'Vacation Mode',
                    subtitle: 'Block out a whole date range at once',
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 12),
                  _buildVacationCard(isDark, isTablet),
                  SizedBox(height: isTablet ? 24 : 20),
                  _sectionHeader(
                    icon: Icons.event_note_rounded,
                    title: 'Date Overrides',
                    subtitle: 'Specific dates that differ from your weekly hours',
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 12),
                  _buildOverridesList(isDark, isTablet),
                ],
              ),
            ),
    );
  }

  // ── Intro banner ────────────────────────────────────────
  Widget _buildIntroBanner(bool isDark, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 18 : 14),
      decoration: BoxDecoration(
        color: AppColors.professionalColor.withOpacity(isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.professionalColor.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: isTablet ? 20 : 18, color: AppColors.professionalColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Exceptions override your regular weekly schedule for specific dates — perfect for holidays, half-days or planned time off.',
              style: TextStyle(
                fontSize: isTablet ? 13.5 : 12.5,
                fontWeight: FontWeight.w500,
                color: context.colors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section header ──────────────────────────────────────
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

  Widget _cardShell({required Widget child, required bool isDark, required bool isTablet}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  // ── Calendar card ───────────────────────────────────────
  Widget _buildCalendarCard(bool isDark, bool isTablet) {
    final days = _gridDays(_visibleMonth);

    return _cardShell(
      isDark: isDark,
      isTablet: isTablet,
      child: Column(
        children: [
          Row(
            children: [
              _monthNavButton(Icons.chevron_left_rounded, () => _changeMonth(-1)),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_visibleMonth),
                    style: TextStyle(
                      fontSize: isTablet ? 17 : 15.5,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              _monthNavButton(Icons.chevron_right_rounded, () => _changeMonth(1)),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Row(
            children: _kWeekdayShort
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 11,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          ...List.generate(6, (row) {
            return Row(
              children: List.generate(7, (col) {
                final day = days[row * 7 + col];
                return Expanded(child: _buildDayCell(day, isDark, isTablet));
              }),
            );
          }),
          SizedBox(height: isTablet ? 14 : 10),
          Divider(color: context.colors.divider.withOpacity(0.6), height: 1),
          SizedBox(height: isTablet ? 14 : 10),
          _buildLegend(isTablet),
        ],
      ),
    );
  }

  Widget _monthNavButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 22, color: context.colors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isDark, bool isTablet) {
    final inMonth = day.month == _visibleMonth.month;
    final isToday = day == _today;
    final key = _key(day);
    final override = _overrides[key];
    final onVacation = _vacation?.covers(day) ?? false;
    final closedWeekday = _isClosedWeekday(day);

    // Priority: vacation > override > closed weekday > normal.
    Color? bg;
    Color? fg;
    Border? border;
    if (onVacation) {
      bg = AppColors.professionalColor.withOpacity(isDark ? 0.22 : 0.14);
      fg = AppColors.professionalColor;
    } else if (override != null) {
      final c = override.type == _OverrideType.unavailable ? AppColors.warning : AppColors.info;
      bg = c.withOpacity(isDark ? 0.20 : 0.13);
      fg = c;
    } else if (closedWeekday) {
      bg = isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.08);
      fg = context.colors.textSecondary;
    } else {
      fg = context.colors.textPrimary;
    }
    if (isToday) {
      border = Border.all(color: AppColors.professionalColor, width: 1.4);
    }

    return Padding(
      padding: const EdgeInsets.all(3),
      child: AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: inMonth ? () => _openDateEditor(day) : null,
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: border,
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  color: inMonth ? fg : (fg ?? context.colors.textSecondary).withOpacity(0.28),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(bool isTablet) {
    Widget dot(Color c) => Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(c),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 12 : 11,
                fontWeight: FontWeight.w500,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        item(context.colors.textPrimary.withOpacity(0.35), 'Working day'),
        item(AppColors.professionalColor, 'Vacation'),
        item(AppColors.info, 'Custom hours'),
        item(AppColors.warning, 'Unavailable'),
        item(context.colors.textSecondary, 'Closed day'),
      ],
    );
  }

  // ── Vacation card ───────────────────────────────────────
  Widget _buildVacationCard(bool isDark, bool isTablet) {
    final isActive = _vacation != null && _vacation!.covers(_today);
    final isScheduled = _vacation != null && !isActive && _today.isBefore(_vacation!.start);

    return _cardShell(
      isDark: isDark,
      isTablet: isTablet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isActive || isScheduled) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.professionalColor.withOpacity(isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flight_takeoff_rounded, size: 15, color: AppColors.professionalColor),
                  const SizedBox(width: 8),
                  Text(
                    isActive
                        ? 'Unavailable during vacation'
                        : 'Vacation scheduled from ${DateFormat('d MMM').format(_vacation!.start)}',
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.professionalColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),
          ],
          Row(
            children: [
              Expanded(
                child: _dateField(
                  label: 'Start Date',
                  value: _vacationStart,
                  isTablet: isTablet,
                  onTap: () => _pickVacationDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateField(
                  label: 'End Date',
                  value: _vacationEnd,
                  isTablet: isTablet,
                  onTap: () => _pickVacationDate(isStart: false),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 14 : 12),
          TextField(
            controller: _reasonController,
            maxLength: 80,
            style: TextStyle(fontSize: isTablet ? 14 : 13, color: context.colors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Reason (optional)',
              labelStyle: TextStyle(color: context.colors.textSecondary, fontSize: 13),
              counterText: '',
              prefixIcon: Icon(Icons.edit_note_rounded, color: context.colors.textSecondary, size: 20),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.04) : context.colors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          SizedBox(height: isTablet ? 16 : 14),
          Row(
            children: [
              if (_vacation != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearVacation,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: context.colors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saveVacation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.professionalColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _vacation == null ? 'Set Vacation' : 'Update Vacation',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : context.colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : context.colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.colors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: context.colors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value != null ? DateFormat('d MMM yyyy').format(value) : 'Select',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isTablet ? 13.5 : 12.5,
                      fontWeight: FontWeight.w700,
                      color: value != null ? context.colors.textPrimary : context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Overrides list ──────────────────────────────────────
  Widget _buildOverridesList(bool isDark, bool isTablet) {
    final sorted = _overrides.values.toList()..sort((a, b) => a.date.compareTo(b.date));

    if (sorted.isEmpty) {
      return _cardShell(
        isDark: isDark,
        isTablet: isTablet,
        child: Row(
          children: [
            Icon(Icons.event_available_rounded, size: 18, color: context.colors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No date overrides yet. Tap a date on the calendar to add one.',
                style: TextStyle(
                  fontSize: isTablet ? 13.5 : 12.5,
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: sorted.asMap().entries.map((entry) {
        final isLast = entry.key == sorted.length - 1;
        final o = entry.value;
        final isUnavailable = o.type == _OverrideType.unavailable;
        final color = isUnavailable ? AppColors.warning : AppColors.info;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openDateEditor(o.date),
              child: Container(
                padding: EdgeInsets.all(isTablet ? 16 : 14),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.10) : Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        isUnavailable ? Icons.event_busy_rounded : Icons.schedule_rounded,
                        size: 19,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('d MMMM, EEEE').format(o.date),
                            style: TextStyle(
                              fontSize: isTablet ? 14.5 : 13.5,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          isUnavailable
                              ? _statusChip('Unavailable', color)
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: o.ranges
                                      .map((r) => _statusChip(
                                            '${r.start.format(context)} – ${r.end.format(context)}',
                                            color,
                                          ))
                                      .toList(),
                                ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          setState(() => _overrides.remove(_key(o.date)));
                          await _persist();
                          if (!mounted) return;
                          AppHelpers.showSuccess(context, 'Override removed');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.delete_outline_rounded, size: 19, color: context.colors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Override editor bottom sheet
// ─────────────────────────────────────────────────────────────────────────

class _OverrideEditorSheet extends StatefulWidget {
  final DateTime date;
  final _DateOverride? existing;
  const _OverrideEditorSheet({required this.date, this.existing});

  @override
  State<_OverrideEditorSheet> createState() => _OverrideEditorSheetState();
}

class _OverrideEditorSheetState extends State<_OverrideEditorSheet> {
  late _OverrideType _type;
  late List<_TimeRange> _ranges;

  @override
  void initState() {
    super.initState();
    _type = widget.existing?.type ?? _OverrideType.unavailable;
    _ranges = widget.existing?.ranges
            .map((r) => _TimeRange(start: r.start, end: r.end))
            .toList() ??
        [_TimeRange(start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 17, minute: 0))];
  }

  Future<void> _pickTime(int index, {required bool isStart}) async {
    final range = _ranges[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? range.start : range.end,
    );
    if (picked == null) return;
    setState(() {
      _ranges[index] = isStart ? range.copyWith(start: picked) : range.copyWith(end: picked);
    });
  }

  void _addRange() {
    final last = _ranges.last;
    final lastEndMinutes = _todMinutes(last.end);
    final newStart = lastEndMinutes + 60 < 24 * 60
        ? TimeOfDay(hour: (lastEndMinutes + 60) ~/ 60, minute: (lastEndMinutes + 60) % 60)
        : const TimeOfDay(hour: 18, minute: 0);
    final int newEndMinutes = (lastEndMinutes + 180).clamp(0, 23 * 60 + 59).toInt();
    setState(() {
      _ranges.add(_TimeRange(
        start: newStart,
        end: TimeOfDay(hour: newEndMinutes ~/ 60, minute: newEndMinutes % 60),
      ));
    });
  }

  void _removeRange(int index) {
    setState(() => _ranges.removeAt(index));
  }

  void _save() {
    if (_type == _OverrideType.customHours) {
      for (final r in _ranges) {
        if (_todMinutes(r.end) <= _todMinutes(r.start)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End time must be after start time'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
    }
    final override = _DateOverride(
      date: DateTime(widget.date.year, widget.date.month, widget.date.day),
      type: _type,
      ranges: _type == _OverrideType.customHours
          ? _ranges
          : [_TimeRange(start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 17, minute: 0))],
    );
    Navigator.of(context).pop(override);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                  decoration: BoxDecoration(
                    color: context.colors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.professionalColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(Icons.event_rounded, size: 19, color: AppColors.professionalColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('d MMMM').format(widget.date),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, yyyy').format(widget.date),
                          style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _typeChip(_OverrideType.unavailable, 'Unavailable', Icons.event_busy_rounded, isDark)),
                  const SizedBox(width: 10),
                  Expanded(child: _typeChip(_OverrideType.customHours, 'Custom Hours', Icons.schedule_rounded, isDark)),
                ],
              ),
              if (_type == _OverrideType.customHours) ...[
                const SizedBox(height: 18),
                ...List.generate(_ranges.length, (i) => _rangeRow(i, isDark)),
                const SizedBox(height: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _addRange,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.professionalColor),
                          const SizedBox(width: 8),
                          Text(
                            'Add another time range',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.professionalColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  if (widget.existing != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop('DELETE'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Remove',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.professionalColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _typeChip(_OverrideType type, String label, IconData icon, bool isDark) {
    final selected = _type == type;
    final color = type == _OverrideType.unavailable ? AppColors.warning : AppColors.info;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _type = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(isDark ? 0.18 : 0.12)
                : (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color.withOpacity(0.55) : Colors.transparent, width: 1.2),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? color : context.colors.textSecondary),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rangeRow(int index, bool isDark) {
    final range = _ranges[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: _timeChip(range.start, isDark, onTap: () => _pickTime(index, isStart: true)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded, size: 15, color: context.colors.textSecondary.withOpacity(0.6)),
          ),
          Expanded(
            child: _timeChip(range.end, isDark, onTap: () => _pickTime(index, isStart: false)),
          ),
          if (_ranges.length > 1) ...[
            const SizedBox(width: 6),
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _removeRange(index),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded, size: 18, color: context.colors.textSecondary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeChip(TimeOfDay time, bool isDark, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : context.colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : context.colors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time_rounded, size: 15, color: context.colors.textSecondary),
            const SizedBox(width: 8),
            Text(
              time.format(context),
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}