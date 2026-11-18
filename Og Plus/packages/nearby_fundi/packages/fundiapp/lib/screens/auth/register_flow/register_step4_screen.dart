// lib/screens/auth/register_flow/register_step4_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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

enum _FacePhase { booting, previewing, capturing, review, submitting }

/// Hints/errors are stored as enums so they re-translate when the language changes.
enum _Hint { opening, position, confirm, saving, unavailable }

enum _Err { noCamera, openFailed, captureFailed, saveFailed, submitFailed, fallbackFailed }

class _RegisterStep4ScreenState extends State<RegisterStep4Screen>
    with WidgetsBindingObserver {
  CameraController? _controller;

  bool _booting = false;

  _FacePhase _phase = _FacePhase.booting;
  _Hint _hint = _Hint.opening;
  _Err? _err;
  String _errDetail = '';
  String? _serverError;

  XFile? _capturedFile;
  bool _cameraFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    final c = _controller;
    _controller = null;
    c?.dispose();
    super.dispose();
  }

  // ── Text resolution ─────────────────────────────────────
  String _hintText(AppLocalizations l) {
    switch (_hint) {
      case _Hint.opening:
        return l.regFaceOpening;
      case _Hint.position:
        return l.regFacePosition;
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
        ResolutionPreset.high, // High resolution for a clear selfie
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
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
        _phase = _FacePhase.previewing;
        _hint = _Hint.position;
      });

    } catch (e) {
      _fail(_Err.openFailed, '$e');
    } finally {
      _booting = false;
    }
  }

  Future<void> _releaseCamera() async {
    final c = _controller;
    _controller = null;
    if (c == null) return;

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

  // ── Capture + submit ────────────────────────────────────
  Future<void> _captureAndReview() async {
    final ctrl = _controller;
    if (ctrl == null || _phase == _FacePhase.capturing) return;

    setState(() => _phase = _FacePhase.capturing);

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
      _phase = _FacePhase.previewing;
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

          // Static overlay for manual alignment
          const _StaticFaceOverlay(),

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
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
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
      onPressed: _phase != _FacePhase.capturing ? _captureAndReview : null,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      icon: const Icon(Icons.camera_rounded),
      label: Text(_phase == _FacePhase.capturing
          ? l10n.regFaceCapturing
          : l10n.regFaceCaptureNow),
    );
  }
}

// ── Static Face Overlay (No ML Kit) ─────────────────────────
class _StaticFaceOverlay extends StatelessWidget {
  const _StaticFaceOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = constraints.maxWidth * 0.66;
        return Center(
          child: SizedBox(
            width: boxSize,
            height: boxSize * 1.25,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(boxSize),
                border: Border.all(color: Colors.white70, width: 3),
              ),
            ),
          ),
        );
      },
    );
  }
}