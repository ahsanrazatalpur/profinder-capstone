// lib/features/auth/services/google_auth_desktop_stub.dart
// Web fallback stub — launches the web auth bridge in browser environments.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import 'google_auth_service.dart';

Future<GoogleAuthResult> performDesktopGoogleSignIn(
  BuildContext context, {
  required String role,
  required String baseUrl,
}) async {
  final completer = Completer<GoogleAuthResult>();
  final authUrl = '$baseUrl/users/google/web-auth/?role=$role';
  final uri = Uri.parse(authUrl);

  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    debugPrint('[GOOGLE WEB BRIDGE LAUNCH ERROR] $e');
  }

  if (!context.mounted) {
    return GoogleAuthResult.error('Context is no longer mounted.');
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      final tokenController = TextEditingController();

      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: const Row(
          children: [
            Icon(Icons.open_in_browser, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Google Sign-In Bridge'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A new tab has opened for Google authentication. Complete your login there, then paste the verification token below:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: tokenController,
              maxLines: 3,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'Paste JWT id_token here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(8),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final text = tokenController.text.trim();
                  if (text.isNotEmpty && !completer.isCompleted) {
                    completer.complete(GoogleAuthResult.success(idToken: text));
                    Navigator.of(dialogCtx).pop();
                  }
                },
                child: const Text('Complete Sign-In'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!completer.isCompleted) {
                completer.complete(GoogleAuthResult.cancelled());
              }
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );

  return completer.isCompleted
      ? await completer.future
      : GoogleAuthResult.cancelled();
}

