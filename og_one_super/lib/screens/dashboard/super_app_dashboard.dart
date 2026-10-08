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
import '../../widgets/skeleton_loader.dart';
import 'dashboard_slideshow.dart';

// Darker gold for TEXT on light backgrounds (AppTheme.gold600 is too pale).
const Color _goldText = Color(0xFF8A6500);
// Higher-contrast grey for hint text on white.
const Color _hintGrey = Color(0xFF5B6B82);
const Color _lightBackground = Color(0xFFF5F7FB);

const _headerGradient = LinearGradient(
  colors: [Color(0xFF000C1F), Color(0xFF001D45), Color(0xFF0A3670)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ============================================================
// HELPERS
// ============================================================
Color _hex(String h) => Color(int.parse(h.replaceFirst('#', '0xFF')));

/// Live apps get a bright, distinct color so they never look disabled.
Color _appColor(MiniApp a) {
  switch (a.slug) {
    case 'nearbyfundi':
      return const Color(0xFF1E6BFF);
    case 'fundiapp':
      return const Color(0xFFFFA000);
    default:
      return _hex(a.color);
  }
}

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
    case 'find_in_page':
      return Icons.find_in_page_rounded;
    default:
      return Icons.apps_rounded;
  }
}

/// Responsive sizes for the dashboard grid.
class _GridLayout {
  final double hPad;
  final double crossAxisExtent;
  final double iconSize;
  final double mainAxisExtent;

  const _GridLayout({
    required this.hPad,
    required this.crossAxisExtent,
    required this.iconSize,
    required this.mainAxisExtent,
  });

  factory _GridLayout.of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final textScale =
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(1.0);

    final hPad = width > 800 ? (width - 760) / 2 : 20.0;
    final crossAxisExtent = width < 360
        ? 92.0
        : width < 420
        ? 100.0
        : width < 600
        ? 108.0
        : 118.0;
    final iconSize = crossAxisExtent * 0.52;
    // circle + gap + 2 label lines + "Soon" badge, scaled with text size
    final mainAxisExtent = iconSize + 6 + 46 * textScale + 28;

    return _GridLayout(
      hPad: hPad,
      crossAxisExtent: crossAxisExtent,
      iconSize: iconSize,
      mainAxisExtent: mainAxisExtent,
    );
  }
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String _selected = 'all';
  bool _intro = true; // entrance animations only on first load
  bool _loading = true; // skeleton covers the whole dashboard until ready

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────

  /// Replace the body with your real fetch (API, provider, Firebase...).
  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 900));
  }

  Future<void> _initialLoad() async {
    try {
      await _loadData();
    } catch (_) {
      // show a snackbar / retry state if you want
    }
    if (!mounted) return;
    setState(() => _loading = false);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _intro = false);
    });
  }

  Future<void> _onRefresh() async {
    try {
      await _loadData();
    } catch (_) {}
    if (!mounted) return;
    _searchController.clear();
    setState(() {
      _query = '';
      _selected = 'all';
    });
    FocusScope.of(context).unfocus();
  }

  // ── Actions ─────────────────────────────────────────────

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _open(MiniApp app, AppLocalizations t) {
    FocusScope.of(context).unfocus();

    if (app.isComingSoon) {
      _snack(t.comingSoonMessage);
      return;
    }

    switch (app.slug) {
      case 'fundiapp':
        _push(const FundiAppMiniApp());
        break;
      case 'nearbyfundi':
        _push(const NearbyFundiMiniApp());
        break;
    // case 'nimepoteza':
    //   _push(const NimepotezaMiniApp()); // add once the SDK is ready
    //   break;
      default:
        _snack(t.opening(t.serviceTitle(app.slug)));
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
    FocusScope.of(context).unfocus();
  }

  void _openSettings() {
    Navigator.pop(context); // close drawer
    Navigator.pushNamed(context, AppRoutes.settings);
  }

  // ── Derived data ────────────────────────────────────────

  List<MiniApp> _filteredApps(AppLocalizations t) {
    final q = _query.trim().toLowerCase();
    return miniApps.where((a) {
      if (q.isNotEmpty) {
        return t.serviceTitle(a.slug).toLowerCase().contains(q) ||
            a.slug.toLowerCase().contains(q) ||
            a.name.toLowerCase().contains(q);
      }
      return _selected == 'all' || a.slug == _selected;
    }).toList();
  }

  List<Slide> _buildSlides(AppLocalizations t) => [
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

  // ── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final t = context.t;
    final layout = _GridLayout.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      // Cap system font scaling so the layout never breaks.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: isDark ? AppTheme.darkBackground : _lightBackground,
          drawer: _AppDrawer(
            t: t,
            languageCode: settings.locale.languageCode,
            onLanguage: (code) => settings.setLocale(Locale(code)),
            onSettings: _openSettings,
          ),
          // Skeleton (whole dashboard) cross-fades into the real content.
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
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
    final apps = _filteredApps(t);
    final chipApps = miniApps.where((a) => !a.isComingSoon).toList();
    final hPad = layout.hPad;

    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: _onRefresh,
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // ── Header + search ──
          SliverToBoxAdapter(
            child: _Header(
              t: t,
              hPad: hPad,
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onAiAgent: () => _snack(t.comingSoonMessage),
              searchController: _searchController,
              onSearch: (v) => setState(() => _query = v),
              onClear: _clearSearch,
              hasText: _query.isNotEmpty,
            ),
          ),

          // ── Slideshow (full width so shadows/peek aren't cropped) ──
          if (!searching)
            SliverPadding(
              padding: const EdgeInsets.only(top: 20),
              sliver: SliverToBoxAdapter(
                child: _Reveal(
                  index: 0,
                  animate: _intro,
                  child: DashboardSlideshow(
                    slides: _buildSlides(t),
                    hPad: hPad,
                  ),
                ),
              ),
            ),

          // ── Section title ──
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

          // ── Filter chips ──
          if (!searching)
            SliverToBoxAdapter(
              child: _ChipRow(
                t: t,
                hPad: hPad,
                isDark: isDark,
                apps: chipApps,
                selected: _selected,
                onSelect: (slug) => setState(() => _selected = slug),
              ),
            ),

          // ── Empty state / Grid ──
          if (apps.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState(message: t.noResults, isDark: isDark),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 36),
              sliver: _buildGrid(t, layout, apps),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(
      AppLocalizations t,
      _GridLayout layout,
      List<MiniApp> apps,
      ) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: layout.crossAxisExtent,
        mainAxisExtent: layout.mainAxisExtent,
        mainAxisSpacing: 4,
        crossAxisSpacing: 10,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, i) {
          final app = apps[i];
          return _Reveal(
            key: ValueKey(app.slug),
            index: i + 2,
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
        findChildIndexCallback: (key) {
          if (key is ValueKey<String>) {
            final idx = apps.indexWhere((a) => a.slug == key.value);
            return idx < 0 ? null : idx;
          }
          return null;
        },
      ),
    );
  }
}

// ============================================================
// CHIP ROW
// ============================================================
class _ChipRow extends StatelessWidget {
  final AppLocalizations t;
  final double hPad;
  final bool isDark;
  final List<MiniApp> apps;
  final String selected;
  final ValueChanged<String> onSelect;

  const _ChipRow({
    required this.t,
    required this.hPad,
    required this.isDark,
    required this.apps,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        clipBehavior: Clip.none, // keep chip shadows
        padding: EdgeInsets.symmetric(horizontal: hPad),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: apps.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _AppChip(
              label: t.allServices,
              icon: Icons.apps_rounded,
              selected: selected == 'all',
              isDark: isDark,
              onTap: () => onSelect('all'),
            );
          }
          final a = apps[i - 1];
          return _AppChip(
            label: t.serviceTitle(a.slug),
            icon: _iconFor(a.icon),
            selected: selected == a.slug,
            isDark: isDark,
            onTap: () => onSelect(a.slug),
          );
        },
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
              color: isDark ? AppTheme.secondary : _goldText,
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
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Expanded(child: SizedBox.shrink()),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppTheme.navy50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                t.language,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.navy100),
            ),
            child: LanguageDropdown(
              currentCode: languageCode,
              onChanged: onLanguage,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: AppTheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onSettings,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        t.settings,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
  final bool showDot; // small gold dot = "coming soon"

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

// ============================================================
// ENTRANCE ANIMATION (first load only)
// ============================================================
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
          ? Duration(milliseconds: 340 + index.clamp(0, 10) * 50)
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

// ============================================================
// HEADER
// ============================================================
class _Header extends StatelessWidget {
  static const double _searchHeight = 52;
  static const double _overlap = 26;

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
          child: _buildBanner(),
        ),
        Positioned(
          left: hPad,
          right: hPad,
          bottom: 0,
          child: _buildSearchBox(),
        ),
      ],
    );
  }

  Widget _buildBanner() {
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
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, _overlap + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _GlassButton(
                        icon: Icons.menu_rounded,
                        tooltip: t.menu,
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
                        tooltip: '${t.aiAssistant} · ${t.comingSoon}',
                        onTap: onAiAgent,
                        showDot: true,
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
    );
  }

  Widget _buildSearchBox() {
    return Container(
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
          hintStyle: const TextStyle(
            color: _hintGrey,
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
    // In dark mode the selected chip uses a lighter navy so it stands out.
    final selectedBg = isDark ? AppTheme.navy600 : AppTheme.primary;
    final bg = selected
        ? selectedBg
        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white);
    final fg = selected
        ? Colors.white
        : (isDark ? Colors.white70 : AppTheme.primary);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: selectedBg.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              else if (!isDark)
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
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

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _appColor(widget.app);
    final soon = widget.app.isComingSoon;
    final iconColor = soon ? (isDark ? AppTheme.secondary : _goldText) : color;

    return Semantics(
      button: true,
      label: widget.title,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // The action fires only on a real tap (not when the finger slides
        // away or a scroll starts). Down/up/cancel only drive the press effect.
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
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
                      : color.withValues(alpha: soon ? 0.10 : 0.13),
                  // No border in light mode; faint tinted ring in dark mode.
                  border: isDark
                      ? Border.all(color: color.withValues(alpha: 0.30))
                      : null,
                  // One light shadow per icon (cheaper on low-end devices).
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: isDark ? 0.16 : 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _iconFor(widget.app.icon),
                  size: widget.size * 0.44,
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
                  fontSize: 12,
                  height: 1.15,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
              if (soon) ...[
                const SizedBox(height: 3),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.soonLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.secondary : _goldText,
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