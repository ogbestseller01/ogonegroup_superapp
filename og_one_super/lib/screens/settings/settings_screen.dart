// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/language_dropdown.dart';

import 'staticpages/about_screen.dart';
import 'staticpages/contact_screen.dart';
import 'staticpages/terms_screen.dart';
import 'staticpages/coming_soon_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final t = context.t;

    return Scaffold(
      backgroundColor:
      isDark ? AppTheme.darkBackground : const Color(0xFFF4F7FC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          t.settings,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          // ========== APPEARANCE ==========
          _SectionTitle(title: t.appearance),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _ThemeOption(
                title: t.system,
                subtitle: t.followDevice,
                icon: Icons.brightness_auto_rounded,
                selected: settings.themeMode == ThemeMode.system,
                onTap: () => settings.setThemeMode(ThemeMode.system),
              ),
              const _Divider(),
              _ThemeOption(
                title: t.light,
                subtitle: t.lightMode,
                icon: Icons.light_mode_rounded,
                selected: settings.themeMode == ThemeMode.light,
                onTap: () => settings.setThemeMode(ThemeMode.light),
              ),
              const _Divider(),
              _ThemeOption(
                title: t.dark,
                subtitle: t.darkMode,
                icon: Icons.dark_mode_rounded,
                selected: settings.themeMode == ThemeMode.dark,
                onTap: () => settings.setThemeMode(ThemeMode.dark),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ========== LANGUAGE ==========
          _SectionTitle(title: t.language),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    _IconBox(icon: Icons.language_rounded, isDark: isDark),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        t.language,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                    LanguageDropdown(
                      currentCode: settings.locale.languageCode,
                      onChanged: (code) => settings.setLocale(Locale(code)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ========== NOTIFICATIONS ==========
          _SectionTitle(title: t.notifications),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsSwitch(
                title: t.pushNotifications,
                subtitle: t.receivePushNotifications,
                icon: Icons.notifications_active_rounded,
                value: settings.pushEnabled,
                onChanged: settings.setPushEnabled,
              ),
              const _Divider(),
              _SettingsSwitch(
                title: t.promotions,
                subtitle: t.promotionsDesc,
                icon: Icons.local_offer_rounded,
                value: settings.promoNotifications,
                onChanged: settings.setPromoNotifications,
                enabled: settings.pushEnabled,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ========== PRIVACY & DATA ==========
          _SectionTitle(title: t.privacyData),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsAction(
                title: t.privacyPolicy,
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Privacy Policy...')),
                  );
                },
              ),
              const _Divider(),
              _SettingsAction(
                title: t.clearCache,
                icon: Icons.cleaning_services_rounded,
                onTap: () => _showClearCacheDialog(context, settings),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ========== HELP & FEEDBACK ==========
          _SectionTitle(title: t.helpFeedback),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              _SettingsAction(
                title: t.helpCenter,
                icon: Icons.help_outline_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help Center coming soon')),
                  );
                },
              ),
              const _Divider(),
              _SettingsAction(
                title: t.sendFeedback,
                icon: Icons.feedback_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback form coming soon')),
                  );
                },
              ),
              const _Divider(),
              _SettingsAction(
                title: t.contactUs,
                icon: Icons.contact_support_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactScreen()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ========== ABOUT & SUPPORT ==========
          _SectionTitle(title: t.about),
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: isDark ? Colors.white : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        t.version,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      '0.0.1',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const _Divider(),
              _SettingsAction(
                title: t.about,
                icon: Icons.info_outline_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
              const _Divider(),
              _SettingsAction(
                title: t.termsConditions,
                icon: Icons.description_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsScreen()),
                ),
              ),
              const _Divider(),
              _SettingsAction(
                title: t.rateApp,
                icon: Icons.star_outline_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rate App feature coming soon!')),
                  );
                },
              ),
              const _Divider(),
              _SettingsAction(
                title: t.comingSoon,
                icon: Icons.hourglass_empty_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, SettingsProvider settings) {
    final t = context.t;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.clearCache),
        content: Text(t.clearCacheConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () async {
              await settings.clearCache();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.cacheCleared)),
                );
              }
            },
            child: Text(t.clear),
          ),
        ],
      ),
    );
  }
}

// ========== HELPER WIDGETS ==========

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white60 : Colors.grey.shade600,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(color: AppTheme.darkBorder.withOpacity(0.6))
            : null,
        boxShadow: isDark
            ? null
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 0.6,
      color: isDark ? AppTheme.darkBorder : Colors.grey.shade200,
      indent: 16,
      endIndent: 16,
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  const _IconBox({required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 22,
        color: isDark ? Colors.white : Colors.grey.shade700,
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.secondary : AppTheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withOpacity(0.15)
                    : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected
                    ? accent
                    : (isDark ? Colors.white : Colors.grey.shade700),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: accent, size: 22),
          ],
        ),
      ),
    );
  }
}

class _SettingsAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconBox(icon: icon, isDark: isDark),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? Colors.white : AppTheme.primary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: isDark ? Colors.white54 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _IconBox(icon: icon, isDark: isDark),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: AppTheme.primary,
              activeTrackColor: AppTheme.primary.withOpacity(0.45),
              inactiveThumbColor:
              isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              inactiveTrackColor:
              isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}