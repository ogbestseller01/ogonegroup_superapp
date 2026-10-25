// lib/screens/onboarding_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_prefs.dart';
import '../../config/app_routes.dart';
import '../../config/app_strings.dart';
import '../../config/app_theme.dart';

// ══════════════════════════════════════════════════════════════
// Constants
// ══════════════════════════════════════════════════════════════
const Color _navy = Color(0xFF1A2B4A);
const Color _gold = Color(0xFFFFB300);
const String _logoAsset = 'assets/images/homeimg.png';
const String _sliderAsset = 'assets/images/sliderimg.png';

const _goldGradient = LinearGradient(
  colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _icons = <String, IconData>{
  'build': Icons.build_rounded,
  'handyman': Icons.handyman_rounded,
  'fastfood': Icons.fastfood_rounded,
  'local_laundry_service': Icons.local_laundry_service_rounded,
  'local_car_wash': Icons.local_car_wash_rounded,
  'local_shipping': Icons.local_shipping_rounded,
  'find_in_page': Icons.find_in_page_rounded,
  'pets': Icons.pets_rounded,
  'delivery_dining': Icons.delivery_dining_rounded,
  'directions_car': Icons.directions_car_rounded,
  'home_work': Icons.home_work_rounded,
};

IconData _iconFor(String name) => _icons[name] ?? Icons.apps_rounded;

Color _shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
      .toColor();
}

// ══════════════════════════════════════════════════════════════
// Content
// ══════════════════════════════════════════════════════════════
class _AppTile {
  final String slug;
  final String iconName;
  final Color color;
  final String? imageAsset;

  const _AppTile(this.slug, this.iconName, this.color, {this.imageAsset});
}

const _nearbyFundi = _AppTile('nearbyfundi', 'build', Color(0xFF2B7BFF), imageAsset: 'assets/images/apps/nearbyfundi.png');
const _fundiApp = _AppTile('fundiapp', 'handyman', Color(0xFFFFB300), imageAsset: 'assets/images/apps/fundi_app.png');
const _msosi = _AppTile('msosi', 'fastfood', Color(0xFFE85D04), imageAsset: 'assets/images/apps/msosi_chap_chap.png');
const _safariPoa = _AppTile('safaripoa', 'directions_car', Color(0xFF00A86B), imageAsset: 'assets/images/apps/safaripoa.png');
const _duma = _AppTile('duma', 'delivery_dining', Color(0xFF6D4C41), imageAsset: 'assets/images/apps/duma_app.png');
const _laundry = _AppTile('laundry', 'local_laundry_service', Color(0xFF2F80D1), imageAsset: 'assets/images/apps/laundry.png');
const _osha = _AppTile('osha', 'local_car_wash', Color(0xFF2E9E8A), imageAsset: 'assets/images/apps/osha_papo_hapo.png');
const _hama = _AppTile('hama', 'local_shipping', Color(0xFF6A3FB5), imageAsset: 'assets/images/apps/hama_chap_chap.png');
const _dalali = _AppTile('dalali', 'home_work', Color(0xFF0E8F6E), imageAsset: 'assets/images/apps/dalali_online.png');
const _nimepoteza = _AppTile('nimepoteza', 'find_in_page', Color(0xFFE6B422), imageAsset: 'assets/images/apps/nimepoteza.png');

enum StepType { welcome, trustedHelp, food, everyday, allInOne }

class _Step {
  final StepType type;
  final List<_AppTile> tiles;
  final int columns;

  const _Step({
    required this.type,
    this.tiles = const [],
    this.columns = 2,
  });

  String getTitle(AppLocalizations t) {
    switch (type) {
      case StepType.welcome: return t.onboardingWelcomeTitle;
      case StepType.trustedHelp: return t.onboardingTrustedHelpTitle;
      case StepType.food: return t.onboardingFoodTitle;
      case StepType.everyday: return t.onboardingEverydayTitle;
      case StepType.allInOne: return t.onboardingAllInOneTitle;
    }
  }

  String getBody(AppLocalizations t) {
    switch (type) {
      case StepType.welcome: return t.onboardingWelcomeBody;
      case StepType.trustedHelp: return t.onboardingTrustedHelpBody;
      case StepType.food: return t.onboardingFoodBody;
      case StepType.everyday: return t.onboardingEverydayBody;
      case StepType.allInOne: return t.onboardingAllInOneBody;
    }
  }
}

const _steps = <_Step>[
  _Step(type: StepType.welcome),
  _Step(type: StepType.trustedHelp, tiles: [_nearbyFundi, _fundiApp]),
  _Step(type: StepType.food, tiles: [_msosi, _duma]),
  _Step(
    type: StepType.everyday,
    // Dalali Online sits right before Nimepoteza.
    tiles: [_laundry, _osha, _hama, _safariPoa, _dalali, _nimepoteza],
    columns: 3,
  ),
  _Step(
    type: StepType.allInOne,
    tiles: [
      _nearbyFundi,
      _fundiApp,
      _msosi,
      _laundry,
      _osha,
      _hama,
      _safariPoa,
      _duma,
      _dalali,
      _nimepoteza,
    ],
    // 10 apps: 4 columns = 3 rows, so the card stays compact.
    columns: 4,
  ),
];

// ══════════════════════════════════════════════════════════════
// Screen
// ══════════════════════════════════════════════════════════════
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = PageController();
  int _index = 0;
  bool _finishing = false;
  late final AnimationController _blobCtrl;

  bool get _last => _index == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _blobCtrl.dispose();
    super.dispose();
  }

  /// Marks onboarding as done (so it never shows again) and opens dashboard.
  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;

    try {
      await AppPrefs.setOnboardingDone();
    } catch (_) {
      // Even if saving fails, still let the user into the app.
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_last) {
      _finish();
      return;
    }
    _ctrl.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _goTo(int i) {
    HapticFeedback.selectionClick();
    _ctrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final screenW = size.width;

    final bg = isDark ? AppTheme.darkBackground : Colors.white;
    final bgAlt = isDark ? AppTheme.darkSurface : const Color(0xFFF4F7FC);
    final onBg = isDark ? Colors.white : AppTheme.primary;
    final muted =
    isDark ? AppTheme.darkTextSecondary : const Color(0xFF5B6B82);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            // Soft gradient base
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bg, bgAlt],
                  ),
                ),
              ),
            ),

            // Soft animated blobs
            AnimatedBuilder(
              animation: _blobCtrl,
              builder: (_, __) {
                final v = _blobCtrl.value;
                return Stack(
                  children: [
                    Positioned(
                      right: -95 + 25 * v,
                      bottom: -140 + 35 * (1 - v),
                      child: _Blob(
                        size: 310 + 35 * v,
                        color: _gold.withValues(alpha: isDark ? 0.07 : 0.13),
                      ),
                    ),
                    Positioned(
                      left: -75 - 18 * v,
                      top: -95 + 28 * v,
                      child: _Blob(
                        size: 250 + 25 * (1 - v),
                        color: AppTheme.primary
                            .withValues(alpha: isDark ? 0.11 : 0.055),
                      ),
                    ),
                    Positioned(
                      left: screenW * 0.38,
                      top: size.height * 0.20,
                      child: _Blob(
                        size: 110 + 18 * v,
                        color: const Color(0xFF6A3FB5)
                            .withValues(alpha: isDark ? 0.07 : 0.045),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Background illustration
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: isDark ? 0.58 : 0.52,
                  child: OverflowBox(
                    maxWidth: screenW * 2.15,
                    maxHeight: double.infinity,
                    alignment: const Alignment(0, 0.08),
                    child: Image.asset(
                      _sliderAsset,
                      width: screenW * 2.15,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    title: t.appName,
                    skipLabel: t.skip,
                    showSkip: !_last,
                    onSkip: _finish,
                    onBg: onBg,
                    muted: muted,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _ctrl,
                      itemCount: _steps.length,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) => _StepPage(
                        step: _steps[i],
                        isDark: isDark,
                        onBg: onBg,
                        muted: muted,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 22),
                    child: Column(
                      children: [
                        _Dots(
                          count: _steps.length,
                          index: _index,
                          isDark: isDark,
                          onTap: _goTo,
                        ),
                        const SizedBox(height: 16),
                        _PrimaryButton(
                          label: _last ? t.getStarted : t.next,
                          icon: _last
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          onTap: _next,
                        ),
                      ],
                    ),
                  ),
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
// Top bar — logo left + title left
// ══════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final String title;
  final String skipLabel;
  final bool showSkip;
  final VoidCallback onSkip;
  final Color onBg;
  final Color muted;

  const _TopBar({
    required this.title,
    required this.skipLabel,
    required this.showSkip,
    required this.onSkip,
    required this.onBg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 10, 0),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            const _MiniLogo(size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: onBg,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: showSkip ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !showSkip,
                child: TextButton(
                  onPressed: onSkip,
                  child: Text(
                    skipLabel,
                    style: TextStyle(
                      color: muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Step page
// ══════════════════════════════════════════════════════════════
class _StepPage extends StatelessWidget {
  final _Step step;
  final bool isDark;
  final Color onBg;
  final Color muted;

  const _StepPage({
    required this.step,
    required this.isDark,
    required this.onBg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return LayoutBuilder(
      builder: (context, constraints) {
        final heroH = constraints.maxHeight * 0.50;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              SizedBox(
                height: heroH,
                child: Center(
                  child: _Hero(step: step, maxHeight: heroH, isDark: isDark),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          step.getTitle(t),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: onBg,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.18,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step.getBody(t),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Hero
// ══════════════════════════════════════════════════════════════
class _Hero extends StatelessWidget {
  final _Step step;
  final double maxHeight;
  final bool isDark;

  const _Hero({
    required this.step,
    required this.maxHeight,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: Transform.scale(scale: 0.94 + 0.06 * v, child: child),
        ),
      ),
      child: step.tiles.isEmpty
          ? _WelcomeVisual(maxHeight: maxHeight, isDark: isDark)
          : _TilesHero(step: step, maxHeight: maxHeight, isDark: isDark),
    );
  }
}

/// Welcome step — orbit of mini-app icons + gold OG badge
class _WelcomeVisual extends StatelessWidget {
  final double maxHeight;
  final bool isDark;

  const _WelcomeVisual({required this.maxHeight, required this.isDark});

  static const _preview = [
    _nearbyFundi,
    _msosi,
    _safariPoa,
    _duma,
    _laundry,
    _osha,
    _hama,
    _fundiApp,
    _dalali,
    _nimepoteza,
  ];

  @override
  Widget build(BuildContext context) {
    final size = math.min(maxHeight * 0.92, 290.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft gold glow
          Container(
            width: size * 0.82,
            height: size * 0.82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _gold.withValues(alpha: isDark ? 0.16 : 0.20),
                  _gold.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Orbit icons (10 now, slightly smaller so they never touch)
          for (var i = 0; i < _preview.length; i++)
            _OrbitIcon(
              tile: _preview[i],
              index: i,
              total: _preview.length,
              radius: size * 0.37,
              iconSize: size * 0.11,
              isDark: isDark,
            ),
          // Center gold badge
          Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _goldGradient,
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.48),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'OG',
                style: TextStyle(
                  color: _navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitIcon extends StatelessWidget {
  final _AppTile tile;
  final int index;
  final int total;
  final double radius;
  final double iconSize;
  final bool isDark;

  const _OrbitIcon({
    required this.tile,
    required this.index,
    required this.total,
    required this.radius,
    required this.iconSize,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rad = (2 * math.pi * index / total) - math.pi / 2;
    final ox = radius * math.cos(rad);
    final oy = radius * math.sin(rad);

    return Transform.translate(
      offset: Offset(ox, oy),
      child: Container(
        width: iconSize * 1.55,
        height: iconSize * 1.55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(iconSize * 0.42),
          gradient: tile.imageAsset == null
              ? LinearGradient(
            colors: [_shade(tile.color, 0.10), _shade(tile.color, -0.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          boxShadow: [
            BoxShadow(
              color: tile.color.withValues(alpha: isDark ? 0.36 : 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: tile.imageAsset != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(iconSize * 0.42),
          child: Image.asset(
            tile.imageAsset!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              _iconFor(tile.iconName),
              size: iconSize * 0.82,
              color: tile.color.computeLuminance() > 0.4 ? _navy : Colors.white,
            ),
          ),
        )
            : Icon(
          _iconFor(tile.iconName),
          size: iconSize * 0.82,
          color: tile.color.computeLuminance() > 0.4 ? _navy : Colors.white,
        ),
      ),
    );
  }
}

class _TilesHero extends StatelessWidget {
  static const double _pad = 16;
  static const double _gap = 10;
  static const double _runGap = 12;
  static const double _labelH = 28;

  final _Step step;
  final double maxHeight;
  final bool isDark;

  const _TilesHero({
    required this.step,
    required this.maxHeight,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cols = step.columns;
    final rows = (step.tiles.length / cols).ceil();

    return Container(
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.09)
              : _navy.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final itemW = (c.maxWidth - _gap * (cols - 1)) / cols;
          final byWidth = itemW * 0.72;
          final rowBudget =
              (maxHeight - 2 * _pad - _runGap * (rows - 1)) / rows;
          final byHeight = rowBudget - 8 - _labelH;
          final tile =
          math.min(byWidth, byHeight).clamp(38.0, 74.0).toDouble();

          // FittedBox only scales the grid down when a small screen cannot
          // fit every row, so the tiles never spill out of the card.
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: c.maxWidth,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: _gap,
                runSpacing: _runGap,
                children: [
                  for (final a in step.tiles)
                    SizedBox(
                      width: itemW,
                      child: _TileView(
                        tile: a,
                        size: tile,
                        compact: itemW < 88,
                        isDark: isDark,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TileView extends StatelessWidget {
  final _AppTile tile;
  final double size;
  final bool compact;
  final bool isDark;

  const _TileView({
    required this.tile,
    required this.size,
    required this.compact,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = tile.color;
    final iconColor = color.computeLuminance() > 0.4 ? _navy : Colors.white;
    final t = context.t;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.32),
            gradient: tile.imageAsset == null
                ? LinearGradient(
              colors: [_shade(color, 0.10), _shade(color, -0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.32 : 0.26),
                blurRadius: 13,
                spreadRadius: -2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: tile.imageAsset != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.32),
            child: Image.asset(
              tile.imageAsset!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                _iconFor(tile.iconName),
                size: size * 0.48,
                color: iconColor,
              ),
            ),
          )
              : Icon(
            _iconFor(tile.iconName),
            size: size * 0.48,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          t.serviceTitle(tile.slug),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.primary,
            fontSize: compact ? 10 : 11.5,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Shared widgets
// ══════════════════════════════════════════════════════════════
class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _MiniLogo extends StatelessWidget {
  final double size;

  const _MiniLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          _logoAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.apps_rounded,
            color: AppTheme.primary,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _Dots({
    required this.count,
    required this.index,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final idle = isDark ? Colors.white24 : Colors.black12;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == index;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: on ? 26 : 7,
              height: 7,
              decoration: BoxDecoration(
                gradient: on ? _goldGradient : null,
                color: on ? null : idle,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _goldGradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.42),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 20, color: _navy),
              ],
            ),
          ),
        ),
      ),
    );
  }
}