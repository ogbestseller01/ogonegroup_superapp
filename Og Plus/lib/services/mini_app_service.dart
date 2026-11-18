
import 'package:flutter/foundation.dart';

import '../data/mini_apps_data.dart';
import '../models/mini_app.dart';
import 'api_service.dart';

class MiniAppService {
  MiniAppService._();

  static final MiniAppService instance = MiniAppService._();

  // Local apps provide offline and first-launch support.
  List<MiniApp> _apps = List.unmodifiable(miniApps);

  /// Returns the current list of mini apps.
  List<MiniApp> get apps => _apps;

  /// Finds an app using its slug.
  MiniApp? bySlug(String slug) {
    final normalizedSlug = slug.trim().toLowerCase();

    for (final app in _apps) {
      if (app.slug.toLowerCase() == normalizedSlug) {
        return app;
      }
    }

    return null;
  }

  /// Converts API values safely into booleans.
  bool _parseBool(dynamic value, {required bool fallback}) {
    if (value == null) return fallback;

    if (value is bool) return value;

    if (value is num) return value != 0;

    switch (value.toString().trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'active':
        return true;

      case 'false':
      case '0':
      case 'no':
      case 'inactive':
        return false;

      default:
        return fallback;
    }
  }

  /// Uses a server string only when it is not empty.
  String? _parseString(dynamic value) {
    if (value == null) return null;

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }

  /// Refreshes the local app list using Laravel.
  ///
  /// - Keeps local apps available offline.
  /// - Updates names and subtitles from Laravel.
  /// - Updates coming-soon status.
  /// - Preserves local-only apps.
  /// - Preserves local properties such as isDemo.
  /// - Never replaces the previous list on failure.
  ///
  /// Returns true when server data is successfully applied.
  Future<bool> refresh() async {
    try {
      final response = await ApiService.instance
          .getMiniApps()
          .timeout(const Duration(seconds: 4));

      if (!response.success || response.data is! List) {
        return false;
      }

      final serverApps = <String, Map<String, dynamic>>{};

      // Prepare server data using app slugs.
      for (final item in response.data as List) {
        if (item is! Map) continue;

        final slug = (item['slug'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        if (slug.isEmpty) continue;

        serverApps[slug] = Map<String, dynamic>.from(item);
      }

      // Apply server updates to the complete local app list.
      final updatedApps = <MiniApp>[];

      for (final localApp in miniApps) {
        final serverApp =
        serverApps[localApp.slug.toLowerCase()];

        if (serverApp == null) {
          // Keep local apps not registered on the server.
          updatedApps.add(localApp);
          continue;
        }

        updatedApps.add(
          localApp.copyWith(
            name: _parseString(serverApp['name']) ?? localApp.name,
            subtitle:
            _parseString(serverApp['subtitle']) ?? localApp.subtitle,
            isComingSoon: _parseBool(
              serverApp['is_coming_soon'],
              fallback: localApp.isComingSoon,
            ),
          ),
        );
      }

      if (updatedApps.isEmpty) return false;

      // Replace the list only after successful processing.
      _apps = List.unmodifiable(updatedApps);

      if (kDebugMode) {
        debugPrint(
          'MiniAppService: Successfully refreshed '
              '${updatedApps.length} mini apps.',
        );
      }

      return true;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('MiniAppService.refresh failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      // Keep the previous list if the request fails.
      return false;
    }
  }
}
