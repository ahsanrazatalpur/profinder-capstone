// lib/features/auth/services/google_auth_desktop_io.dart
// Native desktop loopback authentication handler for Windows, macOS, and Linux.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'google_auth_service.dart';

Future<GoogleAuthResult> performDesktopGoogleSignIn(
  BuildContext context, {
  required String role,
  required String baseUrl,
}) async {
  HttpServer? server;
  StreamSubscription? subscription;
  final completer = Completer<GoogleAuthResult>();

  try {
    // 1. Bind to a random free loopback port on 127.0.0.1
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;

    // 2. Build web authentication URL
    final authUrl = '$baseUrl/users/google/web-auth/?port=$port&role=$role';
    final uri = Uri.parse(authUrl);

    // 3. Listen for browser callback on loopback server
    subscription = server.listen((HttpRequest request) async {
      try {
        if (request.uri.path == '/auth') {
          final idToken = request.uri.queryParameters['id_token'];
          final accessToken = request.uri.queryParameters['access_token'];

          // Return polite closing HTML to browser
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.html;
          request.response.write('''
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <title>ProFinder Authentication</title>
              <style>
                body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; text-align: center; padding: 60px 20px; background: #F8FAFC; color: #0F172A; }
                .box { max-width: 420px; margin: auto; background: #FFF; padding: 36px; border-radius: 16px; border: 1px solid #E2E8F0; }
                h2 { color: #2563EB; margin-bottom: 8px; }
                p { color: #64748B; font-size: 14px; }
              </style>
            </head>
            <body>
              <div class="box">
                <h2>✓ Sign-in Complete</h2>
                <p>You can close this window and return to your ProFinder Desktop app.</p>
              </div>
              <script>setTimeout(function(){ window.close(); }, 2000);</script>
            </body>
            </html>
          ''');
          await request.response.close();

          if (!completer.isCompleted) {
            if (idToken != null || accessToken != null) {
              completer.complete(
                GoogleAuthResult.success(
                  idToken: idToken,
                  accessToken: accessToken,
                ),
              );
            } else {
              completer.complete(
                GoogleAuthResult.error('No token returned from Google.'),
              );
            }
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      } catch (err) {
        if (!completer.isCompleted) {
          completer.complete(
            GoogleAuthResult.error('Error handling loopback callback: $err'),
          );
        }
      }
    });

    // 4. Launch default browser
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // 5. Show in-app tracking modal with manual token fallback
    if (context.mounted) {
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) {
            final tokenController = TextEditingController();
            bool showManualInput = false;

            return StatefulBuilder(
              builder: (ctx, setDialogState) {
                // If completer finished, close dialog automatically
                if (completer.isCompleted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                  });
                }

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.open_in_browser, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Google Sign-In'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'A browser window has opened for Google authentication. Complete your login there to continue.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!showManualInput)
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setDialogState(() => showManualInput = true);
                            },
                            child: const Text(
                              'Didn\'t redirect automatically? Paste token',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      if (showManualInput) ...[
                        const Divider(),
                        const Text(
                          'Paste token from browser:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: tokenController,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Paste JWT id_token here...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              final text = tokenController.text.trim();
                              if (text.isNotEmpty && !completer.isCompleted) {
                                completer.complete(
                                  GoogleAuthResult.success(idToken: text),
                                );
                                Navigator.of(dialogCtx).pop();
                              }
                            },
                            child: const Text('Submit Token'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: const Text('Re-open Browser'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (!completer.isCompleted) {
                          completer.complete(GoogleAuthResult.cancelled());
                        }
                        Navigator.of(dialogCtx).pop();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
    }

    // 6. Wait for result with a generous 4-minute timeout
    final result = await completer.future.timeout(
      const Duration(minutes: 4),
      onTimeout: () {
        return GoogleAuthResult.error(
          'Google authentication timed out. Please try again.',
        );
      },
    );

    return result;
  } catch (e) {
    return GoogleAuthResult.error('Desktop Google Sign-In failed: $e');
  } finally {
    await subscription?.cancel();
    await server?.close(force: true);
  }
}
