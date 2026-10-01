// packages/fundiapp/lib/widgets/safe_youtube_embed.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders a YouTube video as a tappable thumbnail that opens the video on
/// YouTube's own app/website.
///
/// This replaces the previous embedded-player implementation which depended
/// on `youtube_player_flutter` v9's API. That API was removed in v10 — v10's
/// widget no longer exposes `YoutubePlayerFlags`, `bottomActions`,
/// `ProgressBarColors`, callbacks like `onReady`/`onEnded`, or controller
/// methods like `seekTo`/`pause`. Rather than fight the new API, we render
/// a thumbnail and hand off playback to the YouTube app — the same pattern
/// used by `fundi_posts_screen.dart`.
class SafeYoutubeEmbed extends StatelessWidget {
  final String videoUrl;
  final double height;

  const SafeYoutubeEmbed({
    super.key,
    required this.videoUrl,
    this.height = 220,
  });

  /// Pure-regex YouTube ID extractor. Handles:
  ///   • youtu.be/<id>
  ///   • youtube.com/watch?v=<id>
  ///   • youtube.com/embed/<id>
  ///   • youtube.com/shorts/<id>
  ///   • youtube-nocookie.com/embed/<id>
  ///   • iframe <src="..."> embeds
  ///   • raw 11-character IDs
  String? _extractVideoId(String input) {
    if (input.trim().isEmpty) return null;

    String working = input.trim();

    // Pull `src` out of iframe embeds.
    if (working.toLowerCase().contains('<iframe')) {
      final match = RegExp(
        r'''src=["']([^"']+)["']''',
        caseSensitive: false,
      ).firstMatch(working);
      if (match != null) {
        working = match.group(1) ?? working;
      }
    }

    // Standard YouTube URL patterns.
    final regExp = RegExp(
      r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/)|youtube-nocookie\.com\/embed\/)([_\-\w]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(working);
    if (match != null) return match.group(1);

    // Bare 11-character ID.
    if (working.length == 11 &&
        !working.contains('/') &&
        !working.contains('?')) {
      return working;
    }

    return null;
  }

  Future<void> _openOnYoutube(BuildContext context) async {
    final videoId = _extractVideoId(videoUrl);
    if (videoId == null) return;

    final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('⚠️ Cannot launch YouTube URL: $uri');
      }
    } catch (e) {
      debugPrint('❌ Failed to open YouTube: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _extractVideoId(videoUrl);

    // ── Invalid URL ─────────────────────────────────────────
    if (videoId == null) {
      return Container(
        height: height,
        width: double.infinity,
        color: Colors.grey.shade900,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white54, size: 36),
              SizedBox(height: 8),
              Text(
                'Invalid YouTube URL',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final thumbnailUrl =
        'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    final fallbackThumbnail =
        'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    // ── Thumbnail card ─────────────────────────────────────
    return GestureDetector(
      onTap: () => _openOnYoutube(context),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail with graceful fallback
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  fallbackThumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade900,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white54,
                        size: 60,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom gradient for label contrast
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              // Play button
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
              ),

              // Bottom label row
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'Tap to play on YouTube',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'YouTube',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}