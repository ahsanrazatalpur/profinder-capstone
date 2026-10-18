// lib/core/theme/theme_provider.dart
//
// Holds the app's ThemeMode (Light / Dark / System) and persists the user's
// choice across restarts via SharedPreferences. Wired into MaterialApp's
// `themeMode` in main.dart.
//
// Stored values: 'light' | 'dark' | 'system'. Values saved by older versions
// ('light' / 'dark') keep working unchanged.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'theme_mode';

  // First-time users (nothing saved yet) still start in Light, exactly as
  // before. System is opt-in from the theme picker.
  ThemeMode _themeMode = ThemeMode.light;

  // If the user picks a theme before the saved value finished loading, the
  // user's pick wins and the late load must not overwrite it.
  bool _changedByUser = false;

  /// Completes when the saved preference has been read (useful in tests).
  late final Future<void> ready;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isSystem => _themeMode == ThemeMode.system;

  ThemeProvider() {
    ready = _loadFromPrefs();
  }

  static ThemeMode? _parse(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
    }
    return null; // nothing saved, or an unknown value: keep the default
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = _parse(prefs.getString(_prefsKey));
      if (saved != null && !_changedByUser && saved != _themeMode) {
        _themeMode = saved;
        notifyListeners();
      }
    } catch (_) {
      // Storage unavailable: keep the default, the app still works.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _changedByUser = true;
    if (mode != _themeMode) {
      _themeMode = mode;
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _encode(mode));
    } catch (_) {
      // Not persisted this time; the choice still applies for this session.
    }
  }

  /// Kept for existing callers: flips between Light and Dark.
  Future<void> toggleTheme() => setThemeMode(
    _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
  );
}
