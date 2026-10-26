import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../providers/settings_provider.dart';
import 'dash_common.dart';

void showLanguageSheet(BuildContext context) {
  FocusScope.of(context).unfocus();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => const LanguageSheet(),
  );
}

class _LangOption {
  final String code;
  final String label;
  final String badge;
  final String flagAsset;

  const _LangOption(this.code, this.label, this.badge, this.flagAsset);
}

class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final t = context.t;
    final textColor = isDark ? Colors.white : AppTheme.primary;
    final current = settings.locale.languageCode;

    final options = [
      _LangOption('en', t.english, 'EN', 'assets/images/englishflug.png'),
      _LangOption('sw', t.swahili, 'SW', 'assets/images/tzflug.png'),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.07))
            : null,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            18, 12, 18, MediaQuery.paddingOf(context).bottom + 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              t.selectLanguage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: textColor,
              ),
            ),
            const SizedBox(height: 14),
            for (final o in options)
              _LangTile(
                option: o,
                selected: current == o.code,
                onTap: () {
                  HapticFeedback.selectionClick();
                  settings.setLocale(Locale(o.code));
                },
              ),
            const SizedBox(height: 4),
            Material(
              color: isDark
                  ? AppTheme.darkSurfaceLight
                  : AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  // Grab the navigator first, then close the sheet and open
                  // settings, so no context is used after the pop.
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.pushNamed(AppRoutes.settings);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white,
                        ),
                        child: Icon(Icons.settings_rounded,
                            color: textColor, size: 21),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          t.settings,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: textColor),
                    ],
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

class _FlagBadge extends StatelessWidget {
  final _LangOption option;
  final bool selected;
  final bool isDark;

  const _FlagBadge({
    required this.option,
    required this.selected,
    required this.isDark,
  });

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.secondary : AppTheme.primary;
    final textColor = isDark ? Colors.white : AppTheme.primary;

    Widget fallback() => Container(
          color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
          alignment: Alignment.center,
          child: Text(
            option.badge,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: textColor,
            ),
          ),
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: _size,
      height: _size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? accent
              : (isDark ? Colors.white24 : AppTheme.navy100),
          width: selected ? 2.2 : 1.2,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          option.flagAsset,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final _LangOption option;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.secondary : AppTheme.primary;
    final textColor = isDark ? Colors.white : AppTheme.primary;

    final tileColor = selected
        ? accent.withValues(alpha: isDark ? 0.13 : 0.07)
        : (isDark ? AppTheme.darkSurfaceLight : AppTheme.navy50);

    return Pressable(
      label: option.label,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Row(
          children: [
            _FlagBadge(option: option, selected: selected, isDark: isDark),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 23,
              color: selected
                  ? accent
                  : (isDark ? Colors.white30 : AppTheme.navy200),
            ),
          ],
        ),
      ),
    );
  }
}
