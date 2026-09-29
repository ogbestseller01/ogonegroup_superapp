import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Stub WebSocket service – does nothing.
/// Replace with a real WebSocket implementation (e.g., `web_socket_channel`) when needed.
class WebSocketService {
  final String token;
  final int userId;

  final void Function(Map<String, dynamic>) onNewMessage;
  final void Function(Map<String, dynamic>) onMessageRead;
  final void Function(Map<String, dynamic>) onUserTyping;
  final void Function()? onConnected;
  final void Function()? onDisconnected;
  final void Function(String)? onError;

  bool _isConnected = false;
  final Set<String> _subscribedChannels = {};

  bool get isConnected => _isConnected;
  bool get isReady => _isConnected;

  WebSocketService({
    required this.token,
    required this.userId,
    required this.onNewMessage,
    required this.onMessageRead,
    required this.onUserTyping,
    this.onConnected,
    this.onDisconnected,
    this.onError,
  });

  // ============================================
  // CONNECTION MANAGEMENT (stubbed)
  // ============================================

  Future<void> connect() async {
    if (_isConnected) {
      debugPrint('⚠️ WebSocket already connected (stub)');
      return;
    }
    debugPrint('🔌 WebSocket connect called (stub – doing nothing)');
    // In a real implementation, you would establish a WebSocket connection here.
    // For now, we just fake a connection.
    _isConnected = true;
    onConnected?.call();
  }

  Future<void> disconnect() async {
    if (!_isConnected) return;
    debugPrint('🔌 WebSocket disconnect called (stub)');
    _isConnected = false;
    _subscribedChannels.clear();
    onDisconnected?.call();
  }

  Future<void> reconnect() async {
    debugPrint('🔄 WebSocket reconnect called (stub)');
    await disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    await connect();
  }

  void forceReconnect() {
    reconnect();
  }

  // ============================================
  // CHANNEL NAMING (kept for compatibility)
  // ============================================

  String _userChannel(int uid) => 'private-App.Models.User.$uid';
  String _conversationChannel(int conversationId) =>
      'private-conversation.$conversationId';

  // ============================================
  // SUBSCRIPTION METHODS (stubbed)
  // ============================================

  void subscribeToUser(int uid) {
    _subscribe(_userChannel(uid));
  }

  void unsubscribeFromUser(int uid) {
    _unsubscribe(_userChannel(uid));
  }

  void subscribeToTyping(int conversationId) {
    _subscribe(_conversationChannel(conversationId));
  }

  void unsubscribeFromTyping(int conversationId) {
    _unsubscribe(_conversationChannel(conversationId));
  }

  Future<void> _subscribe(String channelName) async {
    if (_subscribedChannels.contains(channelName)) return;
    _subscribedChannels.add(channelName);
    debugPrint('📡 Subscribed to $channelName (stub)');
  }

  Future<void> _unsubscribe(String channelName) async {
    if (!_subscribedChannels.contains(channelName)) return;
    _subscribedChannels.remove(channelName);
    debugPrint('📡 Unsubscribed from $channelName (stub)');
  }

  // ============================================
  // EVENT EMITTERS – No‑ops (handled by Laravel)
  // ============================================

  void sendTypingStatus(int conversationId, bool isTyping) {
    // Handled server‑side via REST – no action needed here.
  }

  void sendPing() {}

  void markMessageAsRead(int messageId) {
    // Handled server‑side via REST – no action needed here.
  }

  // ============================================
  // PUSHER CALLBACKS – removed (no longer needed)
  // ============================================

  // The following callbacks are no longer used because we don't have Pusher.
  // In a real WebSocket implementation, you would handle incoming messages here.

  // ============================================
  // CLEANUP
  // ============================================

  void dispose() {
    disconnect();
  }
}