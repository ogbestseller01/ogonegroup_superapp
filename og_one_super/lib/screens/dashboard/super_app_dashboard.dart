// lib/screens/dashboard/super_app_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fundiapp_sdk/fundi_app_mini.dart';
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
    case 'hotel':
      return Icons.hotel_rounded;
    case 'local_laundry_service':
      return Icons.local_laundry_service_rounded;
    default:
      return Icons.apps_rounded;
  }
}

class SuperAppDashboard extends StatefulWidget {
  const SuperAppDashboard({super.key});

  @override
  State<SuperAppDashboard> createState() => _SuperAppDashboardState();
}

class _SuperAppDashboardState extends State<SuperAppDashboard> {
  String _query = '';

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    // Add future mini-apps here:
    // case 'nearbyfundi': ...
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
    // Content capped at ~760px and centered on tablets/landscape.
    final hPad = width > 800 ? (width - 760) / 2 : 16.0;

    final q = _query.trim().toLowerCase();
    final searching = q.isNotEmpty;
    final apps = miniApps
        .where((a) =>
    !searching || t.serviceTitle(a.slug).toLowerCase().contains(q))
        .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor:
        isDark ? AppTheme.darkBackground : const Color(0xFFF4F7FC),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
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
            if (!searching)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                sliver: SliverToBoxAdapter(
                  child: _Reveal(
                    index: 0,
                    child: _Promo(
                      title: t.bannerTitle,
                      subtitle: t.bannerSubtitle,
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad + 4, 24, hPad + 4, 12),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.allServices,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${apps.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: isDark ? AppTheme.secondary : AppTheme.gold600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (apps.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 44,
                          color:
                          isDark ? Colors.white38 : Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        t.noResults,
                        style: TextStyle(
                          color:
                          isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 32),
                sliver: SliverGrid(
                  // 3 columns on phones, more on tablets.
                  gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150,
                    mainAxisExtent: 132,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, i) {
                      final app = apps[i];
                      return _Reveal(
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
  const _Reveal({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index.clamp(0, 8) * 70),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

// ============================================================
// HEADER (navy) with search bar floating over its bottom edge
// ============================================================
class _Header extends StatelessWidget {
  final AppLocalizations t;
  final double hPad;
  final String languageCode;
  final ValueChanged<String> onLanguage;
  final VoidCallback onSettings;
  final ValueChanged<String> onSearch;

  static const double _searchHeight = 52;
  static const double _overlap = 26;

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
        // Navy background
        Padding(
          padding: const EdgeInsets.only(bottom: _searchHeight - _overlap),
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00102B), Color(0xFF001D45), Color(0xFF0A3670)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -70,
                  right: -50,
                  child: _Blob(
                      size: 200,
                      color: AppTheme.secondary.withValues(alpha: 0.14)),
                ),
                Positioned(
                  bottom: -60,
                  left: -40,
                  child: _Blob(
                      size: 150, color: Colors.white.withValues(alpha: 0.06)),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                    EdgeInsets.fromLTRB(hPad, 12, hPad, _overlap + 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              padding: const EdgeInsets.all(5),
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
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t.appName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            LanguageDropdown(
                              currentCode: languageCode,
                              onChanged: onLanguage,
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: onSettings,
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(9),
                                  child: Icon(Icons.settings_rounded,
                                      color: Colors.white, size: 19),
                                ),
                              ),
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

        // Floating search bar overlapping the header edge
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
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              onChanged: onSearch,
              cursorColor: AppTheme.primary,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 14.5,
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
// PROMO STRIP (gold)
// ============================================================
class _Promo extends StatelessWidget {
  final String title;
  final String subtitle;
  const _Promo({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC61F), Color(0xFFF5C30E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.primary.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: AppTheme.primary, size: 23),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SERVICE CARD (grid)
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE6ECF5),
        ),
        boxShadow: isDark
            ? null
            : [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    color: isDark ? Colors.white : color.withValues(alpha: 0.11),
                  ),
                  child: Icon(_iconFor(app.icon), size: 27, color: iconColor),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.2,
                    color: isDark ? Colors.white : AppTheme.primary,
                  ),
                ),
                if (app.isComingSoon) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      soonLabel,
                      style: TextStyle(
                        fontSize: 9.5,
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
      ),
    );
  }
}