// lib/features/professional/screens/professional_booking_configuration_screen.dart
//
// Premium "Booking Configuration" screen — slot duration, buffer time,
// minimum notice, maximum advance window, and approval mode, styled to
// match Urban Company / Fresha / Booksy / Google Calendar / Calendly.
//
// IMPORTANT — backend contract is untouched:
//   • ProfessionalProfile (backend/apps/profiles/models.py) and Booking
//     (backend/apps/bookings/models.py) have no fields for slot duration,
//     buffer time, minimum notice, advance-booking window, or an
//     automatic/manual approval mode. Adding those would need new backend
//     fields/endpoints — explicitly out of scope since no backend/API/
//     model changes were requested for this screen.
//   • Exactly like the other availability screens in this app, every
//     setting here is kept on-device (SharedPreferences) purely for
//     presentation. This screen makes ZERO network calls — zero risk to
//     existing business logic, providers, controllers, APIs or routes.
//   • Accept / Decline are real, backend-backed actions that already exist
//     on professional_bookings_screen.dart (PATCH → 'accepted' / 'rejected'
//     on the existing Booking model). "Suggest New Time" has no backend
//     support yet (Booking.STATUS_CHOICES has no such state), so it is
//     shown here only as a description of what Manual mode will offer —
//     no new action is wired up, and the real booking screen is untouched.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';

enum _ApprovalMode { automatic, manual }

class _MinNoticeOption {
  final String label;
  final int minutes;
  const _MinNoticeOption(this.label, this.minutes);
}

const List<_MinNoticeOption> _kMinNoticeOptions = [
  _MinNoticeOption('Immediate', 0),
  _MinNoticeOption('1 Hour', 60),
  _MinNoticeOption('2 Hours', 120),
  _MinNoticeOption('24 Hours', 1440),
];

const List<int> _kSlotPresets = [15, 30, 45, 60];
const List<int> _kBufferPresets = [0, 15, 30, 45, 60];
const List<int> _kMaxAdvanceDays = [7, 30, 60, 90];

class ProfessionalBookingConfigurationScreen extends StatefulWidget {
  const ProfessionalBookingConfigurationScreen({super.key});

  @override
  State<ProfessionalBookingConfigurationScreen> createState() =>
      _ProfessionalBookingConfigurationScreenState();
}

class _ProfessionalBookingConfigurationScreenState
    extends State<ProfessionalBookingConfigurationScreen> {
  static const _prefsKey = 'pro_booking_configuration_v1';

  bool _isLoading = true;
  bool _isSaving = false;

  int _slotMinutes = 30;
  bool _isCustomSlot = false;
  int _bufferMinutes = 15;
  int _minNoticeMinutes = 60;
  int _maxAdvanceDays = 30;
  _ApprovalMode _approvalMode = _ApprovalMode.automatic;

  // Snapshot used to detect unsaved changes.
  late Map<String, dynamic> _savedSnapshot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, dynamic> _currentSnapshot() => {
        'slotMinutes': _slotMinutes,
        'isCustomSlot': _isCustomSlot,
        'bufferMinutes': _bufferMinutes,
        'minNoticeMinutes': _minNoticeMinutes,
        'maxAdvanceDays': _maxAdvanceDays,
        'approvalMode': _approvalMode.name,
      };

  bool get _isDirty {
    final now = _currentSnapshot();
    for (final k in now.keys) {
      if (now[k] != _savedSnapshot[k]) return true;
    }
    return false;
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _slotMinutes = prefs.getInt('${_prefsKey}_slot') ?? 30;
      _isCustomSlot = prefs.getBool('${_prefsKey}_slot_custom') ?? false;
      _bufferMinutes = prefs.getInt('${_prefsKey}_buffer') ?? 15;
      _minNoticeMinutes = prefs.getInt('${_prefsKey}_notice') ?? 60;
      _maxAdvanceDays = prefs.getInt('${_prefsKey}_advance') ?? 30;
      final approvalRaw = prefs.getString('${_prefsKey}_approval');
      _approvalMode = approvalRaw == 'manual' ? _ApprovalMode.manual : _ApprovalMode.automatic;

      _savedSnapshot = _currentSnapshot();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppHelpers.showError(context, 'Could not load booking settings');
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_prefsKey}_slot', _slotMinutes);
      await prefs.setBool('${_prefsKey}_slot_custom', _isCustomSlot);
      await prefs.setInt('${_prefsKey}_buffer', _bufferMinutes);
      await prefs.setInt('${_prefsKey}_notice', _minNoticeMinutes);
      await prefs.setInt('${_prefsKey}_advance', _maxAdvanceDays);
      await prefs.setString('${_prefsKey}_approval', _approvalMode.name);

      if (!mounted) return;
      setState(() {
        _savedSnapshot = _currentSnapshot();
        _isSaving = false;
      });
      AppHelpers.showSuccess(context, 'Booking settings saved');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppHelpers.showError(context, 'Could not save booking settings');
    }
  }

  void _discard() {
    setState(() {
      _slotMinutes = _savedSnapshot['slotMinutes'] as int;
      _isCustomSlot = _savedSnapshot['isCustomSlot'] as bool;
      _bufferMinutes = _savedSnapshot['bufferMinutes'] as int;
      _minNoticeMinutes = _savedSnapshot['minNoticeMinutes'] as int;
      _maxAdvanceDays = _savedSnapshot['maxAdvanceDays'] as int;
      _approvalMode =
          _savedSnapshot['approvalMode'] == 'manual' ? _ApprovalMode.manual : _ApprovalMode.automatic;
    });
  }

  Future<void> _pickCustomSlot() async {
    final controller = TextEditingController(text: _isCustomSlot ? '$_slotMinutes' : '');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Custom Slot Duration', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Minutes',
            hintText: 'e.g. 20',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.professionalColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v == null || v < 5 || v > 240) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter a value between 5 and 240 minutes')),
                );
                return;
              }
              Navigator.pop(ctx, v);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _slotMinutes = result;
        _isCustomSlot = true;
      });
    }
  }

  String _minutesLabel(int minutes) {
    if (minutes == 0) return '0 min';
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
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
          'Booking Configuration',
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
              child: CircularProgressIndicator(color: AppColors.professionalColor, strokeWidth: 3),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.professionalColor,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 120),
                children: [
                  _settingsCard(
                    isDark: isDark,
                    isTablet: isTablet,
                    icon: Icons.timer_rounded,
                    title: 'Slot Duration',
                    subtitle: 'How long each booking slot lasts',
                    child: _buildSlotDurationOptions(isDark, isTablet),
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  _settingsCard(
                    isDark: isDark,
                    isTablet: isTablet,
                    icon: Icons.hourglass_bottom_rounded,
                    title: 'Buffer Time',
                    subtitle: 'Break added between consecutive bookings',
                    child: _buildOptionRow(
                      values: _kBufferPresets,
                      selected: _bufferMinutes,
                      isTablet: isTablet,
                      labelBuilder: (v) => v == 0 ? 'None' : '$v min',
                      onSelect: (v) => setState(() => _bufferMinutes = v),
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  _settingsCard(
                    isDark: isDark,
                    isTablet: isTablet,
                    icon: Icons.notifications_active_rounded,
                    title: 'Minimum Booking Notice',
                    subtitle: 'How soon before a slot a customer can still book',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _kMinNoticeOptions
                          .map((o) => _optionChip(
                                label: o.label,
                                selected: _minNoticeMinutes == o.minutes,
                                isTablet: isTablet,
                                onTap: () => setState(() => _minNoticeMinutes = o.minutes),
                              ))
                          .toList(),
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  _settingsCard(
                    isDark: isDark,
                    isTablet: isTablet,
                    icon: Icons.event_available_rounded,
                    title: 'Maximum Advance Booking',
                    subtitle: 'How far into the future customers can book',
                    child: _buildOptionRow(
                      values: _kMaxAdvanceDays,
                      selected: _maxAdvanceDays,
                      isTablet: isTablet,
                      labelBuilder: (v) => '$v Days',
                      onSelect: (v) => setState(() => _maxAdvanceDays = v),
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  _settingsCard(
                    isDark: isDark,
                    isTablet: isTablet,
                    icon: Icons.rule_rounded,
                    title: 'Booking Approval',
                    subtitle: 'Decide how incoming requests are confirmed',
                    child: _buildApprovalOptions(isDark, isTablet),
                  ),
                  if (_approvalMode == _ApprovalMode.manual) ...[
                    SizedBox(height: isTablet ? 16 : 12),
                    _buildManualInfoCard(isDark, isTablet),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: (_isDirty && !_isLoading) ? _buildSaveBar(isTablet) : null,
    );
  }

  // ── Shared settings card shell ──────────────────────────
  Widget _settingsCard({
    required bool isDark,
    required bool isTablet,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.professionalColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
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
                        fontSize: isTablet ? 16.5 : 15.5,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isTablet ? 12.5 : 11.5,
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 18 : 14),
          child,
        ],
      ),
    );
  }

  // ── Slot duration options (includes Custom) ─────────────
  Widget _buildSlotDurationOptions(bool isDark, bool isTablet) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._kSlotPresets.map((v) => _optionChip(
              label: '$v min',
              selected: !_isCustomSlot && _slotMinutes == v,
              isTablet: isTablet,
              onTap: () => setState(() {
                _slotMinutes = v;
                _isCustomSlot = false;
              }),
            )),
        _optionChip(
          label: _isCustomSlot ? 'Custom · ${_minutesLabel(_slotMinutes)}' : 'Custom',
          selected: _isCustomSlot,
          isTablet: isTablet,
          icon: Icons.tune_rounded,
          onTap: _pickCustomSlot,
        ),
      ],
    );
  }

  // ── Generic pill option row (buffer / advance window) ───
  Widget _buildOptionRow({
    required List<int> values,
    required int selected,
    required bool isTablet,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onSelect,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values
          .map((v) => _optionChip(
                label: labelBuilder(v),
                selected: selected == v,
                isTablet: isTablet,
                onTap: () => onSelect(v),
              ))
          .toList(),
    );
  }

  Widget _optionChip({
    required String label,
    required bool selected,
    required bool isTablet,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 14, vertical: isTablet ? 11 : 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.professionalColor.withOpacity(isDark ? 0.20 : 0.12)
                : (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.professionalColor.withOpacity(0.55) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: isTablet ? 16 : 14, color: selected ? AppColors.professionalColor : context.colors.textSecondary),
                const SizedBox(width: 6),
              ],
              if (selected && icon == null) ...[
                Icon(Icons.check_rounded, size: isTablet ? 16 : 14, color: AppColors.professionalColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 13.5 : 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.professionalColor : context.colors.textSecondary,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Booking approval ─────────────────────────────────────
  Widget _buildApprovalOptions(bool isDark, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: _approvalTile(
            mode: _ApprovalMode.automatic,
            label: 'Automatic',
            description: 'Requests confirm instantly',
            icon: Icons.flash_on_rounded,
            isDark: isDark,
            isTablet: isTablet,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _approvalTile(
            mode: _ApprovalMode.manual,
            label: 'Manual',
            description: 'You review each request',
            icon: Icons.fact_check_rounded,
            isDark: isDark,
            isTablet: isTablet,
          ),
        ),
      ],
    );
  }

  Widget _approvalTile({
    required _ApprovalMode mode,
    required String label,
    required String description,
    required IconData icon,
    required bool isDark,
    required bool isTablet,
  }) {
    final selected = _approvalMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _approvalMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14, horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.professionalColor.withOpacity(isDark ? 0.18 : 0.11)
                : (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.professionalColor.withOpacity(0.55) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: isTablet ? 22 : 20, color: selected ? AppColors.professionalColor : context.colors.textSecondary),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 14.5 : 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.professionalColor : context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 11.5 : 10.5,
                  fontWeight: FontWeight.w400,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualInfoCard(bool isDark, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 18 : 14),
      decoration: BoxDecoration(
        color: AppColors.professionalColor.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.professionalColor.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: isTablet ? 18 : 16, color: AppColors.professionalColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'With Manual approval, every new request waits for your response:',
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 14 : 10),
          _manualActionRow(Icons.check_circle_outline_rounded, 'Accept', 'Confirm the booking as requested', AppColors.accent, isTablet),
          SizedBox(height: isTablet ? 10 : 8),
          _manualActionRow(Icons.cancel_outlined, 'Decline', 'Turn down a request that doesn\'t work', AppColors.error, isTablet),
          SizedBox(height: isTablet ? 10 : 8),
          _manualActionRow(Icons.update_rounded, 'Suggest New Time', 'Propose a different slot to the customer', AppColors.info, isTablet),
          SizedBox(height: isTablet ? 14 : 10),
          Text(
            'These actions appear on each request in your Bookings screen.',
            style: TextStyle(
              fontSize: isTablet ? 11.5 : 10.5,
              fontStyle: FontStyle.italic,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _manualActionRow(IconData icon, String title, String subtitle, Color color, bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 13 : 12.5,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isTablet ? 11.5 : 10.5,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sticky save bar ──────────────────────────────────────
  Widget _buildSaveBar(bool isTablet) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(isTablet ? 24 : 16, 12, isTablet ? 24 : 16, 12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -3)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : _discard,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: context.colors.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Discard', style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.professionalColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}