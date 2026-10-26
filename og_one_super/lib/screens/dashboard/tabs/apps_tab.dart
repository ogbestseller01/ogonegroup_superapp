import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../config/app_strings.dart';
import '../../../config/app_theme.dart';
import '../../../models/mini_app.dart';
import '../../../services/mini_app_service.dart';
import '../core/app_category.dart';
import '../core/app_launcher.dart';
import '../core/app_usage_provider.dart';
import '../core/dash_theme.dart';
import '../../../widgets/app_tile.dart';
import '../../../widgets/dash_common.dart';
import '../../../widgets/dash_header.dart';
import '../../../widgets/dash_search_box.dart';

/// Apps: the full directory of every mini app and partner,
/// with Recent + Favorites on top and one section per category.
class AppsTab extends StatefulWidget {
  final VoidCallback onMenu;

  const AppsTab({super.key, required this.onMenu});

  @override
  State<AppsTab> createState() => _AppsTabState();
}

class _AppsTabState extends State<AppsTab> {
  final _search = TextEditingController();
  String _query = '';
  AppCategory? _category; // null = All

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    try {
      await MiniAppService.instance.refresh();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
    FocusScope.of(context).unfocus();
  }

  List<MiniApp> _resolve(List<String> slugs) {
    final out = <MiniApp>[];
    for (final s in slugs) {
      final app = MiniAppService.instance.bySlug(s);
      if (app != null && !app.isComingSoon) out.add(app);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.t;
    final layout = DashGrid.of(context);
    final usage = context.watch<AppUsageProvider>();

    final all = availableFirst(MiniAppService.instance.apps);
    final q = _query.trim().toLowerCase();
    final searching = q.isNotEmpty;

    final results = !searching
        ? const <MiniApp>[]
        : all
        .where((a) =>
    t.serviceTitle(a.slug).toLowerCase().contains(q) ||
        a.slug.toLowerCase().contains(q) ||
        a.name.toLowerCase().contains(q))
        .toList();

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: DashHeader(
              headline: t.navApps,
              subline: t.appsSubtitle,
              hPad: layout.hPad,
              onMenu: widget.onMenu,
              onAiAgent: () => AppLauncher.snack(context, t.comingSoonMessage),
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
          if (searching) ...[
            dashSection(layout.hPad, t.allServices, isDark,
                count: results.length, top: 20),
            if (results.isEmpty)
              SliverToBoxAdapter(
                child: DashEmptyState(
                  icon: Icons.search_off_rounded,
                  title: t.noResults,
                  isDark: isDark,
                ),
              )
            else
              SliverAppGrid(apps: results, layout: layout),
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _CategoryChips(
                  hPad: layout.hPad,
                  selected: _category,
                  onSelect: (c) => setState(() => _category = c),
                ),
              ),
            ),
            if (_category == null) ..._quickAccess(usage, layout, isDark, t),
            ..._categorySections(all, layout, isDark, t),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  // ── Recent + Favorites ─────────────────────────────────
  List<Widget> _quickAccess(
      AppUsageProvider usage,
      DashGrid layout,
      bool isDark,
      AppLocalizations t,
      ) {
    final recents = _resolve(usage.recent);
    final favorites = _resolve(usage.favorites);

    return [
      if (recents.isNotEmpty) ...[
        dashSection(layout.hPad, t.recentApps, isDark,
            icon: Icons.history_rounded, top: 18),
        SliverToBoxAdapter(
            child: AppHorizontalRow(apps: recents, layout: layout)),
      ],
      dashSection(layout.hPad, t.favoriteApps, isDark,
          icon: Icons.star_rounded, top: 14),
      if (favorites.isNotEmpty)
        SliverToBoxAdapter(
            child: AppHorizontalRow(apps: favorites, layout: layout))
      else
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.hPad),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : kGold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded,
                      size: 20, color: dashAccent(isDark)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.favoritesHint,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: dashMuted(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  // ── One section per category ───────────────────────────
  List<Widget> _categorySections(
      List<MiniApp> all,
      DashGrid layout,
      bool isDark,
      AppLocalizations t,
      ) {
    final cats = _category == null ? AppCategory.values : [_category!];
    final out = <Widget>[];

    for (final c in cats) {
      final apps = all.where((a) => categoryOf(a) == c).toList();

      // Hide empty categories on "All", except Partners (future teaser).
      if (apps.isEmpty && _category == null && c != AppCategory.partners) {
        continue;
      }

      out.add(dashSection(layout.hPad, c.label(t), isDark,
          count: apps.isEmpty ? null : apps.length,
          icon: c.icon,
          top: 20));

      if (apps.isNotEmpty) {
        out.add(SliverAppGrid(apps: apps, layout: layout));
      } else if (c == AppCategory.partners) {
        out.add(SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: layout.hPad),
          sliver: SliverToBoxAdapter(
            child: PartnerSoonBox(
              isDark: isDark,
              title: t.comingSoon,
              subtitle: t.partnerAppsHint,
            ),
          ),
        ));
      } else {
        out.add(SliverToBoxAdapter(
          child: DashEmptyState(
            icon: c.icon,
            title: t.noAppsHere,
            isDark: isDark,
          ),
        ));
      }
    }
    return out;
  }
}

// ════════════════════════════════════════════════
// Category filter chips
// ════════════════════════════════════════════════
class _CategoryChips extends StatelessWidget {
  final double hPad;
  final AppCategory? selected;
  final ValueChanged<AppCategory?> onSelect;

  const _CategoryChips({
    required this.hPad,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final entries = <(AppCategory?, String, IconData)>[
      (null, t.filterAll, Icons.apps_rounded),
      for (final c in AppCategory.values) (c, c.label(t), c.icon),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (cat, label, icon) = entries[i];
          return _Chip(
            label: label,
            icon: icon,
            selected: selected == cat,
            onTap: () => onSelect(cat),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = selected ? kNavy : dashInk(isDark);

    return Pressable(
      label: label,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? kGoldGradient : null,
          color: selected ? null : dashSurface(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.08)),
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: kGold.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}