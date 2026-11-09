// lib/core/utils/web_identity/web_identity_web.dart

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

void setWebPageIdentity({
  required String title,
  String? description,
  String? faviconUrl,
  String? imageUrl,
  String? canonicalUrl,
}) {
  try {
    // 1. Update native Flutter application switcher description
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(
        label: title,
        primaryColor: 0xFF2563EB,
      ),
    );

    // 2. Update browser tab title
    web.document.title = title;

    // 3. Update dynamic favicon
    if (faviconUrl != null && faviconUrl.trim().isNotEmpty) {
      _updateFavicon(faviconUrl.trim());
    }

    // 4. Update Open Graph and Twitter meta tags
    if (description != null && description.isNotEmpty) {
      _setMeta('description', description);
      _setMeta('og:description', description);
      _setMeta('twitter:description', description);
    }
    _setMeta('og:title', title);
    _setMeta('twitter:title', title);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      _setMeta('og:image', imageUrl);
      _setMeta('twitter:image', imageUrl);
    }

    if (canonicalUrl != null && canonicalUrl.isNotEmpty) {
      _setMeta('og:url', canonicalUrl);
      _updateCanonical(canonicalUrl);
    }
  } catch (e) {
    // Fail gracefully if running in a restricted iframe or mock environment
  }
}

void _updateFavicon(String url) {
  final head = web.document.head;
  if (head == null) return;

  var link = web.document.querySelector("link[rel*='icon']") as web.HTMLLinkElement?;
  if (link == null) {
    link = web.document.createElement('link') as web.HTMLLinkElement;
    link.rel = 'icon';
    link.type = 'image/png';
    head.appendChild(link);
  }
  link.href = url;

  // Also update apple-touch-icon
  var appleLink = web.document.querySelector("link[rel='apple-touch-icon']") as web.HTMLLinkElement?;
  if (appleLink != null) {
    appleLink.href = url;
  }
}

void _setMeta(String property, String content) {
  final head = web.document.head;
  if (head == null) return;

  web.HTMLMetaElement? meta;
  if (property.startsWith('og:')) {
    meta = web.document.querySelector("meta[property='$property']") as web.HTMLMetaElement?;
  } else {
    meta = web.document.querySelector("meta[name='$property']") as web.HTMLMetaElement?;
  }

  if (meta != null) {
    meta.content = content;
  } else {
    final newMeta = web.document.createElement('meta') as web.HTMLMetaElement;
    if (property.startsWith('og:')) {
      newMeta.setAttribute('property', property);
    } else {
      newMeta.name = property;
    }
    newMeta.content = content;
    head.appendChild(newMeta);
  }
}

void _updateCanonical(String url) {
  final head = web.document.head;
  if (head == null) return;

  var link = web.document.querySelector("link[rel='canonical']") as web.HTMLLinkElement?;
  if (link != null) {
    link.href = url;
  }
}
