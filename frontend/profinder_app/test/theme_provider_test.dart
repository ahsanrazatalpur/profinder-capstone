// ThemeProvider: Light / Dark / System, persistence, and backward
// compatibility with the values saved by older app versions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = 'theme_mode';

  Future<ThemeProvider> make(Map<String, Object> saved) async {
    SharedPreferences.setMockInitialValues(saved);
    final p = ThemeProvider();
    await p.ready;
    return p;
  }

  test('nothing saved: starts in Light (unchanged default)', () async {
    final p = await make({});
    expect(p.themeMode, ThemeMode.light);
    expect(p.isDarkMode, isFalse);
    expect(p.isSystem, isFalse);
  });

  test('values saved by older versions are preserved', () async {
    expect((await make({key: 'dark'})).themeMode, ThemeMode.dark);
    expect((await make({key: 'light'})).themeMode, ThemeMode.light);
  });

  test('system is loaded', () async {
    final p = await make({key: 'system'});
    expect(p.themeMode, ThemeMode.system);
    expect(p.isSystem, isTrue);
    expect(p.isDarkMode, isFalse);
  });

  test('an unknown saved value is ignored', () async {
    expect((await make({key: 'purple'})).themeMode, ThemeMode.light);
  });

  test('setThemeMode applies, notifies once and persists', () async {
    final p = await make({});
    var notified = 0;
    p.addListener(() => notified++);

    await p.setThemeMode(ThemeMode.system);
    expect(p.themeMode, ThemeMode.system);
    expect(notified, 1);
    expect((await SharedPreferences.getInstance()).getString(key), 'system');

    await p.setThemeMode(ThemeMode.dark);
    expect((await SharedPreferences.getInstance()).getString(key), 'dark');
  });

  test('choosing the current mode does not notify but still saves it', () async {
    final p = await make({});
    var notified = 0;
    p.addListener(() => notified++);
    await p.setThemeMode(ThemeMode.light);
    expect(notified, 0);
    expect((await SharedPreferences.getInstance()).getString(key), 'light');
  });

  test('toggleTheme keeps working (Light <-> Dark)', () async {
    final p = await make({});
    await p.toggleTheme();
    expect(p.themeMode, ThemeMode.dark);
    await p.toggleTheme();
    expect(p.themeMode, ThemeMode.light);
    // From System, toggling goes to Light first (not Dark).
    await p.setThemeMode(ThemeMode.system);
    await p.toggleTheme();
    expect(p.themeMode, ThemeMode.dark);
  });

  test('a pick made before the saved value loads is not overwritten by it', () async {
    SharedPreferences.setMockInitialValues({key: 'dark'});
    final p = ThemeProvider(); // load is still pending
    await p.setThemeMode(ThemeMode.light);
    await p.ready;
    expect(p.themeMode, ThemeMode.light);
    expect((await SharedPreferences.getInstance()).getString(key), 'light');
  });
}
