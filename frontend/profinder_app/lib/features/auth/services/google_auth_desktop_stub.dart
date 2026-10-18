// lib/features/auth/services/google_auth_desktop_stub.dart
// Web fallback stub — dart:io is unavailable in browser environments.

import 'package:flutter/material.dart';
import 'google_auth_service.dart';

Future<GoogleAuthResult> performDesktopGoogleSignIn(
  BuildContext context, {
  required String role,
  required String baseUrl,
}) async {
  return GoogleAuthResult.error(
    'Desktop loopback authentication is not supported in a browser environment.',
  );
}
