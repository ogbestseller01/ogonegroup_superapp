// lib/screens/scanner/qr_scanner_screen.dart
//
// Stand-alone scanner. It knows nothing about the dashboard or the mini
// apps: it only reads a QR code, checks it with QrService, and returns the
// mini-app slug through Navigator.pop().
//
//   final slug = await Navigator.of(context).push<String>(
//     MaterialPageRoute(builder: (_) => const QrScannerScreen()),
//   );

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/qr_service.dart';

const Color _navy = Color(0xFF1A2B4A);
const Color _gold = Color(0xFFFFB300);

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  late final AnimationController _line = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  bool _handled = false;
  bool _checking = false;
  bool _torchOn = false;
  String? _error;
  DateTime _lastErrorAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _sw => Localizations.localeOf(context).languageCode == 'sw';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _line.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Release the camera when the app goes to the background.
    if (!_controller.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_handled) _controller.start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller.stop();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled || _checking) return;

    for (final barcode in capture.barcodes) {
      final scan = QrService.parse(barcode.rawValue);
      if (scan == null) continue;

      // Code with a token: ask the server (expiry / revoked).
      var check = QrCheck.ok;
      if (scan.token != null) {
        _checking = true;
        check = await QrService.verify(scan.token!);
        _checking = false;
        if (!mounted) return;
      }

      if (check == QrCheck.ok) {
        _handled = true;
        HapticFeedback.mediumImpact();
        _controller.stop();
        Navigator.of(context).pop<String>(scan.slug);
        return;
      }

      switch (check) {
        case QrCheck.expired:
          _flashError(_sw ? 'QR hii imeisha muda.' : 'This QR code has expired.');
        case QrCheck.invalid:
          _flashError(_sw ? 'QR hii haifai.' : 'This QR code is not valid.');
        case QrCheck.offline:
          _flashError(_sw
              ? 'Imeshindwa kuthibitisha QR. Angalia intaneti.'
              : 'Could not check the code. Check your internet.');
        case QrCheck.ok:
          break;
      }
      return;
    }

    // A QR code was seen but it is not one of ours.
    _flashError(_sw
        ? 'QR hii si ya OG ONE GROUP.'
        : 'This QR code is not an OG ONE GROUP app code.');
  }

  /// Short red message under the frame, at most once every 2 seconds.
  void _flashError(String message) {
    final now = DateTime.now();
    if (now.difference(_lastErrorAt) < const Duration(seconds: 2)) return;
    _lastErrorAt = now;
    HapticFeedback.heavyImpact();
    setState(() => _error = message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _error = null);
    });
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      // Device has no torch.
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final frame = (size.shortestSide * 0.68).clamp(220.0, 320.0);
    final window = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: frame,
      height: frame,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              scanWindow: window,
              onDetect: _onDetect,
              // mobile_scanner 7.x: errorBuilder takes (context, error) only.
              errorBuilder: (context, error) => _CameraError(
                denied:
                error.errorCode == MobileScannerErrorCode.permissionDenied,
                sw: _sw,
                onRetry: () => _controller.start(),
                onBack: () => Navigator.of(context).pop(),
              ),
            ),

            // Dark overlay with a clear hole for the scan area.
            IgnorePointer(
              child: CustomPaint(painter: _OverlayPainter(window)),
            ),

            // Animated scan line
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _line,
                builder: (_, __) {
                  final y =
                      window.top + 18 + (window.height - 36) * _line.value;
                  return Stack(
                    children: [
                      Positioned(
                        left: window.left + 18,
                        width: window.width - 36,
                        top: y,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: _gold,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: _gold.withValues(alpha: 0.7),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    _RoundButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: _sw ? 'Rudi' : 'Back',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    _RoundButton(
                      icon: _torchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      tooltip: _sw ? 'Tochi' : 'Torch',
                      active: _torchOn,
                      onTap: _toggleTorch,
                    ),
                    const SizedBox(width: 10),
                    _RoundButton(
                      icon: Icons.cameraswitch_rounded,
                      tooltip: _sw ? 'Badili kamera' : 'Switch camera',
                      onTap: () => _controller.switchCamera(),
                    ),
                  ],
                ),
              ),
            ),

            // Hint / error text under the frame
            Positioned(
              left: 24,
              right: 24,
              top: window.bottom + 28,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _error != null
                    ? _Pill(
                  key: const ValueKey('error'),
                  text: _error!,
                  color: const Color(0xFFE5484D),
                  icon: Icons.error_outline_rounded,
                )
                    : _Pill(
                  key: const ValueKey('hint'),
                  text: _sw
                      ? 'Elekeza kamera kwenye QR ya app'
                      : 'Point the camera at an app QR code',
                  color: Colors.white24,
                  icon: Icons.qr_code_scanner_rounded,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect window;
  const _OverlayPainter(this.window);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(window, const Radius.circular(28));

    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
        overlay, Paint()..color = Colors.black.withValues(alpha: 0.62));

    // Gold corner brackets
    final p = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const len = 34.0;
    const r = 28.0;
    final l = window.left, t = window.top, rt = window.right, b = window.bottom;

    canvas.drawPath(
      Path()
        ..moveTo(l, t + len)
        ..lineTo(l, t + r)
        ..arcToPoint(Offset(l + r, t), radius: const Radius.circular(r))
        ..lineTo(l + len, t),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rt - len, t)
        ..lineTo(rt - r, t)
        ..arcToPoint(Offset(rt, t + r), radius: const Radius.circular(r))
        ..lineTo(rt, t + len),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(l, b - len)
        ..lineTo(l, b - r)
        ..arcToPoint(Offset(l + r, b),
            radius: const Radius.circular(r), clockwise: false)
        ..lineTo(l + len, b),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rt - len, b)
        ..lineTo(rt - r, b)
        ..arcToPoint(Offset(rt, b - r),
            radius: const Radius.circular(r), clockwise: false)
        ..lineTo(rt, b - len),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) => old.window != window;
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? _gold : Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: active ? _navy : Colors.white, size: 23),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _Pill({
    super.key,
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final bool denied;
  final bool sw;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _CameraError({
    required this.denied,
    required this.sw,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final title = denied
        ? (sw ? 'Ruhusa ya kamera inahitajika' : 'Camera permission needed')
        : (sw ? 'Kamera haipatikani' : 'Camera not available');
    final body = denied
        ? (sw
        ? 'Washa ruhusa ya kamera kwenye Mipangilio ya simu, kisha jaribu tena.'
        : 'Allow camera access in your phone Settings, then try again.')
        : (sw
        ? 'Imeshindwa kuwasha kamera. Jaribu tena.'
        : 'The camera could not be started. Please try again.');

    return Container(
      color: _navy,
      padding: const EdgeInsets.all(32),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_rounded, color: _gold, size: 64),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _navy,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(sw ? 'Jaribu tena' : 'Try again'),
            ),
            TextButton(
              onPressed: onBack,
              child: Text(
                sw ? 'Rudi' : 'Back',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}