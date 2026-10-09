// lib/features/admin/widgets/content_translations_editor.dart
//
// Shared admin UI for ContentTranslation (announcements, promo banners,
// categories, subcategories, notification broadcasts).
//
//   • showContentTranslationsSheet()  → "Translations" bottom sheet for an
//     EXISTING row (saves with PUT per language).
//   • ContentTranslationsSection      → collapsible "Translations (optional)"
//     block for CREATE forms; the screen reads `controller.payload` and sends
//     it as `translations` in the POST body ({ "ur": {"title": .., ...} }).
//   • TranslationsButton              → small button for list cards, with a
//     count of languages already translated.
//
// Backend:
//   GET    /api/admin-panel/languages/
//   PUT    /api/admin-panel/translations/<label>/<object_id>/<language_id>/
//          { "<field>": "text", ... }   (empty string removes that field)
//   Existing rows come with `translations`:
//          [{ language: <id>, language_code: 'ur', <field>: '...' }, ...]
//
// English is the base text on the row itself, so it is never listed here.
// An empty translation field simply falls back to English in the app.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class TranslatableField {
  final String key;
  final String label;
  final bool multiline;
  const TranslatableField(this.key, this.label, {this.multiline = false});
}

class TranslationLanguage {
  final int id;
  final String code;
  final String name;
  final bool isRtl;
  const TranslationLanguage({
    required this.id,
    required this.code,
    required this.name,
    required this.isRtl,
  });

  factory TranslationLanguage.fromJson(Map<String, dynamic> j) => TranslationLanguage(
        id: (j['id'] as num).toInt(),
        code: (j['code']?.toString() ?? '').trim().toLowerCase(),
        name: j['name']?.toString() ?? '',
        isRtl: j['is_rtl'] == true,
      );
}

/// Languages an admin can translate into (everything except English).
class TranslationLanguages {
  static List<TranslationLanguage>? _cache;

  static Future<List<TranslationLanguage>> load(ApiService api, {bool force = false}) async {
    if (!force && _cache != null) return _cache!;
    final r = await api.get('/admin-panel/languages/');
    final raw = r.data is List ? List<dynamic>.from(r.data as List) : <dynamic>[];
    final out = <TranslationLanguage>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final lang = TranslationLanguage.fromJson(Map<String, dynamic>.from(item));
      final base = lang.code.split(RegExp(r'[-_]')).first;
      if (lang.code.isEmpty || base == 'en') continue;
      out.add(lang);
    }
    _cache = out;
    return out;
  }
}

/// Holds { languageCode: { field: text } } while the admin types.
class TranslationsFormController {
  final Map<String, Map<String, String>> _values = {};

  void set(String code, String field, String text) {
    (_values[code] ??= <String, String>{})[field] = text;
  }

  String get(String code, String field) => _values[code]?[field] ?? '';

  /// Seeds from a row's `translations` list (admin read path).
  void seedFrom(List<dynamic>? translations, List<TranslatableField> fields) {
    if (translations == null) return;
    for (final t in translations) {
      if (t is! Map) continue;
      final code = (t['language_code']?.toString() ?? '').toLowerCase();
      if (code.isEmpty) continue;
      for (final f in fields) {
        final v = t[f.key]?.toString() ?? '';
        if (v.isNotEmpty) set(code, f.key, v);
      }
    }
  }

  /// Only non-empty values — exactly what the create endpoints accept.
  Map<String, Map<String, String>> get payload {
    final out = <String, Map<String, String>>{};
    _values.forEach((code, fields) {
      final kept = <String, String>{};
      fields.forEach((k, v) {
        if (v.trim().isNotEmpty) kept[k] = v.trim();
      });
      if (kept.isNotEmpty) out[code] = kept;
    });
    return out;
  }

  Map<String, String> fieldsFor(String code, List<TranslatableField> fields) =>
      {for (final f in fields) f.key: get(code, f.key).trim()};
}

/// How many languages already have at least one translated field on [item].
int countTranslations(dynamic item, List<TranslatableField> fields) {
  if (item is! Map || item['translations'] is! List) return 0;
  var n = 0;
  for (final t in item['translations'] as List) {
    if (t is! Map) continue;
    if (fields.any((f) => (t[f.key]?.toString() ?? '').trim().isNotEmpty)) n++;
  }
  return n;
}

// ── Editor (language chips + fields) ─────────────────────────────────────────

class ContentTranslationsEditor extends StatefulWidget {
  final List<TranslationLanguage> languages;
  final List<TranslatableField> fields;
  final TranslationsFormController controller;

  /// Optional English text per field, shown under each input as a reference.
  final Map<String, String>? baseValues;

  const ContentTranslationsEditor({
    super.key,
    required this.languages,
    required this.fields,
    required this.controller,
    this.baseValues,
  });

  @override
  State<ContentTranslationsEditor> createState() => _ContentTranslationsEditorState();
}

class _ContentTranslationsEditorState extends State<ContentTranslationsEditor> {
  final Map<String, TextEditingController> _ctrls = {};
  int _selected = 0;

  TextEditingController _ctrlFor(String code, String field) {
    return _ctrls.putIfAbsent('$code|$field', () {
      return TextEditingController(text: widget.controller.get(code, field));
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _filled(String code) =>
      widget.fields.any((f) => widget.controller.get(code, f.key).trim().isNotEmpty);

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.lightScaffold,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.adminColor, width: 1.4),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.languages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No other languages are set up yet. Add one under Languages first.',
          style: TextStyle(fontSize: 12.5, color: AppColors.grayDeep),
        ),
      );
    }
    if (_selected >= widget.languages.length) _selected = 0;
    final lang = widget.languages[_selected];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (var i = 0; i < widget.languages.length; i++)
              ChoiceChip(
                selected: i == _selected,
                showCheckmark: false,
                avatar: _filled(widget.languages[i].code)
                    ? Icon(Icons.check_circle_rounded,
                        size: 16,
                        color: i == _selected ? Colors.white : AppColors.success)
                    : null,
                label: Text(widget.languages[i].name),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: i == _selected ? Colors.white : AppColors.gray700,
                ),
                selectedColor: AppColors.adminColor,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.neutral200),
                onSelected: (_) => setState(() => _selected = i),
              ),
          ],
        ),
        const SizedBox(height: 14),
        for (final f in widget.fields) ...[
          TextField(
            // New key per language so each language keeps its own controller.
            key: ValueKey('${lang.code}|${f.key}'),
            controller: _ctrlFor(lang.code, f.key),
            textDirection: lang.isRtl ? TextDirection.rtl : TextDirection.ltr,
            minLines: f.multiline ? 3 : 1,
            maxLines: f.multiline ? 6 : 1,
            decoration: _decoration('${f.label} (${lang.name})'),
            onChanged: (v) {
              widget.controller.set(lang.code, f.key, v);
              setState(() {}); // refresh the "filled" tick on the chip
            },
          ),
          if ((widget.baseValues?[f.key] ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                'English: ${widget.baseValues![f.key]}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.neutral400),
              ),
            ),
          const SizedBox(height: 10),
        ],
        const Text(
          'Leave a field empty to show the English text in this language.',
          style: TextStyle(fontSize: 11.5, color: AppColors.grayDeep),
        ),
      ],
    );
  }
}

// ── Bottom sheet for an existing row ─────────────────────────────────────────

/// Returns true if anything was saved (so the caller can reload its list).
Future<bool> showContentTranslationsSheet(
  BuildContext context, {
  required String label,
  required int objectId,
  required String title,
  required List<TranslatableField> fields,
  List<dynamic>? existing,
  Map<String, String>? baseValues,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => _TranslationsSheet(
      label: label,
      objectId: objectId,
      title: title,
      fields: fields,
      existing: existing,
      baseValues: baseValues,
    ),
  );
  return saved == true;
}

class _TranslationsSheet extends StatefulWidget {
  final String label;
  final int objectId;
  final String title;
  final List<TranslatableField> fields;
  final List<dynamic>? existing;
  final Map<String, String>? baseValues;

  const _TranslationsSheet({
    required this.label,
    required this.objectId,
    required this.title,
    required this.fields,
    this.existing,
    this.baseValues,
  });

  @override
  State<_TranslationsSheet> createState() => _TranslationsSheetState();
}

class _TranslationsSheetState extends State<_TranslationsSheet> {
  final _api = ApiService();
  final _controller = TranslationsFormController();
  final Map<String, Map<String, String>> _initial = {};

  List<TranslationLanguage> _languages = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.seedFrom(widget.existing, widget.fields);
    for (final t in widget.existing ?? const <dynamic>[]) {
      if (t is! Map) continue;
      final code = (t['language_code']?.toString() ?? '').toLowerCase();
      if (code.isEmpty) continue;
      _initial[code] = _controller.fieldsFor(code, widget.fields);
    }
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final langs = await TranslationLanguages.load(_api);
      if (!mounted) return;
      setState(() {
        _languages = langs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load languages.';
      });
    }
  }

  bool _sameFields(Map<String, String> a, Map<String, String> b) {
    for (final f in widget.fields) {
      if ((a[f.key] ?? '') != (b[f.key] ?? '')) return false;
    }
    return true;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    var changed = 0;
    final failed = <String>[];
    for (final lang in _languages) {
      final now = _controller.fieldsFor(lang.code, widget.fields);
      final before = _initial[lang.code] ?? {for (final f in widget.fields) f.key: ''};
      if (_sameFields(now, before)) continue;
      try {
        await _api.put(
          '/admin-panel/translations/${widget.label}/${widget.objectId}/${lang.id}/',
          now,
        );
        _initial[lang.code] = now;
        changed++;
      } catch (_) {
        failed.add(lang.name);
      }
    }
    if (!mounted) return;
    if (failed.isNotEmpty) {
      setState(() {
        _saving = false;
        _error = 'Could not save: ${failed.join(', ')}. Try again.';
      });
      return;
    }
    Navigator.pop(context, changed > 0);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.adminColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.translate_rounded, color: AppColors.adminColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Translations',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gray900)),
                    Text(widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.grayDeep)),
                  ],
                ),
              ),
              IconButton(
                onPressed: _saving ? null : () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : (_languages.isEmpty && _error != null)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_error!, style: const TextStyle(color: AppColors.error)),
                            TextButton(onPressed: _loadLanguages, child: const Text('Retry')),
                          ],
                        )
                      : ContentTranslationsEditor(
                          languages: _languages,
                          fields: widget.fields,
                          controller: _controller,
                          baseValues: widget.baseValues,
                        ),
            ),
          ),
          if (_error != null && _languages.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_loading || _saving || _languages.isEmpty) ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save translations',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Collapsible section for CREATE forms ─────────────────────────────────────

class ContentTranslationsSection extends StatefulWidget {
  final TranslationsFormController controller;
  final List<TranslatableField> fields;
  final String? helper;

  const ContentTranslationsSection({
    super.key,
    required this.controller,
    required this.fields,
    this.helper,
  });

  @override
  State<ContentTranslationsSection> createState() => _ContentTranslationsSectionState();
}

class _ContentTranslationsSectionState extends State<ContentTranslationsSection> {
  final _api = ApiService();
  List<TranslationLanguage>? _languages;
  bool _loading = false;
  String? _error;

  Future<void> _load() async {
    if (_languages != null || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final langs = await TranslationLanguages.load(_api);
      if (!mounted) return;
      setState(() {
        _languages = langs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load languages.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 4),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        leading: const Icon(Icons.translate_rounded, size: 18, color: AppColors.adminColor),
        title: const Text('Translations (optional)',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.gray900)),
        subtitle: Text(
          widget.helper ?? 'Add other languages now, or later from the list.',
          style: const TextStyle(fontSize: 11.5, color: AppColors.grayDeep),
        ),
        onExpansionChanged: (open) {
          if (open) _load();
        },
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Row(
              children: [
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12.5)),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            )
          else if (_languages != null)
            ContentTranslationsEditor(
              languages: _languages!,
              fields: widget.fields,
              controller: widget.controller,
            ),
        ],
      ),
    );
  }
}

// ── Button for list cards ────────────────────────────────────────────────────

class TranslationsButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;
  const TranslationsButton({super.key, required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Translations',
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.translate_rounded, size: 16),
        label: Text(count > 0 ? 'Translations ($count)' : 'Translations',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.adminColor,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}