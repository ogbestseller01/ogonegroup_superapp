// packages/nearby_fundi/lib/screens/onboarding_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_routes.dart';
import '../config/app_theme.dart';

/// Package name of this SDK (must match `name:` in pubspec.yaml).
/// Needed so assets resolve when this code runs inside the super app.
const String _kAssetPackage = 'nearbyfundi_sdk';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String logoPath = 'assets/images/app_icon_foreground.png';

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      title: 'Find Fundis',
      description:
      'Discover trusted and verified technicians offering quality services near you.',
      icon: Icons.handyman_rounded,
    ),
    OnboardingItem(
      title: 'Connect Fast',
      description:
      'Browse technician profiles, check ratings and connect with the right professional.',
      icon: Icons.people_alt_rounded,
    ),
    OnboardingItem(
      title: 'Get It Done',
      description:
      'Send your request, get accepted and follow your service from start to finish.',
      icon: Icons.task_alt_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _changePage(int index) {
    setState(() => _currentPage = index);
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _items.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  /// Open the dashboard. Login is requested later, only when the user
  /// tries something that needs an account.
  void _getStarted() {
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.width < 400;
    final isShort = size.height < 640;
    final isLastPage = _currentPage == _items.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
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
          child: Column(
            children: [
              // ── Top Bar ─────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  isShort ? 10 : 20,
                  24,
                  isShort ? 4 : 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: isShort ? 38 : 44,
                      height: isShort ? 38 : 44,
                      padding: EdgeInsets.all(isShort ? 6 : 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        logoPath,
                        package: _kAssetPackage,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.handyman_rounded,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'NearbyFundi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmall ? 18 : 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!isLastPage)
                      TextButton(
                        onPressed: _skipToEnd,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── PageView ────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: _changePage,
                  itemBuilder: (context, index) => _OnboardingPage(
                    item: _items[index],
                    isSmall: isSmall,
                    isShort: isShort,
                  ),
                ),
              ),

              // ── Bottom Section ──────────────────────────
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    isShort ? 16 : 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_items.length, (index) {
                          final active = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 32 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppTheme.secondary
                                  : Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // CTA button
                      SizedBox(
                        width: double.infinity,
                        height: isShort ? 50 : 56,
                        child: ElevatedButton(
                          onPressed: isLastPage ? _getStarted : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            foregroundColor: AppTheme.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLastPage ? 'Get Started' : 'Continue',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ],
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
// PAGE
// ============================================================
class _OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final bool isSmall;
  final bool isShort;

  const _OnboardingPage({
    required this.item,
    required this.isSmall,
    required this.isShort,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Icon circle scales with the smaller dimension so it never
        // eats the whole page on short/landscape screens.
        final double base = math.min(constraints.maxWidth, constraints.maxHeight);
        final double outer = (base * 0.46).clamp(120.0, 200.0);
        final double inner = outer * 0.70;

        return SingleChildScrollView(
          // Scrollable vertically so text never overflows on small screens.
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: ConstrainedBox(
            // Keep content centered when there is plenty of room.
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon circle
                  Center(
                    child: Container(
                      width: outer,
                      height: outer,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: inner,
                          height: inner,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            item.icon,
                            size: inner * 0.46,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Title
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmall ? 26 : 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Divider
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Description
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: isSmall ? 14.5 : 16,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Benefits — Wrap handles horizontal overflow.
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: const [
                      _Benefit(icon: Icons.verified_rounded, text: 'Verified'),
                      _Benefit(icon: Icons.star_rounded, text: 'Trusted'),
                      _Benefit(icon: Icons.bolt_rounded, text: 'Fast'),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// BENEFIT PILL
// ============================================================
class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Benefit({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.secondary, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MODEL
// ============================================================
class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}