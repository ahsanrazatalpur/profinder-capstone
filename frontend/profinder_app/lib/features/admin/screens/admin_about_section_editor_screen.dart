// lib/features/admin/screens/admin_about_section_editor_screen.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/about_icons.dart';
import '../../../services/api_service.dart';
import '../../../services/about_page_service.dart';
import '../../../shared/widgets/about_image_picker_field.dart';
import '../../../shared/widgets/simple_rich_text_editor.dart';
import '../../about/models/about_page_model.dart';
import 'admin_about_page_screen.dart' show sectionTypeLabel, suggestIconKeyForType;

class AdminAboutSectionEditorScreen extends StatefulWidget {
  final AboutSection section;
  const AdminAboutSectionEditorScreen({super.key, required this.section});

  @override
  State<AdminAboutSectionEditorScreen> createState() => _AdminAboutSectionEditorScreenState();
}

class _AdminAboutSectionEditorScreenState extends State<AdminAboutSectionEditorScreen>
    with SingleTickerProviderStateMixin {
  final _service = AboutPageService();
  final _api = ApiService();

  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _ctaTextCtrl;
  late TextEditingController _ctaUrlCtrl;
  String _ctaStyle = 'primary';
  String _icon = '';
  String _imageUrl = '';
  late Map<String, dynamic> _extraData;

  bool _dirty = false;
  bool _saving = false;
  String? _error;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    final s = widget.section;
    _titleCtrl = TextEditingController(text: s.title)..addListener(_markDirty);
    _subtitleCtrl = TextEditingController(text: s.subtitle)..addListener(_markDirty);
    _descriptionCtrl = TextEditingController(text: s.description)..addListener(_markDirty);
    _ctaTextCtrl = TextEditingController(text: s.ctaText)..addListener(_markDirty);
    _ctaUrlCtrl = TextEditingController(text: s.ctaUrl)..addListener(_markDirty);
    _ctaStyle = s.ctaStyle;
    // If this section was created without an icon (e.g. an older section, or
    // one created before this feature), auto-fill a sensible default based
    // on its type instead of leaving the admin to hunt through the icon
    // grid. This only prefills the field locally — it's saved the next time
    // "Save" is pressed, same as any other edit, and can still be
    // overridden via the icon picker below.
    _icon = s.icon.isNotEmpty ? s.icon : (suggestIconKeyForType(s.sectionType) ?? '');
    if (_icon != s.icon) _dirty = true;
    _imageUrl = s.imageUrl;
    _extraData = Map<String, dynamic>.from(s.extraData);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _descriptionCtrl.dispose();
    _ctaTextCtrl.dispose();
    _ctaUrlCtrl.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    final result = await _service.updateSection(widget.section.id, {
      'title': _titleCtrl.text.trim(),
      'subtitle': _subtitleCtrl.text.trim(),
      'description': wrapPlainParagraphs(_descriptionCtrl.text),
      'icon': _icon,
      'cta_text': _ctaTextCtrl.text.trim(),
      'cta_url': _ctaUrlCtrl.text.trim(),
      'cta_style': _ctaStyle,
      'extra_data': _extraData,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.green.shade600,
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Section saved.'),
            ],
          ),
        ),
      );
    } else {
      setState(() => _error = result['error']?.toString() ?? 'Could not save section.');
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
        ),
        title: const Text('Unsaved Changes', textAlign: TextAlign.center),
        content: const Text('You have unsaved changes. Leave without saving?', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Editing')),
          FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickIcon() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380, maxHeight: 420),
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
                        return _HoverableIconTile(
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
    if (selected != null) setState(() { _icon = selected; _dirty = true; });
  }

  Future<void> _openTranslations() async {
    final result = await _api.get('/admin-panel/languages/');
    final languages = result.data is List ? List<dynamic>.from(result.data) : <dynamic>[];
    if (!mounted) return;
    if (languages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text('No languages configured yet — add one under Content Management → Languages.'),
              ),
            ],
          ),
        ),
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TranslationsSheet(section: widget.section, languages: languages),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          backgroundColor: AppColors.adminColor,
          elevation: 0,
          scrolledUnderElevation: 2,
          titleSpacing: 0,
          title: Text(sectionTypeLabel(widget.section.sectionType),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          actions: [
            _HoverIconButton(
              tooltip: 'Translations',
              icon: Icons.translate_rounded,
              onPressed: _openTranslations,
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _SaveButton(saving: _saving, onPressed: _saving ? null : _save),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final contentWidth = isWide ? 680.0 : constraints.maxWidth;
            return FadeTransition(
              opacity: _fadeIn,
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 0 : 16,
                      vertical: 18,
                    ),
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _error != null
                            ? Container(
                                key: ValueKey(_error),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(_error!,
                                          style: const TextStyle(color: Colors.red, fontSize: 12.5, height: 1.3)),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('no-error')),
                      ),

                      Row(
                        children: [
                          Icon(Icons.key_rounded, size: 14, color: context.colors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('Section key: ${widget.section.sectionKey}',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: context.colors.textSecondary,
                                    fontStyle: FontStyle.italic)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _SectionCard(
                        title: 'Content',
                        icon: Icons.article_outlined,
                        context: context,
                        children: [
                          _field(context, 'Title', _titleCtrl),
                          const SizedBox(height: 14),
                          _field(context, 'Subtitle', _subtitleCtrl),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _SectionCard(
                        title: 'Appearance',
                        icon: Icons.palette_outlined,
                        context: context,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _iconPickerField(context)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AboutImagePickerField(label: 'Image', imageUrl: _imageUrl, onChanged: (url) async {
                            setState(() { _imageUrl = url; _dirty = true; });
                            await _service.updateSection(widget.section.id, {'image': url});
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _SectionCard(
                        title: 'Rich Description',
                        icon: Icons.notes_rounded,
                        context: context,
                        children: [
                          SimpleRichTextEditor(controller: _descriptionCtrl, label: 'Rich Description'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _ctaFields(context),
                      const SizedBox(height: 16),

                      ..._typeSpecificFields(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _iconPickerField(BuildContext context) {
    return GestureDetector(
      onTap: _pickIcon,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Icon',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: context.colors.divider),
                borderRadius: BorderRadius.circular(12),
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
                    child: Text(
                      _icon.isEmpty ? 'Choose an icon…' : _icon,
                      style: TextStyle(
                        fontSize: 13,
                        color: _icon.isEmpty ? context.colors.textSecondary : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: context.colors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext context, String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.adminColor, width: 1.6),
        ),
      ),
    );
  }

  Widget _ctaFields(BuildContext context) {
    return _SectionCard(
      title: 'CTA Button',
      icon: Icons.smart_button_outlined,
      context: context,
      children: [
        _field(context, 'Button Text', _ctaTextCtrl),
        const SizedBox(height: 12),
        _field(context, 'Button URL', _ctaUrlCtrl),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _ctaStyle,
          decoration: InputDecoration(
            labelText: 'Style',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: const [
            DropdownMenuItem(value: 'primary', child: Text('Primary Button')),
            DropdownMenuItem(value: 'secondary', child: Text('Secondary Button')),
            DropdownMenuItem(value: 'link', child: Text('Text Link')),
          ],
          onChanged: (v) => setState(() { _ctaStyle = v!; _dirty = true; }),
        ),
      ],
    );
  }

  // ── Type-specific structured fields (backed by extra_data) ──────────────

  List<Widget> _typeSpecificFields(BuildContext context) {
    switch (widget.section.sectionType) {
      case 'contact_info':
        return [_structuredCard(context, 'Contact Details', Icons.contact_phone_outlined, [
          _extraField('phone', 'Phone'),
          _extraField('email', 'Email'),
          _extraField('address', 'Address'),
          _extraField('hours', 'Business Hours'),
        ])];
      case 'social_media':
        return [_structuredCard(context, 'Social Profiles', Icons.share_outlined, [
          _extraField('facebook', 'Facebook URL'),
          _extraField('instagram', 'Instagram URL'),
          _extraField('twitter', 'Twitter / X URL'),
          _extraField('linkedin', 'LinkedIn URL'),
          _extraField('youtube', 'YouTube URL'),
        ])];
      case 'app_info':
        return [_structuredCard(context, 'App Details', Icons.smartphone_outlined, [
          _extraField('play_store_url', 'Google Play URL'),
          _extraField('app_store_url', 'App Store URL'),
          _extraField('version', 'App Version'),
        ])];
      case 'legal_links':
        return [_legalLinksEditor(context)];
      default:
        return [];
    }
  }

  Widget _structuredCard(BuildContext context, String title, IconData icon, List<Widget> fields) {
    return _SectionCard(
      title: title,
      icon: icon,
      context: context,
      children: [
        for (final f in fields) Padding(padding: const EdgeInsets.only(bottom: 12), child: f),
      ],
    );
  }

  Widget _extraField(String key, String label) {
    final controller = TextEditingController(text: _extraData[key]?.toString() ?? '');
    return TextField(
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
      onChanged: (v) { _extraData[key] = v; _markDirty(); },
    );
  }

  Widget _legalLinksEditor(BuildContext context) {
    final links = List<Map<String, dynamic>>.from(
        (_extraData['links'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));

    return StatefulBuilder(
      builder: (context, setLocalState) {
        void syncBack() {
          _extraData['links'] = links;
          _markDirty();
          setLocalState(() {});
        }
        return _SectionCard(
          title: 'Legal Links',
          icon: Icons.gavel_rounded,
          context: context,
          headerTrailing: _HoverTextButton(
            icon: Icons.add_rounded,
            label: 'Add Link',
            onPressed: () { links.add({'label': '', 'url': ''}); syncBack(); },
          ),
          children: [
            if (links.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No links added yet.',
                  style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary, fontStyle: FontStyle.italic),
                ),
              ),
            for (var i = 0; i < links.length; i++)
              AnimatedContainer(
                key: ValueKey('legal-link-$i'),
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.colors.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: links[i]['label']?.toString() ?? ''),
                        decoration: InputDecoration(
                          labelText: 'Label',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (v) { links[i]['label'] = v; _extraData['links'] = links; _markDirty(); },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: links[i]['url']?.toString() ?? ''),
                        decoration: InputDecoration(
                          labelText: 'URL',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (v) { links[i]['url'] = v; _extraData['links'] = links; _markDirty(); },
                      ),
                    ),
                    const SizedBox(width: 4),
                    _HoverIconButton(
                      tooltip: 'Remove link',
                      icon: Icons.delete_outline_rounded,
                      color: Colors.red.shade400,
                      onPressed: () { links.removeAt(i); syncBack(); },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Shared presentational helpers (UI-only, no logic) ─────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final BuildContext context;
  final List<Widget> children;
  final Widget? headerTrailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.context,
    required this.children,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext buildContext) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.adminColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              if (headerTrailing != null) headerTrailing!,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback? onPressed;
  const _SaveButton({required this.saving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: saving
          ? const SizedBox(
              key: ValueKey('saving'),
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          : TextButton.icon(
              key: const ValueKey('save'),
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.save_outlined, size: 17, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
    );
  }
}

class _HoverIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  const _HoverIconButton({required this.tooltip, required this.icon, required this.onPressed, this.color});

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
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
          color: _hovering ? Colors.white.withOpacity(0.12) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: widget.tooltip,
          icon: Icon(widget.icon, color: widget.color ?? Colors.white),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}

class _HoverTextButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _HoverTextButton({required this.icon, required this.label, required this.onPressed});

  @override
  State<_HoverTextButton> createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<_HoverTextButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _hovering ? 0.75 : 1.0,
        child: TextButton.icon(
          onPressed: widget.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.adminColor,
            visualDensity: VisualDensity.compact,
          ),
          icon: Icon(widget.icon, size: 16),
          label: Text(widget.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _HoverableIconTile extends StatefulWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _HoverableIconTile({required this.icon, required this.selected, required this.onTap});

  @override
  State<_HoverableIconTile> createState() => _HoverableIconTileState();
}

class _HoverableIconTileState extends State<_HoverableIconTile> {
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

class _TranslationsSheet extends StatefulWidget {
  final AboutSection section;
  final List<dynamic> languages;
  const _TranslationsSheet({required this.section, required this.languages});

  @override
  State<_TranslationsSheet> createState() => _TranslationsSheetState();
}

class _TranslationsSheetState extends State<_TranslationsSheet> {
  final _service = AboutPageService();
  int? _selectedLanguageId;
  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _descriptionCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguageId = widget.languages.first['id'];
    _titleCtrl = TextEditingController();
    _subtitleCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();
  }

  Future<void> _save() async {
    if (_selectedLanguageId == null) return;
    setState(() => _saving = true);
    await _service.saveSectionTranslation(widget.section.id, _selectedLanguageId!, {
      'title': _titleCtrl.text.trim(),
      'subtitle': _subtitleCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.green.shade600,
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Translation saved.'),
          ],
        ),
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
      child: Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
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
                const Icon(Icons.translate_rounded, size: 18, color: AppColors.adminColor),
                const SizedBox(width: 8),
                const Text('Translate Section', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _selectedLanguageId,
              decoration: InputDecoration(
                labelText: 'Language',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: widget.languages
                  .map((l) => DropdownMenuItem<int>(value: l['id'], child: Text('${l['name']} (${l['code']})')))
                  .toList(),
              onChanged: (v) => setState(() => _selectedLanguageId = v),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                  labelText: 'Title', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _subtitleCtrl,
              decoration: InputDecoration(
                  labelText: 'Subtitle', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                  labelText: 'Description', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.adminColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.save_outlined, size: 18),
                label: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Translation', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}