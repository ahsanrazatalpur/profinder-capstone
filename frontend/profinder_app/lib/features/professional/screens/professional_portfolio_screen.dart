// lib/features/professional/screens/professional_portfolio_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_context_ext.dart';

class ProfessionalPortfolioScreen extends StatefulWidget {
  const ProfessionalPortfolioScreen({super.key});

  @override
  State<ProfessionalPortfolioScreen> createState() => _ProfessionalPortfolioScreenState();
}

class _ProfessionalPortfolioScreenState extends State<ProfessionalPortfolioScreen> {
  final _api    = ApiService();
  final _picker = ImagePicker();

  List<dynamic> _items     = [];
  bool          _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get(AppConstants.portfolio);
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

  Future<void> _delete(int id) async {
    try {
      await _api.delete('${AppConstants.portfolio}$id/');
      if (!mounted) return;
      AppHelpers.showSuccess(context, 'Deleted');
      _load();
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showError(context, 'Could not delete');
    }
  }

  void _confirmDelete(dynamic item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Text('Delete "${item['title']}"?', style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
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

  void _showAddSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    XFile?     pickedXFile;
    File?      pickedFile;
    Uint8List? webBytes;
    bool       isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Add Portfolio Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
              const SizedBox(height: 16),

              // Image picker
              GestureDetector(
                onTap: () async {
                  final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
                  if (picked == null) return;
                  if (kIsWeb) {
                    final bytes = await picked.readAsBytes();
                    setSheetState(() { pickedXFile = picked; webBytes = bytes; });
                  } else {
                    setSheetState(() { pickedXFile = picked; pickedFile = File(picked.path); });
                  }
                },
                child: Container(
                  width: double.infinity, height: 140,
                  decoration: BoxDecoration(
                    color:        context.colors.background,
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: context.colors.divider, style: BorderStyle.solid),
                  ),
                  child: pickedXFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb && webBytes != null
                              ? Image.memory(webBytes!, fit: BoxFit.cover, width: double.infinity)
                              : Image.file(pickedFile!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.professionalColor),
                            const SizedBox(height: 6),
                            Text('Tap to add image', style: TextStyle(fontSize: 13, color: AppColors.professionalColor, fontWeight: FontWeight.w500)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              TextField(
                controller: titleCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText:   'Title *',
                  hintText:    'e.g. House Construction Project',
                  filled:      true,
                  fillColor:   context.colors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.divider)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.professionalColor, width: 1.5)),
                ),
              ),
              const SizedBox(height: 10),

              // Description
              TextField(
                controller: descCtrl,
                maxLines:   3,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText:     'Description (optional)',
                  hintText:      'Brief description of this work...',
                  filled:        true,
                  fillColor:     context.colors.background,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.divider)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.professionalColor, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),

              // Info note
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:        const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border:       Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your portfolio will be reviewed by admin. Once approved, you\'ll get a verified badge.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.professionalColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSaving ? null : () async {
                    if (titleCtrl.text.trim().isEmpty) {
                      AppHelpers.showError(ctx, 'Please enter a title');
                      return;
                    }
                    setSheetState(() => isSaving = true);
                    try {
                      MultipartFile? imageMultipart;
                      if (pickedXFile != null) {
                        if (kIsWeb) {
                          final bytes = webBytes ?? await pickedXFile!.readAsBytes();
                          imageMultipart = MultipartFile.fromBytes(bytes, filename: 'portfolio.jpg');
                        } else {
                          imageMultipart = await MultipartFile.fromFile(pickedXFile!.path, filename: 'portfolio.jpg');
                        }
                      }

                      final formData = FormData.fromMap({
                        'title':       titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        if (imageMultipart != null) 'image': imageMultipart,
                      });

                      await _api.postForm(AppConstants.portfolio, formData);

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      AppHelpers.showSuccess(context, 'Portfolio submitted for review!');
                      _load();
                    } catch (e) {
                      setSheetState(() => isSaving = false);
                      AppHelpers.showError(ctx, 'Failed to upload');
                    }
                  },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit for Review', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
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
        title: Text('My Portfolio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: AppColors.professionalColor),
            onPressed: _showAddSheet,
            tooltip: 'Add Portfolio',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.professionalColor,
              child: _items.isEmpty
                  ? LayoutBuilder(
                      builder: (ctx, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 88, height: 88,
                                    decoration: BoxDecoration(
                                      color: AppColors.professionalColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.photo_library_outlined,
                                        size: 38, color: AppColors.professionalColor),
                                  ),
                                  const SizedBox(height: 18),
                                  Text('No portfolio items yet',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: context.colors.textPrimary)),
                                  const SizedBox(height: 6),
                                  Text('Add your work to get verified by admin',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
                                  const SizedBox(height: 22),
                                  ElevatedButton.icon(
                                    onPressed: _showAddSheet,
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Add First Item'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.professionalColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:   2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing:  10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (_, i) => _buildCard(_items[i]),
                    ),
            ),
      floatingActionButton: _items.isNotEmpty
          ? FloatingActionButton(
              onPressed:       _showAddSheet,
              backgroundColor: AppColors.professionalColor,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildCard(dynamic item) {
    final itemStatus = item['status']?.toString() ?? 'pending';
    final imageUrl   = item['image_url']?.toString();

    Color statusColor;
    IconData statusIcon;
    switch (itemStatus) {
      case 'approved': statusColor = context.colors.accent;  statusIcon = Icons.verified_rounded; break;
      case 'rejected': statusColor = AppColors.error;   statusIcon = Icons.cancel_rounded;   break;
      default:         statusColor = AppColors.warning; statusIcon = Icons.access_time_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color:        context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height:     110,
                        width:      double.infinity,
                        fit:        BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              // Status badge on image
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color:        statusColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 10, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        AppHelpers.capitalize(itemStatus),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                  ),
                  if (item['description']?.toString().isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      item['description'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: context.colors.textSecondary),
                    ),
                  ],
                  // Admin note if rejected
                  if (itemStatus == 'rejected' && item['admin_note']?.toString().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: ${item['admin_note']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9, color: AppColors.error),
                    ),
                  ],
                  const Spacer(),
                  // Delete button
                  GestureDetector(
                    onTap: () => _confirmDelete(item),
                    child: Row(
                      children: const [
                        Icon(Icons.delete_outline_rounded, size: 13, color: AppColors.error),
                        SizedBox(width: 3),
                        Text('Delete', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 110, width: double.infinity,
      color: context.colors.divider,
      child: Icon(Icons.image_outlined, size: 32, color: context.colors.textDisabled),
    );
  }
}