// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../providers/settings_provider.dart';
// Import the new static pages
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
        padding: const EdgeInsets.all(20),
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

          // ========== ABOUT & SUPPORT ==========
          _SectionTitle(title: t.about), // Or use t.support if you add it
          const SizedBox(height: 12),
          _SettingsCard(
            children: [
              // Version Info
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

              // --- NEW STATIC PAGES MENU ITEMS ---
              _SettingsAction(
                title: t.about, // Assuming t.about exists, or use 'About Us'
                icon: Icons.info_outline_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
              const _Divider(),
              _SettingsAction(
                title: t.contactUs, // Add to AppStrings
                icon: Icons.contact_support_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactScreen()),
                ),
              ),
              const _Divider(),
              _SettingsAction(
                title: t.termsConditions, // Add to AppStrings
                icon: Icons.description_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsScreen()),
                ),
              ),
              const _Divider(),
              _SettingsAction(
                title: t.rateApp, // Add to AppStrings
                icon: Icons.star_outline_rounded,
                onTap: () {
                  // Handle rate app logic here (e.g., show dialog or open store)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rate App feature coming soon!')),
                  );
                },
              ),
              const _Divider(),
              _SettingsAction(
                title: t.comingSoon, // Add to AppStrings
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
}

// ========== EXISTING WIDGETS ==========

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white70 : Colors.grey.shade600,
        letterSpacing: 0.3,
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
            ? Border.all(color: AppTheme.darkBorder.withOpacity(0.5))
            : null,
        boxShadow: isDark
            ? null
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                    : (isDark ? Colors.white : Colors.grey.shade600),
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

// ========== NEW REUSABLE WIDGET FOR STATIC PAGES ==========

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
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isDark ? Colors.white : Colors.grey.shade600,
              ),
            ),
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
              size: 16,
              color: isDark ? Colors.white54 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}