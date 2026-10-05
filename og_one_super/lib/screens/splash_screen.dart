import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/app_routes.dart';
import '../config/app_strings.dart';
import '../config/app_theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/language_dropdown.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _lineWidth;
  late final Animation<double> _bottomOpacity;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    CurvedAnimation iv(double b, double e, Curve curve) =>
        CurvedAnimation(parent: _c, curve: Interval(b, e, curve: curve));

    _logoOpacity = iv(0.00, 0.28, Curves.easeOut);
    _logoScale = Tween(begin: 0.72, end: 1.0)
        .animate(iv(0.00, 0.38, Curves.easeOutBack));

    _textOpacity = iv(0.25, 0.50, Curves.easeOut);
    _textSlide = Tween(begin: const Offset(0, 0.22), end: Offset.zero)
        .animate(iv(0.25, 0.50, Curves.easeOutCubic));

    _lineWidth = Tween(begin: 0.0, end: 1.0)
        .animate(iv(0.40, 0.65, Curves.easeOutCubic));

    _progress = iv(0.15, 0.92, Curves.easeInOut);
    _bottomOpacity = iv(0.55, 0.78, Curves.easeOut);

    _c.forward().whenComplete(() {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      });
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final settings = context.watch<SettingsProvider>();
    final size = MediaQuery.sizeOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF000814),
                Color(0xFF001D45),
                Color(0xFF0A2F5C),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Soft ambient shapes
              Positioned(
                top: -size.height * 0.12,
                right: -size.width * 0.18,
                child: _GlowCircle(
                  size: size.width * 0.55,
                  color: AppTheme.secondary.withValues(alpha: 0.07),
                ),
              ),
              Positioned(
                bottom: -size.height * 0.10,
                left: -size.width * 0.15,
                child: _GlowCircle(
                  size: size.width * 0.48,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Language
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, right: 16),
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: LanguageDropdown(
                            currentCode: settings.locale.languageCode,
                            onChanged: (code) =>
                                settings.setLocale(Locale(code)),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 5),

                    // Logo
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: const _BrandLogo(),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App name + tagline
                    FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            Text(
                              t.appName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.2,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Animated gold line
                            AnimatedBuilder(
                              animation: _lineWidth,
                              builder: (_, __) {
                                return Container(
                                  width: 40 * _lineWidth.value,
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            Text(
                              t.superApps,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.secondary.withValues(alpha: 0.9),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 6),

                    // Progress + version
                    FadeTransition(
                      opacity: _bottomOpacity,
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _progress,
                            builder: (_, __) =>
                                _ThinProgress(value: _progress.value),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'v 0.0.1',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.28),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.0,
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
      ),
    );
  }
}

// ============================================================
// BRAND LOGO
// ============================================================
class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      height: 142,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: 0.35),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.18),
            blurRadius: 32,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/homeimg.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.apps_rounded,
                size: 52,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// THIN PROGRESS
// ============================================================
class _ThinProgress extends StatelessWidget {
  final double value;

  const _ThinProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 3,
      child: Stack(
        children: [
          // Track
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Fill
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5C30E), Color(0xFFFFD54F)],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withValues(alpha: 0.4),
                    blurRadius: 6,
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

// ============================================================
// GLOW CIRCLE
// ============================================================
class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}