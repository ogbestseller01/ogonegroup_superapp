// lib/services/qr_service.dart
//
// QR payload formats:
//     ogone://app/<slug>?t=<token>   expiring code (checked on the server)
//     ogone://app/<slug>             old permanent code
//
// Only slugs compiled into this build (miniApps) are accepted.

import '../data/mini_apps_data.dart';
import 'api_service.dart';

/// What was read from a QR code.
class QrScan {
  final String slug;
  final String? token;
  const QrScan(this.slug, this.token);
}

enum QrCheck { ok, expired, invalid, offline }

class QrService {
  QrService._();

  static const String scheme = 'ogone';
  static const String host = 'app';

  static String payloadFor(String slug) => '$scheme://$host/$slug';

  /// Returns slug (+ token) for one of our QR codes, otherwise null.
  static QrScan? parse(String? raw) {
    if (raw == null) return null;
    final text = raw.trim();
    if (text.isEmpty || text.length > 300) return null;

    final uri = Uri.tryParse(text);
    if (uri == null) return null;
    if (uri.scheme.toLowerCase() != scheme) return null;
    if (uri.host.toLowerCase() != host) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 1) return null;

    final slug = segments.first.toLowerCase();
    if (!miniApps.any((a) => a.slug == slug)) return null;

    final token = uri.queryParameters['t'];
    return QrScan(slug, (token == null || token.isEmpty) ? null : token);
  }

  /// Kept for old call sites.
  static String? slugFrom(String? raw) => parse(raw)?.slug;

  /// Asks Laravel whether the token is still valid.
  static Future<QrCheck> verify(String token) async {
    final res = await ApiService.instance.verifyQr(token);
    if (res.success) return QrCheck.ok;
    final data = res.data;
    final reason = data is Map ? data['reason'] : null;
    if (reason == 'expired') return QrCheck.expired;
    if (reason == 'invalid') return QrCheck.invalid;
    return QrCheck.offline; // no answer from the server
  }
}