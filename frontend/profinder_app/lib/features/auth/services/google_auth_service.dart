// lib/features/auth/services/google_auth_service.dart
// Unified Google Sign-In service supporting Mobile (Android & iOS), Web, and Desktop (Windows, macOS, Linux).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_constants.dart';
import 'google_auth_desktop_stub.dart'
    if (dart.library.io) 'google_auth_desktop_io.dart';

class GoogleAuthResult {
  final String? idToken;
  final String? accessToken;
  final String? errorMessage;
  final bool isCancelled;

  GoogleAuthResult.success({this.idToken, this.accessToken})
    : errorMessage = null,
      isCancelled = false;

  GoogleAuthResult.cancelled()
    : idToken = null,
      accessToken = null,
      errorMessage = null,
      isCancelled = true;

  GoogleAuthResult.error(this.errorMessage)
    : idToken = null,
      accessToken = null,
      isCancelled = false;
}

class GoogleAuthService {
  GoogleAuthService._();

  static const String _clientId =
      '405649887034-vtb975grk99t5qrn4747bk36gifq3g6a.apps.googleusercontent.com';

  static final GoogleSignIn _webGoogleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: _clientId,
  );

  static final GoogleSignIn _mobileGoogleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _clientId,
  );

  /// Authenticates with Google across Mobile, Web, and Desktop environments.
  static Future<GoogleAuthResult> signIn(
    BuildContext context, {
    String role = 'customer',
  }) async {
    // ── 1. Desktop Platforms (Windows, Linux, macOS fallback) ────────────────
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      try {
        return await performDesktopGoogleSignIn(
          context,
          role: role,
          baseUrl: AppConstants.baseUrl,
        );
      } catch (e) {
        return GoogleAuthResult.error('Desktop sign-in failed: $e');
      }
    }

    // ── 2. Web & Mobile (Android, iOS) ───────────────────────────────────────
    final googleSignIn = kIsWeb ? _webGoogleSignIn : _mobileGoogleSignIn;

    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User voluntarily dismissed or cancelled the Google account picker
        return GoogleAuthResult.cancelled();
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        return GoogleAuthResult.error(
          'Google authentication completed, but no verification tokens were returned.',
        );
      }

      return GoogleAuthResult.success(
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      final errStr = e.toString();
      if (kDebugMode) {
        debugPrint('[GOOGLE AUTH SERVICE ERROR] $errStr');
      }

      // Check for user cancellation first
      if (errStr.contains('popup_closed_by_user') ||
          errStr.contains('cancelled') ||
          errStr.contains('canceled') ||
          errStr.contains('User canceled') ||
          errStr.contains('12501')) {
        return GoogleAuthResult.cancelled();
      }

      // Automatically fall back to Web Bridge on Web or if native auth encounters an issue
      if (kIsWeb ||
          errStr.contains('Unimplemented') ||
          errStr.contains('MissingPluginException') ||
          errStr.contains('origin') ||
          errStr.contains('gsi_logger') ||
          errStr.contains('popup_blocked')) {
        if (context.mounted) {
          debugPrint('[GOOGLE AUTH] Native sign-in encountered an issue, launching Web Bridge fallback...');
          try {
            return await performDesktopGoogleSignIn(
              context,
              role: role,
              baseUrl: AppConstants.baseUrl,
            );
          } catch (fallbackErr) {
            debugPrint('[GOOGLE AUTH FALLBACK ERROR] $fallbackErr');
          }
        }
      }

      if (errStr.contains('ApiException: 10') ||
          errStr.contains('DEVELOPER_ERROR')) {
        return GoogleAuthResult.error(
          'Google configuration error: App SHA-1 fingerprint is not registered in Google Cloud Console for this build.',
        );
      } else if (errStr.contains('ApiException: 12500') ||
          errStr.contains('SIGN_IN_FAILED')) {
        return GoogleAuthResult.error(
          'Google Sign-In failed on device. Please check your Google Play Services or network connection.',
        );
      } else if (errStr.contains('network') ||
          errStr.contains('SocketException') ||
          errStr.contains('TimeoutException')) {
        return GoogleAuthResult.error(
          'Network connection error while connecting to Google. Please check your internet connection.',
        );
      }

      return GoogleAuthResult.error(
        'Google Sign-In could not be completed: ${errStr.replaceFirst('Exception: ', '').replaceFirst('PlatformException(', '')}',
      );
    }
  }
}
