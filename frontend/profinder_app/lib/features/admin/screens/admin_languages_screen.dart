// lib/features/admin/screens/admin_languages_screen.dart
//
// Content Management → Languages & Translations
// List all app languages with translation completion %, add a new
// language, change its status (beta/active/disabled — backend blocks
// activating a language until it's 100% translated), delete a language,
// and drill into the translation editor for a language.
//
// Backend:
//   GET   /api/admin-panel/languages/            → list, with completion_percentage
//   POST  /api/admin-panel/languages/              { name, code, is_rtl }
//   PATCH /api/admin-panel/languages/<id>/          { status }
//   DELETE /api/admin-panel/languages/<id>/

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import 'admin_translation_editor_screen.dart';
import '../../../core/theme/theme_context_ext.dart';

class AdminLanguagesScreen extends StatefulWidget {
  const AdminLanguagesScreen({super.key});

  @override
  State<AdminLanguagesScreen> createState() => _AdminLanguagesScreenState();
}

class _AdminLanguagesScreenState extends State<AdminLanguagesScreen> {
  final _api = ApiService();

  bool          _loading = true;
  String?       _error;
  List<dynamic> _languages = [];

  Map<String, Color> get _statusColors => {
    'active':   context.colors.accent,
    'beta':     const Color(0xFFF59E0B),
    'disabled': const Color(0xFF9CA3AF),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.get('/admin-panel/languages/');
      if (!mounted) return;
      setState(() {
        _loading   = false;
        _languages = r.data is List ? List<dynamic>.from(r.data) : [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Failed to load languages'; });
    }
  }

  // ── Add ───────────────────────────────────────────────────
  void _addDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    bool isRtl = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setSheetState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Language',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'Language name (e.g. Urdu)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(hintText: 'Code (e.g. ur)'),
              ),
              const SizedBox(height: 6),
              CheckboxListTile(
                value: isRtl,
                onChanged: (v) => setSheetState(() => isRtl = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Right-to-left (RTL)', style: TextStyle(fontSize: 13)),
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
                final name = nameCtrl.text.trim();
                final code = codeCtrl.text.trim();
                if (name.isEmpty || code.isEmpty) return;
                Navigator.pop(dialogContext);
                try {
                  await _api.post('/admin-panel/languages/',
                      {'name': name, 'code': code, 'is_rtl': isRtl});
                  _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add — code may already exist.')),
                  );
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Change status ─────────────────────────────────────────
  Future<void> _changeStatus(dynamic lang, String newStatus) async {
    try {
      await _api.patch('/admin-panel/languages/${lang['id']}/', {'status': newStatus});
      _load();
    } on DioException catch (e) {
      if (!mounted) return;
      final serverMsg = e.response?.data is Map ? e.response?.data['error']?.toString() : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(serverMsg ?? 'Failed to update status.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status.')),
      );
    }
  }

  void _statusSheet(dynamic lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Change status',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            for (final s in ['active', 'beta', 'disabled'])
              ListTile(
                leading: Icon(Icons.circle, size: 12, color: _statusColors[s]),
                title: Text(s == 'active' ? 'Active' : s == 'beta' ? 'Beta' : 'Disabled'),
                onTap: () {
                  Navigator.pop(context);
                  _changeStatus(lang, s);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────
  void _confirmDelete(dynamic lang) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete language?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently remove "${lang['name']}" and all its translations.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _api.delete('/admin-panel/languages/${lang['id']}/');
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete language.')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.adminColor,
        onPressed: _addDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Language',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.adminColor, strokeWidth: 2.5))
                  : _error != null
                      ? _buildError()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.adminColor,
                          child: _languages.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [_emptyState()],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                  itemCount: _languages.length,
                                  itemBuilder: (_, i) => _languageCard(_languages[i]),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final activeCount = _languages.where((l) => l['status'] == 'active').length;
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
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.translate_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Languages',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('$activeCount active · ${_languages.length} total',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageCard(dynamic lang) {
    final status  = (lang['status'] ?? 'beta').toString();
    final color   = _statusColors[status] ?? const Color(0xFF9CA3AF);
    final pct     = (lang['completion_percentage'] is num)
        ? (lang['completion_percentage'] as num).toDouble()
        : 0.0;
    final isRtl   = lang['is_rtl'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminTranslationEditorScreen(language: lang)),
        ).then((_) => _load()),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(lang['name']?.toString() ?? '',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Text('(${lang['code']})',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                        if (isRtl) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('RTL',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                                    color: Color(0xFF7C3AED))),
                          ),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _statusSheet(lang),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(lang['status_display']?.toString() ?? status,
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
                          const SizedBox(width: 2),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: color),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF3F4F6),
                        color: pct >= 100 ? context.colors.accent : AppColors.info,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${pct.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AdminTranslationEditorScreen(language: lang)),
                      ).then((_) => _load()),
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: const Text('Edit Translations', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                    onPressed: () => _confirmDelete(lang),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.translate_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text('No languages added yet',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 10),
          const Text('Failed to load languages',
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