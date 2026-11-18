import '../config/app_config.dart';

class ImageUtils {
  /// Always returns a URL the phone can reach, built from
  /// [AppConfig.storageBaseUrl], whether the API sent a relative path
  /// ("technicians/a.jpg"), "storage/technicians/a.jpg", or a full URL with
  /// the wrong host ("http://localhost/storage/technicians/a.jpg").
  static String getFullImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';

    final raw = path.trim();
    final storageBase = AppConfig.storageBaseUrl.replaceAll(RegExp(r'/+$'), '');

    // Full URL: keep everything after "/storage/" and swap in our host.
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      const marker = '/storage/';
      final i = raw.indexOf(marker);
      if (i == -1) return raw; // external image (not ours), leave alone
      return '$storageBase/${raw.substring(i + marker.length)}';
    }

    // Relative path
    var clean = raw.replaceFirst(RegExp(r'^/+'), '');
    if (clean.startsWith('storage/')) clean = clean.substring('storage/'.length);
    return '$storageBase/$clean';
  }

  static bool isValidImageUrl(String? url) => url != null && url.isNotEmpty;
}