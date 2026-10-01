// lib/features/admin/screens/admin_about_seo_screen.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../services/about_page_service.dart';
import '../../../shared/widgets/about_image_picker_field.dart';
import '../../../shared/widgets/universal_app_bar.dart';

class AdminAboutSeoScreen extends StatefulWidget {
  const AdminAboutSeoScreen({super.key});

  @override
  State<AdminAboutSeoScreen> createState() => _AdminAboutSeoScreenState();
}

class _AdminAboutSeoScreenState extends State<AdminAboutSeoScreen> with SingleTickerProviderStateMixin {
  final _service = AboutPageService();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();
  String _ogImageUrl = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeIn = CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _keywordsCtrl.dispose();
    _entranceController.dispose();
    super.dispose();
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
    _entranceController.forward();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.green.shade600,
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('SEO settings saved.'),
            ],
          ),
        ),
      );
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
      appBar: UniversalAppBar(
        title: 'SEO Settings',
        icon: Icons.search_rounded,
        actions: [
          _SaveButton(saving: _saving, onPressed: _saving ? null : _save),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                final contentWidth = isWide ? 680.0 : constraints.maxWidth;
                return FadeTransition(
                  opacity: _fadeIn,
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: ListView(
                        padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 16, vertical: 18),
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

                          _SectionCard(
                            title: 'Meta Information',
                            icon: Icons.search_rounded,
                            children: [
                              _seoField(
                                controller: _titleCtrl,
                                label: 'Meta Title',
                                recommended: 60,
                              ),
                              const SizedBox(height: 16),
                              _seoField(
                                controller: _descriptionCtrl,
                                label: 'Meta Description',
                                maxLines: 3,
                                recommended: 160,
                              ),
                              const SizedBox(height: 16),
                              _seoField(
                                controller: _keywordsCtrl,
                                label: 'Meta Keywords (comma-separated)',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _SectionCard(
                            title: 'Open Graph',
                            icon: Icons.image_outlined,
                            children: [
                              AboutImagePickerField(
                                label: 'Open Graph Image',
                                imageUrl: _ogImageUrl,
                                onChanged: _onOgImageChanged,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _seoField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    int? recommended,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final length = value.text.length;
        final overRecommended = recommended != null && length > recommended;
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
            helperText: recommended != null
                ? '$length characters · recommended up to $recommended'
                : null,
            helperStyle: TextStyle(
              fontSize: 11,
              color: overRecommended ? Colors.orange.shade700 : context.colors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.adminColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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