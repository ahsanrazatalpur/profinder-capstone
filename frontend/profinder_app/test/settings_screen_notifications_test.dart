import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:profinder_app/core/network/api_service.dart';
import 'package:profinder_app/core/localization/locale_provider.dart';
import 'package:profinder_app/core/theme/theme_provider.dart';
import 'package:profinder_app/features/settings/screens/settings_screen.dart';
import 'package:profinder_app/l10n/generated/app_localizations.dart';

class FakeSettingsApiService implements ApiService {
  Map<String, dynamic> patchedData = {};
  bool pushNotifications;
  bool emailNotifications;

  FakeSettingsApiService({
    this.pushNotifications = true,
    this.emailNotifications = true,
  });

  @override
  Future<Response> get(String endpoint) async {
    return Response(
      requestOptions: RequestOptions(path: endpoint),
      statusCode: 200,
      data: {
        'id': '1',
        'email': 'user@example.com',
        'push_notifications': pushNotifications,
        'email_notifications': emailNotifications,
      },
    );
  }

  @override
  Future<Response> patch(String endpoint, Map<String, dynamic> data) async {
    patchedData.addAll(data);
    return Response(
      requestOptions: RequestOptions(path: endpoint),
      statusCode: 200,
      data: {'message': 'Updated', ...data},
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildSettingsTestApp({
  Map<String, Object> initialPrefs = const {},
  ApiService? api,
}) {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final localeProvider = LocaleProvider();
  final themeProvider = ThemeProvider();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SettingsScreen(api: api),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen notification switches', () {
    testWidgets('renders push and email notification switches', (tester) async {
      final fakeApi = FakeSettingsApiService();
      await tester.pumpWidget(_buildSettingsTestApp(
        initialPrefs: {
          'pref_push_notifications': true,
          'pref_email_notifications': true,
        },
        api: fakeApi,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsNWidgets(2));
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Email Notifications'), findsOneWidget);

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches[0].value, isTrue);
      expect(switches[1].value, isTrue);
    });

    testWidgets('loads disabled initial state from preferences', (tester) async {
      final fakeApi = FakeSettingsApiService(
        pushNotifications: false,
        emailNotifications: false,
      );
      await tester.pumpWidget(_buildSettingsTestApp(
        initialPrefs: {
          'pref_push_notifications': false,
          'pref_email_notifications': false,
        },
        api: fakeApi,
      ));
      await tester.pumpAndSettle();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches[0].value, isFalse);
      expect(switches[1].value, isFalse);
    });

    testWidgets('toggling switch updates local state and preferences and calls api', (tester) async {
      final fakeApi = FakeSettingsApiService();
      await tester.pumpWidget(_buildSettingsTestApp(
        initialPrefs: {
          'pref_push_notifications': true,
          'pref_email_notifications': true,
        },
        api: fakeApi,
      ));
      await tester.pumpAndSettle();

      // Tap the first switch (push notifications)
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pref_push_notifications'), isFalse);
      expect(fakeApi.patchedData['push_notifications'], isFalse);

      // Tap the second switch (email notifications)
      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();

      expect(prefs.getBool('pref_email_notifications'), isFalse);
      expect(fakeApi.patchedData['email_notifications'], isFalse);
    });
  });
}
