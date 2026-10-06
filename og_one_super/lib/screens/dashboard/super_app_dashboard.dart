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

// ============================================================
// HELPERS
// ============================================================
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

const _headerGradient = LinearGradient(
  colors: [Color(0xFF000C1F), Color(0xFF001D45), Color(0xFF0A3670)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class _Slide {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final Color ink;
  final IconData icon;

  const _Slide(this.title, this.subtitle, this.colors, this.ink, this.icon);
}

// ============================================================
// DASHBOARD
// ============================================================
class SuperAppDashboard extends StatefulWidget {
  const SuperAppDashboard({super.key});

  @override
  State<SuperAppDashboard> createState() => _SuperAppDashboardState();
}

class _SuperAppDashboardState extends State<SuperAppDashboard> {
  String _query = '';
  String _selected = 'all';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
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

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
    FocusScope.of(context).unfocus();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _searchController.clear();
    setState(() {
      _query = '';
      _selected = 'all';
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final t = context.t;
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width > 800 ? (width - 760) / 2 : 20.0;

    final crossAxisExtent = width < 360
        ? 92.0
        : width < 420
        ? 100.0
        : width < 600
        ? 108.0
        : 118.0;
    final mainAxisExtent = crossAxisExtent + 28;

    final q = _query.trim().toLowerCase();
    final searching = q.isNotEmpty;

    final apps = miniApps.where((a) {
      if (searching) {
        return t.serviceTitle(a.slug).toLowerCase().contains(q) ||
            a.slug.toLowerCase().contains(q) ||
            a.name.toLowerCase().contains(q);
      }
      return _selected == 'all' || a.slug == _selected;
    }).toList();

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
        key: _scaffoldKey,
        backgroundColor:
        isDark ? AppTheme.darkBackground : const Color(0xFFF5F7FB),
        drawer: _AppDrawer(
          t: t,
          languageCode: settings.locale.languageCode,
          onLanguage: (code) => settings.setLocale(Locale(code)),
          onSettings: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.settings);
          },
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primary,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Header + search ───────────────────────────
              SliverToBoxAdapter(
                child: _Header(
                  t: t,
                  hPad: hPad,
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onAiAgent: () => _snack('AI Agent — Coming soon'),
                  searchController: _searchController,
                  onSearch: (v) => setState(() => _query = v),
                  onClear: _clearSearch,
                  hasText: _query.isNotEmpty,
                ),
              ),

              // ── Slideshow ─────────────────────────────────
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

              // ── Section title ─────────────────────────────
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 12),
                sliver: SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: t.allServices,
                    count: apps.length,
                    isDark: isDark,
                  ),
                ),
              ),

              // ── Chips ─────────────────────────────────────
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

              // ── Empty state / Grid ────────────────────────
              if (apps.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyState(message: t.noResults, isDark: isDark),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 36),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: crossAxisExtent,
                      mainAxisExtent: mainAxisExtent,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, i) {
                        final app = apps[i];
                        return _Reveal(
                          key: ValueKey('${app.slug}|$_selected|$searching'),
                          index: i + 2,
                          child: _ServiceCard(
                            app: app,
                            title: t.serviceTitle(app.slug),
                            soonLabel: t.soon,
                            onTap: () => _open(app, t),
                            size: crossAxisExtent * 0.52,
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
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================
class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final bool isDark;

  const _SectionTitle({
    required this.title,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.secondary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : AppTheme.primary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: isDark ? AppTheme.secondary : AppTheme.gold600,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================
class _EmptyState extends StatelessWidget {
  final String message;
  final bool isDark;

  const _EmptyState({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 30,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DRAWER
// ============================================================
class _AppDrawer extends StatelessWidget {
  final AppLocalizations t;
  final String languageCode;
  final ValueChanged<String> onLanguage;
  final VoidCallback onSettings;

  const _AppDrawer({
    required this.t,
    required this.languageCode,
    required this.onLanguage,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + 16,
                12,
                20,
              ),
              decoration: const BoxDecoration(gradient: _headerGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _Logo(size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t.appName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _GlassButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Close',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Partnerships & Integrations',
                    style: TextStyle(
                      color: AppTheme.secondary.withValues(alpha: 0.95),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
            Divider(
              height: 1,
              color: isDark ? AppTheme.darkBorder : Colors.grey.shade200,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Language',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LanguageDropdown(
                    currentCode: languageCode,
                    onChanged: onLanguage,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.settings_rounded,
                color: isDark ? Colors.white70 : AppTheme.primary,
              ),
              title: Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
              onTap: onSettings,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SHARED SMALL WIDGETS
// ============================================================
class _Logo extends StatelessWidget {
  final double size;

  const _Logo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.09),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/homeimg.png',
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

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
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
      duration: Duration(milliseconds: 340 + index.clamp(0, 10) * 50),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

// ============================================================
// HEADER
// ============================================================
class _Header extends StatelessWidget {
  final AppLocalizations t;
  final double hPad;
  final VoidCallback onMenu;
  final VoidCallback onAiAgent;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;
  final bool hasText;

  static const double _searchHeight = 52;
  static const double _overlap = 26;

  const _Header({
    required this.t,
    required this.hPad,
    required this.onMenu,
    required this.onAiAgent,
    required this.searchController,
    required this.onSearch,
    required this.onClear,
    required this.hasText,
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
              gradient: _headerGradient,
              borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -70,
                  right: -30,
                  child: _Blob(
                    size: 200,
                    color: AppTheme.secondary.withValues(alpha: 0.10),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: -20,
                  child: _Blob(
                    size: 140,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                    EdgeInsets.fromLTRB(hPad, 12, hPad, _overlap + 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _GlassButton(
                              icon: Icons.menu_rounded,
                              tooltip: 'Menu',
                              onTap: onMenu,
                            ),
                            const SizedBox(width: 12),
                            const _Logo(size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t.appName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            _GlassButton(
                              icon: Icons.smart_toy_rounded,
                              tooltip: 'AI Agent',
                              onTap: onAiAgent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Text(
                          t.welcome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.chooseService,
                          style: TextStyle(
                            color: AppTheme.secondary.withValues(alpha: 0.95),
                            fontSize: 13.5,
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

        // Floating search
        Positioned(
          left: hPad,
          right: hPad,
          bottom: 0,
          child: Container(
            height: _searchHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearch,
              textInputAction: TextInputAction.search,
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
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                suffixIcon: hasText
                    ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  splashRadius: 20,
                )
                    : null,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
// SLIDESHOW
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
    _ctrl = PageController(viewportFraction: 0.93);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_ctrl.hasClients || widget.slides.isEmpty) return;
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
          height: 122,
          child: Listener(
            // Restart the auto-advance timer after the user touches the banner.
            onPointerDown: (_) => _timer?.cancel(),
            onPointerUp: (_) => _startTimer(),
            onPointerCancel: (_) => _startTimer(),
            child: PageView.builder(
              controller: _ctrl,
              itemCount: widget.slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final s = widget.slides[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: s.colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: s.colors.last.withValues(alpha: 0.32),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
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
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: s.ink.withValues(alpha: 0.80),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: s.ink.withValues(alpha: 0.13),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icon, size: 26, color: s.ink),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.slides.length, (i) {
            final on = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: on ? 18 : 6,
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
// CHIP
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
        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white);
    final fg = selected
        ? Colors.white
        : (isDark ? Colors.white70 : AppTheme.primary);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppTheme.primary
                  : (isDark ? AppTheme.darkBorder : const Color(0xFFE3E8F1)),
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
                : [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: selected ? AppTheme.secondary : fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
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
// SERVICE CARD (circle icon + label)
// ============================================================
class _ServiceCard extends StatefulWidget {
  final MiniApp app;
  final String title;
  final String soonLabel;
  final VoidCallback onTap;
  final double size;

  const _ServiceCard({
    required this.app,
    required this.title,
    required this.soonLabel,
    required this.onTap,
    required this.size,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _hex(widget.app.color);
    final iconColor = widget.app.isComingSoon ? AppTheme.gold600 : color;
    final iconSize = widget.size * 0.44;

    return Semantics(
      button: true,
      label: widget.title,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : color.withValues(alpha: 0.11),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkBorder
                        : color.withValues(alpha: 0.20),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isDark ? 0.18 : 0.20),
                      blurRadius: 14,
                      spreadRadius: 0.5,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.22 : 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _iconFor(widget.app.icon),
                  size: iconSize,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  height: 1.15,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
              if (widget.app.isComingSoon) ...[
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.soonLabel,
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
      ),
    );
  }
}