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
    this.height = 140,
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
        setState(() => _error = result['error']?.toString() ?? 'Upload failed.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _uploading = false; _error = 'Upload failed. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.colors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: widget.imageUrl, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Icon(Icons.broken_image_outlined, color: context.colors.textSecondary),
                )
              else
                Center(
                  child: Icon(Icons.image_outlined, size: 32, color: context.colors.textSecondary.withOpacity(0.5)),
                ),
              if (_uploading)
                Container(
                  color: Colors.black.withOpacity(0.35),
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
          Text(_error!, style: const TextStyle(fontSize: 11.5, color: Colors.red)),
        ],
      ],
    );
  }

  Widget _roundIconButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: _uploading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}