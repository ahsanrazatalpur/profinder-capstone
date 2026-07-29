// lib/features/admin/screens/admin_about_seo_screen.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../services/about_page_service.dart';
import '../../../shared/widgets/about_image_picker_field.dart';

class AdminAboutSeoScreen extends StatefulWidget {
  const AdminAboutSeoScreen({super.key});

  @override
  State<AdminAboutSeoScreen> createState() => _AdminAboutSeoScreenState();
}

class _AdminAboutSeoScreenState extends State<AdminAboutSeoScreen> {
  final _service = AboutPageService();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();
  String _ogImageUrl = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _service.getSeo();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true && result['data'] != null) {
        final d = result['data'];
        _titleCtrl.text = d['meta_title'] ?? '';
        _descriptionCtrl.text = d['meta_description'] ?? '';
        _keywordsCtrl.text = d['meta_keywords'] ?? '';
        _ogImageUrl = d['og_image_url'] ?? '';
      }
    });
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    final result = await _service.updateSeo({
      'meta_title': _titleCtrl.text.trim(),
      'meta_description': _descriptionCtrl.text.trim(),
      'meta_keywords': _keywordsCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SEO settings saved.')));
    } else {
      setState(() => _error = result['error']?.toString() ?? 'Could not save.');
    }
  }

  Future<void> _onOgImageChanged(String url) async {
    setState(() => _ogImageUrl = url);
    await _service.updateSeo({'og_image': url});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        title: const Text('SEO Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Meta Title', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Meta Description', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _keywordsCtrl,
                  decoration: const InputDecoration(labelText: 'Meta Keywords (comma-separated)', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 16),
                AboutImagePickerField(label: 'Open Graph Image', imageUrl: _ogImageUrl, onChanged: _onOgImageChanged),
              ],
            ),
    );
  }
}