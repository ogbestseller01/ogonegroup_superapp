import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/image_utils.dart';

/// One place for every network image: builds the full URL, shows a spinner
/// while loading, a fallback on failure, and logs the failing URL.
class AppNetworkImage extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const AppNetworkImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  Widget _placeholder(BuildContext context) =>
      fallback ??
          Container(
            width: width,
            height: height,
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          );

  @override
  Widget build(BuildContext context) {
    final url = ImageUtils.getFullImageUrl(path);
    if (url.isEmpty) return _placeholder(context);

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, _) {
        debugPrint('IMG FAIL: $url -> $error');
        return _placeholder(context);
      },
    );
  }
}