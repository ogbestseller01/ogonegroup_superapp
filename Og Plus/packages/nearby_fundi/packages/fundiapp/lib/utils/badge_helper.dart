// lib/utils/badge_helper.dart

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class BadgeHelper {
  // ✅ Fixed: custom channel matching MainActivity.kt, no longer clashing
  // with the flutter_local_notifications plugin's own internal channel.
  static const MethodChannel _channel = MethodChannel('com.fundapp/badge');

  /// Updates the app icon badge count (Android via ShortcutBadger, iOS via native handler).
  static Future<void> updateBadge(int count) async {
    debugPrint('📱 Updating badge to count: $count');
    try {
      final result = await _channel.invokeMethod('setBadgeCount', {'count': count});
      debugPrint('✅ Badge updated to $count (native result: $result)');
    } on MissingPluginException catch (e) {
      debugPrint('❌ Badge channel not implemented on this platform: $e');
    } catch (e, stack) {
      debugPrint('❌ Failed to update badge: $e');
      debugPrint(stack.toString());
    }
  }

  /// Clears the app icon badge (call on logout).
  static Future<void> clearBadge() async {
    try {
      await _channel.invokeMethod('removeBadge');
      debugPrint('✅ Badge cleared');
    } on MissingPluginException catch (e) {
      debugPrint('❌ Badge channel not implemented on this platform: $e');
    } catch (e) {
      debugPrint('❌ Failed to clear badge: $e');
    }
  }
}