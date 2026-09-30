// ============================================================
//  FundiApp — Settings
//
//  • PNG flags (no emoji → no tofu boxes)
//  • Language picker as a bottom sheet (not a raw dropdown)
//  • Dark / light switch with proper M3 track colours
//  • Logout with a confirmation dialog that matches the login card
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_routes.dart';
import '../../../config/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/theme_provider.dart';
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
              // ── Notifications ────────────────────────────────
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
                          const _IconBadge(
                            icon: Icons.notifications_outlined,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.pushNotifications,
                                    style: theme.textTheme.titleMedium),
                                Text(l10n.receiveAlerts,
                                    style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                      value: settings.notificationsEnabled,
                      onChanged: (val) =>
                          settings.updateNotificationStatus(val),
                      activeColor: theme.colorScheme.primary,
                      activeTrackColor:
                      theme.colorScheme.primary.withOpacity(0.5),
                      inactiveThumbColor:
                      theme.colorScheme.onSurfaceVariant,
                      inactiveTrackColor:
                      theme.colorScheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      tileColor: Colors.transparent,
                    ),
                    _divider(context),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.blue,
                          size: 20,
                        ),
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
                        color:
                        theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationListScreen(),
                          ),
                        );
                      },
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      tileColor: Colors.transparent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Language ─────────────────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
                child: ListTile(
                  leading: const _IconBadge(icon: Icons.language_outlined),
                  title: Text(l10n.language,
                      style: theme.textTheme.titleMedium),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FlagPng(
                        asset: _flagAsset(settings.locale),
                        height: 20,
                        width: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        settings.locale == 'sw' ? 'Kiswahili' : 'English',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                  onTap: () => _showLanguageSheet(
                    context,
                    settings,
                    auth,
                    l10n,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  tileColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 12),

              // ── Dark Mode ────────────────────────────────────
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
                          color: isDarkMode
                              ? Colors.indigo.withOpacity(0.18)
                              : Colors.amber.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDarkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: isDarkMode
                              ? Colors.indigo.shade300
                              : Colors.amber.shade800,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dark Mode',
                                style: theme.textTheme.titleMedium),
                            Text(
                              isDarkMode
                                  ? 'Dark theme enabled'
                                  : 'Light theme enabled',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  value: isDarkMode,
                  onChanged: (val) {
                    themeProvider.setThemeMode(
                        val ? ThemeMode.dark : ThemeMode.light);
                  },
                  activeColor: theme.colorScheme.primary,
                  activeTrackColor:
                  theme.colorScheme.primary.withOpacity(0.5),
                  inactiveThumbColor: theme.colorScheme.onSurfaceVariant,
                  inactiveTrackColor: theme.colorScheme.surfaceVariant,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  tileColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 20),

              // ── Static pages ─────────────────────────────────
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
                child: Column(
                  children: [
                    _settingsTile(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: l10n.aboutUs,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.about),
                    ),
                    _divider(context),
                    _settingsTile(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: l10n.faq,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.faq),
                    ),
                    _divider(context),
                    _settingsTile(
                      context,
                      icon: Icons.description_outlined,
                      title: l10n.terms,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.terms),
                    ),
                    _divider(context),
                    _settingsTile(
                      context,
                      icon: Icons.privacy_tip_rounded,
                      title: l10n.privacyPolicy,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.privacy),
                    ),
                    _divider(context),
                    _settingsTile(
                      context,
                      icon: Icons.contact_mail_outlined,
                      title: l10n.contactUs,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.contactUs),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Logout ───────────────────────────────────────
              const _LogoutCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────

  Widget _settingsTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: _IconBadge(icon: icon),
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

  Widget _divider(BuildContext context) => Divider(
    height: 1,
    color: Theme.of(context).dividerColor,
    indent: 16,
    endIndent: 16,
  );

  // ────────────────────────────────────────────────────────
  // Language picker sheet
  // ────────────────────────────────────────────────────────
  void _showLanguageSheet(
      BuildContext context,
      SettingsProvider settings,
      AuthProvider auth,
      AppLocalizations l10n,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                  isDark ? AppTheme.darkBorder : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.language,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              _langTile(
                label: 'English',
                localeCode: 'en',
                selected: settings.locale == 'en',
                isDark: isDark,
                onTap: () async {
                  await settings.updateLocale('en');
                  await auth.updateLocale('en');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              _langTile(
                label: 'Kiswahili',
                localeCode: 'sw',
                selected: settings.locale == 'sw',
                isDark: isDark,
                onTap: () async {
                  await settings.updateLocale('sw');
                  await auth.updateLocale('sw');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langTile({
    required String label,
    required String localeCode,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = isDark ? AppTheme.secondary : AppTheme.primary;
    final textColor = isDark ? Colors.white : AppTheme.primary;

    return Material(
      color: selected ? activeColor.withOpacity(0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? activeColor
                  : (isDark
                  ? AppTheme.darkBorder
                  : Colors.black.withOpacity(0.08)),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              _FlagPng(
                asset: _flagAsset(localeCode),
                height: 22,
                width: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? activeColor : textColor,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: activeColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  FLAG PNG HELPERS  —  use these across the SDK
// ============================================================

/// Package name of this SDK — required so assets resolve when
/// this code runs inside the host super-app.
const String _kAssetPackage = 'fundiapp_sdk';

/// Map a locale code → the flag PNG asset in this SDK.
String _flagAsset(String localeCode) {
  switch (localeCode) {
    case 'sw':
      return 'assets/images/tzflug.png';
    case 'en':
    default:
      return 'assets/images/englishflug.png';
  }
}

/// Small rounded flag image backed by a PNG asset.
class _FlagPng extends StatelessWidget {
  final String asset;
  final double height;
  final double width;

  const _FlagPng({
    required this.asset,
    this.height = 20,
    this.width = 28,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        asset,
        package: _kAssetPackage,
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

/// Rounded tinted square that holds a leading settings icon.
class _IconBadge extends StatelessWidget {
  final IconData icon;

  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: 20),
    );
  }
}

// ============================================================
//  LOGOUT CARD
// ============================================================
class _LogoutCard extends StatefulWidget {
  const _LogoutCard();

  @override
  State<_LogoutCard> createState() => _LogoutCardState();
}

class _LogoutCardState extends State<_LogoutCard> {
  bool _busy = false;

  Future<void> _confirmAndLogout() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final errorColor = theme.colorScheme.error;
    final auth = context.read<AuthProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_busy,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: errorColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.logout_rounded, color: errorColor, size: 28),
        ),
        title: const Text(
          'Log out?',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        content: const Text(
          'You’ll need to sign in again to access your account.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: errorColor,
              padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Log out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await auth.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
            (route) => false,
      );
    } catch (e, stack) {
      debugPrint('❌ Logout failed: $e\n$stack');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _busy ? null : _confirmAndLogout,
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _busy
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          errorColor),
                    ),
                  )
                      : Icon(Icons.logout_rounded,
                      color: errorColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _busy ? 'Logging out…' : 'Log out',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: errorColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: errorColor.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}