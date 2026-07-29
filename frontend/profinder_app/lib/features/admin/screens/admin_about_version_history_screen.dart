// lib/features/admin/screens/admin_about_version_history_screen.dart

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../services/about_page_service.dart';

class AdminAboutVersionHistoryScreen extends StatefulWidget {
  const AdminAboutVersionHistoryScreen({super.key});

  @override
  State<AdminAboutVersionHistoryScreen> createState() => _AdminAboutVersionHistoryScreenState();
}

class _AdminAboutVersionHistoryScreenState extends State<AdminAboutVersionHistoryScreen> {
  final _service = AboutPageService();
  bool _loading = true;
  List<dynamic> _versions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getVersions();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _versions = result['success'] == true ? List<dynamic>.from(result['data']) : [];
    });
  }

  Future<void> _restore(dynamic version) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restore Version ${version['version_number']}?'),
        content: const Text('This replaces your current draft with this version\'s content. '
            'It does NOT publish automatically — review in Preview, then Publish when ready.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _service.restoreVersion(version['id']);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] == true
            ? 'Draft restored. Review in Preview, then Publish.'
            : (result['error']?.toString() ?? 'Restore failed.'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        title: const Text('Version History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _versions.isEmpty
              ? Center(
                  child: Text('No versions yet — publish the About page to create the first one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.textSecondary)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _versions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final v = _versions[i];
                      DateTime? createdAt;
                      try { createdAt = DateTime.parse(v['created_at']); } catch (_) {}
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.colors.divider),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: AppColors.adminColor.withOpacity(0.1), shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text('v${v['version_number']}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.adminColor)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v['label']?.toString().isNotEmpty == true ? v['label'] : 'No note',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
                                  Text(
                                    [
                                      if (createdAt != null) DateFormat('MMM d, y · h:mm a').format(createdAt),
                                      if (v['created_by_name']?.toString().isNotEmpty == true) 'by ${v['created_by_name']}',
                                    ].join(' — '),
                                    style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(onPressed: () => _restore(v), child: const Text('Restore')),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}