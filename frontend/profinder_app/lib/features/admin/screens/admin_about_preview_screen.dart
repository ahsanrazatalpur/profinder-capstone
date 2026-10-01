// lib/features/admin/screens/admin_about_preview_screen.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../services/about_page_service.dart';
import '../../about/models/about_page_model.dart';
import '../../about/widgets/about_page_content.dart';
import '../../../shared/widgets/universal_app_bar.dart';

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
      appBar: UniversalAppBar(
        title: 'Preview (Draft)',
        icon: Icons.visibility_outlined,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_outlined, size: 15, color: Colors.white70),
                const SizedBox(width: 6),
                const Text('Show disabled', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w600)),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: _includeDisabled,
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.white.withOpacity(0.35),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) { setState(() => _includeDisabled = v); _load(); },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: AppColors.adminColor, strokeWidth: 2.5),
      );
    }

    if (_error != null) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 44, color: context.colors.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.colors.textSecondary)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_data == null || _data!.sections.isEmpty) {
      return Center(
        key: const ValueKey('empty'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.adminColor.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.visibility_off_outlined, size: 40, color: context.colors.textSecondary.withOpacity(0.6)),
              ),
              const SizedBox(height: 16),
              Text(
                'Nothing to preview yet — add a section first.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerBg = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
    final bannerFg = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);

    return Column(
      key: const ValueKey('content'),
      children: [
        Container(
          width: double.infinity,
          color: bannerBg,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: bannerFg),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'This is a draft preview — not visible to the public until you Publish.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: bannerFg, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
                  child: AboutPageContent(sections: _data!.sections, showDisabledBadge: _includeDisabled),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}