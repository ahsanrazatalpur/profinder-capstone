// Cross-platform preview widget for locally selected images prior to upload completion.
//
// On Flutter Web, `image_picker` yields blob URLs where `dart:io.File` is unsupported,
// requiring [Image.network]. On native mobile platforms (Android/iOS), [Image.file]
// resolves the local filesystem path.

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