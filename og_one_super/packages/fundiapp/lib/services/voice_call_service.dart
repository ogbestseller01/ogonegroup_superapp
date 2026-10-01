// lib/services/voice_call_service.dart

import 'package:flutter/foundation.dart';

class VoiceCallService {
  static final VoiceCallService _instance = VoiceCallService._internal();
  factory VoiceCallService() => _instance;
  VoiceCallService._internal();

  bool _isInCall = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  bool get isInCall => _isInCall;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;

  // Callbacks
  Function()? onCallConnected;
  Function()? onCallDisconnected;
  Function(String)? onError;

  Future<bool> startCall(String userId, String userName) async {
    try {
      _isInCall = true;
      debugPrint('🔊 Starting voice call with $userName (ID: $userId)');

      // TODO: Implement actual call logic using Agora/ZEGO
      onCallConnected?.call();
      return true;
    } catch (e) {
      onError?.call('Failed to start call: $e');
      return false;
    }
  }

  Future<void> endCall() async {
    _isInCall = false;
    _isMuted = false;
    _isSpeakerOn = false;
    debugPrint('🔊 Voice call ended');
    onCallDisconnected?.call();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    debugPrint('🔊 Mute: $_isMuted');
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    debugPrint('🔊 Speaker: $_isSpeakerOn');
  }

  void dispose() {
    _isInCall = false;
    _isMuted = false;
    _isSpeakerOn = false;
  }
}