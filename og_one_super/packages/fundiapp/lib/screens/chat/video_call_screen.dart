// lib/screens/chat/video_call_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/video_call_service.dart';


class VideoCallScreen extends StatefulWidget {
  final String userName;
  final String userId;

  const VideoCallScreen({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final VideoCallService _callService = VideoCallService();
  bool _isConnected = false;
  int _callDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _callService.endCall();
    super.dispose();
  }

  Future<void> _initCall() async {
    final success = await _callService.startCall(widget.userId, widget.userName);
    if (success) {
      setState(() => _isConnected = true);
      _startTimer();
    } else {
      Navigator.pop(context);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.navy950,
        child: Stack(
          children: [
            Container(
              color: AppTheme.navy900,
              child: const Center(
                child: Text(
                  'Video Call',
                  style: TextStyle(
                    inherit: true,
                    color: Colors.white54,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 60,
              right: 16,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: AppTheme.navy800,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.videocam_off,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          _callService.endCall();
                          Navigator.pop(context);
                        },
                      ),
                      const Spacer(),
                      const Text(
                        'Video Call',
                        style: TextStyle(
                          inherit: true,
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      inherit: true,
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isConnected
                        ? _formatDuration(_callDuration)
                        : 'Connecting...',
                    style: TextStyle(
                      inherit: true,
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _callService.isMuted ? Icons.mic_off : Icons.mic,
                      color:
                          _callService.isMuted ? AppTheme.error : Colors.white,
                      onPressed: _callService.toggleMute,
                    ),
                    _buildControlButton(
                      icon: _callService.isCameraOn
                          ? Icons.videocam
                          : Icons.videocam_off,
                      color: _callService.isCameraOn
                          ? Colors.white
                          : AppTheme.error,
                      onPressed: _callService.toggleCamera,
                    ),
                    _buildControlButton(
                      icon: _callService.isSpeakerOn
                          ? Icons.volume_up
                          : Icons.volume_off,
                      color: _callService.isSpeakerOn
                          ? AppTheme.secondary
                          : Colors.white,
                      onPressed: _callService.toggleSpeaker,
                    ),
                    _buildControlButton(
                      icon: Icons.call_end,
                      color: AppTheme.error,
                      size: 60,
                      onPressed: () {
                        _callService.endCall();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 50,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size * 0.5),
        onPressed: onPressed,
      ),
    );
  }
}
