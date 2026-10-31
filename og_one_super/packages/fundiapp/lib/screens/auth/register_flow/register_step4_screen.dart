// lib/screens/auth/register_flow/register_step4_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../config/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/register_shell.dart';

class RegisterStep4Screen extends StatefulWidget {
  final int draftId;
  const RegisterStep4Screen({super.key, required this.draftId});

  @override
  State<RegisterStep4Screen> createState() => _RegisterStep4ScreenState();
}

enum _FacePhase { booting, searching, holding, capturing, review, submitting }

/// Hints/errors are stored as enums so they re-translate when the language changes.
enum _Hint { opening, position, none, closer, farther, hold, confirm, saving, unavailable }

enum _Err { noCamera, openFailed, captureFailed, saveFailed, submitFailed, fallbackFailed }

class _RegisterStep4ScreenState extends State<RegisterStep4Screen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  late final FaceDetector _faceDetector;
  Timer? _stabilityTimer;

  bool _isBusy = false;
  bool _booting = false;

  _FacePhase _phase = _FacePhase.booting;
  _Hint _hint = _Hint.opening;
  _Err? _err;
  String _errDetail = '';
  String? _serverError;

  XFile? _capturedFile;
  double? _faceBoxRatio;
  double _progress = 0;
  bool _cameraFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableContours: false,
        enableLandmarks: false,
        enableTracking: true,
        minFaceSize: 0.15,
      ),
    );
    _bootstrapCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _releaseCamera();
    } else if (state == AppLifecycleState.resumed &&
        _capturedFile == null &&
        _controller == null) {
      _bootstrapCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stabilityTimer?.cancel();
    final c = _controller;
    _controller = null;
    c?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  // ── Text resolution ─────────────────────────────────────
  String _hintText(AppLocalizations l) {
    switch (_hint) {
      case _Hint.opening:
        return l.regFaceOpening;
      case _Hint.position:
        return l.regFacePosition;
      case _Hint.none:
        return l.regFaceNone;
      case _Hint.closer:
        return l.regFaceCloser;
      case _Hint.farther:
        return l.regFaceFarther;
      case _Hint.hold:
        return l.regFaceHold;
      case _Hint.confirm:
        return l.regFaceConfirmPhoto;
      case _Hint.saving:
        return l.regFaceSaving;
      case _Hint.unavailable:
        return l.regFaceUnavailable;
    }
  }

  String? _errorText(AppLocalizations l) {
    if (_serverError != null) return _serverError;
    switch (_err) {
      case null:
        return null;
      case _Err.noCamera:
        return l.regFaceNoCamera;
      case _Err.openFailed:
        return l.regFaceOpenFailed(_errDetail);
      case _Err.captureFailed:
        return l.regFaceCaptureFailed(_errDetail);
      case _Err.saveFailed:
        return l.regFaceSaveFailed;
      case _Err.submitFailed:
        return l.regFaceSubmitFailed(_errDetail);
      case _Err.fallbackFailed:
        return l.regFaceFallbackFailed(_errDetail);
    }
  }

  // ── Camera ──────────────────────────────────────────────
  Future<void> _bootstrapCamera() async {
    if (_booting || _capturedFile != null) return;
    _booting = true;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _fail(_Err.noCamera);
        return;
      }

      final front = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final ctrl = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }

      setState(() {
        _controller = ctrl;
        _cameraFailed = false;
        _err = null;
        _serverError = null;
        _phase = _FacePhase.searching;
        _hint = _Hint.position;
      });

      await ctrl.startImageStream(_onCameraFrame);
    } catch (e) {
      _fail(_Err.openFailed, '$e');
    } finally {
      _booting = false;
    }
  }

  Future<void> _releaseCamera() async {
    _stabilityTimer?.cancel();
    _stabilityTimer = null;

    final c = _controller;
    _controller = null;
    if (c == null) return;

    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
    } catch (_) {}
    try {
      await c.dispose();
    } catch (_) {}

    if (mounted && _capturedFile == null) {
      setState(() {
        _phase = _FacePhase.booting;
        _hint = _Hint.opening;
      });
    }
  }

  Future<void> _stopStream() async {
    try {
      if (_controller?.value.isStreamingImages == true) {
        await _controller!.stopImageStream();
      }
    } catch (_) {}
  }

  InputImageRotation? _rotation() {
    final ctrl = _controller;
    if (ctrl == null) return null;
    return InputImageRotationValue.fromRawValue(
        ctrl.description.sensorOrientation);
  }

  Future<void> _onCameraFrame(CameraImage image) async {
    if (_isBusy || !mounted) return;
    if (_phase == _FacePhase.capturing ||
        _phase == _FacePhase.review ||
        _phase == _FacePhase.submitting) {
      return;
    }
    _isBusy = true;

    try {
      final rotation = _rotation();
      final input = _toInputImage(image, rotation);
      if (input == null || rotation == null) return;

      final faces = await _faceDetector.processImage(input);
      if (!mounted) return;

      if (faces.isEmpty) {
        _resetStability(_Hint.none);
        return;
      }

      faces.sort((a, b) => b.boundingBox.width.compareTo(a.boundingBox.width));
      final face = faces.first;

      final rotated = rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg;
      final uprightWidth = (rotated ? image.height : image.width).toDouble();
      final ratio = face.boundingBox.width / uprightWidth;

      if (ratio < 0.18) {
        _resetStability(_Hint.closer, ratio: ratio);
        return;
      }
      if (ratio > 0.60) {
        _resetStability(_Hint.farther, ratio: ratio);
        return;
      }

      _updateFaceRatio(ratio);
      _startStability();
    } catch (_) {
      // ML Kit occasionally throws on transient frames — ignore.
    } finally {
      _isBusy = false;
    }
  }

  void _updateFaceRatio(double ratio) {
    if (!mounted) return;
    if (_faceBoxRatio != null && (_faceBoxRatio! - ratio).abs() < 0.01) return;
    setState(() => _faceBoxRatio = ratio);
  }

  void _resetStability(_Hint hint, {double? ratio}) {
    _stabilityTimer?.cancel();
    _stabilityTimer = null;
    if (!mounted) return;

    final unchanged = _hint == hint &&
        _phase == _FacePhase.searching &&
        _progress == 0 &&
        _faceBoxRatio == ratio;
    if (unchanged) return;

    setState(() {
      _hint = hint;
      _phase = _FacePhase.searching;
      _progress = 0;
      _faceBoxRatio = ratio;
    });
  }

  void _startStability() {
    if (_stabilityTimer?.isActive == true) return;
    if (!mounted) return;

    setState(() {
      _phase = _FacePhase.holding;
      _hint = _Hint.hold;
      _progress = 0;
    });

    const totalMs = 1400;
    const tickMs = 60;
    var elapsed = 0;

    _stabilityTimer = Timer.periodic(const Duration(milliseconds: tickMs), (t) {
      if (!mounted || _phase != _FacePhase.holding) {
        t.cancel();
        return;
      }
      elapsed += tickMs;
      setState(() => _progress = (elapsed / totalMs).clamp(0.0, 1.0));

      if (elapsed >= totalMs) {
        t.cancel();
        _stabilityTimer = null;
        _captureAndReview();
      }
    });
  }

  InputImage? _toInputImage(CameraImage image, InputImageRotation? rotation) {
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (image.planes.isEmpty) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // ── Capture + submit ────────────────────────────────────
  Future<void> _captureAndReview() async {
    final ctrl = _controller;
    if (ctrl == null || _phase == _FacePhase.capturing) return;

    _stabilityTimer?.cancel();
    _stabilityTimer = null;
    setState(() => _phase = _FacePhase.capturing);
    await _stopStream();

    try {
      final file = await ctrl.takePicture();
      if (!mounted) return;
      setState(() {
        _capturedFile = file;
        _phase = _FacePhase.review;
        _hint = _Hint.confirm;
      });
    } catch (e) {
      _fail(_Err.captureFailed, '$e');
    }
  }

  Future<void> _confirmAndSubmit() async {
    final file = _capturedFile;
    if (file == null) return;

    setState(() {
      _phase = _FacePhase.submitting;
      _hint = _Hint.saving;
      _err = null;
      _serverError = null;
    });

    try {
      final bytes = await File(file.path).readAsBytes();
      final faceData = base64Encode(bytes);

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final ok = await auth.registerTechnicianStep4(faceData: faceData);

      if (!mounted) return;

      if (ok) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.registerStep5,
          arguments: {'draftId': widget.draftId},
        );
        return;
      }

      setState(() {
        _phase = _FacePhase.review;
        _hint = _Hint.confirm;
        _serverError = auth.errorMessage;
        _err = auth.errorMessage == null ? _Err.saveFailed : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _FacePhase.review;
        _err = _Err.submitFailed;
        _errDetail = '$e';
      });
    }
  }

  Future<void> _retake() async {
    await _releaseCamera();
    if (!mounted) return;
    setState(() {
      _capturedFile = null;
      _faceBoxRatio = null;
      _progress = 0;
      _err = null;
      _serverError = null;
      _phase = _FacePhase.booting;
      _hint = _Hint.opening;
    });
    await _bootstrapCamera();
  }

  Future<void> _fallbackSystemCamera() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (file == null) return;
      await _stopStream();
      if (!mounted) return;
      setState(() {
        _capturedFile = file;
        _phase = _FacePhase.review;
        _hint = _Hint.confirm;
        _err = null;
        _serverError = null;
      });
    } catch (e) {
      _fail(_Err.fallbackFailed, '$e');
    }
  }

  void _fail(_Err e, [String detail = '']) {
    if (!mounted) return;
    setState(() {
      _phase = _FacePhase.searching;
      _hint = _Hint.unavailable;
      _err = e;
      _errDetail = detail;
      _cameraFailed = true;
    });
  }

  // ── UI ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = RegPalette.of(context);
    final submitting = _phase == _FacePhase.submitting;
    final error = _errorText(l10n);

    return RegisterShell(
      step: 4,
      total: 6,
      title: l10n.regFaceTitle,
      subtitle: _hintText(l10n),
      showNext: false,
      backEnabled: !submitting && _phase != _FacePhase.capturing,
      bottom: _buildFooter(l10n, submitting),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 400, child: _buildPreview(l10n, p)),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview(AppLocalizations l10n, RegPalette p) {
    if ((_phase == _FacePhase.review || _phase == _FacePhase.submitting) &&
        _capturedFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(_capturedFile!.path), fit: BoxFit.cover),
            if (_phase == _FacePhase.submitting)
              Container(
                color: Colors.black54,
                child: const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      );
    }

    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return Container(
        decoration: BoxDecoration(
          color: p.field,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: _cameraFailed
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded, size: 40, color: p.muted),
            const SizedBox(height: 10),
            Text(_hintText(l10n),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.muted)),
          ],
        )
            : const CircularProgressIndicator(),
      );
    }

    final size = ctrl.value.previewSize;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (size != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: size.height, // preview is landscape-reported
                height: size.width,
                child: CameraPreview(ctrl),
              ),
            )
          else
            CameraPreview(ctrl),
          _FaceOverlay(
            faceBoxRatio: _faceBoxRatio,
            progress: _progress,
            phase: _phase,
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _hintText(l10n),
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n, bool submitting) {
    if (_phase == _FacePhase.review || submitting) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: submitting ? null : _retake,
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.regFaceRetake),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: submitting ? null : _confirmAndSubmit,
              style:
              FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: const Icon(Icons.check_rounded),
              label: Text(l10n.regFaceConfirm),
            ),
          ),
        ],
      );
    }

    if (_cameraFailed) {
      return FilledButton.icon(
        onPressed: _fallbackSystemCamera,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        icon: const Icon(Icons.camera_alt_outlined),
        label: Text(l10n.regFaceSystemCamera),
      );
    }

    return FilledButton.icon(
      onPressed: (_faceBoxRatio != null && _phase != _FacePhase.capturing)
          ? _captureAndReview
          : null,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      icon: const Icon(Icons.camera_rounded),
      label: Text(_phase == _FacePhase.capturing
          ? l10n.regFaceCapturing
          : l10n.regFaceCaptureNow),
    );
  }
}

// ── Face overlay ────────────────────────────────────────────
class _FaceOverlay extends StatelessWidget {
  final double? faceBoxRatio;
  final double progress;
  final _FacePhase phase;

  const _FaceOverlay({
    required this.faceBoxRatio,
    required this.progress,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final hasFace = faceBoxRatio != null;
    final isHolding = phase == _FacePhase.holding;
    final color = !hasFace
        ? Colors.white70
        : isHolding
        ? Colors.greenAccent
        : Colors.orangeAccent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = constraints.maxWidth * 0.66;
        return Center(
          child: SizedBox(
            width: boxSize,
            height: boxSize * 1.25,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(boxSize),
                    border: Border.all(color: color, width: 3),
                  ),
                ),
                if (isHolding)
                  SizedBox(
                    width: boxSize + 24,
                    height: boxSize + 24,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      color: Colors.greenAccent,
                      backgroundColor: Colors.white24,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}