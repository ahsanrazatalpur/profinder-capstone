// lib/features/admin/screens/admin_notifications_screen.dart
//
// Content Management → Notifications (admin broadcast center)
// Compose + send/schedule push notifications to All/Customers/
// Professionals/Specific user. Scheduled ones stay editable/cancel-able
// until sent; once sent, locked.
//
// Backend endpoints (UNCHANGED):
//   GET   /api/admin-panel/notifications/?status=scheduled
//   POST  /api/admin-panel/notifications/
//   PATCH /api/admin-panel/notifications/<id>/cancel/

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../shared/widgets/universal_app_bar.dart';

/// Responsive breakpoints used by the list container and grid.
class _Breakpoints {
  static const double tablet = 700;
  static const double desktop = 1100;
}

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _broadcasts = [];
  String _statusFilter = 'all';

  static const _statuses = [
    ('all', 'All', Color(0xFF374151)),
    ('scheduled', 'Scheduled', Color(0xFFF59E0B)),
    ('sent', 'Sent', Color(0xFF16A34A)),
    ('cancelled', 'Cancelled', Color(0xFF64748B)),
    ('failed', 'Failed', Color(0xFFEF4444)),
  ];

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
    _entranceController.dispose();
    super.dispose();
  }

  /// Fetches broadcasts for the active status filter. `all` sends no query
  /// param; other values pass `?status=`. Behavior unchanged.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = _statusFilter == 'all' ? '' : '?status=$_statusFilter';
      final r = await _api.get('/admin-panel/notifications/$query');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _broadcasts = r.data is List ? List<dynamic>.from(r.data) : [];
      });
      _entranceController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load notifications';
      });
    }
  }

  /// Cancels a scheduled broadcast. Behavior unchanged.
  Future<void> _cancel(dynamic broadcast) async {
    try {
      await _api.patch(
          '/admin-panel/notifications/${broadcast['id']}/cancel/', {});
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Failed to cancel — it may have already been sent.')),
      );
    }
  }

  /// Maps a status key to its display color.
  Color _colorFor(String status) => _statuses
      .firstWhere((s) => s.$1 == status, orElse: () => _statuses[0])
      .$3;

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
        title: 'Notifications',
        subtitle: '${_broadcasts.length} ${_statusFilter == 'all' ? 'broadcast' : _statusFilter}${_broadcasts.length == 1 ? '' : 's'}',
        icon: Icons.notifications_active_rounded,
        showBack: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_notifications_fab',
        backgroundColor: AppColors.adminColor,
        onPressed: _openComposeSheet,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Compose',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
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
          child: _broadcasts.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [_emptyState()],
                )
              : isDesktop
                  ? GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 90),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 240,
                      ),
                      itemCount: _broadcasts.length,
                      itemBuilder: (_, i) =>
                          _buildAnimatedCard(_broadcasts[i], i),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 90),
                      itemCount: _broadcasts.length,
                      itemBuilder: (_, i) =>
                          _buildAnimatedCard(_broadcasts[i], i),
                    ),
        ),
      ),
    );
  }

  /// Wraps each card in a staggered fade + slide entrance. Delay is capped
  /// so long lists don't feel sluggish.
  Widget _buildAnimatedCard(dynamic broadcast, int index) {
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
        child: _broadcastCard(broadcast),
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

  // ── Broadcast Card ────────────────────────────────────────
  /// Displays a broadcast: title + status pill, message preview, audience,
  /// and status-specific info row (scheduled time / sent stats). Scheduled
  /// items get a Cancel action.
  Widget _broadcastCard(dynamic b) {
    final status = b['status']?.toString() ?? 'scheduled';
    final color = _colorFor(status);
    final isScheduled = status == 'scheduled';
    final isSent = status == 'sent';

    final title = b['title']?.toString() ?? '';
    final message = b['message']?.toString() ?? '';
    final audienceLabel = b['audience'] == 'specific'
        ? 'To: ${b['specific_user_name'] ?? 'user'}'
        : b['audience_display']?.toString() ?? '';
    final statusDisplay = b['status_display']?.toString() ?? status;

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
            // ── Title + status pill ────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.campaign_rounded,
                      size: 17, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusDisplay,
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: 0.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Message preview ────────────────────
            if (message.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF374151),
                    height: 1.45),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 10),

            // ── Audience row ───────────────────────
            Row(
              children: [
                const Icon(Icons.people_outline_rounded,
                    size: 13, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    audienceLabel,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // ── Status info row ────────────────────
            if (isScheduled) ...[
              const SizedBox(height: 6),
              _statusInfoRow(
                icon: Icons.schedule_rounded,
                color: AppColors.warning,
                text: 'Scheduled for: ${b['scheduled_at'] ?? '—'}',
              ),
            ] else if (isSent) ...[
              const SizedBox(height: 6),
              _statusInfoRow(
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                text:
                    'Sent to ${b['sent_count']} users · Open rate: ${b['open_rate']}%',
              ),
            ],

            // ── Cancel action (scheduled only) ─────
            if (isScheduled) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _HoverLift(
                  borderRadius: BorderRadius.circular(10),
                  hoverScale: 1.02,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(
                          color: AppColors.error, width: 1.3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _cancel(b),
                    icon: const Icon(Icons.close_rounded, size: 15),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Small row of (icon + text) used for the status-specific info line.
  Widget _statusInfoRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Compose sheet ─────────────────────────────────────────
  /// Bottom sheet for composing a new notification. All controllers, POST
  /// body, and validation guards are preserved. UI is polished with a
  /// sticky action bar and animated audience chips.
  void _openComposeSheet() {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final userIdCtrl = TextEditingController();
    String audience = 'all';
    bool scheduleLater = false;
    DateTime? scheduledDateTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.adminColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.campaign_rounded,
                            color: AppColors.adminColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Compose Notification',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Title
                  const _FieldLabel('Title'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: _fieldDecoration(
                        hint: 'Short summary shown in the push'),
                  ),

                  const SizedBox(height: 14),

                  // Message
                  const _FieldLabel('Message'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: messageCtrl,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: _fieldDecoration(
                        hint: 'The body of the notification…'),
                  ),

                  const SizedBox(height: 18),

                  // Audience
                  const _FieldLabel('Audience'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ('all', 'All Users'),
                      ('customers', 'Customers'),
                      ('professionals', 'Professionals'),
                      ('specific', 'Specific User'),
                    ].map((e) {
                      final isActive = audience == e.$1;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () =>
                              setSheetState(() => audience = e.$1),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            constraints:
                                const BoxConstraints(minHeight: 40),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.adminColor
                                      .withOpacity(0.1)
                                  : const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.adminColor
                                    : Colors.transparent,
                                width: 1.3,
                              ),
                            ),
                            child: Text(
                              e.$2,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isActive
                                    ? AppColors.adminColor
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Specific user id field
                  if (audience == 'specific') ...[
                    const SizedBox(height: 12),
                    const _FieldLabel('User ID'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: userIdCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: _fieldDecoration(
                          hint: 'Enter the numeric user id'),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Schedule toggle
                  Container(
                    decoration: BoxDecoration(
                      color: scheduleLater
                          ? AppColors.adminColor.withOpacity(0.05)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheduleLater
                            ? AppColors.adminColor.withOpacity(0.25)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    // CheckboxListTile paints its background/ink splashes on
                    // the nearest Material ancestor. This outer Container has
                    // its own background color, which would hide those
                    // effects and trip Flutter's "background color or ink
                    // splashes may be invisible" assertion. Giving the tile
                    // its own transparent Material fixes that.
                    child: Material(
                      type: MaterialType.transparency,
                      child: CheckboxListTile(
                        value: scheduleLater,
                        onChanged: (v) =>
                            setSheetState(() => scheduleLater = v ?? false),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.adminColor,
                        title: const Text(
                          'Schedule for later',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Leave off to send immediately',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      ),
                    ),
                  ),

                  // Date/time picker
                  if (scheduleLater) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: sheetContext,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (date == null) return;
                          final time = await showTimePicker(
                            context: sheetContext,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time == null) return;
                          setSheetState(() => scheduledDateTime = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              ));
                        },
                        icon: const Icon(Icons.schedule_rounded, size: 16),
                        label: Text(
                          scheduledDateTime == null
                              ? 'Pick date & time'
                              : scheduledDateTime
                                  .toString()
                                  .substring(0, 16),
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.adminColor,
                          side: const BorderSide(
                              color: AppColors.adminColor),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminColor,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty ||
                            messageCtrl.text.trim().isEmpty) {
                          return;
                        }
                        if (audience == 'specific' &&
                            userIdCtrl.text.trim().isEmpty) {
                          return;
                        }
                        if (scheduleLater && scheduledDateTime == null) {
                          return;
                        }

                        Navigator.pop(sheetContext);
                        try {
                          await _api.post(
                              '/admin-panel/notifications/', {
                            'title': titleCtrl.text.trim(),
                            'message': messageCtrl.text.trim(),
                            'audience': audience,
                            if (audience == 'specific')
                              'specific_user_id':
                                  int.tryParse(userIdCtrl.text.trim()),
                            if (scheduleLater)
                              'scheduled_at': scheduledDateTime!
                                  .toUtc()
                                  .toIso8601String(),
                          });
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(scheduleLater
                                  ? 'Notification scheduled.'
                                  : 'Notification sent!'),
                            ),
                          );
                          _load();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Failed to send notification.')),
                          );
                        }
                      },
                      icon: Icon(
                        scheduleLater
                            ? Icons.schedule_send_rounded
                            : Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        scheduleLater ? 'Schedule' : 'Send Now',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shared decoration for the compose-sheet fields.
  InputDecoration _fieldDecoration({required String hint}) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      );

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
                child: const Icon(Icons.notifications_none_rounded,
                    size: 42, color: AppColors.adminColor),
              ),
              const SizedBox(height: 16),
              const Text(
                'No notifications yet',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap Compose to send your first broadcast.',
                style: TextStyle(
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
                'Failed to load notifications',
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

/// Small uppercase caption used above compose-sheet fields.
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFF6B7280),
        letterSpacing: 0.5,
      ),
    );
  }
}

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