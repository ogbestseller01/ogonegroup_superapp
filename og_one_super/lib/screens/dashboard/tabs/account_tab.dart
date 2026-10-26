import 'package:flutter/material.dart';

import '../../../config/app_routes.dart';
import '../../../config/app_strings.dart';
import '../../../config/app_theme.dart';
import '../core/app_launcher.dart';
import '../core/dash_theme.dart';
import '../../../widgets/dash_header.dart';
import '../../../widgets/language_sheet.dart';

/// Account: only the two menus the super app needs.
/// Everything else (theme, notifications, help, about...) already lives
/// in the Settings screen.
class AccountTab extends StatelessWidget {
  final VoidCallback onMenu;

  const AccountTab({super.key, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.t;
    final layout = DashGrid.of(context);
    final lang = Localizations.localeOf(context).languageCode.toUpperCase();

    return CustomScrollView(
      physics:
      const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: DashHeader(
            headline: t.navAccount,
            subline: t.accountSubtitle,
            hPad: layout.hPad,
            onMenu: onMenu,
            onAiAgent: () => AppLauncher.snack(context, t.comingSoonMessage),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(layout.hPad, 20, layout.hPad, 28),
          sliver: SliverList.list(
            children: [
              _Group(isDark: isDark, tiles: [
                _Tile(
                  icon: Icons.language_rounded,
                  title: t.language,
                  trailingText: lang,
                  onTap: () => showLanguageSheet(context),
                ),
                _Tile(
                  icon: Icons.settings_rounded,
                  title: t.settings,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  final bool isDark;
  final List<_Tile> tiles;

  const _Group({required this.isDark, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dashSurface(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              tiles[i],
              if (i != tiles.length - 1)
                Divider(
                  height: 1,
                  indent: 62,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.05),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.secondary.withValues(alpha: 0.14)
                    : kGold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: dashAccent(isDark)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: dashInk(isDark),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: dashMuted(isDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: dashMuted(isDark),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right_rounded, color: dashMuted(isDark)),
          ],
        ),
      ),
    );
  }
}