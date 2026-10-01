// lib/services/video_call_service.dart

import 'package:flutter/foundation.dart';

class VideoCallService {
  static final VideoCallService _instance = VideoCallService._internal();
  factory VideoCallService() => _instance;
  VideoCallService._internal();

  bool _isInCall = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCameraOn = true;

  bool get isInCall => _isInCall;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isCameraOn => _isCameraOn;

  // Callbacks
  Function()? onCallConnected;
  Function()? onCallDisconnected;
  Function(String)? onError;

  Future<bool> startCall(String userId, String userName) async {
    try {
      _isInCall = true;
      debugPrint('📹 Starting video call with $userName (ID: $userId)');

      // TODO: Implement actual video call logic using Agora/ZEGO
      onCallConnected?.call();
      return true;
    } catch (e) {
      onError?.call('Failed to start video call: $e');
      return false;
    }
  }

  Future<void> endCall() async {
    _isInCall = false;
    _isMuted = false;
    _isSpeakerOn = false;
    _isCameraOn = true;
    debugPrint('📹 Video call ended');
    onCallDisconnected?.call();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    debugPrint('📹 Mute: $_isMuted');
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    debugPrint('📹 Speaker: $_isSpeakerOn');
  }

  void toggleCamera() {
    _isCameraOn = !_isCameraOn;
    debugPrint('📹 Camera: $_isCameraOn');
  }

  void dispose() {
    _isInCall = false;
    _isMuted = false;
    _isSpeakerOn = false;
    _isCameraOn = true;
  }
}