// lib/features/professional/widgets/review_photo_viewer.dart
//
// Fullscreen gallery viewer for review photos. Mirrors the drag-to-dismiss
// + Hero pattern already used by FullscreenImageViewer (chat feature), but
// supports swiping between multiple photos with a page indicator, since a
// single review can carry several images.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ReviewPhotoViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String heroTagPrefix;

  const ReviewPhotoViewer({
    super.key,
    required this.imageUrls,
    required this.heroTagPrefix,
    this.initialIndex = 0,
  });

  static Route<void> route({
    required List<String> imageUrls,
    required String heroTagPrefix,
    int initialIndex = 0,
  }) {
    return PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => ReviewPhotoViewer(
        imageUrls: imageUrls,
        heroTagPrefix: heroTagPrefix,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<ReviewPhotoViewer> createState() => _ReviewPhotoViewerState();
}

class _ReviewPhotoViewerState extends State<ReviewPhotoViewer> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late int _currentIndex = widget.initialIndex;

  double _dragOffset = 0;
  double _backgroundOpacity = 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dy;
          _backgroundOpacity = (1 - (_dragOffset.abs() / 300)).clamp(0.3, 1.0);
        });
      },
      onVerticalDragEnd: (details) {
        if (_dragOffset.abs() > 120) {
          Navigator.of(context).pop();
        } else {
          setState(() {
            _dragOffset = 0;
            _backgroundOpacity = 1;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(_backgroundOpacity),
        body: Stack(
          children: [
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.imageUrls.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  final url = widget.imageUrls[index];
                  return Center(
                    child: Hero(
                      tag: '${widget.heroTagPrefix}_$index',
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(color: Colors.white70),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image, color: Colors.white54, size: 48),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Close button ──
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // ── Page indicator ──
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}