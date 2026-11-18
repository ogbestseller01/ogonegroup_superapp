import 'package:flutter/material.dart';

import '../../../config/app_routes.dart';
import '../../../config/app_strings.dart';
import '../../../config/app_theme.dart';
import '../core/app_launcher.dart';
import '../core/dash_theme.dart';
import '../../../widgets/dash_header.dart';

// Static pages moved from Settings to Account
import '../../settings/staticpages/about_screen.dart';
import '../../settings/staticpages/contact_screen.dart';
import '../../settings/staticpages/faq_screen.dart';
import '../../settings/staticpages/feedback_screen.dart';
import '../../settings/staticpages/privacy_screen.dart';
import '../../settings/staticpages/terms_screen.dart';
import '../../system_updates/system_updates_list_screen.dart';

/// Account tab: Settings, App Updates, and all Static Pages.
class AccountTab extends StatelessWidget {
  final VoidCallback onMenu;

  const AccountTab({super.key, required this.onMenu});

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.t;
    final layout = DashGrid.of(context);

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
              // ========== MAIN MENU ==========
              _Group(isDark: isDark, tiles: [
                _Tile(
                  icon: Icons.settings_rounded,
                  title: t.settings,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.settings),
                ),
                _Tile(
                  icon: Icons.system_update_rounded,
                  title: t.appUpdates,
                  onTap: () => _go(context, const SystemUpdatesListScreen()),
                ),
              ]),

              const SizedBox(height: 20),

              // ========== PRIVACY & DATA ==========
              _Group(isDark: isDark, tiles: [
                _Tile(
                  icon: Icons.privacy_tip_outlined,
                  title: t.privacyPolicy,
                  onTap: () => _go(context, const PrivacyScreen()),
                ),
              ]),

              const SizedBox(height: 20),

              // ========== HELP & FEEDBACK ==========
              _Group(isDark: isDark, tiles: [
                _Tile(
                  icon: Icons.help_outline_rounded,
                  title: t.helpCenter,
                  onTap: () => _go(context, const FaqScreen()),
                ),
                _Tile(
                  icon: Icons.contact_support_rounded,
                  title: t.contactUs,
                  onTap: () => _go(context, const ContactScreen()),
                ),
                _Tile(
                  icon: Icons.feedback_outlined,
                  title: t.sendFeedback,
                  onTap: () => _go(context, const FeedbackScreen()),
                ),
              ]),

              const SizedBox(height: 20),

              // ========== ABOUT & SUPPORT ==========
              _Group(isDark: isDark, tiles: [
                _Tile(
                  icon: Icons.info_outline_rounded,
                  title: t.about,
                  onTap: () => _go(context, const AboutScreen()),
                ),
                _Tile(
                  icon: Icons.description_outlined,
                  title: t.termsConditions,
                  onTap: () => _go(context, const TermsScreen()),
                ),
                _Tile(
                  icon: Icons.star_outline_rounded,
                  title: t.rateApp,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rate App feature coming soon!'),
                      ),
                    );
                  },
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
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
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
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: dashInk(isDark),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: dashMuted(isDark)),
          ],
        ),
      ),
    );
  }
}