// lib/services/mini_app_service.dart
//
// Gives the dashboard the list of mini apps.
//
//  * Starts with the compiled list (data/mini_apps_data.dart), so the
//    dashboard works offline and on first launch.
//  * refresh() asks Laravel (GET /v24/mini-apps) and applies what the server
//    says: which apps are active, their order, name/subtitle and the
//    "coming soon" flag.
//  * Local apps that the server does not know yet are still kept
//    (so new apps like Dalali Online appear immediately).

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
      final res = await ApiService.instance
          .getMiniApps()
          .timeout(const Duration(seconds: 4));

      if (!res.success || res.data is! List) return false;

      // Map of what the server returned (slug → data)
      final serverMap = <String, Map>{};
      for (final item in res.data as List) {
        if (item is! Map) continue;
        final slug = (item['slug'] ?? '').toString().toLowerCase();
        if (slug.isEmpty) continue;
        serverMap[slug] = item;
      }

      // Start from the full local list and apply server overrides
      final result = <MiniApp>[];
      for (final local in miniApps) {
        final server = serverMap[local.slug];

        if (server != null) {
          // Server knows this app → use its labels & coming-soon flag
          result.add(local.copyWith(
            name: server['name']?.toString(),
            subtitle: server['subtitle']?.toString(),
            isComingSoon: server['is_coming_soon'] == true ||
                server['is_coming_soon'] == 1,
          ));
        } else {
          // Server does not know this app yet → keep the local version
          result.add(local);
        }
      }

      if (result.isEmpty) return false;

      _apps = List.unmodifiable(result);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('MiniAppService.refresh failed: $e');
      return false;
    }
  }
}