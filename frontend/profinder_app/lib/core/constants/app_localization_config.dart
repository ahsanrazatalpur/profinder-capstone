// lib/core/constants/app_localization_config.dart
//
// Centralized Localization & Scope Configuration for ProFinder Flutter app.
// Controls Pakistan-only operational scope with centralized flags so
// international capabilities can be restored without refactoring.

class AppLocalizationConfig {
  AppLocalizationConfig._();

  /// Set to true for Pakistan National scope. Set to false for Global expansion.
  static const bool isPakistanOnly = true;

  // Defaults
  static const String defaultCountryName = 'Pakistan';
  static const String defaultCountryCode = 'PK';
  static const String defaultDialingCode = '+92';
  static const String defaultCurrencyCode = 'PKR';
  static const String defaultCurrencySymbol = 'Rs.';
  static const String defaultTimezone = 'Asia/Karachi';

  // Feature Flags
  static const bool allowCountrySelection = !isPakistanOnly;
  static const bool allowForeignCurrencies = !isPakistanOnly;
  static const bool allowGlobalLanguages = !isPakistanOnly;

  /// Returns active supported language codes ('en', 'ur' for Pakistan-only mode)
  static const List<String> supportedLanguageCodes = isPakistanOnly
      ? ['en', 'ur']
      : ['en', 'ur', 'hi', 'ar', 'fr', 'es'];
}
