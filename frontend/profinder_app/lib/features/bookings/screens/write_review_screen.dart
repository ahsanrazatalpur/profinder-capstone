// lib/features/bookings/screens/write_review_screen.dart
//
// Customer completed booking ke baad professional ko review deta hai
// Stars (1-5) + optional comment + optional photos (up to 5)
//
// Backend endpoint:
//   POST /api/reviews/professionals/<professional_id>/reviews/
//   multipart body: rating, comment, photos (0-5 files)
//
// Effect:
//   Professional ke profile pe average_rating update hota hai
//   Professional detail screen pe stars dikhte hain
//   Verified Service badge automatically set agar completed booking mila

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
import '../../../l10n/generated/app_localizations.dart';

class _PickedPhoto {
  final XFile file;
  final Uint8List? webBytes; // only populated on web, for preview + upload
  const _PickedPhoto({required this.file, this.webBytes});
}

class WriteReviewScreen extends StatefulWidget {
  final int    professionalId;
  final String professionalName;
  final int?   bookingId;

  // ✅ NEW — Edit mode. When existingReviewId is set, this screen PATCHes
  // that review (rating/comment only — photos aren't editable) instead of
  // creating a new one.
  final int?    existingReviewId;
  final int?    initialRating;
  final String? initialComment;

  const WriteReviewScreen({
    super.key,
    required this.professionalId,
    required this.professionalName,
    this.bookingId,
    this.existingReviewId,
    this.initialRating,
    this.initialComment,
  });

  bool get isEditMode => existingReviewId != null;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _api         = ApiService();
  final _commentCtrl = TextEditingController();
  final _picker      = ImagePicker();

  static const _maxPhotos = 5;

  int  _rating    = 0;
  bool _isLoading = false;
  bool _submitted = false;

  final List<_PickedPhoto> _photos = [];

  static const _ratingLabels = [
    '',
    'Poor 😞',
    'Fair 😐',
    'Good 🙂',
    'Very Good 😊',
    'Excellent 🌟',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _rating = widget.initialRating ?? 0;
      _commentCtrl.text = widget.initialComment ?? '';
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= _maxPhotos) {
      AppHelpers.showInfo(context, AppLocalizations.of(context)!.photoLimitReached(_maxPhotos));
      return;
    }
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
      if (picked == null) return;

      Uint8List? bytes;
      if (kIsWeb) bytes = await picked.readAsBytes();

      setState(() => _photos.add(_PickedPhoto(file: picked, webBytes: bytes)));
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showError(context, AppLocalizations.of(context)!.photoPickError);
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      AppHelpers.showError(context, AppLocalizations.of(context)!.ratingRequiredError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isEditMode) {
        // Edit mode — rating/comment only, no photos, matches backend
        // ReviewDetailView which only accepts those two fields.
        await _api.patch(
          '/reviews/${widget.existingReviewId}/',
          {'rating': _rating, 'comment': _commentCtrl.text.trim()},
        );
      } else {
        final photoFiles = <MultipartFile>[];
        for (final p in _photos) {
          if (kIsWeb) {
            photoFiles.add(MultipartFile.fromBytes(
              p.webBytes ?? await p.file.readAsBytes(),
              filename: p.file.name,
            ));
          } else {
            photoFiles.add(await MultipartFile.fromFile(p.file.path, filename: p.file.name));
          }
        }

        final formData = FormData.fromMap({
          'rating':  _rating.toString(),
          'comment': _commentCtrl.text.trim(),
          if (photoFiles.isNotEmpty) 'photos': photoFiles,
        });

        await _api.postForm(
          '/reviews/professionals/${widget.professionalId}/reviews/',
          formData,
        );
      }

      if (!mounted) return;
      setState(() { _isLoading = false; _submitted = true; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Already reviewed check
      String msg = widget.isEditMode
          ? AppLocalizations.of(context)!.reviewUpdateErrorDefault
          : AppLocalizations.of(context)!.reviewSubmitErrorDefault;
      try {
        final err = (e as dynamic).response?.data;
        if (err is Map && err['error'] != null) {
          msg = err['error'].toString();
        }
      } catch (_) {}

      AppHelpers.showError(context, msg);
    }
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
          widget.isEditMode ? AppLocalizations.of(context)!.editReviewTitle : AppLocalizations.of(context)!.writeReviewTitle,
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
          onPressed: () => Navigator.pop(context, _submitted),
        ),
      ),
      body: _submitted ? _buildSuccessState(isDark, isTablet) : _buildForm(isDark, isTablet),
    );
  }

  // ── Form ──────────────────────────────────────────────────
  Widget _buildForm(bool isDark, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Professional banner ───────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            padding: EdgeInsets.all(isTablet ? 18 : 16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isTablet ? 30 : 26,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : context.colors.primaryLight,
                  child: Text(
                    AppHelpers.getInitials(widget.professionalName),
                    style: TextStyle(
                      color: AppColors.customerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.professionalName,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 15,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.shareExperienceLabel,
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 12,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Stars ─────────────────────────────────────
          Text(
            AppLocalizations.of(context)!.ratingLabel,
            style: TextStyle(
              fontSize: isTablet ? 15 : 14,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 12),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Star row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    final isActive = star <= _rating;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = star),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Icon(
                          isActive
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: isActive
                              ? const Color(0xFFF59E0B)
                              : (isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : const Color(0xFFD1D5DB)),
                          size: isTablet ? 48 : 40,
                        ),
                      ),
                    );
                  }),
                ),

                // Label
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _rating > 0
                        ? _ratingLabels[_rating]
                        : AppLocalizations.of(context)!.tapStarToRateLabel,
                    key: ValueKey(_rating),
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 14,
                      fontWeight: FontWeight.w600,
                      color: _rating > 0
                          ? const Color(0xFFF59E0B)
                          : context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Comment ───────────────────────────────────
          Text(
            AppLocalizations.of(context)!.commentOptionalLabel,
            style: TextStyle(
              fontSize: isTablet ? 15 : 14,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _commentCtrl,
            maxLines: 4,
            maxLength: 500,
            style: TextStyle(
              fontSize: isTablet ? 14 : 13,
              color: context.colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.commentHint(widget.professionalName),
              hintStyle: TextStyle(
                fontSize: isTablet ? 14 : 13,
                color: context.colors.textSecondary,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.customerColor,
                  width: 1.5,
                ),
              ),
              counterStyle: TextStyle(
                fontSize: 11,
                color: context.colors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Photos ────────────────────────────────────
          // Not shown in edit mode — the edit endpoint only accepts
          // rating/comment, matching customer-permission rules.
          if (!widget.isEditMode) ...[
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.photosOptionalLabel,
                  style: TextStyle(
                    fontSize: isTablet ? 15 : 14,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_photos.length}/$_maxPhotos',
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length + (_photos.length < _maxPhotos ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == _photos.length) {
                    return _AddPhotoTile(onTap: _addPhoto, isDark: isDark);
                  }
                  return _PhotoThumb(
                    photo: _photos[index],
                    onRemove: () => _removePhoto(index),
                    isDark: isDark,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Submit ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.customerColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      widget.isEditMode
                          ? AppLocalizations.of(context)!.updateReviewCta
                          : AppLocalizations.of(context)!.submitReviewCta,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success State ─────────────────────────────────────────
  Widget _buildSuccessState(bool isDark, bool isTablet) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF10B981).withOpacity(0.15)
                    : context.colors.accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 44,
                color: context.colors.accent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.isEditMode
                  ? AppLocalizations.of(context)!.reviewUpdatedSuccessTitle
                  : AppLocalizations.of(context)!.reviewSubmittedSuccessTitle,
              style: TextStyle(
                fontSize: isTablet ? 22 : 20,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isEditMode
                  ? AppLocalizations.of(context)!.reviewUpdatedSuccessMessage(widget.professionalName)
                  : AppLocalizations.of(context)!.reviewSubmittedSuccessMessage(widget.professionalName),
              style: TextStyle(
                fontSize: isTablet ? 14 : 13,
                color: context.colors.textSecondary,
                height: 1.6,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Stars display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => Icon(
                i < _rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: const Color(0xFFF59E0B),
                size: isTablet ? 32 : 28,
              )),
            ),
            const SizedBox(height: 8),
            Text(
              _ratingLabels[_rating],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF59E0B),
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.customerColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.isEditMode
                    ? AppLocalizations.of(context)!.doneCta
                    : AppLocalizations.of(context)!.backToBookingsCta,
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  const _AddPhotoTile({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : const Color(0xFFD1D5DB),
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          Icons.add_a_photo_outlined,
          color: AppColors.customerColor,
          size: 24,
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final _PickedPhoto photo;
  final VoidCallback onRemove;
  final bool isDark;
  const _PhotoThumb({required this.photo, required this.onRemove, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: kIsWeb
              ? Image.memory(photo.webBytes!, width: 84, height: 84, fit: BoxFit.cover)
              : Image.file(File(photo.file.path), width: 84, height: 84, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.7)
                    : Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}