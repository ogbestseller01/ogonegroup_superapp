import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/service_provider.dart';

import '../../config/app_config.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';

import '../../widgets/confirmation_dialog.dart';
import '../../widgets/flag_icon.dart';

import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final serviceProvider = context.watch<ServiceProvider>();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          l10n.settings,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),
      ),
      body: Material(
        color: theme.scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // HEADER
            _HeaderSection(
              isDark: isDark,
            ),

            const SizedBox(height: 28),

            // PREFERENCES
            _SectionTitle(title: 'PREFERENCES'),

            const SizedBox(height: 12),

            _SettingsCard(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  secondary: const _LeadingIcon(
                    icon: Icons.notifications_active_rounded,
                    color: Color(0xFF00897B),
                  ),
                  title: Text(
                    l10n.pushNotifications,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    l10n.receiveAlerts,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.hintColor,
                    ),
                  ),
                  value: settings.notificationsEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: settings.updateNotificationStatus,
                ),

                _CardDivider(),

                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  leading: const _LeadingIcon(
                    icon: Icons.language_rounded,
                    color: Color(0xFF1976D2),
                  ),
                  title: const Text(
                    'Language',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    settings.locale == 'sw'
                        ? 'Kiswahili'
                        : 'English',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.hintColor,
                    ),
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settings.locale,
                      borderRadius: BorderRadius.circular(12),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'en',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FlagIcon(
                                emoji: '🇬🇧',
                                height: 16,
                              ),
                              SizedBox(width: 7),
                              Text('English'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'sw',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FlagIcon(
                                emoji: '🇹🇿',
                                height: 16,
                              ),
                              SizedBox(width: 7),
                              Text('Kiswahili'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) async {
                        if (value == null) return;

                        await settings.updateLocale(value);
                        await auth.updateLocale(value);
                        await serviceProvider.fetchServices(
                          locale: value,
                        );
                      },
                    ),
                  ),
                ),

                _CardDivider(),

                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  leading: const _LeadingIcon(
                    icon: Icons.palette_rounded,
                    color: Color(0xFF8E5AC7),
                  ),
                  title: const Text(
                    'Appearance',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _themeLabel(themeProvider.themeMode),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.hintColor,
                    ),
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<ThemeMode>(
                      value: themeProvider.themeMode,
                      borderRadius: BorderRadius.circular(12),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.light_mode_rounded,
                                size: 17,
                              ),
                              SizedBox(width: 8),
                              Text('Light'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.dark_mode_rounded,
                                size: 17,
                              ),
                              SizedBox(width: 8),
                              Text('Dark'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.settings_suggest_rounded,
                                size: 17,
                              ),
                              SizedBox(width: 8),
                              Text('System'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          themeProvider.setThemeMode(mode);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // INFORMATION
            _SectionTitle(title: 'INFORMATION'),

            const SizedBox(height: 12),

            _SettingsCard(
              children: [
                // ===== NOTIFICATIONS (moved from Profile) =====
                _NavigationTile(
                  icon: Icons.notifications_none_rounded,
                  iconColor: const Color(0xFF8E5AC7),
                  title: l10n.notifications,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.notifications,
                  ),
                ),

                _CardDivider(),

                _NavigationTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF1976D2),
                  title: l10n.aboutUs,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.about,
                  ),
                ),

                _CardDivider(),

                _NavigationTile(
                  icon: Icons.help_outline_rounded,
                  iconColor: const Color(0xFF00897B),
                  title: l10n.faq,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.faq,
                  ),
                ),

                _CardDivider(),

                _NavigationTile(
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFF8E5AC7),
                  title: l10n.terms,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.terms,
                  ),
                ),

                _CardDivider(),

                _NavigationTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: const Color(0xFFE68A24),
                  title: l10n.privacyPolicy,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.privacyPolicy,
                  ),
                ),

                _CardDivider(),

                _NavigationTile(
                  icon: Icons.support_agent_rounded,
                  iconColor: const Color(0xFF00897B),
                  title: l10n.contactUs,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.contactUs,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ACCOUNT
            _SectionTitle(title: 'ACCOUNT'),

            const SizedBox(height: 12),

            _SettingsCard(
              children: [
                _NavigationTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppTheme.error,
                  title: l10n.deleteAccount,
                  titleColor: AppTheme.error,
                  onTap: () => _confirmLogout(
                    context,
                    auth,
                    l10n,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // FOOTER
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: theme.hintColor.withOpacity(0.6),
                    size: 22,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'NearbyFundi',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.version} ${AppConfig.appVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Find trusted technicians near you.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light appearance';
      case ThemeMode.dark:
        return 'Dark appearance';
      case ThemeMode.system:
        return 'Follow device settings';
    }
  }

  Future<void> _confirmLogout(
      BuildContext context,
      AuthProvider auth,
      AppLocalizations l10n,
      ) async {
    final confirm = await showConfirmationDialog(
      context,
      l10n.deleteAccount,
      l10n.deleteAccountConfirmation,
    );

    if (confirm != true) return;

    await auth.logout();

    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (_) => false,
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _HeaderSection extends StatelessWidget {
  final bool isDark;

  const _HeaderSection({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primary.withOpacity(0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage your settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Personalize your NearbyFundi experience.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).hintColor,
      ),
    );
  }
}

// ============================================================
// SETTINGS CARD
// ============================================================

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.12),
          ),
        ),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

// ============================================================
// CARD DIVIDER
// ============================================================

class _CardDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.7,
      indent: 72,
      endIndent: 16,
      color: Theme.of(context).dividerColor.withOpacity(0.2),
    );
  }
}

// ============================================================
// LEADING ICON
// ============================================================

class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _LeadingIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 21,
      ),
    );
  }
}

// ============================================================
// NAVIGATION TILE
// ============================================================

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;

  const _NavigationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 3,
      ),
      leading: _LeadingIcon(
        icon: icon,
        color: iconColor,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 15,
        color: titleColor ?? theme.hintColor,
      ),
      onTap: onTap,
    );
  }
}