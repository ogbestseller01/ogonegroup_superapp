// lib/widgets/flag_icon.dart
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

/// Converts a flag emoji like 🇹🇿 into its ISO code ("TZ").
/// A flag emoji is two "regional indicator" characters (A-Z shifted to 0x1F1E6+).
String? isoFromFlagEmoji(String flag) {
  final runes = flag.runes.toList();
  if (runes.length != 2) return null;
  const base = 0x1F1E6;
  final a = runes[0] - base;
  final b = runes[1] - base;
  if (a < 0 || a > 25 || b < 0 || b > 25) return null;
  return String.fromCharCodes([65 + a, 65 + b]);
}

/// Renders a country flag as an SVG image, so it never depends on the
/// device's emoji font. Pass the emoji string you already store in `Country.flag`.
class FlagIcon extends StatelessWidget {
  final String emoji;
  final double height;

  const FlagIcon({
    super.key,
    required this.emoji,
    this.height = 24,
  });

  @override
  Widget build(BuildContext context) {
    final iso = isoFromFlagEmoji(emoji);
    final width = height * 4 / 3;

    if (iso == null) {
      return SizedBox(
        width: width,
        height: height,
        child: Icon(Icons.flag_outlined, size: height * 0.8),
      );
    }

    return CountryFlag.fromCountryCode(
      iso,
      theme: ImageTheme(
        width: width,
        height: height,
        shape: const RoundedRectangle(4),
      ),
    );
  }
}