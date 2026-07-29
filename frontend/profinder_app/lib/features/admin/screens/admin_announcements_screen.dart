// lib/features/admin/screens/admin_announcements_screen.dart
//
// Content Management → Announcements
// Persistent platform-wide in-app messages (maintenance/policy notices) —
// distinct from Notifications (push, fire-and-forget). Type auto-drives
// visual severity so admins don't hand-pick colors.
//
// Backend:
//   GET    /api/admin-panel/announcements/
//   POST   /api/admin-panel/announcements/       { title, message, type, audience, start_date, end_date }
//   PATCH  /api/admin-panel/announcements/<id>/   { is_active, ... }
//   DELETE /api/admin-panel/announcements/<id>/

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _announcements = [];

  static const _typeStyles = {
    'info':        (Color(0xFF3B82F6), Icons.info_outline_rounded),
    'warning':     (Color(0xFFF59E0B), Icons.warning_amber_rounded),
    'maintenance': (Color(0xFFEF4444), Icons.build_circle_outlined),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.get('/admin-panel/announcements/');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _announcements = r.data is List ? List<dynamic>.from(r.data) : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load announcements'; });
    }
  }

  Future<void> _toggleActive(dynamic a) async {
    try {
      await _api.patch('/admin-panel/announcements/${a['id']}/', {'is_active': !(a['is_active'] == true)});
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update.')));
    }
  }

  Future<void> _delete(dynamic a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: Text('Remove "${a['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.delete('/admin-panel/announcements/${a['id']}/');
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.adminColor,
        onPressed: _composeDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
                  const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Announcements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('${_announcements.where((a) => a['is_active'] == true).length} active',
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85))),
                      ],
                    ),
                  ),
                ],
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
                          child: _announcements.isEmpty
                              ? ListView(children: [_emptyState()])
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                  itemCount: _announcements.length,
                                  itemBuilder: (_, i) => _announcementCard(_announcements[i]),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _announcementCard(dynamic a) {
    final type = a['type']?.toString() ?? 'info';
    final (color, icon) = _typeStyles[type] ?? _typeStyles['info']!;
    final isActive = a['is_active'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isActive ? color.withOpacity(0.3) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(a['title']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Switch(value: isActive, activeColor: color, onChanged: (_) => _toggleActive(a)),
            ],
          ),
          const SizedBox(height: 6),
          Text(a['message']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(a['type_display']?.toString() ?? type,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
              ),
              const SizedBox(width: 6),
              Text(a['audience_display']?.toString() ?? '', style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                onPressed: () => _delete(a),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _composeDialog() {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String type = 'info';
    String audience = 'all';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('New Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Title')),
                const SizedBox(height: 10),
                TextField(controller: messageCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Message')),
                const SizedBox(height: 10),
                const Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['info', 'warning', 'maintenance'].map((t) {
                    final isActive = type == t;
                    final (color, _) = _typeStyles[t]!;
                    return GestureDetector(
                      onTap: () => setDialogState(() => type = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? color.withOpacity(0.12) : const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isActive ? color : Colors.transparent),
                        ),
                        child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: isActive ? color : const Color(0xFF6B7280))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                const Text('Audience', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [('all', 'All'), ('customers', 'Customers'), ('professionals', 'Professionals')].map((e) {
                    final isActive = audience == e.$1;
                    return GestureDetector(
                      onTap: () => setDialogState(() => audience = e.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.adminColor.withOpacity(0.1) : const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isActive ? AppColors.adminColor : Colors.transparent),
                        ),
                        child: Text(e.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: isActive ? AppColors.adminColor : const Color(0xFF6B7280))),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) return;
                Navigator.pop(dialogContext);
                try {
                  await _api.post('/admin-panel/announcements/', {
                    'title': titleCtrl.text.trim(), 'message': messageCtrl.text.trim(),
                    'type': type, 'audience': audience,
                  });
                  _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create.')));
                }
              },
              child: const Text('Publish', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(children: [
            Icon(Icons.campaign_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text('No announcements yet', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ]),
        ),
      );

  Widget _errorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 10),
            const Text('Failed to load announcements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            ),
          ],
        ),
      );
}