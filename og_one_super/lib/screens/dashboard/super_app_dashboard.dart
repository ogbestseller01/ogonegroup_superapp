import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fundiapp_sdk/fundi_app_mini.dart';
import 'package:nearbyfundi_sdk/nearby_fundi_mini.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/app_strings.dart'; // This is where your working extension lives
import '../../config/app_theme.dart';
import '../../models/mini_app.dart';
import '../../providers/settings_provider.dart';
import '../../services/mini_app_service.dart';
import '../scanner/qr_scanner_screen.dart';
import '../../widgets/skeleton_loader.dart';
import 'dashboard_slideshow.dart';

// ════════════════════════════════════════════════
// Constants & helpers
// ════════════════════════════════════════════════
const Color _goldText = Color(0xFF8A6500);
const Color _hintGrey = Color(0xFF5B6B82);
const Color _lightBackground = Color(0xFFF7F9FC);
const Color _navy = Color(0xFF1A2B4A);
const Color _gold = Color(0xFFFFB300);

const _headerGradient = LinearGradient(
  colors: [Color(0xFF0B1C3A), Color(0xFF132B55), Color(0xFF1A3A75)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

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
};

IconData _iconFor(String name) => _icons[name] ?? Icons.apps_rounded;

Color _appColor(MiniApp a) {
  switch (a.slug) {
    case 'nearbyfundi':
      return const Color(0xFF2B7BFF);
    case 'fundiapp':
      return const Color(0xFFFFB300);
    default:
      return Color(int.parse(a.color.replaceFirst('#', '0xFF')));
  }
}

Color _accent(bool isDark) => isDark ? AppTheme.secondary : _goldText;
Color _pageBg(bool isDark) =>
    isDark ? AppTheme.darkBackground : _lightBackground;
Color _ink(bool isDark) => isDark ? Colors.white : _navy;

Color _shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

List<MiniApp> _availableFirst(List<MiniApp> apps) => [
  ...apps.where((a) => !a.isComingSoon),
  ...apps.where((a) => a.isComingSoon),
];

const double _labelFont = 12;
const double _labelMinFont = 10.0;
const double _labelLineHeight = 1.25;
const double _compactWidth = 370;

bool _isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < _compactWidth;

class _GridLayout {
  static const double colSpacing = 8;
  static const double _minCellWidth = 76;

  final double hPad;
  final int columns;
  final double crossAxisExtent;
  final double iconSize;
  final double mainAxisExtent;

  const _GridLayout._(this.hPad, this.columns, this.crossAxisExtent,
      this.iconSize, this.mainAxisExtent);

  factory _GridLayout.of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final safe = MediaQuery.paddingOf(context);
    final textScale =
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(1.0);

    final sideInset = max(safe.left, safe.right) + 14;
    final baseH = width < 360 ? 16.0 : 22.0;
    final hPad = width > 800
        ? max((width - 760) / 2, sideInset)
        : max(baseH, sideInset);

    final contentW = width - 2 * hPad;

    final columns = ((contentW + colSpacing) / (_minCellWidth + colSpacing))
        .floor()
        .clamp(3, 6);

    final cellW = (contentW - (columns - 1) * colSpacing) / columns;
    final icon = (cellW * 0.55).clamp(44.0, 52.0).toDouble();
    final labelH =
    (_labelFont * _labelLineHeight * 2 * textScale).ceilToDouble();

    return _GridLayout._(
      hPad,
      columns,
      contentW / columns,
      icon,
      8 + icon + 12 + labelH + 6,
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

  /// Blocks a second tap while a mini app is opening / closing.
  /// Both mini apps share one global navigatorKey, so opening one twice
  /// would throw "Multiple widgets used the same GlobalKey".
  bool _opening = false;

  /// Mini apps: built-in list, adjusted by Laravel when reachable.
  List<MiniApp> get _apps => MiniAppService.instance.apps;

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

  /// Fetches mini apps from Laravel (never throws, falls back to the built-in
  /// list) and keeps the skeleton visible at least 600 ms so it does not flash.
  Future<void> _loadData() async {
    await Future.wait([
      MiniAppService.instance.refresh(),
      Future<void>.delayed(const Duration(milliseconds: 600)),
    ]);
  }

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
    HapticFeedback.mediumImpact();
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
          content: Text(
            message,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          margin:
          EdgeInsets.fromLTRB(16, 0, 16, _BottomBar.heightOf(context) + 6),
        ),
      );
  }

  Future<void> _push(Widget page) async {
    if (_opening || !mounted) return;
    _opening = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
      // Let the pop animation finish so the shared navigatorKey is released
      // before the same mini app can be opened again.
      await Future<void>.delayed(const Duration(milliseconds: 450));
    } finally {
      _opening = false;
    }
  }

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

  /// Opens the scanner, then opens the mini app whose QR code was scanned.
  Future<void> _scan(AppLocalizations t) async {
    if (_opening || !mounted) return;
    FocusScope.of(context).unfocus();
    _opening = true;
    String? slug;
    try {
      slug = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );
    } finally {
      _opening = false;
    }
    if (!mounted || slug == null) return;

    final app = MiniAppService.instance.bySlug(slug);
    if (app == null) {
      // Valid OG ONE code, but the server switched this app off.
      _snack(t.comingSoonMessage);
      return;
    }
    // Give the scanner's pop animation time to release the camera/route.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _open(app, t);
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
    _scroll.animateTo(0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic);
  }

  List<MiniApp> _filtered(AppLocalizations t) {
    final q = _query.trim().toLowerCase();
    final sorted = _availableFirst(_apps);
    if (q.isEmpty) return sorted;
    return sorted
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
        const [Color(0xFFFFD54F), Color(0xFFFFB300)],
        AppTheme.primary,
        Icons.grid_view_rounded),
    Slide(
        t.bannerFundiTitle,
        t.bannerFundiSubtitle,
        const [Color(0xFF1A3A75), Color(0xFF2B5AA8)],
        Colors.white,
        Icons.handyman_rounded),
    Slide(
        t.bannerFoodTitle,
        t.bannerFoodSubtitle,
        const [Color(0xFFE85D04), Color(0xFFF48C06)],
        Colors.white,
        Icons.delivery_dining_rounded),
    Slide(
        t.adsBannersTitle,
        t.adsBannersSubtitle,
        const [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
        Colors.white,
        Icons.campaign_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    context.watch<SettingsProvider>();
    final t = context.t;
    final layout = _GridLayout.of(context);
    final bg = _pageBg(isDark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: bg,
          extendBody: true,
          drawer: _AppDrawer(t: t),
          bottomNavigationBar: _BottomBar(
            homeLabel: t.home,
            scanLabel: t.scan,
            settingsLabel: t.settings,
            onHome: _scrollToTop,
            onScan: () => _scan(t),
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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              t: t,
              hPad: layout.hPad,
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onAiAgent: () => _snack(t.comingSoonMessage),
              onScan: () => _scan(t),
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

  List<Widget> _searchSlivers(
      AppLocalizations t, _GridLayout layout, bool isDark) {
    final apps = _filtered(t);
    return [
      _section(layout.hPad, t.allServices, apps.length, isDark, top: 24),
      if (apps.isEmpty)
        SliverToBoxAdapter(
            child: _EmptyState(message: t.noResults, isDark: isDark))
      else
        ..._appSlivers(t, layout, apps, isDark),
      _bottomSpacer(),
    ];
  }

  List<Widget> _homeSlivers(
      AppLocalizations t, _GridLayout layout, bool isDark) {
    final hPad = layout.hPad;
    final apps = _filtered(t);

    return [
      _section(hPad, t.featured, apps.length, isDark, top: 26),
      ..._appSlivers(t, layout, apps, isDark, startIndex: 1),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 18),
          child: _Reveal(
            index: 5,
            animate: _intro,
            child: DashboardSlideshow(slides: _slides(t), hPad: hPad),
          ),
        ),
      ),
      _section(hPad, t.partnerApps, null, isDark, top: 14),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        sliver: SliverToBoxAdapter(
          child: _Reveal(
            index: 7,
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

  Widget _bottomSpacer() => SliverToBoxAdapter(
    child: SizedBox(height: _BottomBar.heightOf(context) + 18),
  );

  Widget _section(double hPad, String title, int? count, bool isDark,
      {double top = 22}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, top, hPad, 14),
        child: _SectionTitle(title: title, count: count, isDark: isDark),
      ),
    );
  }

  List<Widget> _appSlivers(
      AppLocalizations t,
      _GridLayout layout,
      List<MiniApp> apps,
      bool isDark, {
        int startIndex = 0,
      }) {
    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: layout.hPad),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.columns,
            mainAxisExtent: layout.mainAxisExtent,
            mainAxisSpacing: 14,
            crossAxisSpacing: 10,
          ),
          delegate: SliverChildBuilderDelegate(
                (context, i) {
              final app = apps[i];
              return _Reveal(
                key: ValueKey(app.slug),
                index: startIndex + i,
                animate: _intro,
                child: RepaintBoundary(
                  child: _AppCard(
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
        ),
      ),
    ];
  }
}

// ════════════════════════════════════════════════
// Sub-widgets
// ════════════════════════════════════════════════

class _AppCard extends StatelessWidget {
  final MiniApp app;
  final String title;
  final String soonLabel;
  final VoidCallback onTap;
  final double size;

  const _AppCard({
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
    final hasImage = app.imageAsset != null;
    final iconColor = color.computeLuminance() > 0.4 ? _navy : Colors.white;

    return _Pressable(
      label: soon ? '$title, $soonLabel' : title,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size * 0.28),
                      gradient: hasImage
                          ? null
                          : LinearGradient(
                        colors: [
                          _shade(color, 0.09),
                          _shade(color, -0.07)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: isDark ? 0.25 : 0.2),
                          blurRadius: 14,
                          spreadRadius: -2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: hasImage
                        ? Padding(
                      // Slight padding prevents the 3D icon from
                      // clipping at the edges.
                      padding: EdgeInsets.all(size * 0.05),
                      child: Image.asset(
                        app.imageAsset!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(
                              _iconFor(app.icon),
                              size: size * 0.5,
                              color: iconColor,
                            ),
                      ),
                    )
                        : Icon(
                      _iconFor(app.icon),
                      size: size * 0.5,
                      color: iconColor,
                    ),
                  ),
                  if (soon)
                    Positioned(
                      top: -7,
                      right: -9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: _pageBg(isDark), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          soonLabel,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 8.5,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: _FitLabel(
                  text: title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: _labelFont,
                    height: _labelLineHeight,
                    color: _ink(isDark),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final int? count;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: _ink(isDark),
            ),
          ),
        ),
        if (count != null)
          Container(
            constraints: const BoxConstraints(minWidth: 30),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: _accent(isDark),
              ),
            ),
          ),
      ],
    );
  }
}

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
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 34,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final AppLocalizations t;

  const _AppDrawer({required this.t});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
                18, MediaQuery.paddingOf(context).top + 18, 14, 24),
            decoration: const BoxDecoration(gradient: _headerGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _Logo(size: 46),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        t.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _SoftButton(
                      icon: Icons.close_rounded,
                      tooltip: t.close,
                      onTap: () => Navigator.of(context).pop(),
                      onDark: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  t.welcomePartnerships,
                  style: TextStyle(
                    color: AppTheme.secondary.withValues(alpha: 0.95),
                    fontSize: 13,
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
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
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

class _SoftButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool onDark;

  const _SoftButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final light = onDark || isDark;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: light
            ? Colors.white.withValues(alpha: 0.14)
            : _navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: light ? Colors.white : _navy, size: 22),
          ),
        ),
      ),
    );
  }
}

class _AiAgentButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final bool compact;

  const _AiAgentButton({
    required this.tooltip,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(compact ? 16 : 24);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: 'AI Agent',
        excludeSemantics: true,
        child: Container(
          decoration: BoxDecoration(
            gradient: _goldGradient,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.38),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: radius,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: SizedBox(
                height: compact ? 44 : 40,
                width: compact ? 44 : null,
                child: compact
                    ? const Icon(Icons.auto_awesome_rounded,
                    size: 22, color: _navy)
                    : const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 18, color: _navy),
                      SizedBox(width: 6),
                      Text(
                        'AI Agent',
                        maxLines: 1,
                        style: TextStyle(
                          color: _navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

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
          ? Duration(milliseconds: 340 + index.clamp(0, 10) * 48)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

class _FitLabel extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double minFontSize;

  const _FitLabel({
    required this.text,
    required this.style,
    this.minFontSize = _labelMinFont,
  });

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final base = style.fontSize ?? _labelFont;
        var size = base;

        if (maxW.isFinite) {
          final longest = text
              .split(RegExp(r'\s+'))
              .fold<String>('', (a, b) => b.length > a.length ? b : a);

          final painter = TextPainter(
            text: TextSpan(
              text: longest,
              style: style.copyWith(fontSize: base),
            ),
            textDirection: direction,
            textScaler: scaler,
            maxLines: 1,
          )..layout();

          if (painter.width > maxW) {
            size = (base * maxW / painter.width)
                .clamp(minFontSize, base)
                .toDouble();
          }
          painter.dispose();
        }

        return Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(fontSize: size),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  static const double _searchHeight = 56;
  static const double _overlap = 28;

  final AppLocalizations t;
  final double hPad;
  final VoidCallback onMenu;
  final VoidCallback onAiAgent;
  final VoidCallback onScan;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;
  final bool hasText;

  const _Header({
    required this.t,
    required this.hPad,
    required this.onMenu,
    required this.onAiAgent,
    required this.onScan,
    required this.searchController,
    required this.onSearch,
    required this.onClear,
    required this.hasText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: _searchHeight - _overlap),
          child: _banner(context),
        ),
        Positioned(
          left: hPad,
          right: hPad,
          bottom: 0,
          child: _searchBox(isDark),
        ),
      ],
    );
  }

  Widget _ring(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 1.4),
    ),
  );

  Widget _banner(BuildContext context) {
    final compact = _isCompact(context);
    final narrow = MediaQuery.sizeOf(context).width < 360;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: _headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(38)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gold.withValues(alpha: 0.30),
                    _gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 20,
            child: _ring(90, Colors.white.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: 6,
            left: -50,
            child: _ring(170, Colors.white.withValues(alpha: 0.07)),
          ),
          Positioned(
            right: 18,
            bottom: _overlap + 8,
            child: Icon(
              Icons.grid_view_rounded,
              size: 74,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, _overlap + 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SoftButton(
                        icon: Icons.menu_rounded,
                        tooltip: t.menu,
                        onTap: onMenu,
                        onDark: true,
                      ),
                      SizedBox(width: compact ? 8 : 12),
                      _Logo(size: compact ? 34 : 38),
                      SizedBox(width: compact ? 8 : 11),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            t.appName,
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: compact ? 6 : 8),
                      _AiAgentButton(
                        compact: compact,
                        tooltip: '${t.aiAssistant} · ${t.comingSoon}',
                        onTap: onAiAgent,
                      ),
                    ],
                  ),
                  SizedBox(height: narrow ? 20 : 26),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.welcome,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: narrow ? 26 : 31,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: _goldGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          t.chooseService,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFFFFD54F)
                                .withValues(alpha: 0.95),
                            fontSize: narrow ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox(bool isDark) {
    final fieldColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = _ink(isDark);
    final hintColor = isDark ? AppTheme.darkTextSecondary : _hintGrey;

    return Container(
      height: _searchHeight,
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(28),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.08))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.12),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearch,
        textInputAction: TextInputAction.search,
        cursorColor: isDark ? AppTheme.secondary : AppTheme.primary,
        style: TextStyle(
          color: textColor,
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: t.searchHint,
          hintStyle: TextStyle(color: hintColor, fontWeight: FontWeight.w500),
          prefixIcon: Icon(Icons.search_rounded, color: textColor, size: 23),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasText)
                IconButton(
                  onPressed: onClear,
                  icon: Icon(Icons.close_rounded, color: textColor, size: 20),
                  splashRadius: 20,
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: _gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onScan();
                    },
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.qr_code_scanner_rounded,
                          color: _accent(isDark), size: 21),
                    ),
                  ),
                ),
              ),
            ],
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : const Color(0xFFFFF4D6),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : _gold.withValues(alpha: 0.25),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              bottom: -34,
              child: Icon(
                Icons.hourglass_top_rounded,
                size: 120,
                color: _gold.withValues(alpha: isDark ? 0.10 : 0.18),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: isDark
                        ? AppTheme.secondary.withValues(alpha: 0.16)
                        : Colors.white,
                  ),
                  child: Icon(Icons.hourglass_top_rounded,
                      size: 26, color: accent),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: _ink(isDark),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                          isDark ? AppTheme.darkTextSecondary : _hintGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  static const double _barH = 66;
  static const double _lift = 26;
  static const double _fab = 62;

  static double heightOf(BuildContext context) =>
      _barH + _lift + MediaQuery.paddingOf(context).bottom;

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
    final surface = isDark ? AppTheme.darkSurface : Colors.white;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final labelColor = isDark ? AppTheme.darkTextSecondary : _hintGrey;

    return SizedBox(
      height: heightOf(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _barH + safeBottom,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: surface,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
                border: isDark
                    ? Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08)),
                )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: safeBottom),
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
                    const SizedBox(width: _fab + 36),
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
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: safeBottom + 9,
            child: IgnorePointer(
              child: Text(
                scanLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
          ),
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
                    gradient: _goldGradient,
                    border: Border.all(color: surface, width: 5),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withValues(alpha: isDark ? 0.35 : 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: _navy,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
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
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LangOption {
  final String code;
  final String label;
  final String badge;
  final String flagAsset;

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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.07))
            : null,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, MediaQuery.paddingOf(context).bottom + 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              t.selectLanguage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            for (final o in options)
              _LangTile(
                option: o,
                selected: current == o.code,
                onTap: () {
                  HapticFeedback.selectionClick();
                  settings.setLocale(Locale(o.code));
                },
              ),
            const SizedBox(height: 6),
            Material(
              color: isDark
                  ? AppTheme.darkSurfaceLight
                  : AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  // Grab the navigator first, then close the sheet and open
                  // settings, so no context is used after the pop.
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.pushNamed(AppRoutes.settings);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white,
                        ),
                        child: Icon(Icons.settings_rounded,
                            color: textColor, size: 23),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          t.settings,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
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

class _FlagBadge extends StatelessWidget {
  final _LangOption option;
  final bool selected;
  final bool isDark;

  const _FlagBadge({
    required this.option,
    required this.selected,
    required this.isDark,
  });

  static const double _size = 44;

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
          fontSize: 13.5,
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
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? accent
              : (isDark ? Colors.white24 : AppTheme.navy100),
          width: selected ? 2.2 : 1.2,
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
        ? accent.withValues(alpha: isDark ? 0.13 : 0.07)
        : (isDark ? AppTheme.darkSurfaceLight : AppTheme.navy50);

    return _Pressable(
      label: option.label,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.fromLTRB(13, 11, 15, 11),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Row(
          children: [
            _FlagBadge(option: option, selected: selected, isDark: isDark),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 25,
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