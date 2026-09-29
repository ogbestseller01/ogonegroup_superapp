// lib/services/voice_recording_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceRecordingService {
  static final VoiceRecordingService _instance = VoiceRecordingService._internal();
  factory VoiceRecordingService() => _instance;
  VoiceRecordingService._internal();

  AudioRecorder? _recorder;
  bool _isRecording = false;
  String? _currentRecordingPath;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  double _currentAmplitude = 0.0;

  AudioPlayer? _player;
  bool _isPlaying = false;
  String? _currentPlayingPath;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Callbacks
  Function()? onRecordingStarted;
  Function(String)? onRecordingStopped;
  Function(double)? onAmplitudeChanged;
  Function()? onPlaybackStarted;
  Function()? onPlaybackFinished;
  Function(Duration)? onPlaybackPositionChanged;
  Function(Duration)? onPlaybackDurationChanged;
  Function(String)? onError;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;
  String? get currentPlayingPath => _currentPlayingPath;
  double get currentAmplitude => _currentAmplitude;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  // ============================================
  // RECORDING
  // ============================================

  Future<bool> hasPermission() async {
    try {
      final recorder = AudioRecorder();
      return await recorder.hasPermission();
    } catch (e) {
      debugPrint('🎤 Permission check error: $e');
      return false;
    }
  }

  Future<void> startRecording() async {
    try {
      final recorder = AudioRecorder();
      if (!await recorder.hasPermission()) {
        throw Exception('Microphone permission denied');
      }

      _recorder = AudioRecorder();

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/voice_$timestamp.m4a';

      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      onRecordingStarted?.call();

      // ✅ Bypass static type confusion – use dynamic to access the getter
      _amplitudeSubscription = (_recorder! as dynamic).onAmplitudeChanged.listen((amplitude) {
        _currentAmplitude = amplitude.current;
        onAmplitudeChanged?.call(amplitude.current);
      });

      debugPrint('🎤 Recording started: $_currentRecordingPath');
    } catch (e) {
      debugPrint('🎤 Recording error: $e');
      onError?.call('Failed to start recording: $e');
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    if (_recorder == null || !_isRecording) return null;

    try {
      await _amplitudeSubscription?.cancel();
      final path = await _recorder!.stop();
      _isRecording = false;
      _currentRecordingPath = path;
      onRecordingStopped?.call(path ?? '');
      debugPrint('🎤 Recording stopped: $path');
      return path;
    } catch (e) {
      debugPrint('🎤 Stop recording error: $e');
      onError?.call('Failed to stop recording: $e');
      return null;
    } finally {
      _recorder = null;
    }
  }

  Future<void> cancelRecording() async {
    if (_recorder != null && _isRecording) {
      await _recorder!.stop();
      _isRecording = false;
    }
    if (_currentRecordingPath != null) {
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🎤 Recording cancelled: $_currentRecordingPath');
      }
      _currentRecordingPath = null;
    }
  }

  // ============================================
  // PLAYBACK
  // ============================================

  Future<void> playRecording(String path) async {
    try {
      await stopPlayback();

      final file = File(path);
      if (!await file.exists()) {
        throw Exception('File not found: $path');
      }

      _player = AudioPlayer();
      _currentPlayingPath = path;

      _playerStateSubscription = _player!.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.playing) {
          _isPlaying = true;
          onPlaybackStarted?.call();
        } else if (state == PlayerState.stopped || state == PlayerState.completed) {
          _isPlaying = false;
          if (state == PlayerState.completed) {
            onPlaybackFinished?.call();
          }
        }
      });

      _positionSubscription = _player!.onPositionChanged.listen((position) {
        _currentPosition = position;
        onPlaybackPositionChanged?.call(position);
      });

      _durationSubscription = _player!.onDurationChanged.listen((duration) {
        _totalDuration = duration;
        onPlaybackDurationChanged?.call(duration);
      });

      await _player!.play(DeviceFileSource(path));
      debugPrint('🎤 Playing: $path');
    } catch (e) {
      debugPrint('🎤 Playback error: $e');
      onError?.call('Failed to play recording: $e');
      rethrow;
    }
  }

  Future<void> pausePlayback() async {
    if (_player != null && _isPlaying) {
      await _player!.pause();
      debugPrint('🎤 Playback paused');
    }
  }

  Future<void> resumePlayback() async {
    if (_player != null && !_isPlaying) {
      await _player!.resume();
      debugPrint('🎤 Playback resumed');
    }
  }

  Future<void> stopPlayback() async {
    if (_player != null) {
      await _player!.stop();
      await _player!.dispose();
      _player = null;
      _isPlaying = false;
      _currentPlayingPath = null;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      _playerStateSubscription?.cancel();
      _positionSubscription?.cancel();
      _durationSubscription?.cancel();
      debugPrint('🎤 Playback stopped');
    }
  }

  Future<void> seekPlayback(Duration position) async {
    if (_player != null) {
      await _player!.seek(position);
    }
  }

  // ============================================
  // FILE MANAGEMENT
  // ============================================

  Future<bool> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        if (_currentRecordingPath == path) {
          _currentRecordingPath = null;
        }
        if (_currentPlayingPath == path) {
          await stopPlayback();
        }
        debugPrint('🎤 Recording deleted: $path');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('🎤 Delete recording error: $e');
      return false;
    }
  }

  Future<int> getRecordingSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // ============================================
  // CLEANUP
  // ============================================

  void dispose() {
    _amplitudeSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _recorder?.dispose();
    _player?.dispose();
    _isRecording = false;
    _isPlaying = false;
  }
}