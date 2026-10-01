// lib/services/push_notification_service.dart
//
// Real push notifications (FCM) — app band ho, background ho, ya open ho,
// teeno halaton mein notification mobile ke upar heads-up banner ke sath aayegi.
//
// closed / background : FCM 'notification' payload → Android system khud dikhata hai
//                       (high-importance channel ki wajah se banner + sound)
// foreground          : FCM khud kuch nahi dikhata → flutter_local_notifications se dikhate hain

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'auth_provider.dart';
import '../core/constants/app_constants.dart';
import '../features/chat/data/repositories/chat_repository_impl.dart';
import '../features/chat/domain/entities/conversation_entity.dart';
import '../features/chat/presentation/providers/conversation_list_provider.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/professional/screens/professional_main_screen.dart';

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

  /// MaterialApp(navigatorKey: ...) mein lagana zaroori hai — isi se notification
  /// tap par bina BuildContext ke screen khol sakte hain.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Cold start (app band thi) mein tap hone par app ready hone tak data yahan rukta hai.
  Map<String, dynamic>? _pendingData;
  bool _appReady = false;

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
      await _local.initialize(
        initSettings,
        // Foreground mein dikhayi gayi local notification par tap
        onDidReceiveNotificationResponse: (NotificationResponse r) {
          final payload = r.payload;
          if (payload == null || payload.isEmpty) return;
          try {
            _handleTap(Map<String, dynamic>.from(jsonDecode(payload) as Map));
          } catch (_) {}
        },
      );

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
      _handleTap(Map<String, dynamic>.from(message.data));
    });

    // App bilkul band thi aur notification tap se khuli (cold start)
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] Cold start via notification, data: ${initial.data}');
      _pendingData = Map<String, dynamic>.from(initial.data);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Notification tap → sahi screen par landing
  // ─────────────────────────────────────────────────────────────────

  /// SplashScreen jab home screen par pohanch jaye to ek baar call karo.
  /// Cold start wali pending notification ab khulegi.
  Future<void> onAppReady() async {
    _appReady = true;
    final data = _pendingData;
    _pendingData = null;
    if (data == null) return;
    // Home screen ko build hone ka thora waqt do
    await Future.delayed(const Duration(milliseconds: 400));
    await _navigate(data);
  }

  void _handleTap(Map<String, dynamic> data) {
    if (!_appReady) {
      _pendingData = data; // app abhi splash par hai, baad mein khulegi
      return;
    }
    _navigate(data);
  }

  Future<void> _navigate(Map<String, dynamic> data) async {
    try {
      final nav = navigatorKey.currentState;
      final ctx = navigatorKey.currentContext;
      if (nav == null || ctx == null) return;

      final auth = ctx.read<AuthProvider>();
      final role = auth.role;
      if (!auth.isLoggedIn || role == null) return; // login nahi hai to kuch mat kholo

      final type = data['type']?.toString() ?? 'general';

      switch (type) {
        // 💬 Chat message → seedha us conversation ki chat screen
        case 'chat_message':
          await _openChat(nav, ctx, data);
          break;

        // 📅 Booking → bookings page
        case 'booking':
          if (role == 'professional') {
            nav.popUntil((r) => r.isFirst);
            ProfessionalMainScreen.switchTab(1); // Bookings tab
          } else if (role == 'customer') {
            nav.pushNamed('/bookings');
          } else {
            nav.pushNamed('/notifications');
          }
          break;

        // 📢 Announcement → home (wahan announcement banner dikhta hai)
        case 'announcement':
          nav.popUntil((r) => r.isFirst);
          if (role == 'professional') ProfessionalMainScreen.switchTab(0);
          break;

        // 🔔 Admin notice, 💳 payment, ⭐ review, 🛡️ report, baaki sab → Notifications page
        default:
          nav.pushNamed('/notifications');
      }
    } catch (e) {
      debugPrint('[FCM] Navigation failed: $e');
    }
  }

  Future<void> _openChat(
      NavigatorState nav, BuildContext ctx, Map<String, dynamic> data) async {
    final convId = int.tryParse(data['conversation_id']?.toString() ?? '');
    final senderId = int.tryParse(data['sender_id']?.toString() ?? '');
    if (convId == null) {
      nav.pushNamed('/notifications');
      return;
    }

    // Apna user id (ChatScreen ko chahiye)
    final meRes = await _api.get(AppConstants.me);
    final myId = int.tryParse((meRes.data as Map<String, dynamic>)['id'].toString());
    if (myId == null) return;

    // Conversation ka snapshot — pehle list mein dhoondo, na mile to sender se start/fetch
    final repo = ChatRepositoryImpl();
    ConversationEntity? conv;
    try {
      final list = await repo.getConversations();
      for (final c in list) {
        if (c.id == convId) {
          conv = c;
          break;
        }
      }
    } catch (_) {}
    if (conv == null && senderId != null) {
      try {
        conv = await repo.startConversation(senderId);
      } catch (_) {}
    }
    if (conv == null) {
      nav.pushNamed('/notifications');
      return;
    }

    final opened = conv;
    await nav.push(MaterialPageRoute(
      builder: (_) => ChatScreen(
        conversationId: opened.id,
        currentUserId: myId,
        otherUserName: opened.otherUserName,
        otherUserPhoto: opened.otherUserPhoto,
        conversationSnapshot: opened,
      ),
    ));

    // Chat band hone par unread badge/list refresh
    final currentCtx = navigatorKey.currentContext;
    if (currentCtx != null && currentCtx.mounted) {
      currentCtx.read<ConversationListProvider>().refresh();
    }
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
      payload: jsonEncode(message.data), // tap par kahan jana hai
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