// lib/services/fcm_event_bus.dart

import 'dart:async';

/// Broadcasts live FCM events (foreground pushes) to any listener.
/// This decouples the static [FcmService] from app state (Providers),
/// so the in-app UI (e.g. the notification bell) can react instantly
/// instead of waiting for a manual refresh.
class FcmEventBus {
  FcmEventBus._();

  static final FcmEventBus instance = FcmEventBus._();

  final StreamController<Map<String, dynamic>> _controller =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void emit(Map<String, dynamic> data) {
    if (!_controller.isClosed) {
      _controller.add(data);
    }
  }

  void dispose() {
    _controller.close();
  }
}