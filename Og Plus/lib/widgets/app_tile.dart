
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../models/mini_app.dart';

import '../screens/dashboard/core/app_launcher.dart';
import '../screens/dashboard/core/app_usage_provider.dart';
import '../screens/dashboard/core/dash_theme.dart';
import 'dash_common.dart';

// =====================================================
// DASHBOARD APP FILTER
// =====================================================

List<MiniApp> _dashboardVisibleApps(List<MiniApp> apps) {
  return apps.where((app) {
    final slug = app.slug.trim().toLowerCase();

    return slug == 'nearbyfundi' || app.isDemo;
  }).toList(growable: false);
}

// =====================================================
// APP TILE
// =====================================================

class AppTile extends StatelessWidget {
  final MiniApp app;
  final String title;
  final String soonLabel;
  final double size;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AppTile({
    super.key,
    required this.app,
    required this.title,
    required this.soonLabel,
    required this.size,
    required this.onTap,
    this.onLongPress,
    this.isFavorite = false,
  });

  static const List<double> _fadeMatrix = [
    0.38, 0, 0, 0, 0,
    0, 0.38, 0, 0, 0,
    0, 0, 0.38, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final color = dashAppColor(app);
    final isComingSoon = app.isComingSoon;
    final hasImage = app.imageAsset != null;

    // Demo apps remain visible normally.
    final faded = isComingSoon && !app.isDemo;

    final iconColor =
    color.computeLuminance() > 0.4 ? kNavy : Colors.white;

    final textColor =
    faded ? Colors.transparent : dashInk(isDark);

    final iconContent = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: hasImage
            ? null
            : LinearGradient(
          colors: [
            dashShade(color, 0.09),
            dashShade(color, -0.07),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(
              alpha: isDark ? 0.25 : 0.2,
            ),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasImage
          ? Padding(
        padding: EdgeInsets.all(size * 0.04),
        child: Image.asset(
          app.imageAsset!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              dashIconFor(app.icon),
              size: size * 0.5,
              color: iconColor,
            );
          },
        ),
      )
          : Icon(
        dashIconFor(app.icon),
        size: size * 0.5,
        color: iconColor,
      ),
    );

    final displayedIcon = faded
        ? ColorFiltered(
      colorFilter: const ColorFilter.matrix(_fadeMatrix),
      child: iconContent,
    )
        : iconContent;

    return Pressable(
      label: isComingSoon ? '$title, $soonLabel' : title,
      onTap: onTap,
      onLongPress: isComingSoon ? null : onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  displayedIcon,

                  if (isComingSoon)
                    Positioned(
                      top: -5,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: dashPageBg(isDark),
                            width: 1.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.1,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          soonLabel,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 8,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: kNavy,
                          ),
                        ),
                      ),
                    ),

                  if (isFavorite && !isComingSoon)
                    Positioned(
                      top: -5,
                      left: -6,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: kGoldGradient,
                          border: Border.all(
                            color: dashPageBg(isDark),
                            width: 1.6,
                          ),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 11,
                          color: kNavy,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: FitLabel(
                  text: title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: kLabelFont,
                    height: kLabelLineHeight,
                    color: textColor,
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

// =====================================================
// SLIVER APP GRID
// =====================================================

class SliverAppGrid extends StatelessWidget {
  final List<MiniApp> apps;
  final DashGrid layout;
  final bool animate;
  final int startIndex;

  const SliverAppGrid({
    super.key,
    required this.apps,
    required this.layout,
    this.animate = false,
    this.startIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final usage = context.watch<AppUsageProvider>();

    // Hide all dashboard apps except NearbyFundi and Demo apps.
    final visibleApps = _dashboardVisibleApps(apps);

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: layout.hPad,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: layout.columns,
          mainAxisExtent: layout.mainAxisExtent,
          mainAxisSpacing: DashGrid.rowSpacing,
          crossAxisSpacing: DashGrid.colSpacing,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final app = visibleApps[index];

            return Reveal(
              key: ValueKey(app.slug),
              index: startIndex + index,
              animate: animate,
              child: RepaintBoundary(
                child: AppTile(
                  app: app,
                  title: translations.serviceTitle(app.slug),
                  soonLabel: translations.soon,
                  size: layout.iconSize,
                  isFavorite: usage.isFavorite(app.slug),
                  onTap: () => AppLauncher.open(context, app),
                  onLongPress: () {
                    AppLauncher.toggleFavorite(context, app);
                  },
                ),
              ),
            );
          },
          childCount: visibleApps.length,
        ),
      ),
    );
  }
}

// =====================================================
// HORIZONTAL APP ROW
// =====================================================

class AppHorizontalRow extends StatelessWidget {
  final List<MiniApp> apps;
  final DashGrid layout;

  const AppHorizontalRow({
    super.key,
    required this.apps,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final usage = context.watch<AppUsageProvider>();

    // Apply the same filter to horizontal app lists.
    final visibleApps = _dashboardVisibleApps(apps);

    final tileWidth =
        layout.crossAxisExtent - DashGrid.colSpacing;

    return SizedBox(
      height: layout.mainAxisExtent,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: layout.hPad,
        ),
        physics: const BouncingScrollPhysics(),
        itemCount: visibleApps.length,
        separatorBuilder: (context, index) {
          return const SizedBox(
            width: DashGrid.colSpacing,
          );
        },
        itemBuilder: (context, index) {
          final app = visibleApps[index];

          return SizedBox(
            width: tileWidth,
            child: AppTile(
              app: app,
              title: translations.serviceTitle(app.slug),
              soonLabel: translations.soon,
              size: layout.iconSize,
              isFavorite: usage.isFavorite(app.slug),
              onTap: () => AppLauncher.open(context, app),
              onLongPress: () {
                AppLauncher.toggleFavorite(context, app);
              },
            ),
          );
        },
      ),
    );
  }
}
