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

// ─────────────────────────────────────────────────────────────────────────
// Automatic icon suggestion
//
// Admins used to have to open the icon grid and manually pick an icon for
// every single section/item, even though the type they just chose (e.g.
// "Team Members") already implies an obvious icon. This helper searches the
// *actual* keys available in `kAboutIconMap` (imported from about_icons.dart)
// for the closest semantic match to a given section type, so the icon is
// pre-filled automatically. It never invents a key that doesn't exist in the
// map — if nothing matches, it simply returns null and callers keep their
// previous "no icon selected" behavior, so this can never break rendering.
// ─────────────────────────────────────────────────────────────────────────
const Map<String, List<String>> _kIconSuggestionTerms = {
  'hero_banner':        ['banner', 'home', 'flag', 'star'],
  'company_story':      ['book', 'story', 'building', 'history', 'company'],
  'mission':            ['target', 'rocket', 'flag', 'compass', 'mission'],
  'vision':             ['eye', 'visibility', 'telescope', 'vision', 'binocular'],
  'why_choose_us':      ['check', 'thumb', 'heart', 'verified', 'star'],
  'how_it_works':       ['gear', 'settings', 'cog', 'workflow', 'process'],
  'statistics':         ['chart', 'graph', 'bar', 'trending', 'analytics'],
  'core_values':        ['heart', 'value', 'gem', 'diamond', 'star'],
  'team_members':       ['team', 'people', 'person', 'group', 'user'],
  'investors_partners': ['handshake', 'partner', 'briefcase', 'business'],
  'certifications':     ['certificate', 'badge', 'seal', 'verified', 'award'],
  'awards':             ['award', 'trophy', 'medal', 'star'],
  'contact_info':       ['phone', 'contact', 'call', 'mail'],
  'social_media':       ['share', 'social', 'link'],
  'app_info':           ['smartphone', 'mobile', 'app', 'phone'],
  'legal_links':        ['gavel', 'legal', 'law', 'document', 'shield'],
};

/// Returns the best-matching icon key from `kAboutIconMap` for [sectionType],
/// or null if no reasonable match exists. Safe to call with any string.
String? suggestIconKeyForType(String sectionType) {
  final terms = _kIconSuggestionTerms[sectionType];
  if (terms == null) return null;
  for (final term in terms) {
    for (final iconKey in kAboutIconMap.keys) {
      if (iconKey.toLowerCase().contains(term)) return iconKey;
    }
  }
  return null;
}

class AdminAboutPageScreen extends StatefulWidget {
  const AdminAboutPageScreen({super.key});

  @override
  State<AdminAboutPageScreen> createState() => _AdminAboutPageScreenState();
}

class _AdminAboutPageScreenState extends State<AdminAboutPageScreen> {
  final _service = AboutPageService();
  final _searchCtrl = TextEditingController();

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
    // Optimistic update — flip the switch immediately instead of waiting for
    // the server round-trip. On a slow connection (free-tier PythonAnywhere)
    // the old code left the switch showing the OLD value until _load()
    // finished, so a single tap looked like it did nothing and people ended
    // up tapping 2-3 times (which could re-toggle it back and forth).
    // Revert on failure.
    final index = _sections.indexWhere((s) => s.id == section.id);
    if (index == -1) return;
    final newValue = !section.isEnabled;
    debugPrint('[AboutToggle] tapped id=${section.id} key=${section.sectionKey} target=$newValue');
    setState(() => _sections[index] = section.copyWith(isEnabled: newValue));

    final result = await _service.updateSection(section.id, {'is_enabled': newValue});
    debugPrint('[AboutToggle] result for id=${section.id}: $result');
    if (!mounted) return;
    if (result['success'] != true) {
      // revert the optimistic flip and explain why
      setState(() => _sections[index] = section);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']?.toString() ?? 'Could not update section.')));
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Section?'),
        content: Text('"${section.title.isNotEmpty ? section.title : section.sectionKey}" and all '
            'its items and translations will be permanently deleted. This cannot be undone.'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Add Section'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Section Type', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                // Each entry shows a small preview of the icon that will be
                // auto-assigned for that type, so the admin sees up front
                // that they won't need to pick one manually afterwards.
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: kAboutSectionTypes.map((t) {
                    final suggested = suggestIconKeyForType(t['value']!);
                    return DropdownMenuItem(
                      value: t['value'],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            resolveAboutIcon(suggested ?? '', fallback: Icons.widgets_outlined),
                            size: 16,
                            color: AppColors.adminColor,
                          ),
                          const SizedBox(width: 10),
                          Flexible(child: Text(t['label']!, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  }).toList(),
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
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(
                    labelText: 'Section Key (unique, no spaces)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: error != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 15, color: Colors.red),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.adminColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
                  // Auto-assign an icon that matches the chosen type so the
                  // admin never has to open the icon picker just to get a
                  // sensible default; they can still change it later.
                  'icon': suggestIconKeyForType(selectedType) ?? '',
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
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Section', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final status = _status?['status'] ?? 'draft';
    return AppBar(
      backgroundColor: AppColors.adminColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.15),
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text('About Page Management',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.1)),
      actions: [
        _statusChip(status),
        _HoverAppBarIcon(
          tooltip: 'View Live Page',
          icon: Icons.public_rounded,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
        ),
        _HoverAppBarIcon(
          tooltip: 'SEO',
          icon: Icons.search_rounded,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAboutSeoScreen())),
        ),
        _HoverAppBarIcon(
          tooltip: 'Version History',
          icon: Icons.history_rounded,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAboutVersionHistoryScreen()))
              .then((_) => _load()),
        ),
        _HoverAppBarIcon(
          tooltip: 'Preview',
          icon: Icons.visibility_outlined,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAboutPreviewScreen())),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) async {
            if (value == 'publish') await _publish();
            if (value == 'unpublish') await _unpublish();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'publish',
              child: Row(children: [
                Icon(Icons.cloud_upload_rounded, size: 18, color: Color(0xFF16A34A)),
                SizedBox(width: 10),
                Text('Publish'),
              ]),
            ),
            const PopupMenuItem(
              value: 'unpublish',
              child: Row(children: [
                Icon(Icons.cloud_off_rounded, size: 18, color: Colors.orange),
                SizedBox(width: 10),
                Text('Unpublish'),
              ]),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _statusChip(String status) {
    final isPublished = status == 'published';
    final dotColor = isPublished ? const Color(0xFF4ADE80) : const Color(0xFFFCD34D); // soft green / soft amber dot — reads fine on the red bar instead of another solid block of color fighting it
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(isPublished ? 'Published' : (status == 'unpublished' ? 'Unpublished' : 'Draft'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Future<void> _publish() async {
    final labelController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Publish About Page'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This makes all current draft changes live immediately.'),
            const SizedBox(height: 12),
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                  labelText: 'Version note (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _service.publish(label: labelController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] == true ? 'About page published.' : (result['error']?.toString() ?? 'Publish failed.')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16)));
    _load();
  }

  Future<void> _unpublish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Unpublish About Page?'),
        content: const Text('The public About page will show as not-available until you publish again. '
            'Your content and version history are kept.'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Unpublish')),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _service.unpublish();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] == true ? 'About page unpublished.' : (result['error']?.toString() ?? 'Failed.')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16)));
    _load();
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.adminColor, strokeWidth: 2.5));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 44, color: context.colors.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.colors.textSecondary)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 760 : double.infinity),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search sections by title, key, or type…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor: context.colors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.adminColor.withOpacity(0.4), width: 1.5),
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: _isSearching
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 13, color: context.colors.textSecondary),
                                const SizedBox(width: 5),
                                Text('Clear search to drag-and-drop reorder.',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color: context.colors.textSecondary,
                                        fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          color: AppColors.adminColor,
                          onRefresh: _load,
                          child: _isSearching
                              ? ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                  itemCount: _filtered.length,
                                  itemBuilder: (_, i) => _AnimatedEntry(
                                    index: i,
                                    child: _sectionCard(_filtered[i], reorderable: false, index: i),
                                  ),
                                )
                              : ReorderableListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                  itemCount: _sections.length,
                                  onReorder: _reorder,
                                  // ReorderableListView.builder adds its own
                                  // default drag-handle icon automatically unless
                                  // told not to — since this list already has a
                                  // custom drag handle (the dots on the left, via
                                  // ReorderableDragStartListener in _sectionCard),
                                  // Flutter's auto-added handle was rendering right
                                  // on top of the trailing expand/collapse chevron,
                                  // making the two icons look fused together.
                                  buildDefaultDragHandles: false,
                                  itemBuilder: (_, i) => _sectionCard(_sections[i], reorderable: true, index: i,
                                      key: ValueKey(_sections[i].id)),
                                ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.adminColor.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.dashboard_customize_outlined, size: 40, color: context.colors.textSecondary.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            Text(_isSearching ? 'No sections match your search.' : 'No sections yet.',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
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

// ═══════════════════════════════════════════════════════════════════════════════
//  Small shared UI helpers — presentation only, no logic
// ═══════════════════════════════════════════════════════════════════════════════

/// Fades + slides a list entry in on first build. Purely cosmetic — does not
/// alter widget identity/keys used for search-list rebuilding.
class _AnimatedEntry extends StatelessWidget {
  final int index;
  final Widget child;
  const _AnimatedEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 220 + (index.clamp(0, 6) * 25)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * 10), child: child),
      ),
      child: child,
    );
  }
}

/// AppBar icon button with a soft circular hover highlight on desktop/web.
class _HoverAppBarIcon extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HoverAppBarIcon({required this.icon, required this.tooltip, required this.onPressed});

  @override
  State<_HoverAppBarIcon> createState() => _HoverAppBarIconState();
}

class _HoverAppBarIconState extends State<_HoverAppBarIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: _hovering ? Colors.white.withOpacity(0.15) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: widget.tooltip,
          icon: Icon(widget.icon, color: Colors.white),
          onPressed: widget.onPressed,
        ),
      ),
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
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 14),  // was 10 — cards felt stuck together
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovering ? AppColors.adminColor.withOpacity(0.25) : context.colors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovering ? 0.07 : 0.04),
              blurRadius: _hovering ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                        child: MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Icon(Icons.drag_indicator_rounded, color: context.colors.textSecondary.withOpacity(0.5)),
                        ),
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
                    // The Material 3 Switch's ON-state thumb is nearly
                    // as tall as the track itself, and the old code never set
                    // activeTrackColor — it fell back to a pale tint of the
                    // same admin-red used for the thumb, so ON looked like one
                    // solid red blob instead of a track-with-a-circle (and
                    // that same blob then crowded the chevron next to it).
                    // Scaling the whole switch down + giving the track its
                    // own light tint (25% opacity) distinct from the solid
                    // thumb color fixes both the "merged" look AND leaves
                    // more physical space before the chevron.
                    Transform.scale(
                      scale: 0.82,
                      child: Switch(
                        value: s.isEnabled,
                        onChanged: (_) => widget.onToggle(),
                        thumbColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? AppColors.adminColor
                                : context.colors.textSecondary),
                        trackColor: WidgetStateProperty.resolveWith((states) =>
                            states.contains(WidgetState.selected)
                                ? AppColors.adminColor.withOpacity(0.22)
                                : context.colors.divider),
                        trackOutlineColor: WidgetStateProperty.all(context.colors.textSecondary.withOpacity(0.4)),
                        // Removes the invisible ~48dp tap-target box Switch
                        // reserves around its visible track by default —
                        // without this, spacing after it never actually grows
                        // on screen no matter how big the SizedBox is.
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),  // real breathing room now that the switch is shrink-wrapped + scaled down
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Icon(Icons.expand_more_rounded, color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _expanded
                  ? Padding(
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
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? AppColors.adminColor;
    return _HoverChip(color: c, onTap: onTap, icon: icon, label: label);
  }
}

/// Action chip with a subtle hover/press feedback for desktop and touch.
class _HoverChip extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HoverChip({required this.color, required this.icon, required this.label, required this.onTap});

  @override
  State<_HoverChip> createState() => _HoverChipState();
}

class _HoverChipState extends State<_HoverChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(_hovering ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.color.withOpacity(_hovering ? 0.25 : 0), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 14, color: widget.color),
                const SizedBox(width: 5),
                Text(widget.label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: widget.color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}