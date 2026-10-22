// lib/services/mini_app_service.dart
//
// Gives the dashboard the list of mini apps.
//
//  * Starts with the compiled list (data/mini_apps_data.dart), so the
//    dashboard works offline and on first launch.
//  * refresh() asks Laravel (GET /v24/mini-apps) and applies what the server
//    says: which apps are active, their order, name/subtitle and the
//    "coming soon" flag.
//  * The server can only switch apps on/off or change labels. A mini app
//    that is not compiled into this build can never be opened.

import 'package:flutter/foundation.dart';

import '../data/mini_apps_data.dart';
import '../models/mini_app.dart';
import 'api_service.dart';

class MiniAppService {
  MiniAppService._();
  static final MiniAppService instance = MiniAppService._();

  List<MiniApp> _apps = List.unmodifiable(miniApps);

  /// Current list (server-adjusted when available, otherwise built-in).
  List<MiniApp> get apps => _apps;

  MiniApp? bySlug(String slug) {
    for (final a in _apps) {
      if (a.slug == slug) return a;
    }
    return null;
  }

  /// Never throws; on any failure the previous list is kept.
  /// Returns true when the server list was applied.
  Future<bool> refresh() async {
    try {
      // Short timeout so a dead server never keeps the skeleton on screen
      // for the full 20 s Dio timeout.
      final res = await ApiService.instance
          .getMiniApps()
          .timeout(const Duration(seconds: 4));
      if (!res.success || res.data is! List) return false;

      final result = <MiniApp>[];
      for (final item in res.data as List) {
        if (item is! Map) continue;
        final slug = (item['slug'] ?? '').toString().toLowerCase();
        if (slug.isEmpty) continue;

        final local = miniApps.where((a) => a.slug == slug);
        if (local.isEmpty) continue; // not compiled into this build

        result.add(local.first.copyWith(
          name: item['name']?.toString(),
          subtitle: item['subtitle']?.toString(),
          isComingSoon:
          item['is_coming_soon'] == true || item['is_coming_soon'] == 1,
        ));
      }

      // Empty / unseeded server: keep the built-in list.
      if (result.isEmpty) return false;

      _apps = List.unmodifiable(result);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('MiniAppService.refresh failed: $e');
      return false;
    }
  }
}