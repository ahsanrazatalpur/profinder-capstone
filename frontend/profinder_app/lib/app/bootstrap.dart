// lib/app/bootstrap.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../core/localization/locale_provider.dart';
import '../firebase_options.dart';
import '../services/push_notification_service.dart';
import 'app.dart';

/// Initializes all core application dependencies before rendering the first frame.
///
/// Ensures:
/// - Flutter bindings are initialized.
/// - Firebase and background messaging are configured.
/// - Push notification service and channels are set up.
/// - Persisted user language is loaded to avoid language flashing on startup.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService().init();

  // Load persisted language selection / device locale before rendering
  final localeProvider = LocaleProvider();
  await localeProvider.init();

  runApp(ProFinderApp(localeProvider: localeProvider));
}
