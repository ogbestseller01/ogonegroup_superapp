// ================================================================
// FILE: lib/widgets/safe_youtube_embed.dart
// NearbyFundi - Safe YouTube Video Embed
// ================================================================

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SafeYoutubeEmbed extends StatefulWidget {
  final String videoUrl;
  final double height;
  final bool autoPlay;

  const SafeYoutubeEmbed({
    super.key,
    required this.videoUrl,
    this.height = 220,
    this.autoPlay = false,
  });

  @override
  State<SafeYoutubeEmbed> createState() => _SafeYoutubeEmbedState();
}

class _SafeYoutubeEmbedState extends State<SafeYoutubeEmbed> {
  YoutubePlayerController? _controller;

  String? _videoId;
  String? _errorMessage;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  // ==============================================================
  // EXTRACT YOUTUBE VIDEO ID
  // ==============================================================

  String? _extractVideoId(String input) {
    final value = input.trim();

    if (value.isEmpty) {
      return null;
    }

    // ------------------------------------------------------------
    // 1. Try youtube_player_flutter built-in converter
    // ------------------------------------------------------------

    String? videoId;

    try {
      videoId = YoutubePlayer.convertUrlToId(value);
    } catch (_) {
      videoId = null;
    }

    if (_isValidVideoId(videoId)) {
      return videoId;
    }

    // ------------------------------------------------------------
    // 2. Handle iframe HTML
    // ------------------------------------------------------------

    final iframeMatch = RegExp(
      r'''src\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(value);

    if (iframeMatch != null) {
      final iframeUrl = iframeMatch.group(1);

      if (iframeUrl != null && iframeUrl.isNotEmpty) {
        final extractedId = _extractVideoId(iframeUrl);

        if (_isValidVideoId(extractedId)) {
          return extractedId;
        }
      }
    }

    // ------------------------------------------------------------
    // 3. Manual fallback
    // ------------------------------------------------------------

    final patterns = <RegExp>[
      // https://www.youtube.com/watch?v=VIDEO_ID
      RegExp(
        r'(?:youtube\.com/watch\?v=)([A-Za-z0-9_-]{11})',
        caseSensitive: false,
      ),

      // https://youtu.be/VIDEO_ID
      RegExp(
        r'(?:youtu\.be/)([A-Za-z0-9_-]{11})',
        caseSensitive: false,
      ),

      // https://www.youtube.com/embed/VIDEO_ID
      RegExp(
        r'(?:youtube\.com/embed/)([A-Za-z0-9_-]{11})',
        caseSensitive: false,
      ),

      // https://www.youtube.com/shorts/VIDEO_ID
      RegExp(
        r'(?:youtube\.com/shorts/)([A-Za-z0-9_-]{11})',
        caseSensitive: false,
      ),

      // https://www.youtube.com/v/VIDEO_ID
      RegExp(
        r'(?:youtube\.com/v/)([A-Za-z0-9_-]{11})',
        caseSensitive: false,
      ),

      // Generic v= fallback
      RegExp(
        r'[?&]v=([A-Za-z0-9_-]{11})',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(value);

      if (match != null) {
        final id = match.group(1);

        if (_isValidVideoId(id)) {
          return id;
        }
      }
    }

    // ------------------------------------------------------------
    // 4. If input itself looks like a YouTube ID
    // ------------------------------------------------------------

    if (_isValidVideoId(value)) {
      return value;
    }

    return null;
  }

  // ==============================================================
  // VALIDATE VIDEO ID
  // ==============================================================

  bool _isValidVideoId(String? id) {
    if (id == null || id.isEmpty) {
      return false;
    }

    return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id);
  }

  // ==============================================================
  // INITIALIZE PLAYER
  // ==============================================================

  void _initializePlayer() {
    try {
      final videoId = _extractVideoId(widget.videoUrl);

      if (!_isValidVideoId(videoId)) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _videoId = null;
          _errorMessage = 'Could not extract YouTube video ID';
        });

        return;
      }

      _videoId = videoId;

      _controller = YoutubePlayerController(
        initialVideoId: videoId!,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
          mute: false,
          enableCaption: true,
          controlsVisibleAtStart: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _videoId = null;
        _errorMessage = 'Unable to load video';
      });
    }
  }

  // ==============================================================
  // RETRY
  // ==============================================================

  void _retry() {
    _controller?.dispose();
    _controller = null;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _videoId = null;
      _errorMessage = null;
    });

    _initializePlayer();
  }

  // ==============================================================
  // DISPOSE
  // ==============================================================

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;

    super.dispose();
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_controller == null || !_isValidVideoId(_videoId)) {
      return _buildErrorWidget();
    }

    return _buildPlayerWidget();
  }

  // ==============================================================
  // LOADING
  // ==============================================================

  Widget _buildLoadingWidget() {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: const ColoredBox(
        color: Colors.black,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // ERROR
  // ==============================================================

  Widget _buildErrorWidget() {
    return Container(
      height: widget.height,
      width: double.infinity,
      color: Colors.grey.shade900,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_outline,
                color: Colors.grey.shade600,
                size: 48,
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage ?? 'Video unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _retry,
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // PLAYER
  // ==============================================================

  Widget _buildPlayerWidget() {
    final controller = _controller;

    if (controller == null) {
      return _buildErrorWidget();
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
        ),
      ),
    );
  }
}