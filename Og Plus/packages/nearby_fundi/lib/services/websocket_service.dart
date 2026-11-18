// lib/services/websocket_service.dart

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class WebSocketService {
  io.Socket? _socket;
  final String token;
  final int userId;

  final Function(String) onNewMessage;
  final Function(String) onMessageRead;
  final Function(String, bool) onUserTyping;

  WebSocketService({
    required this.token,
    required this.userId,
    required this.onNewMessage,
    required this.onMessageRead,
    required this.onUserTyping,
  });

  void connect() {
    try {
      // 👇 Use the local WebSocket URL from AppConfig
      final String socketUrl = AppConfig.webSocketUrl;

      debugPrint('🔄 Connecting to WebSocket: $socketUrl');

      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token, 'user_id': userId})
            .setPath('/socket.io')
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .enableReconnection()
            .build(),
      );

      _socket?.onConnect((_) {
        debugPrint('✅ WebSocket connected');
        _subscribeToUser();
      });

      _socket?.onConnectError((data) {
        debugPrint('❌ WebSocket connection error: $data');
      });

      _socket?.onDisconnect((_) {
        debugPrint('⚠️ WebSocket disconnected');
      });

      _socket?.on('new-message', (data) {
        debugPrint('📩 New message received: $data');
        onNewMessage(data.toString());
      });

      _socket?.on('message-read', (data) {
        debugPrint('👁️ Message read: $data');
        onMessageRead(data.toString());
      });

      _socket?.on('user-typing', (data) {
        try {
          final Map<String, dynamic> typingData = data;
          final bool typing = typingData['is_typing'] ?? false;
          final String userId = typingData['user_id']?.toString() ?? '';
          onUserTyping(userId, typing);
        } catch (e) {
          debugPrint('Failed to parse typing data: $e');
        }
      });

      _socket?.onError((data) {
        debugPrint('⚠️ Socket error: $data');
      });

    } catch (e) {
      debugPrint('❌ WebSocket initialization error: $e');
    }
  }

  void _subscribeToUser() {
    _socket?.emit('subscribe', {'user_id': userId});
  }

  void subscribeToUser(int userId) {
    _socket?.emit('subscribe', {'user_id': userId});
  }

  void unsubscribeFromUser(int userId) {
    _socket?.emit('unsubscribe', {'user_id': userId});
  }

  void subscribeToTyping(int conversationId) {
    _socket?.emit('subscribe-typing', {'conversation_id': conversationId});
  }

  void sendTypingStatus(int conversationId, bool isTyping) {
    _socket?.emit('user-typing', {
      'conversation_id': conversationId,
      'is_typing': isTyping,
      'user_id': userId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
  }
}