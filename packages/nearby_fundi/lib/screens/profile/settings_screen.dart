// screens/profile/settings_screen.dart
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─── Push Notifications ──────────────────────────────────────
            SwitchListTile(
              title: Text(
                l10n.pushNotifications,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                l10n.receiveAlerts,
                style: theme.textTheme.bodySmall,
              ),
              value: settings.notificationsEnabled,
              onChanged: (val) => settings.updateNotificationStatus(val),
              activeColor: AppTheme.primary,
            ),
            const Divider(),

            // ─── Language Toggle ────────────────────────────────────────
            _LanguageToggle(
              currentLocale: settings.locale,
              onChanged: (val) async {
                if (val != null) {
                  await settings.updateLocale(val);
                  await auth.updateLocale(val);
                  await serviceProvider.fetchServices(locale: val);
                }
              },
            ),
            const Divider(),

            // ─── Theme Toggle ───────────────────────────────────────────
            _ThemeToggle(
              currentThemeMode: themeProvider.themeMode,
              onChanged: (mode) {
                if (mode != null) {
                  themeProvider.setThemeMode(mode);
                }
              },
            ),
            const Divider(),

            // ─── About ──────────────────────────────────────────────────
            ListTile(
              title: Text(l10n.aboutUs, style: theme.textTheme.titleMedium),
              onTap: () => Navigator.pushNamed(context, AppRoutes.about),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.hintColor,
              ),
            ),

            // ─── FAQ ─────────────────────────────────────────────────────
            ListTile(
              title: Text(l10n.faq, style: theme.textTheme.titleMedium),
              onTap: () => Navigator.pushNamed(context, AppRoutes.faq),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.hintColor,
              ),
            ),

            // ─── Terms ──────────────────────────────────────────────────
            ListTile(
              title: Text(l10n.terms, style: theme.textTheme.titleMedium),
              onTap: () => Navigator.pushNamed(context, AppRoutes.terms),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.hintColor,
              ),
            ),

            // ─── Privacy Policy ──────────────────────────────────────────
            ListTile(
              title: Text(
                l10n.privacyPolicy,
                style: theme.textTheme.titleMedium,
              ),
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.privacyPolicy),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.hintColor,
              ),
            ),

            // ─── Contact Us ─────────────────────────────────────────────
            ListTile(
              title: Text(l10n.contactUs, style: theme.textTheme.titleMedium),
              onTap: () => Navigator.pushNamed(context, AppRoutes.contactUs),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.hintColor,
              ),
            ),
            const Divider(),

            // ─── Delete Account ─────────────────────────────────────────
            ListTile(
              title: Text(
                l10n.deleteAccount,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.error,
                ),
              ),
              onTap: () => _confirmLogout(context, auth, l10n, theme),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 20),

            // ─── Version ────────────────────────────────────────────────
            Center(
              child: Text(
                '${l10n.version} ${AppConfig.appVersion}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context,
      AuthProvider auth,
      AppLocalizations l10n,
      ThemeData theme,
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

// ─── Language Toggle Widgets ──────────────────────────────────────────
class _LanguageToggle extends StatelessWidget {
  final String currentLocale;
  final ValueChanged<String?> onChanged;

  const _LanguageToggle({
    required this.currentLocale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnglish = currentLocale == 'en';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            'Language',
            style: theme.textTheme.titleMedium,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SegmentOption(
                  isSelected: isEnglish,
                  onTap: () => onChanged('en'),
                  leading: const FlagIcon(emoji: '🇬🇧', height: 16),
                  label: 'English',
                ),
              ),
              Expanded(
                child: _SegmentOption(
                  isSelected: !isEnglish,
                  onTap: () => onChanged('sw'),
                  leading: const FlagIcon(emoji: '🇹🇿', height: 16),
                  label: 'Kiswahili',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Theme Toggle Widgets ──────────────────────────────────────────────
class _ThemeToggle extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode?> onChanged;

  const _ThemeToggle({
    required this.currentThemeMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            'Theme',
            style: theme.textTheme.titleMedium,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SegmentOption(
                  isSelected: currentThemeMode == ThemeMode.light,
                  onTap: () => onChanged(ThemeMode.light),
                  leading: const Icon(Icons.light_mode_rounded, size: 16),
                  label: 'Light',
                ),
              ),
              Expanded(
                child: _SegmentOption(
                  isSelected: currentThemeMode == ThemeMode.dark,
                  onTap: () => onChanged(ThemeMode.dark),
                  leading: const Icon(Icons.dark_mode_rounded, size: 16),
                  label: 'Dark',
                ),
              ),
              Expanded(
                child: _SegmentOption(
                  isSelected: currentThemeMode == ThemeMode.system,
                  onTap: () => onChanged(ThemeMode.system),
                  leading: const Icon(Icons.settings_suggest_rounded, size: 16),
                  label: 'System',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared Segment Option ────────────────────────────────────────────
/// A reusable, overflow-safe segment used by both the language and
/// theme toggles. Shows a leading icon (or flag) + optional checkmark
/// + label, all constrained with Flexible to prevent overflow.
class _SegmentOption extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget leading;
  final String label;

  const _SegmentOption({
    required this.isSelected,
    required this.onTap,
    required this.leading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? AppTheme.secondary : AppTheme.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_circle_rounded,
                color: activeColor,
                size: 14,
              ),
              const SizedBox(width: 4),
            ],
            // Leading icon/flag — fades in color when not selected
            Opacity(
              opacity: isSelected ? 1.0 : 0.6,
              child: IconTheme(
                data: IconThemeData(
                  color: isSelected ? activeColor : theme.hintColor,
                  size: 16,
                ),
                child: leading,
              ),
            ),
            const SizedBox(width: 6),
            // Label — Flexible + ellipsis prevents the overflow you saw
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? activeColor
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}