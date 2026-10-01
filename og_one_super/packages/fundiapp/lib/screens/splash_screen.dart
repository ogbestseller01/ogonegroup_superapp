// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

/// Package name of this SDK (must match `name:` in pubspec.yaml).
/// Needed so assets resolve when this code runs inside the super app.
const String _kAssetPackage = 'fundiapp_sdk';

/// SharedPreferences key — one flag per SDK, so Fundi and NearbyFundi
/// don't stomp on each other when both are embedded.
const String _kFirstLaunchKey = 'fundiapp_is_first_launch';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const String logoPath = 'assets/images/app_icon.png';

  late final AnimationController _mainController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _mainController.forward();
    _navigate();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(_kFirstLaunchKey) ?? true;

    // Read auth *after* the delay so a login completed during the
    // splash animation is picked up correctly.
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    if (isFirstLaunch) {
      await prefs.setBool(_kFirstLaunchKey, false);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else if (auth.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.navy950,
              AppTheme.navy800,
              AppTheme.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulse =
                              1.0 + (_pulseController.value * 0.02);
                          return Transform.scale(
                            scale: pulse,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.secondary
                                        .withOpacity(0.35),
                                    blurRadius: 50,
                                    spreadRadius: 10,
                                  ),
                                  BoxShadow(
                                    color:
                                    Colors.black.withOpacity(0.2),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Image.asset(
                                logoPath,
                                package: _kAssetPackage,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.handyman_rounded,
                                  size: 64,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Brand
                  FadeTransition(
                    opacity: _contentFade,
                    child: Column(
                      children: [
                        const Text(
                          'Fundi App',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.secondary,
                                AppTheme.gold400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Trusted technicians, right where you need them.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Loading dots
                  FadeTransition(
                    opacity: _contentFade,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLoadingDot(0),
                            const SizedBox(width: 12),
                            _buildLoadingDot(1),
                            const SizedBox(width: 12),
                            _buildLoadingDot(2),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDot(int index) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        final delay = index * 0.15;
        final progress =
        (_mainController.value - delay).clamp(0.0, 1.0);
        final scale = 0.4 + (progress * 1.6);

        return Transform.scale(
          scale: scale.clamp(0.4, 2.0),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color:
              AppTheme.secondary.withOpacity(0.3 + (progress * 0.7)),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondary.withOpacity(0.25 * progress),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}