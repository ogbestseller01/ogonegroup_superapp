// lib/screens/dashboard/tabs/home_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../config/app_strings.dart';
import '../../../config/app_theme.dart';
import '../../../models/mini_app.dart';
import '../../../providers/banner_provider.dart';
import '../../../providers/system_update_provider.dart';
import '../../../services/mini_app_service.dart';
import '../../../services/system_update_push.dart';
import '../../../widgets/app_tile.dart';
import '../../../widgets/dash_common.dart';
import '../../../widgets/dash_header.dart';
import '../../../widgets/dash_search_box.dart';
import '../../../widgets/system_update_card.dart';
import '../../../widgets/system_update_sheet.dart';
import '../core/app_launcher.dart';
import '../core/dash_theme.dart';
import '../dashboard_slideshow.dart';

/// Home tab: header + search (with QR), system updates, featured apps,
/// banners, partner teaser.
class HomeTab extends StatefulWidget {
  final bool intro;
  final VoidCallback onMenu;
  final VoidCallback onSeeAllApps;

  const HomeTab({
    super.key,
    required this.intro,
    required this.onMenu,
    required this.onSeeAllApps,
  });

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  static const int _featuredCount = 8;

  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';

  VoidCallback? _stopPush;

  @override
  void initState() {
    super.initState();
    _listenForUpdatePushes();
  }

  /// Foreground push  → refresh the card.
  /// Tapped push      → refresh, then open that update.
  Future<void> _listenForUpdatePushes() async {
    final stop = await SystemUpdatePush.listen((id, tapped) async {
      if (!mounted) return;
      final provider = context.read<SystemUpdateProvider>();
      await provider.load();
      if (!tapped || !mounted) return;
      final update = await provider.findById(id);
      if (update != null && mounted) {
        await showSystemUpdateSheet(context, update);
      }
    });

    if (mounted) {
      _stopPush = stop;
    } else {
      stop();
    }
  }

  @override
  void dispose() {
    _stopPush?.call();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Called by the shell when Home is tapped while already on Home.
  void scrollToTop() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    try {
      await Future.wait([
        MiniAppService.instance.refresh(),
        context.read<BannerProvider>().fetchBanners(),
        context.read<SystemUpdateProvider>().load(),
        Future<void>.delayed(const Duration(milliseconds: 600)),
      ]);
    } catch (_) {
      // Non-fatal — keep whatever we already have on screen.
    }
    if (mounted) _clearSearch();
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
    FocusScope.of(context).unfocus();
  }

  List<MiniApp> _filtered(AppLocalizations t) {
    final q = _query.trim().toLowerCase();
    final sorted = availableFirst(MiniAppService.instance.apps);
    if (q.isEmpty) return sorted;
    return sorted
        .where((a) =>
    t.serviceTitle(a.slug).toLowerCase().contains(q) ||
        a.slug.toLowerCase().contains(q) ||
        a.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.t;
    final layout = DashGrid.of(context);
    final searching = _query.trim().isNotEmpty;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: DashHeader(
              headline: t.welcome,
              subline: t.chooseService,
              hPad: layout.hPad,
              onMenu: widget.onMenu,
              onAiAgent: () =>
                  AppLauncher.snack(context, t.comingSoonMessage),
              searchBox: DashSearchBox(
                controller: _search,
                hint: t.searchHint,
                hasText: _query.isNotEmpty,
                onChanged: (v) => setState(() => _query = v),
                onClear: _clearSearch,
                onScan: () => AppLauncher.scan(context),
              ),
            ),
          ),

          // ── Content ──
          ...(searching
              ? _searchSlivers(t, layout, isDark)
              : _homeSlivers(t, layout, isDark)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Search results
  // ─────────────────────────────────────────────────────────────
  List<Widget> _searchSlivers(
      AppLocalizations t,
      DashGrid layout,
      bool isDark,
      ) {
    final apps = _filtered(t);
    return [
      dashSection(
        layout.hPad,
        t.allServices,
        isDark,
        count: apps.length,
        top: 20,
      ),
      if (apps.isEmpty)
        SliverToBoxAdapter(
          child: DashEmptyState(
            icon: Icons.search_off_rounded,
            title: t.noResults,
            isDark: isDark,
          ),
        )
      else
        SliverAppGrid(apps: apps, layout: layout),
      const SliverToBoxAdapter(child: SizedBox(height: 28)),
    ];
  }

  // ─────────────────────────────────────────────────────────────
  // Home content
  // ─────────────────────────────────────────────────────────────
  List<Widget> _homeSlivers(
      AppLocalizations t,
      DashGrid layout,
      bool isDark,
      ) {
    final hPad = layout.hPad;
    final all = _filtered(t);
    final featured = all.take(_featuredCount).toList();

    return [
      // ── System update card (top of home, dismissible) ──
      SliverToBoxAdapter(
        child: SystemUpdateCard(hPad: hPad),
      ),

      // ── Featured section + always visible "View All" ──
      dashSection(
        hPad,
        t.featured,
        isDark,
        count: all.length,
        top: 20,
        actionLabel: t.seeAll,
        onAction: widget.onSeeAllApps,
      ),
      SliverAppGrid(
        apps: featured,
        layout: layout,
        animate: widget.intro,
        startIndex: 1,
      ),

      // ── Banners slideshow (from API) ──
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Reveal(
            index: 5,
            animate: widget.intro,
            child: Consumer<BannerProvider>(
              builder: (context, bannerProvider, _) {
                return DashboardSlideshow(
                  banners: bannerProvider.banners,
                  loading: bannerProvider.loading,
                  hPad: hPad,
                );
              },
            ),
          ),
        ),
      ),

      // ── Partner apps ──
      dashSection(hPad, t.partnerApps, isDark, top: 8),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        sliver: SliverToBoxAdapter(
          child: Reveal(
            index: 7,
            animate: widget.intro,
            child: PartnerSoonBox(
              isDark: isDark,
              title: t.comingSoon,
              subtitle: t.partnerAppsHint,
            ),
          ),
        ),
      ),

      const SliverToBoxAdapter(child: SizedBox(height: 28)),
    ];
  }
}