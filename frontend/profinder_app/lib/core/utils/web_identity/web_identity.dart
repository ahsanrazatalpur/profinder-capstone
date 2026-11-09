// lib/core/utils/web_identity/web_identity.dart

import 'web_identity_stub.dart'
    if (dart.library.js_interop) 'web_identity_web.dart' as impl;

/// Cross-platform utility to dynamically update browser tab title, favicon,
/// Open Graph metadata, and task switcher labels on Web, Android, and iOS.
class WebIdentity {
  WebIdentity._();

  static const String brandTitle = 'ProFinder | Find Trusted Professionals in Pakistan';
  static const String defaultFavicon = 'favicon.png?v=profinder2';

  /// Dynamically updates the browser tab title, favicon, and meta tags.
  static void setIdentity({
    required String title,
    String? description,
    String? faviconUrl,
    String? imageUrl,
    String? canonicalUrl,
  }) {
    impl.setWebPageIdentity(
      title: title,
      description: description,
      faviconUrl: faviconUrl ?? defaultFavicon,
      imageUrl: imageUrl,
      canonicalUrl: canonicalUrl,
    );
  }

  /// Reset to standard brand identity
  static void resetToDefault() {
    setIdentity(
      title: brandTitle,
      description: 'Find trusted professionals, doctors, electricians, tutors, plumbers, and mechanics near you in Pakistan.',
      faviconUrl: defaultFavicon,
    );
  }
}
