// lib/screens/chat/voice_call_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/voice_call_service.dart';


class VoiceCallScreen extends StatefulWidget {
  final String userName;
  final String userId;

  const VoiceCallScreen({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final VoiceCallService _callService = VoiceCallService();
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
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            Container(
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
                    'Voice Call',
                    style: TextStyle(
                      inherit: true,
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        inherit: true,
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      inherit: true,
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isConnected
                        ? _formatDuration(_callDuration)
                        : 'Connecting...',
                    style: TextStyle(
                      inherit: true,
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _callService.isMuted ? Icons.mic_off : Icons.mic,
                    color: _callService.isMuted ? AppTheme.error : Colors.white,
                    onPressed: _callService.toggleMute,
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
                    size: 70,
                    onPressed: () {
                      _callService.endCall();
                      Navigator.pop(context);
                    },
                  ),
                ],
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
