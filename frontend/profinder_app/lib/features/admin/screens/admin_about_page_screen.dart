// lib/features/admin/screens/admin_about_page_screen.dart
//
// About Page Management — the single source of truth for the public About
// page. Nothing here depends on seed data or management commands: an admin
// creates every section directly from "Add Section", picking a type from
// the same 16 the spec calls for (or "Custom" for anything future).
//
// Backend: /api/about-page/admin/... (see about_page_service.dart)

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/about_icons.dart';
import '../../../services/about_page_service.dart';
import '../../about/models/about_page_model.dart';
import '../../about/screens/about_screen.dart';
import 'admin_about_section_editor_screen.dart';
import 'admin_about_section_items_screen.dart';
import 'admin_about_seo_screen.dart';
import 'admin_about_version_history_screen.dart';
import 'admin_about_preview_screen.dart';

/// (type value, display label, icon) — mirrors the backend's
/// SECTION_TYPE_CHOICES so "Add Section" always matches what the public
/// renderer knows how to lay out.
const List<Map<String, String>> kAboutSectionTypes = [
  {'value': 'hero_banner',        'label': 'Hero Banner'},
  {'value': 'company_story',      'label': 'Company Story'},
  {'value': 'mission',            'label': 'Mission'},
  {'value': 'vision',             'label': 'Vision'},
  {'value': 'why_choose_us',      'label': 'Why Choose Us'},
  {'value': 'how_it_works',       'label': 'How It Works'},
  {'value': 'statistics',         'label': 'Statistics'},
  {'value': 'core_values',        'label': 'Core Values'},
  {'value': 'team_members',       'label': 'Team Members'},
  {'value': 'investors_partners', 'label': 'Investors & Partners'},
  {'value': 'certifications',     'label': 'Certifications'},
  {'value': 'awards',             'label': 'Awards'},
  {'value': 'contact_info',       'label': 'Contact Information'},
  {'value': 'social_media',       'label': 'Social Media Links'},
  {'value': 'app_info',           'label': 'App Information'},
  {'value': 'legal_links',        'label': 'Legal Links'},
  {'value': 'custom',             'label': 'Custom Section'},
];

String sectionTypeLabel(String value) {
  final match = kAboutSectionTypes.firstWhere(
      (t) => t['value'] == value, orElse: () => {'label': 'Custom'});
  return match['label']!;
}

class AdminAboutPageScreen extends StatefulWidget {
  const AdminAboutPageScreen({super.key});

  @override
  State<AdminAboutPageScreen> createState() => _AdminAboutPageScreenState();
}

class _AdminAboutPageScreenState extends State<AdminAboutPageScreen> {
  final _service = AboutPageService();

  bool _loading = true;
  String? _error;
  List<AboutSection> _sections = [];
  Map<String, dynamic>? _status;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final results = await Future.wait([_service.getAdminSections(), _service.getStatus()]);
    if (!mounted) return;
    final sectionsResult = results[0];
    final statusResult = results[1];
    setState(() {
      _loading = false;
      if (sectionsResult['success'] == true) {
        _sections = List<AboutSection>.from(sectionsResult['data']);
        _sections.sort((a, b) => a.order.compareTo(b.order));
      } else {
        _error = sectionsResult['error']?.toString();
      }
      if (statusResult['success'] == true) _status = statusResult['data'];
    });
  }

  List<AboutSection> get _filtered {
    if (_query.trim().isEmpty) return _sections;
    final q = _query.toLowerCase();
    return _sections.where((s) =>
        s.title.toLowerCase().contains(q) ||
        s.sectionKey.toLowerCase().contains(q) ||
        sectionTypeLabel(s.sectionType).toLowerCase().contains(q)).toList();
  }

  bool get _isSearching => _query.trim().isNotEmpty;

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _reorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _sections.removeAt(oldIndex);
      _sections.insert(newIndex, item);
    });
    final order = [
      for (var i = 0; i < _sections.length; i++) {'id': _sections[i].id, 'order': i}
    ];
    await _service.reorderSections(order);
  }

  Future<void> _toggleEnabled(AboutSection section) async {
    final result = await _service.updateSection(section.id, {'is_enabled': !section.isEnabled});
    if (result['success'] == true) _load();
  }

  Future<void> _duplicate(AboutSection section) async {
    final newKey = '${section.sectionKey}_copy_${DateTime.now().millisecondsSinceEpoch % 100000}';
    final result = await _service.createSection({
      'section_type': section.sectionType,
      'section_key': newKey,
      'title': '${section.title} (Copy)',
      'subtitle': section.subtitle,
      'description': section.description,
      'icon': section.icon,
      'cta_text': section.ctaText,
      'cta_url': section.ctaUrl,
      'cta_style': section.ctaStyle,
      'extra_data': section.extraData,
      'is_enabled': false, // duplicates start disabled so they don't double-publish accidentally
    });
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Section duplicated (disabled by default).')));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Could not duplicate section.')));
    }
  }

  Future<void> _confirmDelete(AboutSection section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Section?'),
        content: Text('"${section.title.isNotEmpty ? section.title : section.sectionKey}" and all '
            'its items and translations will be permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _service.deleteSection(section.id);
    if (result['success'] == true) _load();
  }

  Future<void> _showAddSectionDialog() async {
    String selectedType = 'custom';
    final keyController = TextEditingController();
    final titleController = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Section'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Section Type', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: kAboutSectionTypes
                      .map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!)))
                      .toList(),
                  onChanged: (v) => setDialogState(() {
                    selectedType = v!;
                    if (keyController.text.isEmpty || kAboutSectionTypes.any((t) => t['value'] == keyController.text)) {
                      keyController.text = selectedType;
                    }
                  }),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'Section Key (unique, no spaces)',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final key = keyController.text.trim().replaceAll(' ', '_').toLowerCase();
                if (key.isEmpty) {
                  setDialogState(() => error = 'Section key is required.');
                  return;
                }
                final result = await _service.createSection({
                  'section_type': selectedType,
                  'section_key': key,
                  'title': titleController.text.trim(),
                  'is_enabled': true,
                });
                if (result['success'] == true) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } else {
                  setDialogState(() => error = result['error']?.toString() ?? 'Could not create section.');
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'about_page_add_section_fab',
        onPressed: _showAddSectionDialog,
        backgroundColor: AppColors.adminColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Section', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final status = _status?['status'] ?? 'draft';
    return AppBar(
      backgroundColor: AppColors.adminColor,
      title: const Text('About Page Management', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      actions: [
        _statusChip(status),
        IconButton(
          tooltip: 'View Live Page',
          icon: const Icon(Icons.public_rounded, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
        ),
        IconButton(
          tooltip: 'SEO',
          icon: const Icon(Icons.search_rounded, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAboutSeoScreen())),
        ),
        IconButton(
          tooltip: 'Version History',
          icon: const Icon(Icons.history_rounded, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAboutVersionHistoryScreen()))
              .then((_) => _load()),
        ),
        IconButton(
          tooltip: 'Preview',
          icon: const Icon(Icons.visibility_outlined, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAboutPreviewScreen())),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (value) async {
            if (value == 'publish') await _publish();
            if (value == 'unpublish') await _unpublish();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'publish', child: Text('Publish')),
            const PopupMenuItem(value: 'unpublish', child: Text('Unpublish')),
          ],
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    final isPublished = status == 'published';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Chip(
        label: Text(isPublished ? 'Published' : (status == 'unpublished' ? 'Unpublished' : 'Draft'),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: isPublished ? Colors.green.shade600 : Colors.orange.shade700,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Future<void> _publish() async {
    final labelController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish About Page'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This makes all current draft changes live immediately.'),
            const SizedBox(height: 12),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                  labelText: 'Version note (optional)', border: OutlineInputBorder(), isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Publish')),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _service.publish(label: labelController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] == true ? 'About page published.' : (result['error']?.toString() ?? 'Publish failed.'))));
    _load();
  }

  Future<void> _unpublish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpublish About Page?'),
        content: const Text('The public About page will show as not-available until you publish again. '
            'Your content and version history are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700),
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Unpublish')),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _service.unpublish();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] == true ? 'About page unpublished.' : (result['error']?.toString() ?? 'Failed.'))));
    _load();
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: context.colors.textSecondary)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Try Again')),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search sections by title, key, or type…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              filled: true,
              fillColor: context.colors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ),
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Clear search to drag-and-drop reorder.',
                  style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary, fontStyle: FontStyle.italic)),
            ),
          ),
        Expanded(
          child: _filtered.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _isSearching
                      ? ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _sectionCard(_filtered[i], reorderable: false, index: i),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: _sections.length,
                          onReorder: _reorder,
                          itemBuilder: (_, i) => _sectionCard(_sections[i], reorderable: true, index: i,
                              key: ValueKey(_sections[i].id)),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_outlined, size: 48, color: context.colors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(_isSearching ? 'No sections match your search.' : 'No sections yet.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
            const SizedBox(height: 6),
            if (!_isSearching)
              Text('Tap "Add Section" to build your first About page block.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(AboutSection section, {required bool reorderable, required int index, Key? key}) {
    return _AboutSectionCard(
      key: key ?? ValueKey('search_${section.id}'),
      section: section,
      index: index,
      reorderable: reorderable,
      onToggle: () => _toggleEnabled(section),
      onEdit: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminAboutSectionEditorScreen(section: section)),
      ).then((_) => _load()),
      onManageItems: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminAboutSectionItemsScreen(section: section)),
      ).then((_) => _load()),
      onDuplicate: () => _duplicate(section),
      onDelete: () => _confirmDelete(section),
    );
  }
}

/// Collapsible card for one section in the list — drag handle, type badge,
/// enable switch, and quick actions. Expands to a short content preview.
class _AboutSectionCard extends StatefulWidget {
  final AboutSection section;
  final int index;
  final bool reorderable;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onManageItems;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _AboutSectionCard({
    super.key,
    required this.section,
    required this.index,
    required this.reorderable,
    required this.onToggle,
    required this.onEdit,
    required this.onManageItems,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  State<_AboutSectionCard> createState() => _AboutSectionCardState();
}

class _AboutSectionCardState extends State<_AboutSectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (widget.reorderable)
                    ReorderableDragStartListener(
                      index: widget.index,
                      child: Icon(Icons.drag_indicator_rounded, color: context.colors.textSecondary.withOpacity(0.5)),
                    )
                  else
                    const SizedBox(width: 24),
                  const SizedBox(width: 8),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.adminColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(resolveAboutIcon(s.icon, fallback: Icons.widgets_outlined), color: AppColors.adminColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title.isNotEmpty ? s.title : s.sectionKey,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                        Text(sectionTypeLabel(s.sectionType),
                            style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                      ],
                    ),
                  ),
                  Switch(value: s.isEnabled, onChanged: (_) => widget.onToggle(), activeThumbColor: AppColors.adminColor),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: context.colors.textSecondary),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.subtitle.isNotEmpty)
                    Text(s.subtitle, style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _actionChip(context, Icons.edit_outlined, 'Edit', widget.onEdit),
                      if (s.isCollectionType)
                        _actionChip(context, Icons.list_alt_rounded, 'Manage Items (${s.items.length})', widget.onManageItems),
                      _actionChip(context, Icons.copy_all_outlined, 'Duplicate', widget.onDuplicate),
                      _actionChip(context, Icons.delete_outline_rounded, 'Delete', widget.onDelete, color: Colors.red),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionChip(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? AppColors.adminColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: c)),
          ],
        ),
      ),
    );
  }
}