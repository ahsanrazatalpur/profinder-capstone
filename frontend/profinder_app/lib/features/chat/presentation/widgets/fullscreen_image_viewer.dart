// lib/features/chat/presentation/widgets/fullscreen_image_viewer.dart
//
// Uses Flutter's built-in InteractiveViewer (no new dependency needed for
// pinch-zoom) plus a Hero for the shared-element transition from the chat
// bubble, and a drag-down-to-dismiss gesture like WhatsApp/Instagram.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'local_image.dart';

class FullscreenImageViewer extends StatefulWidget {
  final String heroTag;
  final String? imageUrl;   // a message image already on the server
  final String? localPath;  // an optimistic image not yet uploaded

  const FullscreenImageViewer({super.key, required this.heroTag, this.imageUrl, this.localPath})
      : assert(imageUrl != null || localPath != null);

  static Route<void> route({required String heroTag, String? imageUrl, String? localPath}) {
    return PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => FullscreenImageViewer(heroTag: heroTag, imageUrl: imageUrl, localPath: localPath),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  double _dragOffset = 0;
  double _backgroundOpacity = 1;

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
            Center(
              child: Transform.translate(
                offset: Offset(0, _dragOffset),
                child: Hero(
                  tag: widget.heroTag,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: widget.localPath != null
                        ? LocalImagePreview(path: widget.localPath!, fit: BoxFit.contain)
                        : CachedNetworkImage(
                            imageUrl: widget.imageUrl!,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(color: Colors.white70),
                            ),
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                          ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 12,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}