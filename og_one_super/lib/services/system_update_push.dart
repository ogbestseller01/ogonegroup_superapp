// lib/services/system_update_push.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

typedef SystemUpdateCallback = void Function(int updateId, bool tapped);

class SystemUpdatePush {
  static Future<VoidCallback> listen(SystemUpdateCallback onUpdate) async {
    void handle(RemoteMessage m, bool tapped) {
      if (m.data['type'] != 'system_update') return;
      final id = int.tryParse('${m.data['update_id']}');
      if (id != null) onUpdate(id, tapped);
    }

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) handle(initial, true);

    final opened =
    FirebaseMessaging.onMessageOpenedApp.listen((m) => handle(m, true));
    final fg =
    FirebaseMessaging.onMessage.listen((m) => handle(m, false));

    return () {
      opened.cancel();
      fg.cancel();
    };
  }
}

/// MUST be top-level + registered in main() before runApp().
@pragma('vm:entry-point')
Future<void> systemUpdateBackgroundHandler(RemoteMessage m) async {
  if (m.data['type'] == 'system_update') {
    debugPrint('[FCM/background] system_update ${m.data['update_id']}');
  }
}