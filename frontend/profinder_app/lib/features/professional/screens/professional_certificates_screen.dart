// PATH: lib/features/professional/screens/professional_certificates_screen.dart
// lib/features/professional/screens/professional_certificates_screen.dart
//
// ⚠️ BACKEND NOTE: Uses `AppConstants.certificates` ('/profiles/certificates/').
// This endpoint doesn't exist in the current backend — add a Certificate
// model (title, issuing_organization, issue_date, certificate_image, status)
// with a CRUD viewset mirroring the existing Portfolio app.

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

class ProfessionalCertificatesScreen extends StatefulWidget {
  const ProfessionalCertificatesScreen({super.key});

  @override
  State<ProfessionalCertificatesScreen> createState() => _ProfessionalCertificatesScreenState();
}

class _ProfessionalCertificatesScreenState extends State<ProfessionalCertificatesScreen> {
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
      final res = await _api.get(AppConstants.certificates);
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
      await _api.delete('${AppConstants.certificates}$id/');
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
    final orgCtrl   = TextEditingController();
    DateTime?  issueDate;
    XFile?     pickedXFile;
    File?      pickedFile;
    Uint8List? webBytes;
    bool       isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Add Certificate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () async {
                  final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 900);
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
                    color:        const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: context.colors.divider),
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
                            Icon(Icons.card_membership_outlined, size: 32, color: AppColors.professionalColor),
                            const SizedBox(height: 6),
                            Text('Tap to add certificate image', style: TextStyle(fontSize: 13, color: AppColors.professionalColor, fontWeight: FontWeight.w500)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: titleCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Certificate Title *',
                  hintText:  'e.g. Certified Electrician',
                  filled: true, fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.divider)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.professionalColor, width: 1.5)),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: orgCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Issuing Organization',
                  hintText:  'e.g. TEVTA / Coursera',
                  filled: true, fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.divider)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.professionalColor, width: 1.5)),
                ),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1980),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setSheetState(() => issueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: context.colors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        issueDate == null ? 'Issue Date (optional)' : '${issueDate!.year}-${issueDate!.month.toString().padLeft(2, '0')}-${issueDate!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 13.5, color: issueDate == null ? context.colors.textSecondary : context.colors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (titleCtrl.text.trim().isEmpty) {
                      AppHelpers.showError(ctx, 'Title is required');
                      return;
                    }
                    setSheetState(() => isSaving = true);
                    try {
                      MultipartFile? imgPart;
                      if (pickedXFile != null) {
                        imgPart = kIsWeb
                            ? MultipartFile.fromBytes(webBytes ?? await pickedXFile!.readAsBytes(), filename: 'cert.jpg')
                            : await MultipartFile.fromFile(pickedXFile!.path, filename: 'cert.jpg');
                      }
                      await _api.postForm(AppConstants.certificates, FormData.fromMap({
                        'title': titleCtrl.text.trim(),
                        'issuing_organization': orgCtrl.text.trim(),
                        if (issueDate != null) 'issue_date': issueDate!.toIso8601String().split('T').first,
                        if (imgPart != null) 'image': imgPart,
                      }));
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      AppHelpers.showSuccess(context, 'Certificate added');
                      _load();
                    } catch (e) {
                      setSheetState(() => isSaving = false);
                      AppHelpers.showError(ctx, 'Could not add certificate');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.professionalColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Certificate', style: TextStyle(fontWeight: FontWeight.w700)),
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
        title: Text('Certificates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.colors.textPrimary), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: AppColors.professionalColor),
            onPressed: _showAddSheet,
            tooltip: 'Add Certificate',
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
                              Icon(Icons.card_membership_outlined, size: 64, color: context.colors.textDisabled),
                              const SizedBox(height: 12),
                              Text('No certificates yet', style: TextStyle(fontSize: 15, color: context.colors.textSecondary)),
                              const SizedBox(height: 6),
                              Text('Add certifications to build trust', style: TextStyle(fontSize: 12, color: context.colors.textSecondary)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _showAddSheet,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add First Certificate'),
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
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (_, i) => _buildTile(_items[i]),
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

  Widget _buildTile(dynamic item) {
    final imageUrl = item['certificate_image']?.toString() ?? item['image_url']?.toString();
    final org      = item['issuing_organization']?.toString() ?? '';
    final date     = item['issue_date']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: context.colors.divider,
                        child: Icon(Icons.card_membership_outlined, color: context.colors.textDisabled)))
                : Container(width: 56, height: 56, color: context.colors.divider,
                    child: Icon(Icons.card_membership_outlined, color: context.colors.textDisabled)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title']?.toString() ?? '', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                if (org.isNotEmpty) Text(org, style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary)),
                if (date.isNotEmpty) Text(date, style: TextStyle(fontSize: 10.5, color: context.colors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(item),
            child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}