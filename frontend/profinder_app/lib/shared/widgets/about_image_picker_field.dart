// lib/shared/widgets/about_image_picker_field.dart
//
// Upload / preview / replace / delete for a single image field — used by
// the About Page section editor and item editor. Upload goes through
// AboutPageService.uploadImage, which already returns an optimized
// (WebP/auto-quality) Cloudinary URL, so nothing extra is needed here.

import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;

import '../../core/theme/theme_context_ext.dart';
import '../../services/about_page_service.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/generated/app_localizations.dart';

class AboutImagePickerField extends StatefulWidget {
  final String label;
  final String imageUrl;
  final ValueChanged<String> onChanged;
  final double height;

  const AboutImagePickerField({
    super.key,
    required this.label,
    required this.imageUrl,
    required this.onChanged,
    this.height = 190,
  });

  @override
  State<AboutImagePickerField> createState() => _AboutImagePickerFieldState();
}

class _AboutImagePickerFieldState extends State<AboutImagePickerField> {
  final _picker = ImagePicker();
  final _service = AboutPageService();
  bool _uploading = false;
  String? _error;

  Future<void> _pick() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() { _uploading = true; _error = null; });
    try {
      dio.MultipartFile multipart;
      if (kIsWeb) {
        final Uint8List bytes = await picked.readAsBytes();
        multipart = dio.MultipartFile.fromBytes(bytes, filename: picked.name);
      } else {
        multipart = await dio.MultipartFile.fromFile(picked.path, filename: picked.name);
      }
      final result = await _service.uploadImage(multipart);
      if (!mounted) return;
      setState(() => _uploading = false);
      if (result['success'] == true) {
        widget.onChanged(result['url'] as String);
      } else {
        setState(() => _error = result['error']?.toString() ?? AppLocalizations.of(context).uploadError);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _uploading = false; _error = AppLocalizations.of(context).uploadFailedTryAgain; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: TextStyle(fontSize: AppFontSizes.secondary, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: context.colors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.imageUrl.isNotEmpty)
                Container(
                  color: context.colors.background,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl, fit: BoxFit.contain,
                    errorWidget: (_, _, _) => Icon(Icons.broken_image_outlined, color: context.colors.textSecondary),
                  ),
                )
              else
                Center(
                  child: Icon(Icons.image_outlined, size: 32, color: context.colors.textSecondary.withValues(alpha: 0.5)),
                ),
              if (_uploading)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              Positioned(
                right: 8, bottom: 8,
                child: Row(
                  children: [
                    _roundIconButton(Icons.upload_rounded, widget.imageUrl.isEmpty ? 'Upload' : 'Replace', _pick),
                    if (widget.imageUrl.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _roundIconButton(Icons.delete_outline_rounded, 'Remove', () => widget.onChanged('')),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!, style: const TextStyle(fontSize: AppFontSizes.small, color: Colors.red)),
        ],
      ],
    );
  }

  Widget _roundIconButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: _uploading ? null : onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusChip),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}