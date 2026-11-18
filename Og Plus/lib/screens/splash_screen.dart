// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_prefs.dart';
import '../config/app_routes.dart';
import '../config/app_strings.dart';
import '../config/app_theme.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _main;
  late final AnimationController _pulse;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _nameFade;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _lineFade;
  late final Animation<double> _tagFade;
  late final Animation<double> _bar;

  /// Read the flag while the splash animation plays, so there is no delay
  /// when the animation ends.
  late final Future<bool> _onboardingDone;

  @override
  void initState() {
    super.initState();

    _onboardingDone = AppPrefs.isOnboardingDone();

    _main = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    CurvedAnimation iv(double a, double b, [Curve c = Curves.easeOut]) =>
        CurvedAnimation(parent: _main, curve: Interval(a, b, curve: c));

    _logoFade = iv(0.00, 0.28);
    _logoScale =
        Tween(begin: 0.72, end: 1.0).animate(iv(0.00, 0.40, Curves.easeOutBack));
    _nameFade = iv(0.25, 0.50);
    _nameSlide = Tween(begin: const Offset(0, 0.22), end: Offset.zero)
        .animate(iv(0.25, 0.50, Curves.easeOutCubic));
    _lineFade = iv(0.42, 0.62);
    _tagFade = iv(0.50, 0.72);
    _bar = iv(0.15, 0.88, Curves.easeInOut);

    _main.forward().whenComplete(_goNext);
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;

    bool done;
    try {
      done = await _onboardingDone;
    } catch (_) {
      done = false;
    }

    if (!mounted) return;

    if (done) {
      // Returning user: splash -> dashboard
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } else {
      // First install only: splash -> onboarding -> dashboard
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 480),
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _main.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    final bg = isDark ? AppTheme.darkBackground : const Color(0xFF0F1A2E);
    final onBg = Colors.white;
    final muted = Colors.white70;
    const gold = Color(0xFFFFB300);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            // Deep navy gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                      AppTheme.darkBackground,
                      const Color(0xFF152238),
                      AppTheme.darkSurface,
                    ]
                        : [
                      const Color(0xFF0F1A2E),
                      const Color(0xFF1A2B4A),
                      const Color(0xFF152238),
                    ],
                  ),
                ),
              ),
            ),

            // Soft gold glow top-right
            Positioned(
              right: -size.width * 0.25,
              top: -size.height * 0.12,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  final s = 280.0 + 40 * _pulse.value;
                  return Container(
                    width: s,
                    height: s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          gold.withValues(alpha: 0.18 + 0.06 * _pulse.value),
                          gold.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Soft blue glow bottom-left
            Positioned(
              left: -size.width * 0.2,
              bottom: -size.height * 0.08,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2B7BFF).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Logo
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: _SplashLogo(pulse: _pulse),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // App name
                  FadeTransition(
                    opacity: _nameFade,
                    child: SlideTransition(
                      position: _nameSlide,
                      child: Text(
                        t.appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: onBg,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3.8,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Gold line + dot
                  FadeTransition(
                    opacity: _lineFade,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 36, height: 1.5, color: gold),
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: const BoxDecoration(
                            color: gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(width: 36, height: 1.5, color: gold),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Tagline
                  FadeTransition(
                    opacity: _tagFade,
                    child: Text(
                      t.superApps,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.8,
                      ),
                    ),
                  ),

                  const Spacer(flex: 4),

                  // Progress
                  FadeTransition(
                    opacity: _tagFade,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _bar,
                          builder: (_, __) => _SlimBar(
                            value: _bar.value,
                            gold: gold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'v 0.0.1',
                          style: TextStyle(
                            color: muted.withValues(alpha: 0.55),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logo ────────────────────────────────────────────────────
class _SplashLogo extends StatelessWidget {
  final AnimationController pulse;

  const _SplashLogo({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final glow = 0.35 + 0.15 * pulse.value;
        return Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFB300).withValues(alpha: 0.55),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withValues(alpha: glow * 0.45),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 108,
              height: 108,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
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
                    color: Color(0xFF1A2B4A),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Slim gold progress bar ──────────────────────────────────
class _SlimBar extends StatelessWidget {
  final double value;
  final Color gold;

  const _SlimBar({required this.value, required this.gold});

  @override
  Widget build(BuildContext context) {
    const w = 140.0;
    const h = 3.5;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(h),
            ),
          ),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gold.withValues(alpha: 0.7), gold],
                ),
                borderRadius: BorderRadius.circular(h),
                boxShadow: [
                  BoxShadow(
                    color: gold.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}