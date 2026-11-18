// lib/services/location_sharing_service.dart

import 'technician_heartbeat_service.dart';

/// Simple facade for live location sharing.
/// Used while the Fundi is on the way / in progress.
class LocationSharingService {
  LocationSharingService._(); // prevent instantiation

  static final TechnicianHeartbeatService _heartbeat =
  TechnicianHeartbeatService();

  /// Start continuous GPS sharing (call when status becomes on_the_way)
  static void startSharing() {
    if (_heartbeat.isRunning) return;
    _heartbeat.start();
  }

  /// Stop GPS sharing (call on completed / cancelled / rejected)
  static void stopSharing() {
    if (!_heartbeat.isRunning) return;
    _heartbeat.stop();
  }

  /// Whether location is currently being shared
  static bool get isSharing => _heartbeat.isRunning;
}