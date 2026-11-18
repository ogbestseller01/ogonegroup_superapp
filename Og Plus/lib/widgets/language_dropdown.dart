import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class _Lang {
  final String code;
  final String label;
  final String flagAsset;
  const _Lang(this.code, this.label, this.flagAsset);
}

const _languages = [
  _Lang('en', 'English', 'assets/images/englishflug.png'),
  _Lang('sw', 'Swahili', 'assets/images/tzflug.png'),
];

_Lang _byCode(String code) =>
    _languages.firstWhere((l) => l.code == code, orElse: () => _languages.first);

class _Flag extends StatelessWidget {
  final String asset;
  final double size;
  const _Flag({required this.asset, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1),
      ),
      child: ClipOval(
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppTheme.navy100,
            child: Icon(Icons.flag_rounded,
                size: size * 0.6, color: AppTheme.primary),
          ),
        ),
      ),
    );
  }
}

/// "Lang" pill with the current flag; opens a dropdown of languages with flags.
class LanguageDropdown extends StatelessWidget {
  final String currentCode;
  final ValueChanged<String> onChanged;

  const LanguageDropdown({
    super.key,
    required this.currentCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = _byCode(currentCode);

    return PopupMenuButton<String>(
      initialValue: current.code,
      onSelected: onChanged,
      offset: const Offset(0, 46),
      elevation: 8,
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => [
        for (final l in _languages)
          PopupMenuItem<String>(
            value: l.code,
            child: Row(
              children: [
                _Flag(asset: l.flagAsset, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: l.code == current.code
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.primary,
                    ),
                  ),
                ),
                if (l.code == current.code)
                  Icon(Icons.check_rounded,
                      color: isDark ? AppTheme.secondary : AppTheme.primary,
                      size: 18),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Flag(asset: current.flagAsset, size: 24),
            const SizedBox(width: 6),
            const Text(
              'Lang',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}