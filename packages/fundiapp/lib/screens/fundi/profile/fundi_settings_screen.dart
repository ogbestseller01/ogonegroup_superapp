import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../config/app_routes.dart';
import '../../../config/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../notifications/notification_list_screen.dart';

class FundiSettingsScreen extends StatelessWidget {
  const FundiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ---- Notifications ----
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.notifications_outlined, color: theme.colorScheme.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.pushNotifications, style: theme.textTheme.titleMedium),
                                Text(l10n.receiveAlerts, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                      value: settings.notificationsEnabled,
                      onChanged: (val) => settings.updateNotificationStatus(val),
                      activeColor: theme.colorScheme.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      tileColor: Colors.transparent,
                    ),
                    Divider(height: 1, color: theme.dividerColor, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.notifications_active_rounded, color: Colors.blue, size: 20),
                      ),
                      title: Text(
                        l10n.viewNotifications,
                        style: theme.textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        l10n.seeAllNotifications,
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationListScreen(),
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      tileColor: Colors.transparent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ---- Language ----
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.language_outlined, color: theme.colorScheme.primary, size: 20),
                  ),
                  title: Text(l10n.language, style: theme.textTheme.titleMedium),
                  trailing: DropdownButton<String>(
                    value: settings.locale,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English 🇬🇧')),
                      DropdownMenuItem(value: 'sw', child: Text('Kiswahili 🇹🇿')),
                    ],
                    onChanged: (val) async {
                      if (val != null) {
                        await settings.updateLocale(val);
                        await auth.updateLocale(val);
                      }
                    },
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    dropdownColor: theme.cardColor,
                    underline: Container(),
                    icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  tileColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 12),

              // ---- Dark Mode ----
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
                child: SwitchListTile(
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: isDarkMode ? Colors.amber.shade300 : Colors.amber.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dark Mode', style: theme.textTheme.titleMedium),
                            Text(
                              isDarkMode ? 'Dark theme enabled 🌙' : 'Light theme enabled ☀️',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  value: isDarkMode,
                  onChanged: (val) {
                    themeProvider.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                  },
                  activeColor: theme.colorScheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  tileColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 20),

              // ---- Static Pages ----
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: l10n.aboutUs,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                    ),
                    _buildDivider(context),
                    _buildSettingsTile(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: l10n.faq,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.faq),
                    ),
                    _buildDivider(context),
                    _buildSettingsTile(
                      context,
                      icon: Icons.description_outlined,
                      title: l10n.terms,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.terms),
                    ),
                    _buildDivider(context),
                    _buildSettingsTile(
                      context,
                      icon: Icons.privacy_tip_rounded,
                      title: l10n.privacyPolicy,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
                    ),
                    _buildDivider(context),
                    _buildSettingsTile(
                      context,
                      icon: Icons.contact_mail_outlined,
                      title: l10n.contactUs,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.contactUs),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(title, style: theme.textTheme.titleMedium),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      tileColor: Colors.transparent,
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(height: 1, color: theme.dividerColor, indent: 16, endIndent: 16);
  }
}