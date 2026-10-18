// The shared theme picker sheet and the real System behaviour of MaterialApp.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/core/theme/app_theme.dart';
import 'package:profinder_app/core/theme/theme_mode_picker.dart';
import 'package:profinder_app/core/theme/theme_provider.dart';
import 'package:profinder_app/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(ThemeProvider provider, {Locale locale = const Locale('en'), double textScale = 1.0}) {
  return ChangeNotifierProvider<ThemeProvider>.value(
    value: provider,
    child: Consumer<ThemeProvider>(
      builder: (context, tp, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: tp.themeMode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: c!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                // Shows which brightness is really in effect.
                Text(Theme.of(context).brightness == Brightness.dark ? 'effective:dark' : 'effective:light'),
                TextButton(onPressed: () => showThemeModeSheet(context), child: const Text('open picker')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<ThemeProvider> _provider([Map<String, Object> saved = const {}]) async {
  SharedPreferences.setMockInitialValues(saved);
  final p = ThemeProvider();
  await p.ready;
  return p;
}

void main() {
  testWidgets('the sheet offers Light, Dark and System default; current one is marked', (tester) async {
    final provider = await _provider();
    await tester.pumpWidget(_app(provider));
    await tester.tap(find.text('open picker'));
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Light Mode'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Matches your device setting'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget); // Light is current
  });

  testWidgets('choosing Dark applies it, closes the sheet and persists', (tester) async {
    final provider = await _provider();
    await tester.pumpWidget(_app(provider));
    expect(find.text('effective:light'), findsOneWidget);

    await tester.tap(find.text('open picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark Mode'));
    await tester.pumpAndSettle();

    expect(provider.themeMode, ThemeMode.dark);
    expect(find.text('effective:dark'), findsOneWidget);
    expect(find.text('System default'), findsNothing); // sheet closed
    expect((await SharedPreferences.getInstance()).getString('theme_mode'), 'dark');
  });

  testWidgets('System default really follows the device brightness', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final provider = await _provider();
    await tester.pumpWidget(_app(provider));
    expect(find.text('effective:light'), findsOneWidget); // default is still Light

    await tester.tap(find.text('open picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('System default'));
    await tester.pumpAndSettle();
    expect(provider.themeMode, ThemeMode.system);
    expect(find.text('effective:dark'), findsOneWidget); // device is dark

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(find.text('effective:light'), findsOneWidget); // follows the device live
  });

  testWidgets('a previously saved choice is shown as current', (tester) async {
    final provider = await _provider({'theme_mode': 'system'});
    await tester.pumpWidget(_app(provider));
    await tester.tap(find.text('open picker'));
    await tester.pumpAndSettle();
    // The check mark sits on the System row.
    final systemTile = find.ancestor(of: find.text('System default'), matching: find.byType(ListTile));
    expect(find.descendant(of: systemTile, matching: find.byIcon(Icons.check_rounded)), findsOneWidget);
  });

  testWidgets('Urdu (RTL), 2x text, narrow screen: no overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = await _provider();
    await tester.pumpWidget(_app(provider, locale: const Locale('ur'), textScale: 2.0));
    await tester.tap(find.text('open picker'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
