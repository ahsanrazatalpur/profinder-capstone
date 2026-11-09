// lib/app/bootstrap.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';

import '../core/localization/locale_provider.dart';
import '../firebase_options.dart';
import '../services/push_notification_service.dart';
import 'app.dart';

/// Initializes all core application dependencies and renders the UI safely.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely initialize Firebase with defaultPlatform options before UI mount so Firebase.app() is ready
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[Bootstrap] Firebase.initializeApp note: $e');
  }

  // Load persisted language selection / device locale before rendering
  final localeProvider = LocaleProvider();
  try {
    await localeProvider.init();
  } catch (e) {
    debugPrint('[Bootstrap] LocaleProvider init note: $e');
  }

  // Render the application
  runApp(ProFinderApp(localeProvider: localeProvider));

  // Initialize push notification listeners without blocking UI mount
  _initNotifications();
}

Future<void> _initNotifications() async {
  try {
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
    await PushNotificationService().init();
  } catch (e) {
    debugPrint('[Bootstrap] Notification service note: $e');
  }
}
