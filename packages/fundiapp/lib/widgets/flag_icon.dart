// lib/widgets/flag_icon.dart
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

class FlagIcon extends StatelessWidget {
  /// Flag emoji like '🇹🇿' or '🇰🇪'. ISO-2 code is derived from it.
  final String emoji;
  final double height;
  final double? width;

  const FlagIcon({
    super.key,
    required this.emoji,
    this.height = 24,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? height * 4 / 3;
    final code = _isoCodeFromEmoji(emoji);

    if (code != null) {
      return SizedBox(
        width: w,
        height: height,
        child: CountryFlag.fromCountryCode(code),
      );
    }

    // Unknown emoji → neutral grey placeholder
    return Container(
      width: w,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Icon(
        Icons.flag_rounded,
        size: height * 0.7,
        color: Colors.grey.shade600,
      ),
    );
  }

  static String? _isoCodeFromEmoji(String input) {
    final runes = input.runes.toList();
    if (runes.length < 2) return null;
    if (runes[0] < 0x1F1E6 || runes[0] > 0x1F1FF) return null;
    if (runes[1] < 0x1F1E6 || runes[1] > 0x1F1FF) return null;
    final a = String.fromCharCode(runes[0] - 0x1F1E6 + 0x41);
    final b = String.fromCharCode(runes[1] - 0x1F1E6 + 0x41);
    return (a + b).toLowerCase();
  }
}