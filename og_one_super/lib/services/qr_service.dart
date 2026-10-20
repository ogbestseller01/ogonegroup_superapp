// lib/services/qr_service.dart
//
// QR payload format for mini apps:
//
//     ogone://app/<slug>        e.g.  ogone://app/nearbyfundi
//
// Only slugs that exist in miniApps are accepted, so a random QR code
// (a website, a Wi-Fi code, ...) is rejected instead of opening something.

import '../data/mini_apps_data.dart';

class QrService {
  QrService._();

  static const String scheme = 'ogone';
  static const String host = 'app';

  /// Text that is encoded inside the QR image for a mini app.
  static String payloadFor(String slug) => '$scheme://$host/$slug';

  /// Returns the mini-app slug for a scanned value, or null when the
  /// value is not one of our QR codes.
  static String? slugFrom(String? raw) {
    if (raw == null) return null;
    final text = raw.trim();
    if (text.isEmpty) return null;

    final uri = Uri.tryParse(text);
    if (uri == null) return null;
    if (uri.scheme.toLowerCase() != scheme) return null;
    if (uri.host.toLowerCase() != host) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 1) return null;

    final slug = segments.first.toLowerCase();
    return miniApps.any((a) => a.slug == slug) ? slug : null;
  }
}