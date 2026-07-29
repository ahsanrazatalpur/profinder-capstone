// lib/features/about/screens/about_screen.dart
//
// Public About page. No role check on this screen itself — every role
// (Guest, Customer, Professional, Admin) reaches it the same way, from
// their Profile/Settings menu, and sees the same read-only content.
// Editing only ever happens through the Admin Panel's About Page
// Management module, never here. Rendering itself lives in
// AboutPageContent so the admin Preview screen can reuse it byte-for-byte.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_context_ext.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../services/about_page_service.dart';
import '../models/about_page_model.dart';
import '../widgets/about_page_content.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _service = AboutPageService();

  bool _loading = true;
  String? _error;
  AboutPageData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final lang = context.read<LocaleProvider>().locale.languageCode;
    final result = await _service.getAboutPage(lang: lang);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _data = result['data'] as AboutPageData;
      } else {
        _error = result['error'] as String? ?? 'Could not load the About page.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text('About',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _data == null) {
      return _errorState();
    }
    if (_data!.sections.isEmpty) {
      return _emptyState();
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: AboutPageContent(sections: _data!.sections),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 40, color: context.colors.textSecondary),
            const SizedBox(height: 12),
            Text(_error ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: context.colors.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text("This page hasn't been published yet.",
          style: TextStyle(fontSize: 13.5, color: context.colors.textSecondary)),
    );
  }
}