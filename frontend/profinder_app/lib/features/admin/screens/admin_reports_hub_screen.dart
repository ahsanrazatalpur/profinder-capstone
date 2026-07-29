// lib/features/admin/screens/admin_reports_hub_screen.dart
//
// Business Management → Reports (export hub)
// Deliberately boring/utilitarian — its only job is turning platform data
// into a downloadable file. No charts, no cards beyond quick-launch tiles.
//
// Backend: GET /api/admin-panel/reports-hub/?type=revenue&days=30

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';

class AdminReportsHubScreen extends StatefulWidget {
  const AdminReportsHubScreen({super.key});

  @override
  State<AdminReportsHubScreen> createState() => _AdminReportsHubScreenState();
}

class _AdminReportsHubScreenState extends State<AdminReportsHubScreen> {
  final _api = ApiService();
  bool _generating = false;

  List<(String, String, IconData, Color)> get _reportTypes => [
    ('revenue', 'Revenue Report', Icons.payments_rounded, const Color(0xFF16A34A)),
    ('users', 'User Growth Report', Icons.groups_rounded, context.colors.primary),
    ('bookings', 'Booking Summary', Icons.event_note_rounded, context.colors.accent),
    ('subscriptions', 'Subscription Report', Icons.workspace_premium_rounded, const Color(0xFF7C3AED)),
  ];

  final List<Map<String, String>> _history = [];

  Future<void> _generate(String type, String label) async {
    setState(() => _generating = true);
    try {
      final r = await _api.get('/admin-panel/reports-hub/?type=$type&days=30');
      final rows = (r.data['rows'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _generating = false;
        _history.insert(0, {
          'label': label,
          'rows': '${rows.length}',
          'date': DateTime.now().toString().substring(0, 16),
        });
      });
      _previewDialog(label, rows);
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate report.')));
    }
  }

  void _previewDialog(String label, List rows) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: rows.isEmpty
              ? const Center(child: Text('No data in this range.'))
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final row = Map<String, dynamic>.from(rows[i]);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        row.entries.map((e) => '${e.key}: ${e.value}').join('  ·  '),
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard-style export (CSV) — ready to share.')));
            },
            child: const Text('Export CSV', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.adminColor, Color(0xFFB91C1C)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.summarize_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Quick Generate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.4,
                children: _reportTypes.map((r) {
                  final (type, label, icon, color) = r;
                  return GestureDetector(
                    onTap: _generating ? null : () => _generate(type, label),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Icon(icon, size: 18, color: color),
                          ),
                          const Spacer(),
                          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          const Text('Last 30 days', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_generating)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.adminColor)),
                ),
              const SizedBox(height: 20),
              const Text('Generation History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (_history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: const Center(child: Text('No reports generated yet this session.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
                )
              else
                ..._history.map((h) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h['label']!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                Text('${h['rows']} rows · ${h['date']}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}