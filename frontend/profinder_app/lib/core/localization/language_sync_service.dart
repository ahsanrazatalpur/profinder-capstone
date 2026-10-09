// lib/core/localization/language_sync_service.dart
//
// Login-time language sync, as specified:
//   - The language chosen on this device wins and is uploaded to the backend.
//   - Only if this device never chose a language does the backend value apply.
//
// Call `LanguageSyncService().syncAfterLogin(...)` right after a
// successful login response is received — see AuthService.login().

import '../../services/api_service.dart';
import '../constants/app_constants.dart';
import 'locale_provider.dart';
import 'supported_languages.dart';

class LanguageSyncService {
  final ApiService _api = ApiService();

  /// [backendLanguage] is the `preferred_language` value returned by the
  /// login response (nullable). [localeProvider] is the app's live
  /// LocaleProvider instance so the switch takes effect immediately.
  Future<void> syncAfterLogin({
    required String? backendLanguage,
    required LocaleProvider localeProvider,
  }) async {
    // The language the user picked on THIS device (first-launch screen, guest
    // mode or Settings) always wins. Previously the backend's saved
    // preferred_language overrode it, so a guest using Urdu logged in and
    // suddenly got Hindi (an old value stored on the account). Now we push the
    // local choice to the backend so both stay in sync.
    if (localeProvider.hasChosenLanguage ||
        backendLanguage == null ||
        !SupportedLanguages.isSupported(backendLanguage)) {
      await _uploadLanguage(localeProvider.locale.languageCode);
      return;
    }

    // Device has never had a language chosen (fresh install, login before the
    // language screen) -> adopt the account's saved language.
    if (backendLanguage != localeProvider.locale.languageCode) {
      await localeProvider.setLocale(backendLanguage);
    }
  }

  /// Also called from Settings → Language when a logged-in user changes
  /// their language, so the backend stays in sync going forward.
  Future<void> _uploadLanguage(String languageCode) async {
    try {
      await _api.patch(AppConstants.updateLanguage, {
        'preferred_language': languageCode,
      });
    } catch (_) {
      // Best-effort — the app already switched locally; a failed sync
      // just means we retry next login. Never block the UI on this.
    }
  }

  /// Call after a logged-in user changes language from Settings.
  Future<void> uploadLanguage(String languageCode) => _uploadLanguage(languageCode);
}