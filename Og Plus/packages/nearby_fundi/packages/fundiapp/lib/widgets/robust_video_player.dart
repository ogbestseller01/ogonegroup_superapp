import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../config/app_theme.dart';

/// A cross-platform video player that:
///  * Plays HLS (.m3u8) and MP4/MOV from HTTP(S)
///  * Does NOT send custom Range/Accept headers (AVPlayer on iOS manages
///    byte ranges itself; forcing `Range: bytes=0-` breaks it)
///  * Handles iOS CoreMediaErrorDomain -11850 / -12939 gracefully
///  * Auto-pauses when scrolled out of view using native layout metrics
///    (no visibility_detector dependency needed)
///  * Pauses when the app goes to the background
///  * Shows a retry / "Open externally" fallback on unrecoverable errors
class RobustVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool loop;
  final double? aspectRatio; // fallback aspect ratio if unknown
  final BoxFit fit;

  const RobustVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.loop = false,
    this.aspectRatio,
    this.fit = BoxFit.cover,
  });

  @override
  State<RobustVideoPlayer> createState() => _RobustVideoPlayerState();
}

class _RobustVideoPlayerState extends State<RobustVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        (_controller?.value.isPlaying ?? false)) {
      _controller?.pause();
    }
  }

  Future<void> _disposeController() async {
    final old = _controller;
    _controller = null;
    if (old != null) {
      old.removeListener(_onControllerUpdate);
      await old.dispose();
    }
  }

  Future<void> _initialize() async {
    await _disposeController();

    if (mounted) {
      setState(() {
        _initialized = false;
        _hasError = false;
        _errorMessage = null;
      });
    }

    try {
      final uri = Uri.parse(widget.videoUrl);

      final VideoPlayerController controller;
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        // IMPORTANT: no custom httpHeaders here.
        // On iOS, headers are passed to AVURLAsset and a forced
        // `Range: bytes=0-` header conflicts with AVPlayer's own range
        // requests, which causes -11850 / -12939 on many servers.
        controller = VideoPlayerController.networkUrl(
          uri,
          formatHint: _isHls(uri) ? VideoFormat.hls : null,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );
      } else if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(uri);
      } else {
        controller = VideoPlayerController.file(File(widget.videoUrl));
      }

      await controller.initialize();

      if (controller.value.duration == Duration.zero &&
          controller.value.size == Size.zero) {
        await controller.dispose();
        throw const FormatException(
          'Video reported zero duration/size. Server may not support Range requests (HTTP 206).',
        );
      }

      await controller.setLooping(widget.loop);
      if (widget.autoPlay) {
        await controller.play();
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      controller.addListener(_onControllerUpdate);

      setState(() {
        _controller = controller;
        _initialized = true;
        _hasError = false;
      });

      _scheduleHideControls();
    } catch (e) {
      debugPrint('❌ Video init failed for ${widget.videoUrl}: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  bool _isHls(Uri uri) => uri.path.toLowerCase().endsWith('.m3u8');

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('-12939') ||
        msg.contains('-11850') ||
        msg.contains('Operation Stopped')) {
      return 'The video server is not correctly configured (missing HTTP Range support).';
    }
    if (msg.contains('FormatException')) {
      return 'This video format is not supported, or the server returned an empty response.';
    }
    return 'Unable to load video.';
  }

  void _onControllerUpdate() {
    if (!mounted || _controller == null) return;
    if (_controller!.value.hasError) {
      final err = _controller!.value.errorDescription ?? 'Playback error';
      setState(() {
        _hasError = true;
        _errorMessage = _friendlyError(err);
      });
    } else {
      setState(() {});
    }
  }

  void _togglePlay() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      _showControls = true;
    } else {
      _controller!.play();
      _scheduleHideControls();
    }
    setState(() {});
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(widget.videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Native layout-based visibility tracking
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (_controller?.value.isPlaying ?? false) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null && renderBox.attached) {
            final translation = renderBox.localToGlobal(Offset.zero);
            final screenHeight = MediaQuery.of(context).size.height;
            if (translation.dy + renderBox.size.height < 0 ||
                translation.dy > screenHeight) {
              _controller?.pause();
            }
          }
        }
        return false;
      },
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Extra safety: never allow infinite width to reach AspectRatio
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        Widget content;

        if (_hasError) {
          content = AspectRatio(
            aspectRatio: widget.aspectRatio ?? 16 / 9,
            child: Container(
              color: Colors.black87,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off_rounded,
                      color: Colors.white70, size: 48),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _errorMessage ?? 'Unable to load video',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _initialize,
                        icon: const Icon(Icons.refresh_rounded,
                            size: 18, color: Colors.white),
                        label: const Text('Retry',
                            style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _openExternally,
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Open'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else if (!_initialized || _controller == null) {
          content = AspectRatio(
            aspectRatio: widget.aspectRatio ?? 16 / 9,
            child: Container(
              color: Colors.black12,
              child: const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            ),
          );
        } else {
          final ar = _controller!.value.aspectRatio;
          final safeAr =
          (ar.isFinite && ar > 0) ? ar : (widget.aspectRatio ?? 16 / 9);

          content = AspectRatio(
            aspectRatio: safeAr,
            child: GestureDetector(
              onTap: () {
                setState(() => _showControls = !_showControls);
                if (_showControls) _scheduleHideControls();
              },
              child: Container(
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FittedBox(
                      fit: widget.fit,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: _showControls ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: Container(
                          color: Colors.black26,
                          child: Center(
                            child: Material(
                              color: Colors.black45,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _togglePlay,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Icon(
                                    _controller!.value.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      bottom: _showControls ? 0 : -40,
                      left: 0,
                      right: 0,
                      child: VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: AppTheme.primary,
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white10,
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      top: _showControls ? 8 : -40,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_fmt(_controller!.value.position)} / ${_fmt(_controller!.value.duration)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: width,
          child: content,
        );
      },
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}