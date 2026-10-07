import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_routes.dart';
import '../config/app_strings.dart';
import '../config/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _rings;
  late final AnimationController _shimmer;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _bottomOpacity;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _rings = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    CurvedAnimation iv(double b, double e, Curve curve) =>
        CurvedAnimation(parent: _intro, curve: Interval(b, e, curve: curve));

    _logoOpacity = iv(0.00, 0.30, Curves.easeOut);
    _logoScale = Tween(begin: 0.80, end: 1.0)
        .animate(iv(0.00, 0.45, Curves.easeOutBack));
    _titleOpacity = iv(0.28, 0.55, Curves.easeOut);
    _titleSlide = Tween(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(iv(0.28, 0.55, Curves.easeOutCubic));
    _taglineOpacity = iv(0.45, 0.70, Curves.easeOut);
    _progress = iv(0.20, 0.90, Curves.easeInOut);
    _bottomOpacity = iv(0.60, 0.85, Curves.easeOut);

    _intro.forward().whenComplete(() {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      });
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _rings.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Theme-aware palette ─────────────────────────────
    final bg = isDark ? AppTheme.darkBackground : Colors.white;
    final bgAlt = isDark ? AppTheme.darkSurface : const Color(0xFFF4F7FC);
    final onBg = isDark ? Colors.white : AppTheme.primary;
    final muted =
    isDark ? AppTheme.darkTextSecondary : const Color(0xFF5B6B82);
    final gold = AppTheme.secondary;
    final ringBase = isDark ? AppTheme.secondary : AppTheme.primary;
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : AppTheme.primary.withValues(alpha: 0.10);
    final bigBlob = gold.withValues(alpha: isDark ? 0.06 : 0.12);
    final smallBlob =
    AppTheme.primary.withValues(alpha: isDark ? 0.10 : 0.05);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            // ── Background gradient (theme-aware) ──
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [AppTheme.darkBackground, bgAlt]
                        : [Colors.white, bgAlt],
                  ),
                ),
              ),
            ),

            // ── Soft ambient shapes ──
            Positioned(
              right: -100,
              bottom: -140,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bigBlob,
                ),
              ),
            ),
            Positioned(
              left: -80,
              top: -100,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: smallBlob,
                ),
              ),
            ),

            // ── Main content ──
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 4),

                  // ── Logo with pulsing rings ──
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: _LogoWithRings(
                        ringBase: ringBase,
                        ringCtrl: _rings,
                        isDark: isDark,
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),

                  // ── App name ──
                  FadeTransition(
                    opacity: _titleOpacity,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: Text(
                        t.appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onBg,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3.5,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Gold divider with dot ──
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 30, height: 1.4, color: gold),
                        Container(
                          width: 6,
                          height: 6,
                          margin:
                          const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(width: 30, height: 1.4, color: gold),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Tagline ──
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: Text(
                      t.superApps,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3.2,
                      ),
                    ),
                  ),

                  const Spacer(flex: 5),

                  // ── Progress bar + version ──
                  FadeTransition(
                    opacity: _bottomOpacity,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _progress,
                          builder: (_, __) => _ProgressBar(
                            value: _progress.value,
                            track: trackColor,
                            gold: gold,
                            shimmer: _shimmer,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'v 0.0.1',
                          style: TextStyle(
                            color: muted.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LOGO WITH PULSING RINGS
// ══════════════════════════════════════════════════════════════
class _LogoWithRings extends StatelessWidget {
  final Color ringBase;
  final AnimationController ringCtrl;
  final bool isDark;

  const _LogoWithRings({
    required this.ringBase,
    required this.ringCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const baseSize = 124.0;
    const maxSize = 190.0;

    return SizedBox(
      width: maxSize + 24,
      height: maxSize + 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding pulse rings
          AnimatedBuilder(
            animation: ringCtrl,
            builder: (_, __) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(2, (i) {
                  final t = (ringCtrl.value + i * 0.5) % 1.0;
                  final size = baseSize + (maxSize - baseSize) * t;
                  final opacity = (1.0 - t) * 0.85;
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ringBase.withValues(alpha: opacity),
                        width: 1.3,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          // Logo core
          _LogoCore(isDark: isDark),
        ],
      ),
    );
  }
}

class _LogoCore extends StatelessWidget {
  final bool isDark;
  const _LogoCore({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final outerRing = isDark
        ? AppTheme.secondary.withValues(alpha: 0.55)
        : AppTheme.primary.withValues(alpha: 0.35);
    final glow = isDark
        ? AppTheme.secondary.withValues(alpha: 0.22)
        : AppTheme.primary.withValues(alpha: 0.14);

    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: outerRing, width: 1.5),
        boxShadow: [
          BoxShadow(color: glow, blurRadius: 28, spreadRadius: 2),
        ],
      ),
      child: Center(
        child: Container(
          width: 112,
          height: 112,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/homeimg.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.apps_rounded,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PROGRESS BAR WITH SHIMMER
// ══════════════════════════════════════════════════════════════
class _ProgressBar extends StatelessWidget {
  final double value;
  final Color track;
  final Color gold;
  final AnimationController shimmer;

  const _ProgressBar({
    required this.value,
    required this.track,
    required this.gold,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    const w = 132.0;
    const h = 4.0;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          // Track
          Container(
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(h),
            ),
          ),
          // Fill
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(h),
              child: Container(
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(h),
                ),
                child: AnimatedBuilder(
                  animation: shimmer,
                  builder: (_, __) => CustomPaint(
                    painter: _ShimmerPainter(
                      progress: shimmer.value,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ShimmerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bandW = size.width * 0.3;
    final x = -bandW + (size.width + bandW * 2) * progress;
    final rect = Rect.fromLTWH(x - bandW / 2, 0, bandW, size.height);

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color,
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      old.progress != progress || old.color != color;
}