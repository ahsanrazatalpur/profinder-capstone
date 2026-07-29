// PATH: lib/features/chat/presentation/widgets/local_image.dart
//
// 🐛 FIX — "red screen" the moment a chat image is picked, before any
// network call even happens.
//
// `Image.file(File(path))` was used to preview a just-picked image while
// the upload is still in flight. On Flutter Web, `dart:io.File` is a stub
// — image_picker gives back an XFile whose `.path` is a `blob:` URL, and
// wrapping that in `dart:io.File` then asking Image.file to read it throws
// `UnsupportedError` synchronously during build, which is exactly what a
// Flutter "red screen" build-time exception looks like.
//
// A `blob:` URL, however, IS something the browser can load directly as an
// image source — so on web we just hand it to Image.network instead. Native
// platforms (Android/iOS) keep using Image.file with a real file path,
// completely unchanged.

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class LocalImagePreview extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;

  const LocalImagePreview({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(path, width: width, height: height, fit: fit);
    }
    return Image.file(File(path), width: width, height: height, fit: fit);
  }
}