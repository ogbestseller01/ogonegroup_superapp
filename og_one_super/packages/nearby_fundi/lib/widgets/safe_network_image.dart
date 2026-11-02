// lib/widgets/safe_network_image.dart
import 'package:flutter/material.dart';

/// Network image that never retries a URL that already failed (404, timeout…).
///
/// - Empty / null URL  -> [fallback]
/// - Failed URL        -> [fallback] (and remembered, so the server is not
///                        asked again on every rebuild)
class SafeNetworkImage extends StatelessWidget {
  const SafeNetworkImage({
    super.key,
    required this.url,
    required this.fallback,
    this.size,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  final String? url;
  final Widget fallback;
  final double? size;
  final BoxFit fit;
  final int? cacheWidth;

  static const int _maxRemembered = 200;
  static final Set<String> _failed = <String>{};

  /// Allow failed URLs to be tried again (after an upload, or on refresh).
  static void clearFailed() => _failed.clear();

  static void _remember(String url) {
    if (_failed.length >= _maxRemembered) {
      _failed.remove(_failed.first);
    }
    _failed.add(url);
  }

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty || _failed.contains(u)) return fallback;

    return Image.network(
      u,
      width: size,
      height: size,
      fit: fit,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) {
        _remember(u);
        return fallback;
      },
    );
  }
}