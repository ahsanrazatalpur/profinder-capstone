// test/localization_persistence_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/core/localization/locale_provider.dart';
import 'package:profinder_app/core/localization/supported_languages.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleProvider Persistence', () {
    test(
      'initializes with default fallback when no preference saved',
      () async {
        SharedPreferences.setMockInitialValues({});
        final provider = LocaleProvider();
        await provider.init();

        expect(provider.hasChosenLanguage, isFalse);
        expect(provider.isLoading, isFalse);
        expect(
          SupportedLanguages.isSupported(provider.locale.languageCode),
          isTrue,
        );
      },
    );

    test('loads persisted locale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'app_locale_code': 'ur',
        'app_locale_has_chosen': true,
      });

      final provider = LocaleProvider();
      await provider.init();

      expect(provider.locale.languageCode, 'ur');
      expect(provider.hasChosenLanguage, isTrue);
      expect(LocaleProvider.currentCode, 'ur');
    });

    test('setLocale persists language code and notifies listeners', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = LocaleProvider();
      await provider.init();

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.setLocale('ar');

      expect(provider.locale.languageCode, 'ar');
      expect(provider.hasChosenLanguage, isTrue);
      expect(LocaleProvider.currentCode, 'ar');
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale_code'), 'ar');
      expect(prefs.getBool('app_locale_has_chosen'), isTrue);
    });

    test('ignores unsupported language codes', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = LocaleProvider();
      await provider.init();

      final initialLocale = provider.locale;
      await provider.setLocale('xyz_unsupported');

      expect(provider.locale, initialLocale);
    });

    test('SupportedLanguages defines all 6 required languages', () {
      final codes = SupportedLanguages.all.map((l) => l.code).toSet();
      expect(codes.contains('en'), isTrue);
      expect(codes.contains('ur'), isTrue);
      expect(codes.contains('ar'), isTrue);
      expect(codes.contains('es'), isTrue);
      expect(codes.contains('fr'), isTrue);
      expect(codes.contains('hi'), isTrue);
    });
  });
}
