// lib/screens/splash_screen.dart

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
  late final AnimationController _controller;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    CurvedAnimation interval(double begin, double end, Curve curve) =>
        CurvedAnimation(parent: _controller, curve: Interval(begin, end, curve: curve));

    _logoFade = interval(0.00, 0.25, Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(interval(0.00, 0.35, Curves.easeOutBack));

    _titleFade = interval(0.20, 0.45, Curves.easeOut);
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(interval(0.20, 0.45, Curves.easeOutCubic));

    _taglineFade = interval(0.35, 0.60, Curves.easeOut);
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(interval(0.35, 0.60, Curves.easeOutCubic));

    _progress = interval(0.15, 1.0, Curves.easeInOut);

    _controller.forward().whenComplete(() {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final settings = context.watch<SettingsProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00102B), Color(0xFF001D45), Color(0xFF0A3670)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Soft decorative circles
              Positioned(
                top: -90,
                right: -60,
                child: _Blob(
                  size: 260,
                  color: AppTheme.secondary.withValues(alpha: 0.10),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -60,
                child: _Blob(
                  size: 220,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),

              // Centered brand block
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: const _Logo(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _titleFade,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: Text(
                          t.appName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _taglineFade,
                      child: SlideTransition(
                        position: _taglineSlide,
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppTheme.secondary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.superApps,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Language dropdown (top right)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, right: 16),
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: LanguageDropdown(
                        currentCode: settings.locale.languageCode,
                        onChanged: (code) => settings.setLocale(Locale(code)),
                      ),
                    ),
                  ),
                ),
              ),

              // Loading bar (bottom)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (_, __) => _ProgressBar(value: _progress.value),
                    ),
                  ),
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
// LOGO (white disc with a soft gold ring)
// ============================================================
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 154,
      height: 154,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.secondary.withValues(alpha: 0.45),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.18),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Container(
        width: 132,
        height: 132,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/homeimg.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.apps_rounded,
              size: 64,
              color: AppTheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROGRESS BAR
// ============================================================
class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}