// lib/core/localization/language_sync_service.dart
//
// Login-time language sync, as specified:
//   - If the backend already has a preferred_language, that wins — the
//     app switches to it (e.g. user logged in on a new device).
//   - If the backend has none (null), we upload whatever is currently
//     selected locally (from first-launch detection or Settings).
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
    if (backendLanguage != null && SupportedLanguages.isSupported(backendLanguage)) {
      // Backend already has a preference — it wins.
      if (backendLanguage != localeProvider.locale.languageCode) {
        await localeProvider.setLocale(backendLanguage);
      }
      return;
    }

    // Backend has none yet — upload the locally selected language.
    await _uploadLanguage(localeProvider.locale.languageCode);
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