// lib/core/utils/web_identity/web_identity_stub.dart

import 'package:flutter/services.dart';

void setWebPageIdentity({
  required String title,
  String? description,
  String? faviconUrl,
  String? imageUrl,
  String? canonicalUrl,
}) {
  // On mobile platforms (Android/iOS), set the task switcher description
  try {
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(
        label: title,
        primaryColor: 0xFF2563EB,
      ),
    );
  } catch (_) {}
}
