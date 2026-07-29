// lib/features/chat/data/datasources/chat_socket_data_source.dart
//
// One instance = one live connection to ws/chat/<conversation_id>/.
// Speaks the exact protocol defined by apps/messaging/consumers.py:
//
//   OUTBOUND action:            INBOUND type:
//   - send_message              - new_message
//   - typing                    - typing
//   - mark_delivered            - status_update
//   - mark_seen                 - presence
//
// Requires the `web_socket_channel` package (add to pubspec.yaml — see
// note at the end of the response).

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/message_model.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatSocketDataSource {
  WebSocketChannel? _channel;
  StreamController<ChatSocketEvent>? _controller;

  bool get isConnected => _channel != null;

  Future<Stream<ChatSocketEvent>> connect(int conversationId) async {
    await disconnect(); // guard against double-connect if a screen re-enters fast

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.accessTokenKey);
    final uri = Uri.parse('${AppConstants.wsBaseUrl}${AppConstants.wsChat(conversationId)}?token=$token');

    _controller = StreamController<ChatSocketEvent>.broadcast();
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (raw) => _handleRaw(raw),
      onError: (err) => _controller?.add(SocketErrorEvent(err.toString())),
      onDone: () {
        // Server closed the socket (e.g. token expired -> code 4001,
        // not a member -> 4003). The provider decides whether to
        // fall back to REST-only mode.
      },
      cancelOnError: false,
    );

    return _controller!.stream;
  }

  void _handleRaw(dynamic raw) {
    if (_controller == null || _controller!.isClosed) return;
    late final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return; // ignore malformed frames rather than crash the stream
    }

    switch (data['type']) {
      case 'new_message':
        final msgJson = data['message'] as Map<String, dynamic>;
        _controller!.add(NewMessageSocketEvent(
          MessageModel.fromJson(msgJson),
          tempId: msgJson['temp_id']?.toString(),
        ));
        break;
      case 'typing':
        _controller!.add(TypingSocketEvent(
          int.parse(data['user_id'].toString()),
          data['is_typing'] == true,
        ));
        break;
      case 'status_update':
        _controller!.add(StatusUpdateSocketEvent(
          data['event'].toString(),
          (data['message_ids'] as List).map((e) => e.toString()).toList(),
          int.parse(data['actor_user_id'].toString()),
        ));
        break;
      case 'presence':
        _controller!.add(PresenceSocketEvent(
          int.parse(data['user_id'].toString()),
          data['is_online'] == true,
          data['last_seen'] != null ? DateTime.parse(data['last_seen'].toString()).toLocal() : null,
        ));
        break;
      // ✅ NEW — reactions
      case 'reaction_update':
        final msgJson = data['message'] as Map<String, dynamic>;
        _controller!.add(ReactionSocketEvent(MessageModel.fromJson(msgJson)));
        break;
      case null:
        if (data['error'] != null) _controller!.add(SocketErrorEvent(data['error'].toString()));
        break;
    }
  }

  void _sendJson(Map<String, dynamic> payload) {
    if (_channel == null) return; // socket down -> caller already fell back to REST
    _channel!.sink.add(jsonEncode(payload));
  }

  void sendTyping(bool isTyping) => _sendJson({'action': 'typing', 'is_typing': isTyping});

  void sendMessage({required String text, String? replyToId, required String tempId}) {
    _sendJson({
      'action': 'send_message',
      'text': text,
      'temp_id': tempId,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
  }

  void sendMarkDelivered() => _sendJson({'action': 'mark_delivered'});
  void sendMarkSeen() => _sendJson({'action': 'mark_seen'});

  Future<void> disconnect() async {
    await _channel?.sink.close();
    await _controller?.close();
    _channel = null;
    _controller = null;
  }
}