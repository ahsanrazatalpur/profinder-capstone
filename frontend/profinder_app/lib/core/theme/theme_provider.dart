// lib/core/theme/theme_provider.dart
//
// Holds the app's current ThemeMode (light/dark) and persists the user's
// choice across app restarts via SharedPreferences. Wire this into
// MaterialApp's `themeMode` in main.dart, and call toggleTheme() from
// wherever the dark-mode switch lives (e.g. guest_profile_screen.dart).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'theme_mode';

  // Default is light — first-time users (no saved preference yet) see
  // light mode. Dark is only used once the user explicitly toggles it,
  // at which point it's saved to prefs and persists across restarts.
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'light') {
      _themeMode = ThemeMode.light;
      notifyListeners();
    } else if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
      notifyListeners();
    }
    // If nothing saved yet, keep the default above.
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }
}