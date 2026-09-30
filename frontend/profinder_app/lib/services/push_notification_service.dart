// lib/services/push_notification_service.dart
//
// Real push notifications (FCM) — app band ho, background ho, ya open ho,
// teeno halaton mein notification mobile ke upar heads-up banner ke sath aayegi.
//
// closed / background : FCM 'notification' payload → Android system khud dikhata hai
//                       (high-importance channel ki wajah se banner + sound)
// foreground          : FCM khud kuch nahi dikhata → flutter_local_notifications se dikhate hain

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import '../core/constants/app_constants.dart';

/// IMPORTANT: Background handler top-level (class ke bahar) function
/// hona zaroori hai — Flutter ka requirement hai, warna kaam nahi karega.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // App background/killed state mein ho tab ye chalta hai.
  // 'notification' payload wale messages ko Android system khud tray mein dikha deta hai.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final _api = ApiService();
  final _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  bool _tokenListenerAttached = false;

  // IDs backend (notifications/utils.py & messaging/push.py) ke channel_id se match hone chahiye.
  // Importance.max = heads-up banner + sound. Default FCM channel ka importance kam hota hai,
  // isliye banner nahi aata — yehi asal masla tha.
  static const AndroidNotificationChannel _generalChannel = AndroidNotificationChannel(
    'profinder_default_channel',
    'General Notifications',
    description: 'Bookings, announcements, reports and other alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  static const AndroidNotificationChannel _chatChannel = AndroidNotificationChannel(
    'profinder_chat_channel',
    'Chat Messages',
    description: 'New chat messages',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// main.dart mein app start hote hi (runApp se pehle) ek baar call karo.
  Future<void> init() async {
    // Notification permission maango — iOS aur Android 13+ par zaroori hai
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // iOS: foreground mein bhi banner dikhao
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android: high-importance channels banao + local notifications init
    if (_isAndroid) {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _local.initialize(initSettings);

      final androidImpl = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(_generalChannel);
      await androidImpl?.createNotificationChannel(_chatChannel);
    }

    // App foreground mein khuli ho aur notification aaye
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('[FCM] Foreground: ${message.notification?.title} — ${message.notification?.body}');
      await _showForegroundNotification(message);
    });

    // User ne notification tap ki aur app khuli
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Opened via notification, data: ${message.data}');
      // Chahein to yahan specific screen (jese booking detail) par navigate karo
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    // iOS foreground banner system khud dikhata hai (upar ki presentation options)
    if (!_isAndroid) return;
    final n = message.notification;
    if (n == null) return;

    final isChat = message.data['type'] == 'chat_message';
    final ch = isChat ? _chatChannel : _generalChannel;

    await _local.show(
      DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff),
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          ch.id,
          ch.name,
          channelDescription: ch.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Login / app-start (already logged in) ke baad call karo — device ka token
  /// backend ko bhejta hai taake backend us device ko push bhej sake.
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
    if (!_tokenListenerAttached) {
      _tokenListenerAttached = true;
      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          await _api.patch(AppConstants.me, {'fcm_token': newToken});
          debugPrint('[FCM] Token refreshed & updated');
        } catch (_) {}
      });
    }
  }

  /// Logout par call karo (JWT hatane se PEHLE) — is device ko is account se alag karo.
  Future<void> unregisterToken() async {
    try {
      await _api.patch(AppConstants.me, {'fcm_token': ''});
      await _messaging.deleteToken(); // agla login naya token lega
      debugPrint('[FCM] Token unregistered');
    } catch (e) {
      debugPrint('[FCM] Token unregister failed: $e');
    }
  }
}