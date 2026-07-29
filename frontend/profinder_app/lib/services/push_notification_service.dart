// lib/services/push_notification_service.dart
//
// Real push notifications (FCM) — app band ho, background ho, ya open ho,
// teeno halaton mein notification aayegi.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../core/constants/app_constants.dart';

/// IMPORTANT: Background handler top-level (class ke bahar) function
/// hona zaroori hai — Flutter ka requirement hai, warna kaam nahi karega.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // App background/killed state mein ho tab ye chalta hai.
  // Yahan heavy/UI kaam mat karo — sirf lightweight handling.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final _api = ApiService();
  final _messaging = FirebaseMessaging.instance;

  /// main.dart mein app start hote hi (runApp se pehle) ek baar call karo.
  Future<void> init() async {
    // Notification permission maango — iOS aur Android 13+ par zaroori hai
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // App foreground mein khuli ho aur notification aaye
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title} — ${message.notification?.body}');
      // Chahein to yahan ek in-app banner/snackbar dikha sakte hain
    });

    // User ne notification tap ki aur app khuli
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Opened via notification, data: ${message.data}');
      // Chahein to yahan specific screen (jese booking detail) par navigate karo
    });
  }

  /// Login successful hone ke baad call karo — device ka token backend ko bhejta hai
  /// taake backend us device ko push bhej sake.
  Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('[FCM] Could not get token (web ke liye VAPID key chahiye ho sakti hai)');
        return;
      }
      await _api.patch(AppConstants.me, {'fcm_token': token});
      debugPrint('[FCM] Token registered with backend');
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }

    // Token kabhi refresh ho jaye (app reinstall, cache clear, etc.) to backend update karo
    _messaging.onTokenRefresh.listen((newToken) async {
      try {
        await _api.patch(AppConstants.me, {'fcm_token': newToken});
        debugPrint('[FCM] Token refreshed & updated');
      } catch (_) {}
    });
  }
}