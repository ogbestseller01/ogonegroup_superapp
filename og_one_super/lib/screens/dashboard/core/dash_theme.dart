import 'dart:math' show max;

import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../models/mini_app.dart';

// ════════════════════════════════════════════════
// Colors & gradients
// ════════════════════════════════════════════════
const Color kGoldText = Color(0xFF8A6500);
const Color kHintGrey = Color(0xFF5B6B82);
const Color kLightBg = Color(0xFFF7F9FC);
const Color kNavy = Color(0xFF1A2B4A);
const Color kGold = Color(0xFFFFB300);

const kHeaderGradient = LinearGradient(
  colors: [Color(0xFF0B1C3A), Color(0xFF132B55), Color(0xFF1A3A75)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kGoldGradient = LinearGradient(
  colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ════════════════════════════════════════════════
// Helpers
// ════════════════════════════════════════════════
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
  'directions_car': Icons.directions_car_rounded,
  'home_work': Icons.home_work_rounded,
};

IconData dashIconFor(String name) => _icons[name] ?? Icons.apps_rounded;

Color dashAppColor(MiniApp a) {
  switch (a.slug) {
    case 'nearbyfundi':
      return const Color(0xFF2B7BFF);
    case 'fundiapp':
      return const Color(0xFFFFB300);
    case 'dalali':
      return const Color(0xFF0E8F6E);
    default:
      return Color(int.parse(a.color.replaceFirst('#', '0xFF')));
  }
}

Color dashAccent(bool isDark) => isDark ? AppTheme.secondary : kGoldText;
Color dashPageBg(bool isDark) =>
    isDark ? AppTheme.darkBackground : kLightBg;
Color dashInk(bool isDark) => isDark ? Colors.white : kNavy;
Color dashMuted(bool isDark) =>
    isDark ? AppTheme.darkTextSecondary : kHintGrey;
Color dashSurface(bool isDark) => isDark ? AppTheme.darkSurface : Colors.white;

Color dashShade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

List<MiniApp> availableFirst(List<MiniApp> apps) => [
      ...apps.where((a) => !a.isComingSoon),
      ...apps.where((a) => a.isComingSoon),
    ];

const double kLabelFont = 11.5;
const double kLabelMinFont = 9.5;
const double kLabelLineHeight = 1.2;
const double kCompactWidth = 370;

bool isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kCompactWidth;

// ════════════════════════════════════════════════
// Grid sizing (responsive)
// ════════════════════════════════════════════════
class DashGrid {
  static const double colSpacing = 6;
  static const double rowSpacing = 8;
  static const double _minCellWidth = 70;

  final double hPad;
  final int columns;
  final double crossAxisExtent;
  final double iconSize;
  final double mainAxisExtent;

  const DashGrid._(this.hPad, this.columns, this.crossAxisExtent,
      this.iconSize, this.mainAxisExtent);

  factory DashGrid.of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final safe = MediaQuery.paddingOf(context);
    final textScale =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(1.0);

    final sideInset = max(safe.left, safe.right) + 12;
    final baseH = width < 360 ? 14.0 : 18.0;
    final hPad = width > 800
        ? max((width - 760) / 2, sideInset)
        : max(baseH, sideInset);

    final contentW = width - 2 * hPad;
    final columns = ((contentW + colSpacing) / (_minCellWidth + colSpacing))
        .floor()
        .clamp(3, 6);

    final cellW = (contentW - (columns - 1) * colSpacing) / columns;
    final icon = (cellW * 0.52).clamp(38.0, 46.0).toDouble();
    final labelH =
        (kLabelFont * kLabelLineHeight * 2 * textScale).ceilToDouble();

    return DashGrid._(
      hPad,
      columns,
      contentW / columns,
      icon,
      6 + icon + 8 + labelH + 4,
    );
  }
}
