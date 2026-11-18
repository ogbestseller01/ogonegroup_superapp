
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

// =====================================================
// APPS TAB
// =====================================================

class AppsTab extends StatefulWidget {
  final VoidCallback onMenu;

  const AppsTab({
    super.key,
    required this.onMenu,
  });

  @override
  State<AppsTab> createState() => _AppsTabState();
}

class _AppsTabState extends State<AppsTab> {
  final TextEditingController _search = TextEditingController();

  String _query = '';
  AppCategory? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ===================================================
  // APP VISIBILITY RULE
  // ===================================================

  bool _shouldShowApp(MiniApp app) {
    final slug = app.slug.trim().toLowerCase();

    // Always show NearbyFundi and Demo apps.
    // Hide every other app marked Coming Soon.
    return slug == 'nearbyfundi' ||
        app.isDemo ||
        !app.isComingSoon;
  }

  List<MiniApp> _visibleApps(List<MiniApp> apps) {
    return apps.where(_shouldShowApp).toList(growable: false);
  }

  // ===================================================
  // REFRESH
  // ===================================================

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();

    try {
      await MiniAppService.instance.refresh();
    } catch (error) {
      debugPrint('AppsTab refresh error: $error');
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ===================================================
  // SEARCH
  // ===================================================

  void _clearSearch() {
    _search.clear();

    setState(() {
      _query = '';
    });

    FocusScope.of(context).unfocus();
  }

  // ===================================================
  // RESOLVE RECENT AND FAVORITE APPS
  // ===================================================

  List<MiniApp> _resolve(List<String> slugs) {
    final result = <MiniApp>[];

    for (final slug in slugs) {
      final app = MiniAppService.instance.bySlug(slug);

      if (app != null && _shouldShowApp(app)) {
        result.add(app);
      }
    }

    return result;
  }

  // ===================================================
  // BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final t = context.t;
    final layout = DashGrid.of(context);
    final usage = context.watch<AppUsageProvider>();

    // Only visible apps are used throughout this screen.
    final all = availableFirst(
      _visibleApps(MiniAppService.instance.apps),
    );

    final q = _query.trim().toLowerCase();
    final searching = q.isNotEmpty;

    // Search only visible apps.
    final results = !searching
        ? const <MiniApp>[]
        : all.where((app) {
      return t
          .serviceTitle(app.slug)
          .toLowerCase()
          .contains(q) ||
          app.slug.toLowerCase().contains(q) ||
          app.name.toLowerCase().contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        keyboardDismissBehavior:
        ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // HEADER
          SliverToBoxAdapter(
            child: DashHeader(
              headline: t.navApps,
              subline: t.appsSubtitle,
              hPad: layout.hPad,
              onMenu: widget.onMenu,
              onAiAgent: () {
                AppLauncher.snack(
                  context,
                  t.comingSoonMessage,
                );
              },
              searchBox: DashSearchBox(
                controller: _search,
                hint: t.searchHint,
                hasText: _query.isNotEmpty,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                onClear: _clearSearch,
                onScan: () => AppLauncher.scan(context),
              ),
            ),
          ),

          // =================================================
          // SEARCH RESULTS
          // =================================================

          if (searching) ...[
            dashSection(
              layout.hPad,
              t.allServices,
              isDark,
              count: results.length,
              top: 20,
            ),

            if (results.isEmpty)
              SliverToBoxAdapter(
                child: DashEmptyState(
                  icon: Icons.search_off_rounded,
                  title: t.noResults,
                  isDark: isDark,
                ),
              )
            else
              SliverAppGrid(
                apps: results,
                layout: layout,
              ),
          ]

          // =================================================
          // NORMAL APP DIRECTORY
          // =================================================

          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _CategoryChips(
                  hPad: layout.hPad,
                  selected: _category,
                  onSelect: (category) {
                    setState(() {
                      _category = category;
                    });
                  },
                ),
              ),
            ),

            if (_category == null)
              ..._quickAccess(
                usage,
                layout,
                isDark,
                t,
              ),

            ..._categorySections(
              all,
              layout,
              isDark,
              t,
            ),
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: 28),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // RECENT + FAVORITES
  // ===================================================

  List<Widget> _quickAccess(
      AppUsageProvider usage,
      DashGrid layout,
      bool isDark,
      AppLocalizations t,
      ) {
    final recents = _resolve(usage.recent);
    final favorites = _resolve(usage.favorites);

    return [
      // RECENT APPS
      if (recents.isNotEmpty) ...[
        dashSection(
          layout.hPad,
          t.recentApps,
          isDark,
          icon: Icons.history_rounded,
          count: recents.length,
          top: 18,
        ),
        SliverToBoxAdapter(
          child: AppHorizontalRow(
            apps: recents,
            layout: layout,
          ),
        ),
      ],

      // FAVORITES
      if (favorites.isNotEmpty) ...[
        dashSection(
          layout.hPad,
          t.favoriteApps,
          isDark,
          icon: Icons.star_rounded,
          count: favorites.length,
          top: 14,
        ),
        SliverToBoxAdapter(
          child: AppHorizontalRow(
            apps: favorites,
            layout: layout,
          ),
        ),
      ] else ...[
        dashSection(
          layout.hPad,
          t.favoriteApps,
          isDark,
          icon: Icons.star_rounded,
          top: 14,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: layout.hPad,
            ),
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
                  Icon(
                    Icons.touch_app_rounded,
                    size: 20,
                    color: dashAccent(isDark),
                  ),
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
      ],
    ];
  }

  // ===================================================
  // CATEGORY SECTIONS
  // ===================================================

  List<Widget> _categorySections(
      List<MiniApp> all,
      DashGrid layout,
      bool isDark,
      AppLocalizations t,
      ) {
    final categories = _category == null
        ? AppCategory.values
        : [_category!];

    final output = <Widget>[];

    for (final category in categories) {
      // Only visible apps are counted and displayed.
      final categoryApps = all
          .where((app) => categoryOf(app) == category)
          .toList();

      // Hide empty categories when showing All.
      // Partners retains its Coming Soon placeholder.
      if (categoryApps.isEmpty &&
          _category == null &&
          category != AppCategory.partners) {
        continue;
      }

      output.add(
        dashSection(
          layout.hPad,
          category.label(t),
          isDark,
          count: categoryApps.isEmpty
              ? null
              : categoryApps.length,
          icon: category.icon,
          top: 20,
        ),
      );

      if (categoryApps.isNotEmpty) {
        output.add(
          SliverAppGrid(
            apps: categoryApps,
            layout: layout,
          ),
        );
      } else if (category == AppCategory.partners) {
        output.add(
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: layout.hPad,
            ),
            sliver: SliverToBoxAdapter(
              child: PartnerSoonBox(
                isDark: isDark,
                title: t.comingSoon,
                subtitle: t.partnerAppsHint,
              ),
            ),
          ),
        );
      } else if (_category != null) {
        output.add(
          SliverToBoxAdapter(
            child: DashEmptyState(
              icon: category.icon,
              title: t.noAppsHere,
              isDark: isDark,
            ),
          ),
        );
      }
    }

    return output;
  }
}

// =====================================================
// CATEGORY FILTER CHIPS
// =====================================================

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
      (
      null,
      t.filterAll,
      Icons.apps_rounded,
      ),
      for (final category in AppCategory.values)
        (
        category,
        category.label(t),
        category.icon,
        ),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: hPad,
        ),
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final (category, label, icon) = entries[index];

          return _Chip(
            label: label,
            icon: icon,
            selected: selected == category,
            onTap: () => onSelect(category),
          );
        },
      ),
    );
  }
}

// =====================================================
// CATEGORY CHIP
// =====================================================

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
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final foreground = selected ? kNavy : dashInk(isDark);

    return Pressable(
      label: label,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? kGoldGradient : null,
          color: selected ? null : dashSurface(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.08),
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
            Icon(
              icon,
              size: 16,
              color: foreground,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected
                    ? FontWeight.w800
                    : FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
