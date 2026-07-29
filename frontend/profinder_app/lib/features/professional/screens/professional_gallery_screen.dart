// lib/features/professional/screens/professional_gallery_screen.dart
//
// ⚠️ BACKEND NOTE: Uses `AppConstants.gallery` ('/profiles/gallery/').
// This is intentionally simpler than Portfolio — just images, no title,
// description, or admin approval flow. Add a lightweight Gallery model
// (image field only) with a CRUD viewset.

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';

class ProfessionalGalleryScreen extends StatefulWidget {
  const ProfessionalGalleryScreen({super.key});

  @override
  State<ProfessionalGalleryScreen> createState() => _ProfessionalGalleryScreenState();
}

class _ProfessionalGalleryScreenState extends State<ProfessionalGalleryScreen> {
  final _api    = ApiService();
  final _picker = ImagePicker();

  List<dynamic> _items     = [];
  bool          _isLoading = true;
  bool          _isUploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(AppConstants.gallery);
      if (!mounted) return;
      setState(() {
        _items     = res.data is List ? res.data as List : [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 900);
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      MultipartFile imgPart;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        imgPart = MultipartFile.fromBytes(bytes, filename: 'gallery.jpg');
      } else {
        imgPart = await MultipartFile.fromFile(picked.path, filename: 'gallery.jpg');
      }
      await _api.postForm(AppConstants.gallery, FormData.fromMap({'image': imgPart}));
      if (!mounted) return;
      AppHelpers.showSuccess(context, 'Photo added to gallery');
      _load();
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showError(context, 'Could not upload photo');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _delete(int id) async {
    try {
      await _api.delete('${AppConstants.gallery}$id/');
      if (!mounted) return;
      _load();
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showError(context, 'Could not delete photo');
    }
  }

  void _confirmDelete(dynamic item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Photo?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Text('This photo will be removed from your gallery.', style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () { Navigator.pop(context); _delete(item['id']); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text('Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.colors.textPrimary), onPressed: () => Navigator.pop(context)),
        actions: [
          _isUploading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : IconButton(
                  icon: Icon(Icons.add_photo_alternate_outlined, color: AppColors.professionalColor),
                  onPressed: _pickAndUpload,
                  tooltip: 'Add Photo',
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.professionalColor,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_outlined, size: 64, color: context.colors.textDisabled),
                              const SizedBox(height: 12),
                              Text('No photos yet', style: TextStyle(fontSize: 15, color: context.colors.textSecondary)),
                              const SizedBox(height: 6),
                              Text('Add photos to showcase your work environment', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _pickAndUpload,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add Photo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.professionalColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        final imageUrl = item['image_url']?.toString() ?? item['image']?.toString();
                        return GestureDetector(
                          onLongPress: () => _confirmDelete(item),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(imageUrl, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: context.colors.divider,
                                        child: Icon(Icons.image_outlined, color: context.colors.textDisabled)))
                                : Container(color: context.colors.divider,
                                    child: Icon(Icons.image_outlined, color: context.colors.textDisabled)),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}