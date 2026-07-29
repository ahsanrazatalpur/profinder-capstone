// lib/features/admin/screens/admin_notifications_screen.dart
//
// Content Management → Notifications (admin broadcast center)
// Compose + send/schedule push notifications to All/Customers/
// Professionals/Specific user. Scheduled ones stay editable/cancel-able
// until sent; once sent, locked (see design spec reasoning).
//
// Backend:
//   GET   /api/admin-panel/notifications/?status=scheduled
//   POST  /api/admin-panel/notifications/
//   PATCH /api/admin-panel/notifications/<id>/cancel/

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final query = _statusFilter == 'all' ? '' : '?status=$_statusFilter';
      final r = await _api.get('/admin-panel/notifications/$query');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _broadcasts = r.data is List ? List<dynamic>.from(r.data) : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load notifications'; });
    }
  }

  Future<void> _cancel(dynamic broadcast) async {
    try {
      await _api.patch('/admin-panel/notifications/${broadcast['id']}/cancel/', {});
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel — it may have already been sent.')));
    }
  }

  Color _colorFor(String status) =>
      _statuses.firstWhere((s) => s.$1 == status, orElse: () => _statuses[0]).$3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.adminColor,
        onPressed: _openComposeSheet,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Compose', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.adminColor, Color(0xFFB91C1C)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statuses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final (key, label, color) = _statuses[i];
                    final isActive = _statusFilter == key;
                    return GestureDetector(
                      onTap: () { setState(() => _statusFilter = key); _load(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isActive ? color.withOpacity(0.12) : const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isActive ? color : Colors.transparent),
                        ),
                        alignment: Alignment.center,
                        child: Text(label, style: TextStyle(fontSize: 12,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? color : const Color(0xFF6B7280))),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.adminColor))
                  : _error != null
                      ? _errorState()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.adminColor,
                          child: _broadcasts.isEmpty
                              ? ListView(children: [_emptyState()])
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                  itemCount: _broadcasts.length,
                                  itemBuilder: (_, i) => _broadcastCard(_broadcasts[i]),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _broadcastCard(dynamic b) {
    final status = b['status']?.toString() ?? 'scheduled';
    final color = _colorFor(status);
    final isScheduled = status == 'scheduled';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(b['title']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(b['status_display']?.toString() ?? status,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(b['message']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people_outline_rounded, size: 13, color: AppColors.adminColor),
              const SizedBox(width: 4),
              Text(
                b['audience'] == 'specific'
                    ? 'To: ${b['specific_user_name'] ?? 'user'}'
                    : b['audience_display']?.toString() ?? '',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (isScheduled)
            Text('Scheduled for: ${b['scheduled_at'] ?? '—'}', style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600))
          else if (status == 'sent')
            Text('Sent to ${b['sent_count']} users · Open rate: ${b['open_rate']}%',
                style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
          if (isScheduled) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                onPressed: () => _cancel(b),
                child: const Text('Cancel', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Compose Notification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl,
                    decoration: const InputDecoration(hintText: 'Title', filled: true, fillColor: Color(0xFFF5F7FA), border: OutlineInputBorder(borderSide: BorderSide.none))),
                const SizedBox(height: 10),
                TextField(controller: messageCtrl, maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Message', filled: true, fillColor: Color(0xFFF5F7FA), border: OutlineInputBorder(borderSide: BorderSide.none))),
                const SizedBox(height: 14),
                const Text('Audience', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    ('all', 'All Users'), ('customers', 'Customers'),
                    ('professionals', 'Professionals'), ('specific', 'Specific User'),
                  ].map((e) {
                    final isActive = audience == e.$1;
                    return GestureDetector(
                      onTap: () => setSheetState(() => audience = e.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.adminColor.withOpacity(0.1) : const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isActive ? AppColors.adminColor : Colors.transparent),
                        ),
                        child: Text(e.$2, style: TextStyle(fontSize: 12,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? AppColors.adminColor : const Color(0xFF6B7280))),
                      ),
                    );
                  }).toList(),
                ),
                if (audience == 'specific') ...[
                  const SizedBox(height: 10),
                  TextField(controller: userIdCtrl, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'User ID', filled: true, fillColor: Color(0xFFF5F7FA), border: OutlineInputBorder(borderSide: BorderSide.none))),
                ],
                const SizedBox(height: 14),
                CheckboxListTile(
                  value: scheduleLater,
                  onChanged: (v) => setSheetState(() => scheduleLater = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Schedule for later', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                if (scheduleLater)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                          context: sheetContext, initialDate: DateTime.now(),
                          firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (date == null) return;
                      final time = await showTimePicker(context: sheetContext, initialTime: TimeOfDay.now());
                      if (time == null) return;
                      setSheetState(() => scheduledDateTime =
                          DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    },
                    icon: const Icon(Icons.schedule_rounded, size: 16),
                    label: Text(scheduledDateTime == null ? 'Pick date & time' : scheduledDateTime.toString().substring(0, 16)),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) return;
                      if (audience == 'specific' && userIdCtrl.text.trim().isEmpty) return;
                      if (scheduleLater && scheduledDateTime == null) return;

                      Navigator.pop(sheetContext);
                      try {
                        await _api.post('/admin-panel/notifications/', {
                          'title': titleCtrl.text.trim(),
                          'message': messageCtrl.text.trim(),
                          'audience': audience,
                          if (audience == 'specific') 'specific_user_id': int.tryParse(userIdCtrl.text.trim()),
                          if (scheduleLater) 'scheduled_at': scheduledDateTime!.toUtc().toIso8601String(),
                        });
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(scheduleLater ? 'Notification scheduled.' : 'Notification sent!')));
                        _load();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to send notification.')));
                      }
                    },
                    child: Text(scheduleLater ? 'Schedule' : 'Send Now', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(children: [
            Icon(Icons.notifications_none_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text('No notifications yet', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ]),
        ),
      );

  Widget _errorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 10),
            const Text('Failed to load notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            ),
          ],
        ),
      );
}