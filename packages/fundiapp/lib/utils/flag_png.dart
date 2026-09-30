// lib/widgets/flag_png.dart  ← suggested location
// Package-private helpers, export them as you see fit.

import 'package:flutter/material.dart';

/// Package name of this SDK — required so assets resolve when this
/// code runs inside the host super app.
const String kFundiAssetPackage = 'fundiapp_sdk';

/// Map a locale code → the flag PNG asset in this SDK.
String flagAssetFor(String localeCode) {
  switch (localeCode) {
    case 'sw':
      return 'assets/images/tzflug.png';
    case 'en':
    default:
      return 'assets/images/englishflug.png';
  }
}

/// Rounded flag image backed by a PNG asset that lives in this SDK.
///
/// ```dart
/// FlagPng(asset: flagAssetFor('sw'), height: 20, width: 28)
/// ```
class FlagPng extends StatelessWidget {
  final String asset;
  final double height;
  final double width;
  final double radius;

  const FlagPng({
    super.key,
    required this.asset,
    this.height = 20,
    this.width = 28,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset,
        package: kFundiAssetPackage,
        height: height,
        width: width,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          width: width,
          alignment: Alignment.center,
          color: theme.colorScheme.primary.withOpacity(0.10),
          child: Icon(
            Icons.flag_rounded,
            size: height * 0.7,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}