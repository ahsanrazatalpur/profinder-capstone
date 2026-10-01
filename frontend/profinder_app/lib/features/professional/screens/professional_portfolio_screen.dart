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
import '../../../shared/widgets/universal_app_bar.dart';
import '../../../l10n/generated/app_localizations.dart';

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
      if (mounted) {
        AppHelpers.showError(context, AppLocalizations.of(context)!.loadPortfolioError);
      }
    }
  }

  Future<void> _delete(int id) async {
    try {
      await _api.delete('${AppConstants.portfolio}$id/');
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
        title: Text(AppLocalizations.of(context)!.deleteDialogTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Text(
          AppLocalizations.of(context)!.deleteDialogContent(item['title']?.toString() ?? ''),
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
              Text(
                AppLocalizations.of(context)!.addPortfolioTitle,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
              ),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: context.colors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: pickedXFile != null ? AppColors.professionalColor : context.colors.divider,
                      width: pickedXFile != null ? 2 : 1,
                    ),
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
                            Text(
                              AppLocalizations.of(context)!.addImageLabel,
                              style: TextStyle(fontSize: 13, color: AppColors.professionalColor, fontWeight: FontWeight.w500),
                            ),
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
                  labelText: AppLocalizations.of(context)!.titleLabelRequired,
                  hintText: AppLocalizations.of(context)!.titleHint,
                  filled: true,
                  fillColor: context.colors.background,
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
                  labelText: AppLocalizations.of(context)!.descriptionLabelOptional,
                  hintText: AppLocalizations.of(context)!.descriptionHint,
                  filled: true,
                  fillColor: context.colors.background,
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
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.portfolioInfoNote,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
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
                      AppHelpers.showError(ctx, AppLocalizations.of(context)!.titleValidationError);
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
                      AppHelpers.showSuccess(context, AppLocalizations.of(context)!.uploadSuccess);
                      _load();
                    } catch (e) {
                      setSheetState(() => isSaving = false);
                      AppHelpers.showError(ctx, AppLocalizations.of(context)!.uploadError);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(AppLocalizations.of(context)!.submitReviewCta, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width > 600;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: UniversalAppBar(
        title: AppLocalizations.of(context)!.myPortfolioTitle,
        icon: Icons.collections_rounded,
        actions: [
          AppBarIconButton(
            icon: Icons.add_rounded,
            tooltip: AppLocalizations.of(context)!.addPortfolioTooltip,
            onGradient: true,
            onPressed: _showAddSheet,
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
                                  Text(
                                    AppLocalizations.of(context)!.emptyPortfolioTitle,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    AppLocalizations.of(context)!.emptyPortfolioSubtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                                  ),
                                  const SizedBox(height: 22),
                                  ElevatedButton.icon(
                                    onPressed: _showAddSheet,
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: Text(AppLocalizations.of(context)!.addFirstItemCta),
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
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isTablet ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: _items.length,
                      itemBuilder: (_, i) => _buildCard(_items[i], isDark),
                    ),
            ),
      floatingActionButton: _items.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddSheet,
              backgroundColor: AppColors.professionalColor,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildCard(dynamic item, bool isDark) {
    final itemStatus = item['status']?.toString() ?? 'pending';
    final imageUrl   = item['image_url']?.toString();

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (itemStatus) {
      case 'approved':
        statusColor = context.colors.accent;
        statusIcon = Icons.verified_rounded;
        statusLabel = AppLocalizations.of(context)!.statusApproved;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        statusLabel = AppLocalizations.of(context)!.statusRejected;
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Icons.access_time_rounded;
        statusLabel = AppLocalizations.of(context)!.statusPending;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.15) : Colors.grey.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              // Status badge on image
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 11, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  if (item['description']?.toString().isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      item['description'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                  // Admin note if rejected
                  if (itemStatus == 'rejected' && item['admin_note']?.toString().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${AppLocalizations.of(context)!.adminNoteLabel} ${item['admin_note']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9, color: AppColors.error),
                    ),
                  ],
                  const Spacer(),
                  // Delete button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _confirmDelete(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.deleteCta,
                              style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
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
      height: 120,
      width: double.infinity,
      color: context.colors.divider,
      child: Icon(Icons.image_outlined, size: 32, color: context.colors.textDisabled),
    );
  }
}