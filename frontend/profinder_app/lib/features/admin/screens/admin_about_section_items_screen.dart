// lib/features/admin/screens/admin_about_section_items_screen.dart
//
// Manages the unlimited AboutSectionItem rows under one collection-type
// AboutSection (Why Choose Us cards, How It Works steps, Statistics
// counters, Core Values, Team Members, Investors & Partners,
// Certifications, Awards). One screen handles all eight — the extra
// fields shown in the edit dialog just change based on section_type.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/about_icons.dart';
import '../../../services/about_page_service.dart';
import '../../../shared/widgets/about_image_picker_field.dart';
import '../../about/models/about_page_model.dart';

class AdminAboutSectionItemsScreen extends StatefulWidget {
  final AboutSection section;
  const AdminAboutSectionItemsScreen({super.key, required this.section});

  @override
  State<AdminAboutSectionItemsScreen> createState() => _AdminAboutSectionItemsScreenState();
}

class _AdminAboutSectionItemsScreenState extends State<AdminAboutSectionItemsScreen> {
  final _service = AboutPageService();
  bool _loading = true;
  List<AboutSectionItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getSectionItems(widget.section.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _items = List<AboutSectionItem>.from(result['data']);
        _items.sort((a, b) => a.order.compareTo(b.order));
      }
    });
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    final order = [for (var i = 0; i < _items.length; i++) {'id': _items[i].id, 'order': i}];
    await _service.reorderItems(widget.section.id, order);
  }

  Future<void> _toggleEnabled(AboutSectionItem item) async {
    final result = await _service.updateItem(item.id, {'is_enabled': !item.isEnabled});
    if (result['success'] == true) _load();
  }

  Future<void> _delete(AboutSectionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('"${item.title}" will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _service.deleteItem(item.id);
    if (result['success'] == true) _load();
  }

  Future<void> _openEditor({AboutSectionItem? item}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemEditorSheet(
        sectionType: widget.section.sectionType,
        sectionId: widget.section.id,
        item: item,
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.section.title.isNotEmpty ? widget.section.title : widget.section.sectionKey;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        title: Text('Items — $label', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'about_page_add_item_fab',
        backgroundColor: AppColors.adminColor,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text('No items yet. Tap "Add Item" to add your first one.',
                      style: TextStyle(color: context.colors.textSecondary)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: _items.length,
                    onReorder: _reorder,
                    itemBuilder: (_, i) => _itemCard(_items[i], i),
                  ),
                ),
    );
  }

  Widget _itemCard(AboutSectionItem item, int index) {
    return Container(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(index: index,
              child: Icon(Icons.drag_indicator_rounded, color: context.colors.textSecondary.withOpacity(0.5))),
          const SizedBox(width: 10),
          if (item.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(item.imageUrl, width: 40, height: 40, fit: BoxFit.cover),
            )
          else
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.adminColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(resolveAboutIcon(item.icon), color: AppColors.adminColor, size: 18),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title.isEmpty ? '(untitled)' : item.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                if (item.subtitle.isNotEmpty || item.value.isNotEmpty)
                  Text(item.value.isNotEmpty ? item.value : item.subtitle,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary)),
              ],
            ),
          ),
          Switch(value: item.isEnabled, onChanged: (_) => _toggleEnabled(item), activeThumbColor: AppColors.adminColor),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 19), onPressed: () => _openEditor(item: item)),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Colors.red), onPressed: () => _delete(item)),
        ],
      ),
    );
  }
}

class _ItemEditorSheet extends StatefulWidget {
  final String sectionType;
  final int sectionId;
  final AboutSectionItem? item;
  const _ItemEditorSheet({required this.sectionType, required this.sectionId, this.item});

  @override
  State<_ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<_ItemEditorSheet> {
  final _service = AboutPageService();
  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _linkUrlCtrl;
  String _icon = '';
  String _imageUrl = '';
  late Map<String, dynamic> _extraData;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _titleCtrl = TextEditingController(text: i?.title ?? '');
    _subtitleCtrl = TextEditingController(text: i?.subtitle ?? '');
    _descriptionCtrl = TextEditingController(text: i?.description ?? '');
    _valueCtrl = TextEditingController(text: i?.value ?? '');
    _linkUrlCtrl = TextEditingController(text: i?.linkUrl ?? '');
    _icon = i?.icon ?? '';
    _imageUrl = i?.imageUrl ?? '';
    _extraData = Map<String, dynamic>.from(i?.extraData ?? {});
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    final data = {
      'title': _titleCtrl.text.trim(),
      'subtitle': _subtitleCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'icon': _icon,
      'value': _valueCtrl.text.trim(),
      'link_url': _linkUrlCtrl.text.trim(),
      'extra_data': _extraData,
    };
    final result = _isEdit
        ? await _service.updateItem(widget.item!.id, data)
        : await _service.createItem(widget.sectionId, data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = result['error']?.toString() ?? 'Could not save item.');
    }
  }

  List<Widget> _extraFieldsForType() {
    switch (widget.sectionType) {
      case 'team_members':
        return [_extraField('designation', 'Designation / Role'),
                _extraField('linkedin', 'LinkedIn URL')];
      case 'awards':
        return [_extraField('year', 'Year'), _extraField('issuer', 'Issued By')];
      case 'certifications':
        return [_extraField('issued_date', 'Issued Date'),
                _extraField('expiry_date', 'Expiry Date'),
                _extraField('credential_id', 'Credential ID')];
      case 'statistics':
        return [_extraField('suffix', 'Suffix (e.g. "+", "K", "%")')];
      default:
        return [];
    }
  }

  Widget _extraField(String key, String label) {
    final controller = TextEditingController(text: _extraData[key]?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        onChanged: (v) => _extraData[key] = v,
      ),
    );
  }

  bool get _showValueField => widget.sectionType == 'statistics';
  bool get _showLinkField => ['investors_partners', 'certifications', 'awards', 'team_members'].contains(widget.sectionType);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? 'Edit Item' : 'Add Item', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              const SizedBox(height: 8),
            ],
            TextField(controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 12),
            if (_showValueField) ...[
              TextField(controller: _valueCtrl,
                  decoration: const InputDecoration(labelText: 'Number / Value', border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 12),
            ] else ...[
              TextField(controller: _subtitleCtrl,
                  decoration: const InputDecoration(labelText: 'Subtitle', border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 12),
            ],
            TextField(controller: _descriptionCtrl, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 12),
            if (_showLinkField) ...[
              TextField(controller: _linkUrlCtrl,
                  decoration: const InputDecoration(labelText: 'Link URL', border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 12),
            ],
            ..._extraFieldsForType(),
            Row(
              children: [
                Expanded(child: _iconPicker()),
              ],
            ),
            const SizedBox(height: 14),
            AboutImagePickerField(label: 'Image', imageUrl: _imageUrl, height: 110, onChanged: (url) => setState(() => _imageUrl = url)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.adminColor),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconPicker() {
    return GestureDetector(
      onTap: () async {
        final selected = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Choose Icon'),
            content: SizedBox(
              width: 300,
              child: GridView.count(
                crossAxisCount: 6,
                shrinkWrap: true,
                children: kAboutIconMap.entries
                    .map((e) => InkWell(onTap: () => Navigator.pop(ctx, e.key), child: Icon(e.value, size: 20)))
                    .toList(),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
          ),
        );
        if (selected != null) setState(() => _icon = selected);
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(resolveAboutIcon(_icon)), const SizedBox(width: 8), Text(_icon.isEmpty ? 'Choose Icon…' : _icon, style: const TextStyle(fontSize: 12))],
        ),
      ),
    );
  }
}