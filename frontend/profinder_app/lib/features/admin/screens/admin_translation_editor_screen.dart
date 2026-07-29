// lib/features/admin/screens/admin_translation_editor_screen.dart
//
// Translation editor for one language — every TranslationKey paired with
// that language's current text. Also lets the admin add new translation
// keys to the master list (language-independent).
//
// Backend:
//   GET   /api/admin-panel/languages/<id>/translations/
//     → { language: {...}, rows: [{key_id, key, description, text}, ...] }
//   PATCH /api/admin-panel/languages/<id>/translations/
//     Body: { "translations": { "<key_id>": "translated text", ... } }
//   POST  /api/admin-panel/translation-keys/   { key, description }

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

class AdminTranslationEditorScreen extends StatefulWidget {
  final dynamic language;
  const AdminTranslationEditorScreen({super.key, required this.language});

  @override
  State<AdminTranslationEditorScreen> createState() => _AdminTranslationEditorScreenState();
}

class _AdminTranslationEditorScreenState extends State<AdminTranslationEditorScreen> {
  final _api        = ApiService();
  final _searchCtrl = TextEditingController();

  bool          _loading = true;
  bool          _saving  = false;
  String?       _error;
  List<dynamic> _rows      = [];
  List<dynamic> _filtered  = [];
  final Map<int, TextEditingController> _controllers = {};
  final Set<int> _dirtyKeyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.get('/admin-panel/languages/${widget.language['id']}/translations/');
      if (!mounted) return;

      final rows = r.data['rows'] is List ? List<dynamic>.from(r.data['rows']) : [];

      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
      _dirtyKeyIds.clear();

      for (final row in rows) {
        final keyId = row['key_id'] as int;
        _controllers[keyId] = TextEditingController(text: row['text']?.toString() ?? '');
      }

      setState(() {
        _loading = false;
        _rows     = rows;
      });
      _applySearch();
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load translations'; });
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List<dynamic>.from(_rows)
          : _rows.where((row) {
              return (row['key'] ?? '').toString().toLowerCase().contains(q) ||
                     (row['description'] ?? '').toString().toLowerCase().contains(q);
            }).toList();
    });
  }

  // ── Save ──────────────────────────────────────────────────
  Future<void> _save() async {
    if (_dirtyKeyIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = <String, String>{
        for (final keyId in _dirtyKeyIds) keyId.toString(): _controllers[keyId]?.text ?? '',
      };
      final r = await _api.patch(
        '/admin-panel/languages/${widget.language['id']}/translations/',
        {'translations': payload},
      );
      if (!mounted) return;
      setState(() { _saving = false; _dirtyKeyIds.clear(); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.data['message']?.toString() ?? 'Translations saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save translations.')),
      );
    }
  }

  // ── Add new key ───────────────────────────────────────────
  void _addKeyDialog() {
    final keyCtrl  = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Translation Key',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(hintText: 'Key (e.g. home.welcome_title)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(hintText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              final key = keyCtrl.text.trim();
              if (key.isEmpty) return;
              Navigator.pop(dialogContext);
              try {
                await _api.post('/admin-panel/translation-keys/',
                    {'key': key, 'description': descCtrl.text.trim()});
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to add — key may already exist.')),
                );
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDiscard() async {
    if (_dirtyKeyIds.isEmpty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard changes?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('You have ${_dirtyKeyIds.length} unsaved translation(s).',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _dirtyKeyIds.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.adminColor,
          onPressed: _addKeyDialog,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add Key', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearch(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.adminColor, strokeWidth: 2.5))
                    : _error != null
                        ? _buildError()
                        : _filtered.isEmpty
                            ? _emptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) => _translationRow(_filtered[i]),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = widget.language['name']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.adminColor, Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () async {
              if (await _confirmDiscard() && mounted) Navigator.pop(context);
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Translate — $name',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('${_rows.length} keys · ${_dirtyKeyIds.length} unsaved',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ),
          if (_dirtyKeyIds.isNotEmpty)
            _saving
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  )
                : TextButton(
                    onPressed: _save,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => _applySearch(),
        decoration: InputDecoration(
          hintText: 'Search keys…',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _translationRow(dynamic row) {
    final keyId = row['key_id'] as int;
    final controller = _controllers[keyId]!;
    final isDirty = _dirtyKeyIds.contains(keyId);
    final isEmpty = controller.text.trim().isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDirty ? AppColors.adminColor.withOpacity(0.4) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(row['key']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
              ),
              if (isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Missing',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.error)),
                ),
            ],
          ),
          if ((row['description'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(row['description'].toString(),
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: null,
            onChanged: (_) => setState(() => _dirtyKeyIds.add(keyId)),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Translated text…',
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.translate_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Text('No translation keys yet',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 4),
                const Text('Tap "Add Key" to create the first one.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 10),
          const Text('Failed to load translations',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor),
          ),
        ],
      ),
    );
  }
}