// lib/core/localization/supported_languages.dart
//
// Single source of truth for every language ProFinder supports.
// ProFinder is strictly a Pakistan National platform: English and Urdu only.

import 'package:flutter/material.dart';

class AppLanguage {
  final String code; // ISO 639-1, matches the ARB file suffix + backend value
  final String englishName;
  final String nativeName;
  final String flag; // Unicode flag or display indicator
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

  static const bool isNationalOnly = true;

  static const List<AppLanguage> nationalLanguages = [
    AppLanguage(
      code: 'en',
      englishName: 'English',
      nativeName: 'English',
      flag: '🇬🇧',
    ),
    AppLanguage(
      code: 'ur',
      englishName: 'Urdu',
      nativeName: 'اردو',
      flag: '🇵🇰',
      isRtl: true,
    ),
  ];

  static List<AppLanguage> get all => nationalLanguages;

  static const AppLanguage fallback = AppLanguage(
    code: 'en',
    englishName: 'English',
    nativeName: 'English',
    flag: '🇬🇧',
  );

  static List<Locale> get supportedLocales =>
      all.map((l) => l.locale).toList(growable: false);

  static bool isSupported(String code) => all.any((l) => l.code == code);

  static AppLanguage byCode(String code) =>
      all.firstWhere((l) => l.code == code, orElse: () => fallback);

  static AppLanguage fromDeviceLocale(Locale deviceLocale) {
    return all.firstWhere(
      (l) => l.code == deviceLocale.languageCode,
      orElse: () => fallback,
    );
  }
}
