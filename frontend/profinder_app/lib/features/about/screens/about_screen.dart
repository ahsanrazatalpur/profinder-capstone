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

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../services/about_page_service.dart';
import '../models/about_page_model.dart';
import '../widgets/about_page_content.dart';
import '../../../l10n/generated/app_localizations.dart';

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
        _error = result['error'] as String? ?? AppLocalizations.of(context)!.aboutLoadError;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.aboutTitle,
          style: TextStyle(
            fontSize: isTablet ? 18.0 : 16.0,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: context.colors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(isDark, isTablet),
    );
  }

  Widget _buildBody(bool isDark, bool isTablet) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: AppColors.customerColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.aboutLoadingText,
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }
    if (_error != null || _data == null) {
      return _errorState(isDark, isTablet);
    }
    if (_data!.sections.isEmpty) {
      return _emptyState(isDark, isTablet);
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.customerColor,
      child: AboutPageContent(sections: _data!.sections),
    );
  }

  Widget _errorState(bool isDark, bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: 40,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _error ?? AppLocalizations.of(context)!.aboutLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: context.colors.textSecondary,
                letterSpacing: 0.2,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                AppLocalizations.of(context)!.tryAgainCta,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.customerColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark, bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: 40,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppLocalizations.of(context)!.aboutEmptyStateTitle,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.aboutEmptyStateMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 15 : 13.5,
                color: context.colors.textSecondary,
                letterSpacing: 0.2,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}