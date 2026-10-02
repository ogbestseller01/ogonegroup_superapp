// lib/screens/dashboard/super_app_dashboard.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fundiapp_sdk/fundi_app_mini.dart';
import 'package:nearbyfundi_sdk/nearby_fundi_mini.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../data/mini_apps_data.dart';
import '../../models/mini_app.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/language_dropdown.dart';

Color _hex(String h) => Color(int.parse(h.replaceFirst('#', '0xFF')));

IconData _iconFor(String name) {
  switch (name) {
    case 'build':
      return Icons.build_rounded;
    case 'handyman':
      return Icons.handyman_rounded;
    case 'fastfood':
      return Icons.fastfood_rounded;
    case 'local_hospital':
      return Icons.local_hospital_rounded;
    case 'local_laundry_service':
      return Icons.local_laundry_service_rounded;
    case 'local_car_wash':
      return Icons.local_car_wash_rounded;
    case 'local_shipping':
      return Icons.local_shipping_rounded;
    case 'meeting_room':
      return Icons.meeting_room_rounded;
    default:
      return Icons.apps_rounded;
  }
}

/// Slide shown in the banner slideshow.
class _Slide {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final Color ink;
  final IconData icon;
  const _Slide(this.title, this.subtitle, this.colors, this.ink, this.icon);
}

class SuperAppDashboard extends StatefulWidget {
  const SuperAppDashboard({super.key});

  @override
  State<SuperAppDashboard> createState() => _SuperAppDashboardState();
}

class _SuperAppDashboardState extends State<SuperAppDashboard> {
  String _query = '';

  /// 'all' or the slug of the selected app.
  String _selected = 'all';

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  void _open(MiniApp app, AppLocalizations t) {
    FocusScope.of(context).unfocus();
    if (app.isComingSoon) {
      _snack(t.comingSoonMessage);
      return;
    }
    switch (app.slug) {
      case 'fundiapp':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FundiAppMiniApp()),
        );
        break;
      case 'nearbyfundi':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NearbyFundiMiniApp()),
        );
        break;
      default:
        _snack(t.opening(t.serviceTitle(app.slug)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final t = context.t;
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width > 800 ? (width - 760) / 2 : 20.0;

    final q = _query.trim().toLowerCase();
    final searching = q.isNotEmpty;

    // Search wins; otherwise filter by the selected app chip.
    final apps = miniApps.where((a) {
      if (searching) {
        final title = t.serviceTitle(a.slug).toLowerCase();
        return title.contains(q) ||
            a.slug.toLowerCase().contains(q) ||
            a.name.toLowerCase().contains(q);
      }
      return _selected == 'all' || a.slug == _selected;
    }).toList();

    // Chips: "All" + every live app, by app name.
    final chipApps = miniApps.where((a) => !a.isComingSoon).toList();

    final slides = <_Slide>[
      _Slide(
        t.bannerTitle,
        t.bannerSubtitle,
        const [Color(0xFFFFC61F), Color(0xFFF5A90E)],
        AppTheme.primary,
        Icons.grid_view_rounded,
      ),
      const _Slide(
        'Trusted fundis, near you',
        'Book verified technicians in a few taps',
        [Color(0xFF0A3670), Color(0xFF1A5BB5)],
        Colors.white,
        Icons.handyman_rounded,
      ),
      const _Slide(
        'Food & laundry, delivered',
        'Msosi Chap Chap and Mfua Nguo at your door',
        [Color(0xFFE8590C), Color(0xFFF98A3B)],
        Colors.white,
        Icons.delivery_dining_rounded,
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor:
        isDark ? AppTheme.darkBackground : const Color(0xFFF5F7FB),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: _Header(
                t: t,
                hPad: hPad,
                languageCode: settings.locale.languageCode,
                onLanguage: (code) => settings.setLocale(Locale(code)),
                onSettings: () =>
                    Navigator.pushNamed(context, AppRoutes.settings),
                onSearch: (v) => setState(() => _query = v),
              ),
            ),

            // ── Slideshow banner (only when not searching) ─
            if (!searching)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                sliver: SliverToBoxAdapter(
                  child: _Reveal(
                    index: 0,
                    child: _Slideshow(slides: slides),
                  ),
                ),
              ),

            // ── Section title ───────────────────────────────
            SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.allServices,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${apps.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color:
                          isDark ? AppTheme.secondary : AppTheme.gold600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── App-name chips (All + each app) ─────────────
            if (!searching)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: chipApps.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _AppChip(
                          label: t.allServices,
                          icon: Icons.apps_rounded,
                          selected: _selected == 'all',
                          isDark: isDark,
                          onTap: () => setState(() => _selected = 'all'),
                        );
                      }
                      final a = chipApps[i - 1];
                      return _AppChip(
                        label: t.serviceTitle(a.slug),
                        icon: _iconFor(a.icon),
                        selected: _selected == a.slug,
                        isDark: isDark,
                        onTap: () => setState(() => _selected = a.slug),
                      );
                    },
                  ),
                ),
              ),

            // ── Empty / Grid ────────────────────────────────
            if (apps.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 56),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: isDark ? Colors.white30 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.noResults,
                        style: TextStyle(
                          fontSize: 15,
                          color:
                          isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 40),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 100, // compact circular tiles
                    mainAxisExtent: 118,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final app = apps[i];
                      return _Reveal(
                        key: ValueKey('${app.slug}|$_selected'),
                        index: i + 2,
                        child: _ServiceCard(
                          app: app,
                          title: t.serviceTitle(app.slug),
                          soonLabel: t.soon,
                          onTap: () => _open(app, t),
                        ),
                      );
                    },
                    childCount: apps.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ENTRANCE ANIMATION
// ============================================================
class _Reveal extends StatelessWidget {
  final int index;
  final Widget child;
  const _Reveal({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + index.clamp(0, 10) * 60),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

// ============================================================
// HEADER (unchanged)
// ============================================================
class _Header extends StatelessWidget {
  final AppLocalizations t;
  final double hPad;
  final String languageCode;
  final ValueChanged<String> onLanguage;
  final VoidCallback onSettings;
  final ValueChanged<String> onSearch;

  static const double _searchHeight = 54;
  static const double _overlap = 28;

  const _Header({
    required this.t,
    required this.hPad,
    required this.languageCode,
    required this.onLanguage,
    required this.onSettings,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: _searchHeight - _overlap),
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF000C1F),
                  Color(0xFF001D45),
                  Color(0xFF0A3670),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -40,
                  child: _Blob(
                      size: 220,
                      color: AppTheme.secondary.withValues(alpha: 0.12)),
                ),
                Positioned(
                  bottom: -50,
                  left: -30,
                  child: _Blob(
                      size: 160, color: Colors.white.withValues(alpha: 0.05)),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                    EdgeInsets.fromLTRB(hPad, 14, hPad, _overlap + 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/homeimg.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.apps_rounded,
                                    color: AppTheme.primary,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t.appName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            LanguageDropdown(
                              currentCode: languageCode,
                              onChanged: onLanguage,
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: onSettings,
                                borderRadius: BorderRadius.circular(14),
                                child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Icon(Icons.settings_rounded,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          t.welcome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.chooseService,
                          style: TextStyle(
                            color: AppTheme.secondary.withValues(alpha: 0.95),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
        Positioned(
          left: hPad,
          right: hPad,
          bottom: 0,
          child: Container(
            height: _searchHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              onChanged: onSearch,
              cursorColor: AppTheme.primary,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: t.searchHint,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.primary, size: 22),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
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

// ============================================================
// SLIDESHOW — auto-advancing banner cards
// ============================================================
class _Slideshow extends StatefulWidget {
  final List<_Slide> slides;
  const _Slideshow({required this.slides});

  @override
  State<_Slideshow> createState() => _SlideshowState();
}

class _SlideshowState extends State<_Slideshow> {
  late final PageController _ctrl;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.92);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_ctrl.hasClients) return;
      final next = (_page + 1) % widget.slides.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        SizedBox(
          height: 118,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final s = widget.slides[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: s.colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: s.colors.last.withValues(alpha: 0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: s.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: s.ink.withValues(alpha: 0.78),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Circular icon badge on the right
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: s.ink.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(s.icon, size: 28, color: s.ink),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.slides.length, (i) {
            final on = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: on ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: on
                    ? AppTheme.secondary
                    : (isDark ? Colors.white24 : Colors.black12),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ============================================================
// APP-NAME CHIP
// ============================================================
class _AppChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _AppChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppTheme.primary
        : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white);
    final fg = selected
        ? Colors.white
        : (isDark ? Colors.white70 : AppTheme.primary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : (isDark ? AppTheme.darkBorder : const Color(0xFFE3E8F1)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: selected ? AppTheme.secondary : fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SERVICE CARD — circular, compact mini-app tile (unchanged)
// ============================================================
class _ServiceCard extends StatelessWidget {
  final MiniApp app;
  final String title;
  final String soonLabel;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.app,
    required this.title,
    required this.soonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _hex(app.color);
    final iconColor = app.isComingSoon ? AppTheme.gold600 : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : color.withValues(alpha: 0.12),
                border: Border.all(
                  color: isDark
                      ? AppTheme.darkBorder
                      : color.withValues(alpha: 0.18),
                  width: 1.2,
                ),
                boxShadow: isDark
                    ? null
                    : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(_iconFor(app.icon), size: 28, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                height: 1.2,
                color: isDark ? Colors.white : AppTheme.primary,
              ),
            ),
            if (app.isComingSoon) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  soonLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.secondary : AppTheme.gold600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}