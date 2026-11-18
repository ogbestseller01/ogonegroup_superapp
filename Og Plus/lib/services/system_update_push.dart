// lib/services/system_update_push.dart
//
// Firebase-free system-update poller.
//
// Public API (unchanged from the old FCM version):
//
//   final stop = await SystemUpdatePush.listen((id, tapped) async { ... });
//
// Behaviour:
//   • Polls the backend for the latest active system update.
//   • Fires the callback once per new update id.
//   • `tapped` is always false — no OS-level push is observed without Firebase.
//   • Optionally calls `provider.refresh()` so the UI reacts immediately.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../providers/system_update_provider.dart';
import 'api_service.dart';

typedef SystemUpdateCallback = Future<void> Function(int id, bool tapped);

class SystemUpdatePush {
  SystemUpdatePush._();

  static const Duration _pollInterval = Duration(seconds: 45);
  static const Duration _firstPollDelay = Duration(seconds: 2);

  /// Start listening. Returns a `stop()` function you must call in dispose.
  static Future<Future<void> Function()> listen(
      SystemUpdateCallback onUpdate, {
        SystemUpdateProvider? provider,
        bool skipInitial = true,
      }) async {
    int? lastDeliveredId;
    Timer? timer;
    bool stopped = false;

    Future<Map<String, dynamic>?> fetchLatest() async {
      final res = await ApiService.instance.getActiveSystemUpdates();
      if (!res.success) return null;

      final payload = res.data;
      dynamic first;

      if (payload is List && payload.isNotEmpty) {
        first = payload.first;
      } else if (payload is Map && payload['data'] is List) {
        final list = payload['data'] as List;
        if (list.isEmpty) return null;
        first = list.first;
      } else {
        return null;
      }

      if (first is! Map) return null;
      return Map<String, dynamic>.from(first);
    }

    if (skipInitial) {
      try {
        final seed = await fetchLatest();
        lastDeliveredId = int.tryParse('${seed?['id']}');
      } catch (e, st) {
        debugPrint('SystemUpdatePush.seed error: $e\n$st');
      }
    }

    Future<void> poll() async {
      if (stopped) return;

      try {
        final update = await fetchLatest();
        if (update == null) return;

        final id = int.tryParse('${update['id']}');
        if (id == null) return;
        if (lastDeliveredId != null && id <= lastDeliveredId!) return;

        lastDeliveredId = id;

        if (provider != null) {
          try {
            await provider.refresh();
          } catch (e, st) {
            debugPrint('SystemUpdatePush.provider.refresh error: $e\n$st');
          }
        }

        await onUpdate(id, false);
      } catch (e, st) {
        debugPrint('SystemUpdatePush.poll error: $e\n$st');
      }
    }

    unawaited(Future.delayed(_firstPollDelay, poll));
    timer = Timer.periodic(_pollInterval, (_) => unawaited(poll()));

    return () async {
      stopped = true;
      timer?.cancel();
      timer = null;
    };
  }

  /// Call from a notification-tap handler if you add local notifications later.
  static Future<void> handleTap(int id) async {
    // No-op until local notifications are wired up.
  }
}