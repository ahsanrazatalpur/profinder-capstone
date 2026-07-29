// lib/core/localization/locale_provider.dart
//
// The single source of truth for "what language is the app in right now".
// Wrapped around MaterialApp in main.dart so changing the locale here
// rebuilds the whole app immediately — no restart needed.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supported_languages.dart';

class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'app_locale_code';
  static const _prefsHasChosenKey = 'app_locale_has_chosen';

  Locale _locale = SupportedLanguages.fallback.locale;
  bool _hasChosenLanguage = false;
  bool _isLoading = true;

  Locale get locale => _locale;
  bool get isLoading => _isLoading;

  /// False only before the very first language pick — main.dart uses this
  /// to decide whether to show the first-launch language selection screen.
  bool get hasChosenLanguage => _hasChosenLanguage;

  /// Loads the persisted language (if any) and detects the device language
  /// otherwise. Call once, before runApp — see main.dart.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefsKey);
    _hasChosenLanguage = prefs.getBool(_prefsHasChosenKey) ?? false;

    if (savedCode != null && SupportedLanguages.isSupported(savedCode)) {
      _locale = Locale(savedCode);
    } else {
      // First ever launch — detect device language, but don't mark
      // hasChosenLanguage true yet: the user still needs to see and
      // confirm the language selection screen once.
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      _locale = SupportedLanguages.fromDeviceLocale(deviceLocale).locale;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Called from the first-launch language selection screen (Continue)
  /// and from Settings → Language. Persists immediately and rebuilds the
  /// whole app via notifyListeners().
  Future<void> setLocale(String languageCode, {bool markAsChosen = true}) async {
    if (!SupportedLanguages.isSupported(languageCode)) return;

    _locale = Locale(languageCode);
    if (markAsChosen) _hasChosenLanguage = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, languageCode);
    if (markAsChosen) await prefs.setBool(_prefsHasChosenKey, true);
  }

  /// Used only by "reset app" / debug flows to bring back the first-launch
  /// language selection screen.
  Future<void> resetFirstLaunchFlag() async {
    _hasChosenLanguage = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsHasChosenKey, false);
  }
}