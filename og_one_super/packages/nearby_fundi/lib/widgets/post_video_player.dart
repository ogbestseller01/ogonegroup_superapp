import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

/// Plays a post video on iOS and Android.
///
/// 1. Tries to stream from the network (needs HTTP Range support on the server).
/// 2. If that fails (e.g. server without Range support), downloads the file to the
///    cache once and plays the local copy, which needs no Range support at all.
class PostVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final double aspectRatio;

  const PostVideoPlayer({
    super.key,
    required this.videoUrl,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

enum _VState { idle, loading, ready, error }

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  VideoPlayerController? _controller;
  _VState _state = _VState.idle;

  Future<VideoPlayerController> _open({required bool fromCache}) async {
    final VideoPlayerController c;
    if (fromCache) {
      final file = await DefaultCacheManager().getSingleFile(widget.videoUrl);
      c = VideoPlayerController.file(file);
    } else {
      c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    }
    try {
      await c.initialize().timeout(const Duration(seconds: 20));
    } catch (_) {
      await c.dispose();
      rethrow;
    }
    return c;
  }

  Future<void> _load() async {
    setState(() => _state = _VState.loading);

    VideoPlayerController? c;
    try {
      c = await _open(fromCache: false);
    } catch (e) {
      debugPrint('Video stream failed, falling back to cached download: $e');
      try {
        c = await _open(fromCache: true);
      } catch (e2) {
        debugPrint('Video load failed: $e2');
      }
    }

    if (!mounted) {
      c?.dispose();
      return;
    }
    if (c == null) {
      setState(() => _state = _VState.error);
      return;
    }

    c.setLooping(false);
    setState(() {
      _controller = c;
      _state = _VState.ready;
    });
    c.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = (_state == _VState.ready && _controller!.value.aspectRatio > 0)
        ? _controller!.value.aspectRatio
        : widget.aspectRatio;

    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: ratio,
        child: ColoredBox(
          color: const Color(0xFF1E1E1E),
          child: switch (_state) {
            _VState.idle => Center(
              child: IconButton(
                iconSize: 64,
                color: Colors.white,
                icon: const Icon(Icons.play_circle_fill_rounded),
                onPressed: _load,
              ),
            ),
            _VState.loading => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            _VState.error => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white70, size: 36),
                  const SizedBox(height: 8),
                  const Text('Could not load video',
                      style: TextStyle(color: Colors.white70)),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
            _VState.ready => _player(_controller!),
          },
        ),
      ),
    );
  }

  Widget _player(VideoPlayerController c) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => c.value.isPlaying ? c.pause() : c.play(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(c),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: c,
            builder: (_, v, __) => v.isPlaying
                ? const SizedBox.shrink()
                : const Icon(Icons.play_circle_fill_rounded,
                size: 64, color: Colors.white70),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(c, allowScrubbing: true),
          ),
        ],
      ),
    );
  }
}