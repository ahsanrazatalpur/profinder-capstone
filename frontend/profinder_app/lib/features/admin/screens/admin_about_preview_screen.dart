// lib/features/admin/screens/admin_about_preview_screen.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../services/about_page_service.dart';
import '../../about/models/about_page_model.dart';
import '../../about/widgets/about_page_content.dart';

class AdminAboutPreviewScreen extends StatefulWidget {
  const AdminAboutPreviewScreen({super.key});

  @override
  State<AdminAboutPreviewScreen> createState() => _AdminAboutPreviewScreenState();
}

class _AdminAboutPreviewScreenState extends State<AdminAboutPreviewScreen> {
  final _service = AboutPageService();
  bool _loading = true;
  bool _includeDisabled = true;
  AboutPageData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getPreview(includeDisabled: _includeDisabled);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _data = result['data'] as AboutPageData;
        _error = null;
      } else {
        _error = result['error']?.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        title: const Text('Preview (Draft)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          Row(
            children: [
              const Text('Show disabled', style: TextStyle(fontSize: 11, color: Colors.white)),
              Switch(
                value: _includeDisabled,
                activeThumbColor: Colors.white,
                onChanged: (v) { setState(() => _includeDisabled = v); _load(); },
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: context.colors.textSecondary)))
              : (_data == null || _data!.sections.isEmpty)
                  ? Center(child: Text('Nothing to preview yet — add a section first.', style: TextStyle(color: context.colors.textSecondary)))
                  : Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF7A5B00)
                              : Colors.amber.shade100,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('This is a draft preview — not visible to the public until you Publish.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.amber.shade100
                                    : Colors.black87,
                              )),
                        ),
                        Expanded(child: AboutPageContent(sections: _data!.sections, showDisabledBadge: _includeDisabled)),
                      ],
                    ),
    );
  }
}