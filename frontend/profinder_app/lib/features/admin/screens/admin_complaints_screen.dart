// lib/features/admin/screens/admin_complaints_screen.dart
//
// Business Management → Complaints
// Service/booking-dispute workflow: Open → In Progress → Resolved/Rejected.
// Distinct from Reported Users (Trust & Safety, user-conduct reports).
//
// Backend:
//   GET   /api/admin-panel/complaints/?status=open&category=no_show
//   PATCH /api/admin-panel/complaints/<id>/
//     { assign_to_me: true } or { status, resolution_note }

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<dynamic> _all = [];
  String _statusFilter = 'open';

  static const _statuses = [
    ('open', 'Open', Color(0xFFF59E0B)),
    ('in_progress', 'In Progress', Color(0xFF3B82F6)),
    ('resolved', 'Resolved', Color(0xFF16A34A)),
    ('rejected', 'Rejected', Color(0xFF64748B)),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.get('/admin-panel/complaints/?status=$_statusFilter');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _all = r.data is List ? List<dynamic>.from(r.data) : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load complaints'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
                  const Icon(Icons.report_problem_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Complaints', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
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
                          child: _all.isEmpty
                              ? ListView(children: [_emptyState()])
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                  itemCount: _all.length,
                                  itemBuilder: (_, i) => _complaintCard(_all[i]),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _complaintCard(dynamic c) {
    final status = c['status']?.toString() ?? 'open';
    final color = _statuses.firstWhere((e) => e.$1 == status, orElse: () => _statuses[0]).$3;
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
                child: Text(c['category_display']?.toString() ?? '',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(c['status_display']?.toString() ?? '', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(c['description']?.toString() ?? '', style: const TextStyle(fontSize: 12.5), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text('${c['complainant_name']} vs ${c['against_name']}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          if (c['assigned_to_name'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Assigned to: ${c['assigned_to_name']}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF3B82F6))),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (status == 'open')
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _assignToMe(c),
                    child: const Text('Assign to Me', style: TextStyle(fontSize: 12)),
                  ),
                ),
              if (status == 'in_progress') ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resolveDialog(c, 'resolved'),
                    child: const Text('Resolve', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                    onPressed: () => _resolveDialog(c, 'rejected'),
                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _assignToMe(dynamic c) async {
    try {
      await _api.patch('/admin-panel/complaints/${c['id']}/', {'assign_to_me': true});
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to assign.')));
    }
  }

  void _resolveDialog(dynamic complaint, String status) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(status == 'resolved' ? 'Resolve Complaint' : 'Reject Complaint'),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(hintText: 'Resolution note'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: status == 'resolved' ? context.colors.accent : AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _api.patch('/admin-panel/complaints/${complaint['id']}/',
                    {'status': status, 'resolution_note': noteCtrl.text.trim()});
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update.')));
              }
            },
            child: Text(status == 'resolved' ? 'Resolve' : 'Reject', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(
          child: Column(children: [
            Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(_statusFilter == 'open' ? 'No open complaints — all clear! 🎉' : 'No complaints in this category',
                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ]),
        ),
      );

  Widget _errorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 10),
            const Text('Failed to load complaints', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            ),
          ],
        ),
      );
}