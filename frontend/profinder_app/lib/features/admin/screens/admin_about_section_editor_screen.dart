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
import 'admin_about_page_screen.dart' show sectionTypeLabel;

class AdminAboutSectionEditorScreen extends StatefulWidget {
  final AboutSection section;
  const AdminAboutSectionEditorScreen({super.key, required this.section});

  @override
  State<AdminAboutSectionEditorScreen> createState() => _AdminAboutSectionEditorScreenState();
}

class _AdminAboutSectionEditorScreenState extends State<AdminAboutSectionEditorScreen> {
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
    _icon = s.icon;
    _imageUrl = s.imageUrl;
    _extraData = Map<String, dynamic>.from(s.extraData);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Section saved.')));
    } else {
      setState(() => _error = result['error']?.toString() ?? 'Could not save section.');
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Leave without saving?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Editing')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickIcon() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Icon'),
        content: SizedBox(
          width: 320,
          child: GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            children: kAboutIconMap.entries.map((e) {
              final selectedNow = e.key == _icon;
              return InkWell(
                onTap: () => Navigator.pop(ctx, e.key),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: selectedNow ? AppColors.adminColor.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: selectedNow ? Border.all(color: AppColors.adminColor) : null,
                  ),
                  child: Icon(e.value, size: 20),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
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
          const SnackBar(content: Text('No languages configured yet — add one under Content Management → Languages.')));
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
          title: Text(sectionTypeLabel(widget.section.sectionType),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          actions: [
            IconButton(
              tooltip: 'Translations',
              icon: const Icon(Icons.translate_rounded, color: Colors.white),
              onPressed: _openTranslations,
            ),
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
              ),
            ],
            Text('Section key: ${widget.section.sectionKey}',
                style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary, fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),

            _field('Title', _titleCtrl),
            const SizedBox(height: 14),
            _field('Subtitle', _subtitleCtrl),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickIcon,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Icon', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: context.colors.divider),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(resolveAboutIcon(_icon)),
                              const SizedBox(width: 8),
                              Text(_icon.isEmpty ? 'Choose…' : _icon, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            AboutImagePickerField(label: 'Image', imageUrl: _imageUrl, onChanged: (url) async {
              setState(() { _imageUrl = url; _dirty = true; });
              await _service.updateSection(widget.section.id, {'image': url});
            }),
            const SizedBox(height: 16),

            SimpleRichTextEditor(controller: _descriptionCtrl, label: 'Rich Description'),
            const SizedBox(height: 16),

            _ctaFields(),
            const SizedBox(height: 16),

            ..._typeSpecificFields(),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
    );
  }

  Widget _ctaFields() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CTA Button', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _field('Button Text', _ctaTextCtrl),
          const SizedBox(height: 10),
          _field('Button URL', _ctaUrlCtrl),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _ctaStyle,
            decoration: const InputDecoration(labelText: 'Style', border: OutlineInputBorder(), isDense: true),
            items: const [
              DropdownMenuItem(value: 'primary', child: Text('Primary Button')),
              DropdownMenuItem(value: 'secondary', child: Text('Secondary Button')),
              DropdownMenuItem(value: 'link', child: Text('Text Link')),
            ],
            onChanged: (v) => setState(() { _ctaStyle = v!; _dirty = true; }),
          ),
        ],
      ),
    );
  }

  // ── Type-specific structured fields (backed by extra_data) ──────────────

  List<Widget> _typeSpecificFields() {
    switch (widget.section.sectionType) {
      case 'contact_info':
        return [_structuredCard('Contact Details', [
          _extraField('phone', 'Phone'),
          _extraField('email', 'Email'),
          _extraField('address', 'Address'),
          _extraField('hours', 'Business Hours'),
        ])];
      case 'social_media':
        return [_structuredCard('Social Profiles', [
          _extraField('facebook', 'Facebook URL'),
          _extraField('instagram', 'Instagram URL'),
          _extraField('twitter', 'Twitter / X URL'),
          _extraField('linkedin', 'LinkedIn URL'),
          _extraField('youtube', 'YouTube URL'),
        ])];
      case 'app_info':
        return [_structuredCard('App Details', [
          _extraField('play_store_url', 'Google Play URL'),
          _extraField('app_store_url', 'App Store URL'),
          _extraField('version', 'App Version'),
        ])];
      case 'legal_links':
        return [_legalLinksEditor()];
      default:
        return [];
    }
  }

  Widget _structuredCard(String title, List<Widget> fields) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final f in fields) Padding(padding: const EdgeInsets.only(bottom: 10), child: f),
        ],
      ),
    );
  }

  Widget _extraField(String key, String label) {
    final controller = TextEditingController(text: _extraData[key]?.toString() ?? '');
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      onChanged: (v) { _extraData[key] = v; _markDirty(); },
    );
  }

  Widget _legalLinksEditor() {
    final links = List<Map<String, dynamic>>.from(
        (_extraData['links'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));

    return StatefulBuilder(
      builder: (context, setLocalState) {
        void syncBack() {
          _extraData['links'] = links;
          _markDirty();
          setLocalState(() {});
        }
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Legal Links', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
                  TextButton.icon(
                    onPressed: () { links.add({'label': '', 'url': ''}); syncBack(); },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Link'),
                  ),
                ],
              ),
              for (var i = 0; i < links.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: links[i]['label']?.toString() ?? ''),
                          decoration: const InputDecoration(labelText: 'Label', border: OutlineInputBorder(), isDense: true),
                          onChanged: (v) { links[i]['label'] = v; _extraData['links'] = links; _markDirty(); },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: links[i]['url']?.toString() ?? ''),
                          decoration: const InputDecoration(labelText: 'URL', border: OutlineInputBorder(), isDense: true),
                          onChanged: (v) { links[i]['url'] = v; _extraData['links'] = links; _markDirty(); },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () { links.removeAt(i); syncBack(); },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Translation saved.')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Translate Section', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _selectedLanguageId,
            decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder(), isDense: true),
            items: widget.languages
                .map((l) => DropdownMenuItem<int>(value: l['id'], child: Text('${l['name']} (${l['code']})')))
                .toList(),
            onChanged: (v) => setState(() => _selectedLanguageId = v),
          ),
          const SizedBox(height: 12),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          TextField(controller: _subtitleCtrl, decoration: const InputDecoration(labelText: 'Subtitle', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          TextField(controller: _descriptionCtrl, maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : const Text('Save Translation'),
            ),
          ),
        ],
      ),
    );
  }
}