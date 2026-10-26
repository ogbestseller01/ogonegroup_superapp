import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_strings.dart';
import '../../providers/settings_provider.dart';
import '../../services/mini_app_service.dart';
import '../../widgets/skeleton_loader.dart';
import 'core/app_usage_provider.dart';
import 'core/dash_theme.dart';
import 'tabs/account_tab.dart';
import 'tabs/apps_tab.dart';
import 'tabs/home_tab.dart';
import '../../widgets/dash_bottom_nav.dart';
import '../../widgets/dash_drawer.dart';

/// Super app shell: Home | Apps | Account.
/// QR scanning lives only in the search bar (Home and Apps tabs).
class SuperAppDashboard extends StatelessWidget {
  const SuperAppDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppUsageProvider()..load(),
      child: const _DashboardShell(),
    );
  }
}

class _DashboardShell extends StatefulWidget {
  const _DashboardShell();

  @override
  State<_DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<_DashboardShell> {
  static const int _home = 0;
  static const int _apps = 1;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _homeKey = GlobalKey<HomeTabState>();

  int _index = _home;
  bool _loading = true;
  bool _intro = true;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  /// Fetches mini apps from Laravel (never throws, falls back to the built-in
  /// list) and keeps the skeleton visible at least 600 ms so it does not flash.
  Future<void> _initialLoad() async {
    try {
      await Future.wait([
        MiniAppService.instance.refresh(),
        Future<void>.delayed(const Duration(milliseconds: 600)),
      ]);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _intro = false);
    });
  }

  void _select(int i) {
    FocusScope.of(context).unfocus();
    if (i == _index) {
      if (i == _home) _homeKey.currentState?.scrollToTop();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    context.watch<SettingsProvider>(); // rebuild when the language changes
    final t = context.t;
    final layout = DashGrid.of(context);

    final items = [
      DashNavItem(Icons.home_outlined, Icons.home_rounded, t.home),
      DashNavItem(Icons.apps_outlined, Icons.apps_rounded, t.navApps),
      DashNavItem(
          Icons.person_outline_rounded, Icons.person_rounded, t.navAccount),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: PopScope(
          // Back from any other tab returns to Home first.
          canPop: _index == _home,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) setState(() => _index = _home);
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: dashPageBg(isDark),
            drawer: const DashDrawer(),
            bottomNavigationBar: DashBottomNav(
              currentIndex: _index,
              items: items,
              onSelect: _select,
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
                  : IndexedStack(
                key: const ValueKey('content'),
                index: _index,
                children: [
                  HomeTab(
                    key: _homeKey,
                    intro: _intro,
                    onMenu: _openDrawer,
                    onSeeAllApps: () => _select(_apps),
                  ),
                  AppsTab(onMenu: _openDrawer),
                  AccountTab(onMenu: _openDrawer),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}