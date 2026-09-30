import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecorderService {
  static final VoiceRecorderService _instance = VoiceRecorderService._internal();
  factory VoiceRecorderService() => _instance;
  VoiceRecorderService._internal();

  AudioRecorder? _audioRecorder;
  bool _isRecording = false;
  String? _recordingPath;

  Future<void> init() async {
    _audioRecorder ??= AudioRecorder();
  }

  Future<bool> startRecording() async {
    await init();

    try {
      // Check and request microphone permission
      final hasPermission = await _audioRecorder!.hasPermission();
      if (!hasPermission) {
        debugPrint('⚠️ Microphone permission not granted');
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording with AAC LC codec
      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 16000,
        ),
        path: path,
      );

      _isRecording = true;
      _recordingPath = path;
      debugPrint('🎙️ Recording started at: $path');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start recording: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    if (_audioRecorder == null || !_isRecording) return null;

    try {
      final path = await _audioRecorder!.stop();
      _isRecording = false;
      debugPrint('⏹️ Recording stopped. File: $path');
      return path ?? _recordingPath;
    } catch (e) {
      debugPrint('❌ Failed to stop recording: $e');
      return null;
    }
  }

  bool get isRecording => _isRecording;
  String? get recordingPath => _recordingPath;

  void dispose() {
    _audioRecorder?.dispose();
    _audioRecorder = null;
  }
}