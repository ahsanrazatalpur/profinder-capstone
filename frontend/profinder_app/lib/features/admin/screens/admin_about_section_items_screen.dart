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
import 'admin_about_page_screen.dart' show suggestIconKeyForType;

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
    // Same optimistic-update fix as the sections list — instant switch flip
    // instead of waiting for the slow backend round-trip, with revert +
    // error SnackBar on failure.
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) return;
    final newValue = !item.isEnabled;
    setState(() => _items[index] = item.copyWith(isEnabled: newValue));

    final result = await _service.updateItem(item.id, {'is_enabled': newValue});
    if (!mounted) return;
    if (result['success'] != true) {
      setState(() => _items[index] = item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(result['error']?.toString() ?? 'Could not update item.')),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _delete(AboutSectionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 26),
        ),
        title: const Text('Delete Item?', textAlign: TextAlign.center),
        content: Text('"${item.title}" will be permanently deleted.', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
      backgroundColor: Colors.transparent,
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
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Text('Items — $label',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'about_page_add_item_fab',
        backgroundColor: AppColors.adminColor,
        elevation: 2,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _loading
            ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
            : _items.isEmpty
                ? _emptyState(context)
                : _itemsList(context),
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
              decoration: BoxDecoration(
                color: AppColors.adminColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_outlined, size: 36, color: AppColors.adminColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            Text(
              'No items yet. Tap "Add Item" to add your first one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemsList(BuildContext context) {
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
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: _items.length,
                onReorder: _reorder,
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      final t = Curves.easeOut.transform(animation.value);
                      return Transform.scale(
                        scale: 1.0 + (0.02 * t),
                        child: Material(
                          elevation: 6 * t,
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.transparent,
                          child: child,
                        ),
                      );
                    },
                  );
                },
                itemBuilder: (_, i) => _itemCard(_items[i], i),
              ),
            ),
          ),
        );
      },
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Icon(Icons.drag_indicator_rounded, color: context.colors.textSecondary.withOpacity(0.5)),
            ),
          ),
          const SizedBox(width: 10),
          if (item.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 40,
                    height: 40,
                    color: context.colors.divider.withOpacity(0.3),
                    child: const Center(
                      child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.adminColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(resolveAboutIcon(item.icon), color: AppColors.adminColor, size: 18),
                ),
              ),
            )
          else
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.adminColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(resolveAboutIcon(item.icon), color: AppColors.adminColor, size: 18),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title.isEmpty ? '(untitled)' : item.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                if (item.subtitle.isNotEmpty || item.value.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.value.isNotEmpty ? item.value : item.subtitle,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          Switch(
            value: item.isEnabled,
            onChanged: (_) => _toggleEnabled(item),
            activeThumbColor: AppColors.adminColor,
            inactiveThumbColor: context.colors.textSecondary,
            inactiveTrackColor: context.colors.divider,
            trackOutlineColor: WidgetStateProperty.all(context.colors.textSecondary.withOpacity(0.4)),
          ),
          _hoverIcon(
            icon: Icons.edit_outlined,
            tooltip: 'Edit item',
            onPressed: () => _openEditor(item: item),
          ),
          _hoverIcon(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete item',
            color: Colors.red,
            onPressed: () => _delete(item),
          ),
        ],
      ),
    );
  }

  Widget _hoverIcon({required IconData icon, required String tooltip, required VoidCallback onPressed, Color? color}) {
    return _HoverIconAction(icon: icon, tooltip: tooltip, onPressed: onPressed, color: color);
  }
}

class _HoverIconAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  const _HoverIconAction({required this.icon, required this.tooltip, required this.onPressed, this.color});

  @override
  State<_HoverIconAction> createState() => _HoverIconActionState();
}

class _HoverIconActionState extends State<_HoverIconAction> {
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
          color: _hovering ? (widget.color ?? AppColors.adminColor).withOpacity(0.08) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: widget.tooltip,
          icon: Icon(widget.icon, size: 19, color: widget.color),
          onPressed: widget.onPressed,
        ),
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
    // New items get an icon auto-suggested from the parent section's type
    // (e.g. Team Members → a person/people icon) so the admin doesn't have
    // to open the icon grid for every single card. Existing items keep
    // whatever icon they already have; the picker below still lets anyone
    // override the suggestion.
    _icon = i?.icon ?? (suggestIconKeyForType(widget.sectionType) ?? '');
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
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.adminColor, width: 1.6),
          ),
        ),
        onChanged: (v) => _extraData[key] = v,
      ),
    );
  }

  bool get _showValueField => widget.sectionType == 'statistics';
  bool get _showLinkField => ['investors_partners', 'certifications', 'awards', 'team_members'].contains(widget.sectionType);

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.adminColor, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(_isEdit ? Icons.edit_outlined : Icons.add_circle_outline_rounded,
                          size: 18, color: AppColors.adminColor),
                      const SizedBox(width: 8),
                      Text(_isEdit ? 'Edit Item' : 'Add Item',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _error != null
                        ? Container(
                            key: ValueKey(_error),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withOpacity(0.25)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-error')),
                  ),
                  TextField(controller: _titleCtrl, decoration: _decoration('Title')),
                  const SizedBox(height: 12),
                  if (_showValueField) ...[
                    TextField(controller: _valueCtrl, decoration: _decoration('Number / Value')),
                    const SizedBox(height: 12),
                  ] else ...[
                    TextField(controller: _subtitleCtrl, decoration: _decoration('Subtitle')),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: _descriptionCtrl, maxLines: 3, decoration: _decoration('Description')),
                  const SizedBox(height: 12),
                  if (_showLinkField) ...[
                    TextField(controller: _linkUrlCtrl, decoration: _decoration('Link URL')),
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.adminColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _saving
                              ? const SizedBox.shrink()
                              : const Icon(Icons.check_rounded, size: 18),
                          label: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconPicker() {
    return GestureDetector(
      onTap: () async {
        final selected = await showDialog<String>(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360, maxHeight: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Choose Icon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        child: GridView.count(
                          crossAxisCount: 6,
                          shrinkWrap: true,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          physics: const NeverScrollableScrollPhysics(),
                          children: kAboutIconMap.entries.map((e) {
                            final selectedNow = e.key == _icon;
                            return _HoverableIconChoice(
                              icon: e.value,
                              selected: selectedNow,
                              onTap: () => Navigator.pop(ctx, e.key),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        if (selected != null) setState(() => _icon = selected);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.adminColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(resolveAboutIcon(_icon), size: 18, color: AppColors.adminColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_icon.isEmpty ? 'Choose Icon…' : _icon,
                    style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: Theme.of(context).dividerColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverableIconChoice extends StatefulWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _HoverableIconChoice({required this.icon, required this.selected, required this.onTap});

  @override
  State<_HoverableIconChoice> createState() => _HoverableIconChoiceState();
}

class _HoverableIconChoiceState extends State<_HoverableIconChoice> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.adminColor.withOpacity(0.15)
                : (_hovering ? AppColors.adminColor.withOpacity(0.06) : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: widget.selected ? Border.all(color: AppColors.adminColor) : null,
          ),
          child: Icon(widget.icon, size: 20),
        ),
      ),
    );
  }
}