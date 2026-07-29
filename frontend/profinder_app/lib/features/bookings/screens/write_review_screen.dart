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
import '../../../core/utils/app_helpers.dart';
import '../../../services/api_service.dart';
import '../../../core/theme/theme_context_ext.dart';

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
      AppHelpers.showInfo(context, 'You can attach up to $_maxPhotos photos');
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
      AppHelpers.showError(context, 'Could not pick photo');
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      AppHelpers.showError(context, 'Please select a star rating');
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
          ? 'Failed to update review. Try again.'
          : 'Failed to submit review. Try again.';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation:       0,
        title: Text(widget.isEditMode ? 'Edit Review' : 'Write a Review',
            style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF111827))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context, _submitted),
        ),
      ),
      body: _submitted ? _buildSuccessState() : _buildForm(),
    );
  }

  // ── Form ──────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Professional banner ───────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:       Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius:          26,
                  backgroundColor: context.colors.primaryLight,
                  child: Text(
                    AppHelpers.getInitials(widget.professionalName),
                    style: TextStyle(
                        color:      context.colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize:   14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.professionalName,
                          style: const TextStyle(
                              fontSize:   15,
                              fontWeight: FontWeight.w700,
                              color:      Color(0xFF111827))),
                      const SizedBox(height: 2),
                      const Text('Share your experience',
                          style: TextStyle(
                              fontSize: 12,
                              color:    Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Stars ─────────────────────────────────────
          const Text('Your Rating',
              style: TextStyle(
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                  color:      Color(0xFF111827))),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:       Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                // Star row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star     = i + 1;
                    final isActive = star <= _rating;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = star),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Icon(
                          isActive
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: isActive
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFD1D5DB),
                          size: 40,
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
                    _rating > 0 ? _ratingLabels[_rating] : 'Tap a star to rate',
                    key:   ValueKey(_rating),
                    style: TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      color:      _rating > 0
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Comment ───────────────────────────────────
          const Text('Your Comment (Optional)',
              style: TextStyle(
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                  color:      Color(0xFF111827))),
          const SizedBox(height: 8),

          TextFormField(
            controller: _commentCtrl,
            maxLines:   4,
            maxLength:  500,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText:  'Describe your experience with ${widget.professionalName}...',
              hintStyle: const TextStyle(
                  fontSize: 13, color: Color(0xFF9CA3AF)),
              filled:    true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: context.colors.primary, width: 1.5)),
              counterStyle: const TextStyle(
                  fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ),

          const SizedBox(height: 20),

          // ── Photos ────────────────────────────────────
          // Not shown in edit mode — the edit endpoint only accepts
          // rating/comment, matching customer-permission rules.
          if (!widget.isEditMode) ...[
          Row(
            children: [
              const Text('Add Photos (Optional)',
                  style: TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w700,
                      color:      Color(0xFF111827))),
              const SizedBox(width: 6),
              Text('${_photos.length}/$_maxPhotos',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
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
                  return _AddPhotoTile(onTap: _addPhoto);
                }
                return _PhotoThumb(
                  photo: _photos[index],
                  onRemove: () => _removePhoto(index),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          ],

          // ── Submit ────────────────────────────────────
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22, width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text(widget.isEditMode ? 'Update Review' : 'Submit Review',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Success State ─────────────────────────────────────────
  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color:        context.colors.accentLight,
                shape:        BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_outline_rounded,
                  size: 44, color: context.colors.accent),
            ),
            const SizedBox(height: 20),
            Text(widget.isEditMode ? 'Review Updated! 🎉' : 'Review Submitted! 🎉',
                style: const TextStyle(
                    fontSize:   20,
                    fontWeight: FontWeight.w700,
                    color:      Color(0xFF111827))),
            const SizedBox(height: 8),
            Text(
              widget.isEditMode
                  ? 'Your review for ${widget.professionalName} has been updated.'
                  : 'Thank you for reviewing ${widget.professionalName}. Your feedback helps others make better decisions.',
              style: const TextStyle(
                  fontSize:   13,
                  color:      Color(0xFF6B7280),
                  height:     1.6),
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
                size:  28,
              )),
            ),
            const SizedBox(height: 8),
            Text(_ratingLabels[_rating],
                style: const TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                    color:      Color(0xFFF59E0B))),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(widget.isEditMode ? 'Done' : 'Back to Bookings',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84, height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid),
        ),
        child: Icon(Icons.add_a_photo_outlined, color: context.colors.primary, size: 24),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final _PickedPhoto photo;
  final VoidCallback onRemove;
  const _PhotoThumb({required this.photo, required this.onRemove});

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
          top: 4, right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}