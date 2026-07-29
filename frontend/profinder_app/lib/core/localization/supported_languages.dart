// lib/core/localization/supported_languages.dart
//
// Single source of truth for every language ProFinder supports.
//
// ➕ Adding a new language later:
//   1. Add an `app_<code>.arb` file under lib/l10n/ with the same keys.
//   2. Add one `AppLanguage` entry below.
//   3. Add the Locale to `supportedLocales` in main.dart.
// No other code needs to change — the language selection screen, the
// Settings → Language screen, and the login-sync flow all read from
// this list.

import 'package:flutter/material.dart';

class AppLanguage {
  final String code; // ISO 639-1, matches the ARB file suffix + backend value
  final String englishName;
  final String nativeName;
  final String flag; // Unicode flag emoji shown in the language picker UI
  final bool isRtl;

  const AppLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.flag,
    this.isRtl = false,
  });

  Locale get locale => Locale(code);
}

class SupportedLanguages {
  SupportedLanguages._();

  static const List<AppLanguage> all = [
    AppLanguage(code: 'en', englishName: 'English', nativeName: 'English', flag: '🇺🇸'),
    AppLanguage(code: 'ur', englishName: 'Urdu', nativeName: 'اردو', flag: '🇵🇰', isRtl: true),
    AppLanguage(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    AppLanguage(code: 'ar', englishName: 'Arabic', nativeName: 'العربية', flag: '🇸🇦', isRtl: true),
    AppLanguage(code: 'fr', englishName: 'French', nativeName: 'Français', flag: '🇫🇷'),
    AppLanguage(code: 'es', englishName: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
  ];

  static const AppLanguage fallback = AppLanguage(
    code: 'en',
    englishName: 'English',
    nativeName: 'English',
    flag: '🇺🇸',
  );

  static List<Locale> get supportedLocales =>
      all.map((l) => l.locale).toList(growable: false);

  static bool isSupported(String code) =>
      all.any((l) => l.code == code);

  /// Returns the matching AppLanguage, or English if the code isn't
  /// (yet) supported.
  static AppLanguage byCode(String code) =>
      all.firstWhere((l) => l.code == code, orElse: () => fallback);

  /// Maps a raw device locale (e.g. from `WidgetsBinding` at first boot) to
  /// one of our supported languages — falls back to English when the
  /// device's language isn't one we support.
  static AppLanguage fromDeviceLocale(Locale deviceLocale) {
    return all.firstWhere(
      (l) => l.code == deviceLocale.languageCode,
      orElse: () => fallback,
    );
  }
}