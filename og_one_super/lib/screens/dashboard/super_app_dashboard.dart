import 'dart:math' show max;

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
import '../../widgets/skeleton_loader.dart';
import 'dashboard_slideshow.dart';

// ════════════════════════════════════════════════
// Constants & helpers
// ════════════════════════════════════════════════
const Color _goldText = Color(0xFF8A6500);
const Color _hintGrey = Color(0xFF5B6B82);
const Color _lightBackground = Color(0xFFF5F7FB);

const _headerGradient = LinearGradient(
  colors: [Color(0xFF000C1F), Color(0xFF001D45), Color(0xFF0A3670)],
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
};

IconData _iconFor(String name) => _icons[name] ?? Icons.apps_rounded;

Color _appColor(MiniApp a) {
  switch (a.slug) {
    case 'nearbyfundi':
      return const Color(0xFF1E6BFF);
    case 'fundiapp':
      return const Color(0xFFFFA000);
    default:
      return Color(int.parse(a.color.replaceFirst('#', '0xFF')));
  }
}

Color _accent(bool isDark) => isDark ? AppTheme.secondary : _goldText;

Color _shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
      .toColor();
}

/// App label under each icon — shared by the layout maths and the Text itself.
const double _labelFont = 11.5;
const double _labelLineHeight = 1.2;

/// Responsive sizing for the apps grid. Every cell has the same fixed height,
/// so icons and labels line up on a common baseline across each row.
///
///  • < 340dp  → 3 columns (very small phones)
///  • < 600dp  → 4 columns (phones)
///  • < 900dp  → 5 columns (large phones / small tablets)
///  • ≥ 900dp  → 6 columns (tablets, landscape)
class _GridLayout {
  static const double cardPad = 16;
  static const double colSpacing = 8;

  final double hPad;
  final int columns;
  final double crossAxisExtent; // used by the skeleton loader
  final double iconSize;
  final double mainAxisExtent;

  const _GridLayout._(this.hPad, this.columns, this.crossAxisExtent,
      this.iconSize, this.mainAxisExtent);

  factory _GridLayout.of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final safe = MediaQuery.paddingOf(context);
    final textScale =
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(1.0);

    // Side padding: comfortable margin, centred column on wide screens, and
    // never under a notch / rounded corner in landscape.
    final sideInset = max(safe.left, safe.right) + 12;
    final baseH = width < 360 ? 16.0 : 20.0;
    final hPad = width > 800
        ? max((width - 760) / 2, sideInset)
        : max(baseH, sideInset);

    final columns = width < 340 ? 3 : (width < 600 ? 4 : (width < 900 ? 5 : 6));
    final contentW = width - 2 * hPad;
    final gridW = contentW - 2 * cardPad;
    final cellW = (gridW - (columns - 1) * colSpacing) / columns;

    final icon = (cellW * 0.80).clamp(48.0, 72.0).toDouble();
    final labelH =
    (_labelFont * _labelLineHeight * 2 * textScale).ceilToDouble();

    return _GridLayout._(
      hPad,
      columns,
      contentW / columns,
      icon,
      icon + 12 + labelH + 8, // icon + gap + 2-line label + breathing room
    );
  }
}

// ════════════════════════════════════════════════
// Dashboard
// ════════════════════════════════════════════════
class SuperAppDashboard extends StatefulWidget {
  const SuperAppDashboard({super.key});

  @override
  State<SuperAppDashboard> createState() => _SuperAppDashboardState();
}

class _SuperAppDashboardState extends State<SuperAppDashboard> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _scroll = ScrollController();

  String _query = '';
  bool _intro = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Replace the delay with real data fetching when available.
  Future<void> _loadData() =>
      Future.delayed(const Duration(milliseconds: 900));

  Future<void> _initialLoad() async {
    try {
      await _loadData();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _intro = false);
    });
  }

  Future<void> _onRefresh() async {
    try {
      await _loadData();
    } catch (_) {}
    if (mounted) _clearSearch();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
    FocusScope.of(context).unfocus();
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

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  void _open(MiniApp app, AppLocalizations t) {
    FocusScope.of(context).unfocus();
    if (app.isComingSoon) return _snack(t.comingSoonMessage);

    switch (app.slug) {
      case 'fundiapp':
        _push(const FundiAppMiniApp());
      case 'nearbyfundi':
        _push(const NearbyFundiMiniApp());
      default:
        _snack(t.opening(t.serviceTitle(app.slug)));
    }
  }

  void _showSettingsSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => const _SettingsSheet(),
    );
  }

  void _scrollToTop() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Derived data ──
  List<MiniApp> _filtered(AppLocalizations t) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return miniApps;
    return miniApps
        .where((a) =>
    t.serviceTitle(a.slug).toLowerCase().contains(q) ||
        a.slug.toLowerCase().contains(q) ||
        a.name.toLowerCase().contains(q))
        .toList();
  }

  List<Slide> _slides(AppLocalizations t) => [
    Slide(
      t.bannerTitle,
      t.bannerSubtitle,
      const [Color(0xFFFFC61F), Color(0xFFF5A90E)],
      AppTheme.primary,
      Icons.grid_view_rounded,
    ),
    Slide(
      t.bannerFundiTitle,
      t.bannerFundiSubtitle,
      const [Color(0xFF0A3670), Color(0xFF1A5BB5)],
      Colors.white,
      Icons.handyman_rounded,
    ),
    Slide(
      t.bannerFoodTitle,
      t.bannerFoodSubtitle,
      const [Color(0xFFD9480F), Color(0xFFF0701E)],
      Colors.white,
      Icons.delivery_dining_rounded,
    ),
    Slide(
      t.adsBannersTitle,
      t.adsBannersSubtitle,
      const [Color(0xFF6B21A8), Color(0xFF9333EA)],
      Colors.white,
      Icons.campaign_rounded,
    ),
  ];

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    context.watch<SettingsProvider>(); // rebuild when language changes
    final t = context.t;
    final layout = _GridLayout.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: isDark ? AppTheme.darkBackground : _lightBackground,
          extendBody: true,
          drawer: _AppDrawer(t: t),
          bottomNavigationBar: _BottomBar(
            homeLabel: t.home,
            scanLabel: t.scan,
            settingsLabel: t.settings,
            onHome: _scrollToTop,
            onScan: () => _snack(t.comingSoonMessage),
            onSettings: _showSettingsSheet,
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: [...previous, if (current != null) current],
            ),
            child: _loading
                ? SkeletonLoader(
              key: const ValueKey('skeleton'),
              hPad: layout.hPad,
              crossAxisExtent: layout.crossAxisExtent,
              mainAxisExtent: layout.mainAxisExtent,
              iconSize: layout.iconSize,
            )
                : _buildContent(t, layout, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations t, _GridLayout layout, bool isDark) {
    final searching = _query.trim().isNotEmpty;

    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: _onRefresh,
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              t: t,
              hPad: layout.hPad,
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onAiAgent: () => _snack(t.comingSoonMessage),
              searchController: _searchController,
              onSearch: (v) => setState(() => _query = v),
              onClear: _clearSearch,
              hasText: _query.isNotEmpty,
            ),
          ),
          ...(searching
              ? _searchSlivers(t, layout, isDark)
              : _homeSlivers(t, layout, isDark)),
        ],
      ),
    );
  }

  // ── Search results ──
  List<Widget> _searchSlivers(
      AppLocalizations t, _GridLayout layout, bool isDark) {
    final apps = _filtered(t);
    return [
      _section(layout.hPad, t.allServices, apps.length, isDark, top: 22),
      if (apps.isEmpty)
        SliverToBoxAdapter(
          child: _EmptyState(message: t.noResults, isDark: isDark),
        )
      else
        _gridCard(t, layout, apps, isDark, bottom: 8),
      _bottomSpacer(),
    ];
  }

  // ── Home ──
  List<Widget> _homeSlivers(
      AppLocalizations t, _GridLayout layout, bool isDark) {
    final hPad = layout.hPad;

    return [
      // 1. Featured — every app, as circle icons
      _section(hPad, t.featured, miniApps.length, isDark, top: 22),
      _gridCard(t, layout, miniApps, isDark, startIndex: 1),

      // 2. Slideshow
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: _Reveal(
            index: 2,
            animate: _intro,
            child: DashboardSlideshow(slides: _slides(t), hPad: hPad),
          ),
        ),
      ),

      // 3. Partner's apps — empty for now
      _section(
        hPad,
        t.partnerApps,
        0,
        isDark,
        top: 22,
        trailing: Text(
          t.comingSoon,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _accent(isDark),
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 0),
        sliver: SliverToBoxAdapter(
          child: _Reveal(
            index: 4,
            animate: _intro,
            child: _ComingSoonBox(
              isDark: isDark,
              title: t.comingSoon,
              subtitle: t.partnerAppsHint,
            ),
          ),
        ),
      ),
      _bottomSpacer(),
    ];
  }

  /// Space at the end of the list so content can scroll clear of the bottom bar.
  Widget _bottomSpacer() => SliverToBoxAdapter(
    child: SizedBox(height: _BottomBar.heightOf(context) + 20),
  );

  Widget _section(
      double hPad,
      String title,
      int count,
      bool isDark, {
        double top = 20,
        Widget? trailing,
      }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, top, hPad, 8),
        child: _SectionTitle(
          title: title,
          count: count,
          isDark: isDark,
          trailing: trailing,
        ),
      ),
    );
  }

  /// The grid, sitting on a soft rounded surface so it reads as one group.
  Widget _gridCard(
      AppLocalizations t,
      _GridLayout layout,
      List<MiniApp> apps,
      bool isDark, {
        int startIndex = 0,
        double bottom = 6,
      }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(layout.hPad, 6, layout.hPad, bottom),
      sliver: DecoratedSliver(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: isDark
              ? Border.all(color: Colors.white.withValues(alpha: 0.06))
              : null,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: isDark ? 0.0 : 0.07),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        sliver: SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              _GridLayout.cardPad, 20, _GridLayout.cardPad, 8),
          sliver: _grid(t, layout, apps, startIndex: startIndex),
        ),
      ),
    );
  }

  Widget _grid(
      AppLocalizations t,
      _GridLayout layout,
      List<MiniApp> apps, {
        int startIndex = 0,
      }) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: layout.columns,
        mainAxisExtent: layout.mainAxisExtent,
        mainAxisSpacing: 8,
        crossAxisSpacing: _GridLayout.colSpacing,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, i) {
          final app = apps[i];
          return _Reveal(
            key: ValueKey(app.slug),
            index: startIndex + i,
            animate: _intro,
            child: RepaintBoundary(
              child: _ServiceCard(
                app: app,
                title: t.serviceTitle(app.slug),
                soonLabel: t.soon,
                onTap: () => _open(app, t),
                size: layout.iconSize,
              ),
            ),
          );
        },
        childCount: apps.length,
      ),
    );
  }
}

// ════════════════════════════════════════════════
// Section title
// ════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final bool isDark;
  final Widget? trailing;

  const _SectionTitle({
    required this.title,
    required this.count,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFC61F), Color(0xFFF5A90E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : AppTheme.primary,
            ),
          ),
        ),
        if (trailing != null) ...[trailing!, const SizedBox(width: 10)],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: _accent(isDark),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════
// Empty state
// ════════════════════════════════════════════════
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 32,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
// Drawer
// ════════════════════════════════════════════════
class _AppDrawer extends StatelessWidget {
  final AppLocalizations t;
  const _AppDrawer({required this.t});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Header only — everything below stays empty.
    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.paddingOf(context).top + 16, 12, 22),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _GlassButton(
                      icon: Icons.close_rounded,
                      tooltip: t.close,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  t.welcomePartnerships,
                  style: TextStyle(
                    color: AppTheme.secondary.withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
// Shared widgets
// ════════════════════════════════════════════════
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
  final bool showDot;

  const _GlassButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
          ),
          if (showDot)
            Positioned(
              top: -2,
              right: -2,
              child: IgnorePointer(
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.navy900, width: 2),
                  ),
                ),
              ),
            ),
        ],
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

/// Tap target with a subtle press-scale. Shared by every card.
class _Pressable extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Widget child;

  const _Pressable({
    required this.label,
    required this.onTap,
    required this.child,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Fade + slide-up entrance.
class _Reveal extends StatelessWidget {
  final int index;
  final bool animate;
  final Widget child;

  const _Reveal({
    super.key,
    required this.index,
    required this.animate,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: animate
          ? Duration(milliseconds: 320 + index.clamp(0, 10) * 45)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

// ════════════════════════════════════════════════
// Header
// ════════════════════════════════════════════════
class _Header extends StatelessWidget {
  static const double _searchHeight = 50;
  static const double _overlap = 24;

  final AppLocalizations t;
  final double hPad;
  final VoidCallback onMenu;
  final VoidCallback onAiAgent;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;
  final bool hasText;

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
          child: _banner(),
        ),
        Positioned(left: hPad, right: hPad, bottom: 0, child: _searchBox()),
      ],
    );
  }

  Widget _banner() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: _headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -30,
            child: _Blob(
                size: 170, color: AppTheme.secondary.withValues(alpha: 0.12)),
          ),
          Positioned(
            top: 40,
            right: 70,
            child: _Blob(size: 36, color: Colors.white.withValues(alpha: 0.06)),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: _Blob(size: 120, color: Colors.white.withValues(alpha: 0.05)),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, _overlap + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _GlassButton(
                          icon: Icons.menu_rounded,
                          tooltip: t.menu,
                          onTap: onMenu),
                      const SizedBox(width: 10),
                      const _Logo(size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      _GlassButton(
                        icon: Icons.smart_toy_rounded,
                        tooltip: '${t.aiAssistant} · ${t.comingSoon}',
                        onTap: onAiAgent,
                        showDot: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    t.welcome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.chooseService,
                    style: TextStyle(
                      color: AppTheme.secondary.withValues(alpha: 0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      height: _searchHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: t.searchHint,
          hintStyle: const TextStyle(
            color: _hintGrey,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.primary, size: 22),
          suffixIcon: hasText
              ? IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded,
                color: AppTheme.primary, size: 19),
            splashRadius: 18,
          )
              : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
// Empty "coming soon" placeholder
// ════════════════════════════════════════════════
class _ComingSoonBox extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;

  const _ComingSoonBox({
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accent(isDark);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border.all(color: accent.withValues(alpha: 0.30), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.secondary.withValues(alpha: 0.18),
            ),
            child: Icon(Icons.hourglass_top_rounded, size: 24, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkTextSecondary : _hintGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
// Service card (grid)
// ════════════════════════════════════════════════
class _ServiceCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _appColor(app);
    final soon = app.isComingSoon;
    final surface = isDark ? AppTheme.darkSurface : Colors.white;
    final inner = size * 0.72;

    // Outer circular card: a soft tint of the app colour, a ring and a glow.
    final cardFill = Color.alphaBlend(
      color.withValues(alpha: isDark ? 0.14 : 0.07),
      isDark ? AppTheme.darkSurfaceLight : Colors.white,
    );
    final ringAlpha = soon ? (isDark ? 0.35 : 0.18) : (isDark ? 0.60 : 0.35);
    final glowAlpha = soon ? 0.10 : (isDark ? 0.30 : 0.22);

    // Inner medallion: live apps are solid with a white icon,
    // coming-soon apps are a light tint with a coloured icon.
    final medallion = Container(
      width: inner,
      height: inner,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: soon
            ? null
            : LinearGradient(
          colors: [_shade(color, 0.08), _shade(color, -0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: soon ? color.withValues(alpha: isDark ? 0.24 : 0.14) : null,
      ),
      child: Icon(
        _iconFor(app.icon),
        size: inner * 0.54,
        color: soon
            ? (isDark ? _shade(color, 0.22) : color.withValues(alpha: 0.9))
            : Colors.white,
      ),
    );

    final circleCard = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cardFill,
        border: Border.all(color: color.withValues(alpha: ringAlpha), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: glowAlpha),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: medallion,
    );

    return _Pressable(
      label: soon ? '$title, $soonLabel' : title,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                circleCard,
                if (soon)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -7,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: surface, width: 1.5),
                        ),
                        child: Text(
                          soonLabel,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 8.5,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: _labelFont,
              height: _labelLineHeight,
              color: isDark
                  ? (soon ? AppTheme.darkTextSecondary : Colors.white)
                  : (soon ? _hintGrey : AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
// Bottom bar: Home · Scanner (centre) · Settings
// ════════════════════════════════════════════════
class _BottomBar extends StatelessWidget {
  static const double _barH = 64;
  static const double _lift = 30; // how far the scanner rises above the bar
  static const double _fab = 62;
  static const double _maxWidth = 560; // keeps the bar tidy on tablets

  /// Bottom padding that clears the home indicator without wasting space.
  static double _inset(BuildContext context) {
    final i = MediaQuery.paddingOf(context).bottom;
    return i > 8 ? i - 8 : 8;
  }

  /// Total height — used to pad scrolling content so nothing hides behind it.
  static double heightOf(BuildContext context) =>
      _barH + _lift + _inset(context);

  final String homeLabel;
  final String scanLabel;
  final String settingsLabel;
  final VoidCallback onHome;
  final VoidCallback onScan;
  final VoidCallback onSettings;

  const _BottomBar({
    required this.homeLabel,
    required this.scanLabel,
    required this.settingsLabel,
    required this.onHome,
    required this.onScan,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inset = _inset(context);
    final surface = isDark ? AppTheme.darkSurface : Colors.white;

    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: SizedBox(
          height: _barH + _lift + inset,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bar surface
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _barH + inset,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                    border: isDark
                        ? Border.all(color: Colors.white.withValues(alpha: 0.07))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary
                            .withValues(alpha: isDark ? 0 : 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                ),
              ),

              // Side items
              Positioned(
                left: 0,
                right: 0,
                bottom: inset,
                height: _barH,
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: Icons.home_rounded,
                        label: homeLabel,
                        active: true,
                        onTap: onHome,
                      ),
                    ),
                    const SizedBox(width: _fab + 24),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.settings_rounded,
                        label: settingsLabel,
                        active: false,
                        onTap: onSettings,
                      ),
                    ),
                  ],
                ),
              ),

              // Centre scanner
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: _Pressable(
                    label: scanLabel,
                    onTap: onScan,
                    child: Container(
                      width: _fab,
                      height: _fab,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFC61F), Color(0xFFF5A90E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: surface, width: 5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF5A90E)
                                .withValues(alpha: isDark ? 0.35 : 0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppTheme.primary,
                        size: 28,
                      ),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = active
        ? (isDark ? AppTheme.secondary : AppTheme.primary)
        : (isDark ? AppTheme.darkTextSecondary : _hintGrey);

    return _Pressable(
      label: label,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            decoration: BoxDecoration(
              color: active
                  ? (isDark
                  ? AppTheme.secondary.withValues(alpha: 0.16)
                  : AppTheme.primary.withValues(alpha: 0.08))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════
// Settings bottom sheet (language + link to full settings)
// ════════════════════════════════════════════════
class _LangOption {
  final String code;
  final String label;
  final String badge; // text fallback if the flag image can't be loaded
  final String flagAsset; // local flag image bundled in assets/images
  const _LangOption(this.code, this.label, this.badge, this.flagAsset);
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final t = context.t;
    final textColor = isDark ? Colors.white : AppTheme.primary;
    final current = settings.locale.languageCode;

    final options = [
      _LangOption('en', t.english, 'EN', 'assets/images/englishflug.png'),
      _LangOption('sw', t.swahili, 'SW', 'assets/images/tzflug.png'),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.07))
            : null,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.paddingOf(context).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Language
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFC61F), Color(0xFFF5A90E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.selectLanguage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final o in options)
              _LangTile(
                option: o,
                selected: current == o.code,
                onTap: () {
                  HapticFeedback.selectionClick();
                  settings.setLocale(Locale(o.code));
                },
              ),

            const SizedBox(height: 4),

            // Full settings
            Material(
              color: isDark
                  ? AppTheme.darkSurfaceLight
                  : AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.settings);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white,
                          border: Border.all(
                            color: isDark ? Colors.white24 : AppTheme.navy100,
                          ),
                        ),
                        child: Icon(Icons.settings_rounded,
                            color: textColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          t.settings,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: textColor),
                    ],
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

/// Circular flag loaded from the app's bundled assets. If the asset is missing
/// it shows the EN/SW text badge instead.
class _FlagBadge extends StatelessWidget {
  final _LangOption option;
  final bool selected;
  final bool isDark;

  const _FlagBadge({
    required this.option,
    required this.selected,
    required this.isDark,
  });

  static const double _size = 42;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.secondary : AppTheme.primary;
    final textColor = isDark ? Colors.white : AppTheme.primary;

    Widget fallback() => Container(
      color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
      alignment: Alignment.center,
      child: Text(
        option.badge,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: textColor,
        ),
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? accent
              : (isDark ? Colors.white24 : AppTheme.navy100),
          width: selected ? 2 : 1,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          option.flagAsset,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      ),
    );
  }
}

/// One selectable language row with a flag badge that stays clearly
/// visible in both light and dark themes.
class _LangTile extends StatelessWidget {
  final _LangOption option;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.secondary : AppTheme.primary;
    final textColor = isDark ? Colors.white : AppTheme.primary;

    final tileColor = selected
        ? accent.withValues(alpha: isDark ? 0.12 : 0.06)
        : (isDark ? AppTheme.darkSurfaceLight : AppTheme.navy50);

    return _Pressable(
      label: option.label,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            _FlagBadge(option: option, selected: selected, isDark: isDark),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 24,
              color: selected
                  ? accent
                  : (isDark ? Colors.white30 : AppTheme.navy200),
            ),
          ],
        ),
      ),
    );
  }
}