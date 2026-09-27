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
import '../../../l10n/generated/app_localizations.dart';

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
      if (mounted) {
        AppHelpers.showError(context, AppLocalizations.of(context)!.loadGalleryError);
      }
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
      AppHelpers.showSuccess(context, AppLocalizations.of(context)!.galleryUploadSuccess);
      _load();
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showError(context, AppLocalizations.of(context)!.galleryUploadError);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _delete(int id) async {
    try {
      await _api.delete('${AppConstants.gallery}$id/');
      if (!mounted) return;
      AppHelpers.showSuccess(context, AppLocalizations.of(context)!.deleteSuccess);
      _load();
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showError(context, AppLocalizations.of(context)!.deleteError);
    }
  }

  void _confirmDelete(dynamic item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.deleteGalleryDialogTitle,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteGalleryDialogContent,
          style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancelCta),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () { Navigator.pop(context); _delete(item['id']); },
            child: Text(AppLocalizations.of(context)!.deleteCta),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(dynamic item) {
    final imageUrl = item['image_url']?.toString() ?? item['image']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  height: 300,
                  color: context.colors.surface,
                  child: Icon(Icons.broken_image, size: 48, color: context.colors.textDisabled),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;
    final crossAxisCount = isTablet ? 4 : 3;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.galleryTitle,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isUploading
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.professionalColor,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.add_photo_alternate_outlined, color: AppColors.professionalColor),
                  onPressed: _pickAndUpload,
                  tooltip: AppLocalizations.of(context)!.addPhotoTooltip,
                ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.professionalColor,
                  strokeWidth: 3,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.professionalColor,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: AppColors.professionalColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.photo_library_outlined,
                                  size: 40,
                                  color: AppColors.professionalColor,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                AppLocalizations.of(context)!.emptyGalleryTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppLocalizations.of(context)!.emptyGallerySubtitle,
                                style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                              ),
                              const SizedBox(height: 22),
                              ElevatedButton.icon(
                                onPressed: _pickAndUpload,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: Text(AppLocalizations.of(context)!.addPhotoCta),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.professionalColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(isTablet ? 16 : 12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: isTablet ? 12 : 8,
                        mainAxisSpacing: isTablet ? 12 : 8,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        final imageUrl = item['image_url']?.toString() ?? item['image']?.toString();
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () => _showImagePreview(item),
                            onLongPress: () => _confirmDelete(item),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: context.colors.divider,
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 32,
                                          color: context.colors.textDisabled,
                                        ),
                                      ),
                                      loadingBuilder: (ctx, child, progress) {
                                        if (progress == null) return child;
                                        return Container(
                                          color: context.colors.background,
                                          child: Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.professionalColor,
                                                value: progress.expectedTotalBytes != null
                                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: context.colors.divider,
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 32,
                                        color: context.colors.textDisabled,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}