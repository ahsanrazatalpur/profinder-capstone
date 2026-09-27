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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.adminColor.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.history_rounded, color: AppColors.adminColor, size: 26),
        ),
        title: Text('Restore Version ${version['version_number']}?', textAlign: TextAlign.center),
        content: const Text(
          'This replaces your current draft with this version\'s content. '
          'It does NOT publish automatically — review in Preview, then Publish when ready.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.adminColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _service.restoreVersion(version['id']);
    if (!mounted) return;
    final success = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: success ? Colors.green.shade600 : null,
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(success
                  ? 'Draft restored. Review in Preview, then Publish.'
                  : (result['error']?.toString() ?? 'Restore failed.')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: const Text('Version History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _loading
            ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
            : _versions.isEmpty
                ? _emptyState(context)
                : _versionsList(context),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.adminColor.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.history_toggle_off_rounded, size: 36, color: AppColors.adminColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            Text(
              'No versions yet — publish the About page to create the first one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _versionsList(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey('list'),
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final contentWidth = isWide ? 720.0 : constraints.maxWidth;
        return RefreshIndicator(
          onRefresh: _load,
          color: AppColors.adminColor,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentWidth,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _versions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _versionCard(context, _versions[i], i),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _versionCard(BuildContext context, dynamic v, int index) {
    DateTime? createdAt;
    try { createdAt = DateTime.parse(v['created_at']); } catch (_) {}

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + (index * 30).clamp(0, 300)),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 8), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.divider),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: context.colors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [
                            if (createdAt != null) DateFormat('MMM d, y · h:mm a').format(createdAt),
                            if (v['created_by_name']?.toString().isNotEmpty == true) 'by ${v['created_by_name']}',
                          ].join(' — '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _RestoreButton(onPressed: () => _restore(v)),
          ],
        ),
      ),
    );
  }
}

class _RestoreButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _RestoreButton({required this.onPressed});

  @override
  State<_RestoreButton> createState() => _RestoreButtonState();
}

class _RestoreButtonState extends State<_RestoreButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovering ? AppColors.adminColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton.icon(
          onPressed: widget.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.adminColor,
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.restore_rounded, size: 16),
          label: const Text('Restore', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}