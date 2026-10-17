// lib/features/notifications/services/push_notification_service.dart
//
// Real push notifications (FCM) — app closed, background, or foreground heads-up banner support.

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_service.dart';
import '../../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../../features/chat/domain/entities/conversation_entity.dart';
import '../../../features/chat/presentation/providers/conversation_list_provider.dart';
import '../../../features/chat/presentation/screens/chat_screen.dart';
import '../../../features/professional/screens/professional_main_screen.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/auth_provider.dart';

/// Top-level background message handler required by Flutter FCM.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final _api = ApiService();
  final _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _tokenListenerAttached = false;

  /// Global navigator key for navigation without local BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Map<String, dynamic>? _pendingData;
  bool _appReady = false;

  static const AndroidNotificationChannel _generalChannel =
      AndroidNotificationChannel(
        'profinder_default_channel',
        'General Notifications',
        description: 'Bookings, announcements, reports and other alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
        'profinder_chat_channel',
        'Chat Messages',
        description: 'New chat messages',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  String? _channelLang;

  Future<void> updateChannelLocalization(AppLocalizations t) async {
    if (!_isAndroid || _channelLang == t.localeName) return;
    _channelLang = t.localeName;
    try {
      final impl = _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await impl?.createNotificationChannel(
        AndroidNotificationChannel(
          _generalChannel.id,
          t.pushChannelGeneralName,
          description: t.pushChannelGeneralDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await impl?.createNotificationChannel(
        AndroidNotificationChannel(
          _chatChannel.id,
          t.pushChannelChatName,
          description: t.pushChannelChatDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    } catch (e) {
      debugPrint('[FCM] updateChannelLocalization failed: $e');
    }
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> init() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (_isAndroid) {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _local.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse r) {
          final payload = r.payload;
          if (payload == null || payload.isEmpty) return;
          try {
            _handleTap(Map<String, dynamic>.from(jsonDecode(payload) as Map));
          } catch (_) {}
        },
      );

      final androidImpl = _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.createNotificationChannel(_generalChannel);
      await androidImpl?.createNotificationChannel(_chatChannel);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
        '[FCM] Foreground: ${message.notification?.title} — ${message.notification?.body}',
      );
      await _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Opened via notification, data: ${message.data}');
      _handleTap(Map<String, dynamic>.from(message.data));
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] Cold start via notification, data: ${initial.data}');
      _pendingData = Map<String, dynamic>.from(initial.data);
    }
  }

  Future<void> onAppReady() async {
    _appReady = true;
    final data = _pendingData;
    _pendingData = null;
    if (data == null) return;
    await Future.delayed(const Duration(milliseconds: 400));
    await _navigate(data);
  }

  void _handleTap(Map<String, dynamic> data) {
    if (!_appReady) {
      _pendingData = data;
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
      if (!auth.isLoggedIn || role == null) return;

      final type = data['type']?.toString() ?? 'general';

      switch (type) {
        case 'chat_message':
          await _openChat(nav, ctx, data);
          break;

        case 'booking':
          if (role == 'professional') {
            nav.popUntil((r) => r.isFirst);
            ProfessionalMainScreen.switchTab(1);
          } else if (role == 'customer') {
            nav.pushNamed('/bookings');
          } else {
            nav.pushNamed('/notifications');
          }
          break;

        case 'announcement':
          nav.popUntil((r) => r.isFirst);
          if (role == 'professional') ProfessionalMainScreen.switchTab(0);
          break;

        default:
          nav.pushNamed('/notifications');
      }
    } catch (e) {
      debugPrint('[FCM] Navigation failed: $e');
    }
  }

  Future<void> _openChat(
    NavigatorState nav,
    BuildContext ctx,
    Map<String, dynamic> data,
  ) async {
    final convId = int.tryParse(data['conversation_id']?.toString() ?? '');
    final senderId = int.tryParse(data['sender_id']?.toString() ?? '');
    if (convId == null) {
      nav.pushNamed('/notifications');
      return;
    }

    final meRes = await _api.get(AppConstants.me);
    final myId = int.tryParse(
      (meRes.data as Map<String, dynamic>)['id'].toString(),
    );
    if (myId == null) return;

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
    await nav.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: opened.id,
          currentUserId: myId,
          otherUserName: opened.otherUserName,
          otherUserPhoto: opened.otherUserPhoto,
          conversationSnapshot: opened,
        ),
      ),
    );

    final currentCtx = navigatorKey.currentContext;
    if (currentCtx != null && currentCtx.mounted) {
      currentCtx.read<ConversationListProvider>().refresh();
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
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
      payload: jsonEncode(message.data),
    );
  }

  Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('[FCM] Could not get token (web may require VAPID key)');
        return;
      }
      await _api.patch(AppConstants.me, {'fcm_token': token});
      debugPrint('[FCM] Token registered with backend');
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }

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

  Future<void> unregisterToken() async {
    try {
      await _api.patch(AppConstants.me, {'fcm_token': ''});
      await _messaging.deleteToken();
      debugPrint('[FCM] Token unregistered');
    } catch (e) {
      debugPrint('[FCM] Token unregister failed: $e');
    }
  }
}
