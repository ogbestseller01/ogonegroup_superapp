import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class ImageUtils {
  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      debugPrint('🖼️ ImageUtils → path is null/empty');
      return '';
    }

    // Already a full URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      debugPrint('🖼️ ImageUtils → already full URL: $path');
      return path;
    }

    // Remove trailing /api
    String base = AppConfig.baseUrl.replaceAll(RegExp(r'/api/?$'), '');

    // Clean path
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;

    String finalUrl;
    if (cleanPath.startsWith('storage/')) {
      finalUrl = '$base/$cleanPath';
    } else {
      finalUrl = '$base/storage/$cleanPath';
    }

    debugPrint('🖼️ ImageUtils → original: $path');
    debugPrint('🖼️ ImageUtils → final URL: $finalUrl');
    return finalUrl;
  }

  static bool isValidImageUrl(String? url) {
    return url != null && url.isNotEmpty;
  }
}