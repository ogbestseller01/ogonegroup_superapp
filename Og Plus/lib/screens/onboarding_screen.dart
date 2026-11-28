// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_prefs.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../config/app_strings.dart';

// ══════════════════════════════════════════════════════════════
// Design Constants & Colors (Synced with AppTheme Dark Mode)
// ══════════════════════════════════════════════════════════════
const Color _gold = AppTheme.secondary;
const Color _goldLight = AppTheme.goldLight;
const String _logoAsset = 'assets/images/homeimg.png';

const _goldGradient = LinearGradient(
  colors: [_goldLight, _gold],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class _AppTile {
  final String slug;
  final String label;
  final Color color;
  final String? imageAsset;
  final bool isComingSoon;
  final bool isDemo;

  const _AppTile(
      this.slug,
      this.label,
      this.color, {
        this.imageAsset,
        this.isComingSoon = false,
        this.isDemo = false,
      });
}

// ── APP DEFINITIONS ──
const _nearbyFundi = _AppTile(
  'nearbyfundi',
  'NearbyFundi',
  Color(0xFF2B7BFF),
  imageAsset: 'assets/images/apps/nearbyfundi.png',
);

class _OnboardStep {
  final String title;
  final String subtitle;
  final List<_AppTile> tiles;

  const _OnboardStep({
    required this.title,
    required this.subtitle,
    this.tiles = const [],
  });
}

// ══════════════════════════════════════════════════════════════
// Onboarding Screen State & Layout (Dark-First Default)
// ══════════════════════════════════════════════════════════════
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isFinishing = false;

  bool get _isLastPage => _currentIndex == 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_isFinishing) return;
    _isFinishing = true;

    try {
      await AppPrefs.setOnboardingDone();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  void _onNextPressed() {
    HapticFeedback.selectionClick();
    if (_isLastPage) {
      _completeOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    const backgroundColor = AppTheme.darkBackground;
    const textColor = AppTheme.darkTextPrimary;
    const secondaryText = AppTheme.darkTextSecondary;

    // Dynamic steps based on locale
    final steps = [
      _OnboardStep(
        title: t.onboardingWelcomeTitle,
        subtitle: t.onboardingWelcomeSubtitle,
      ),
      _OnboardStep(
        title: t.onboardingFeaturedTitle,
        subtitle: t.onboardingFeaturedSubtitle,
        tiles: [_nearbyFundi],
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // ── Full-Screen Faint Dark Background Image ──────────
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(
                  'assets/images/ogplus.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: ClipOval(
                                child: Image.asset(
                                  _logoAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.flash_on, size: 20, color: _gold),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            t.appName,
                            style: const TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      if (!_isLastPage)
                        TextButton(
                          onPressed: _completeOnboarding,
                          style: TextButton.styleFrom(foregroundColor: secondaryText),
                          child: Text(t.onboardingSkip, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),

                // Page View Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: steps.length,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (step.tiles.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(20),
                                margin: const EdgeInsets.only(bottom: 36),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkSurface.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  border: Border.all(
                                    color: AppTheme.darkBorder,
                                    width: 0.6,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  alignment: WrapAlignment.center,
                                  children: step.tiles.map((tile) => _buildAppTile(tile)).toList(),
                                ),
                              )
                            else
                              Container(
                                height: 160,
                                width: 160,
                                margin: const EdgeInsets.only(bottom: 36),
                                decoration: BoxDecoration(
                                  gradient: _goldGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _gold.withValues(alpha: 0.35),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.verified_rounded, size: 64, color: AppTheme.primary),
                                ),
                              ),

                            Text(
                              step.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              step.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: secondaryText,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Indicators & Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(steps.length, (i) {
                          bool isActive = i == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive ? _gold : secondaryText.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _onNextPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: AppTheme.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                          child: Text(
                            _isLastPage ? t.onboardingGetStarted : t.onboardingContinue,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppTile(_AppTile tile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            color: tile.color,
            boxShadow: [
              BoxShadow(
                color: tile.color.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: tile.imageAsset != null
                ? Image.asset(tile.imageAsset!, fit: BoxFit.cover, width: 64, height: 64)
                : const Icon(Icons.apps_rounded, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tile.label, // Uses localized label if needed, though "NearbyFundi" is a brand
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkTextSecondary,
          ),
        ),
      ],
    );
  }
}