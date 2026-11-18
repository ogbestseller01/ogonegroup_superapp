import '../config/app_config.dart';

class ImageUtils {
  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = AppConfig.baseUrl.replaceFirst('/api', '');
    if (path.startsWith('storage/')) return '$base/$path';
    return '$base/storage/$path';
  }
}