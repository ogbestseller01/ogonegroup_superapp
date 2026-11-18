// lib/widgets/register_shell.dart
//
// Shared, theme-aware shell for the fundi registration flow.
// Same visual language as LoginScreen: hero gradient, rounded card,
// language + theme buttons, light/dark aware.
//
// Layout (fixed header, scrollable body, pinned footer):
//   ┌─────────────────────────────┐
//   │  Hero gradient (scrolls)    │
//   │  Card content (scrolls)     │
//   ├─────────────────────────────┤
//   │  [ Continue ]  (PINNED)     │
//   └─────────────────────────────┘

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/country.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import 'custom_button.dart';
import 'flag_icon.dart';
import 'loading_overlay.dart';

const String _kAssetPackage = 'fundiapp_sdk';
const Color _kFieldTint = Color(0xFFF1F5FB);

// ============================================================
//  PALETTE
// ============================================================
class RegPalette {
  final bool isDark;
  final Color bg, card, muted, text, link, field;

  const RegPalette._(
      this.isDark,
      this.bg,
      this.card,
      this.muted,
      this.text,
      this.link,
      this.field,
      );

  factory RegPalette.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RegPalette._(
      dark,
      dark ? AppTheme.darkBackground : AppTheme.scaffoldLight,
      dark ? AppTheme.darkSurface : Colors.white,
      dark ? AppTheme.darkTextSecondary : AppTheme.greyText,
      dark ? Colors.white : AppTheme.primary,
      dark ? AppTheme.secondary : AppTheme.primary,
      dark ? Colors.white.withOpacity(0.05) : _kFieldTint,
    );
  }
}

// ============================================================
//  HELPERS
// ============================================================
String? _flagAsset(String countryName) {
  switch (countryName.toLowerCase()) {
    case 'tanzania':
      return 'assets/images/tzflug.png';
    case 'english':
    case 'united kingdom':
      return 'assets/images/englishflug.png';
    default:
      return null;
  }
}

Widget regFlag(String name, String emoji, double height) {
  final asset = _flagAsset(name);
  if (asset != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.asset(
        asset,
        package: _kAssetPackage,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => FlagIcon(emoji: emoji, height: height),
      ),
    );
  }
  return FlagIcon(emoji: emoji, height: height);
}

void regSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        error ? Theme.of(context).colorScheme.error : AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
}

InputDecoration regInputDecoration(
    BuildContext context, {
      required String hint,
      required IconData icon,
      Widget? suffix,
    }) {
  final theme = Theme.of(context);
  final p = RegPalette.of(context);

  OutlineInputBorder border(Color? c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide:
    c == null ? BorderSide.none : BorderSide(color: c, width: w),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle:
    TextStyle(color: theme.hintColor.withOpacity(0.65), fontSize: 14.5),
    prefixIcon: Icon(icon, size: 20, color: theme.hintColor),
    suffixIcon: suffix,
    filled: true,
    fillColor: p.field,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(null),
    enabledBorder: border(null),
    focusedBorder: border(p.link, 1.8),
    errorBorder: border(Colors.redAccent, 1.4),
    focusedErrorBorder: border(Colors.redAccent, 1.8),
  );
}

// ============================================================
//  SHELL
// ============================================================
class RegisterShell extends StatelessWidget {
  final int step;
  final int total;
  final String title;
  final String subtitle;
  final Widget child;

  /// Primary button. Null = disabled. Hidden when [showNext] is false.
  final VoidCallback? onNext;
  final String? nextLabel;
  final bool showNext;

  /// Custom widget rendered under the primary button (used instead of / with next).
  final Widget? bottom;

  final VoidCallback? onBack;
  final bool backEnabled;
  final bool isLoading;

  const RegisterShell({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onNext,
    this.nextLabel,
    this.showNext = true,
    this.bottom,
    this.onBack,
    this.backEnabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = RegPalette.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isSmall = MediaQuery.sizeOf(context).width < 380;
    final canGoBack = onBack != null || Navigator.of(context).canPop();
    final showFooter = showNext || bottom != null;

    return Scaffold(
      backgroundColor: p.bg,
      resizeToAvoidBottomInset: true,
      body: LoadingOverlay(
        isLoading: isLoading,
        child: Column(
          children: [
            // ═══════════════════════════════════════════
            //  SCROLLABLE REGION (hero + card content)
            // ═══════════════════════════════════════════
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    // ── Hero ──
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        isSmall ? 16 : 20,
                        topInset + 12,
                        isSmall ? 16 : 20,
                        28,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.navy900, AppTheme.primary],
                        ),
                        borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(36)),
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (canGoBack)
                                    _GlassIconButton(
                                      icon: Icons.arrow_back_rounded,
                                      tooltip: l10n.regBack,
                                      onTap: backEnabled
                                          ? (onBack ??
                                              () => Navigator.of(context)
                                              .maybePop())
                                          : null,
                                    )
                                  else
                                    const SizedBox(width: 44, height: 44),
                                  const Spacer(),
                                  _GlassIconButton(
                                    icon: Icons.language_rounded,
                                    tooltip: l10n.language,
                                    onTap: () => _showLanguageSheet(context),
                                  ),
                                  const SizedBox(width: 8),
                                  _GlassIconButton(
                                    icon: p.isDark
                                        ? Icons.dark_mode_rounded
                                        : Icons.light_mode_rounded,
                                    tooltip: l10n.themeLabel,
                                    onTap: () => _showThemeSheet(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                l10n.regStepOf(step, total),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: (step / total).clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor:
                                  Colors.white.withOpacity(0.2),
                                  valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      AppTheme.secondary),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: isSmall ? 22 : 25,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.15,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.35,
                                  color: Colors.white.withOpacity(0.82),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Card (content only — no button inside) ──
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isSmall ? 16 : 20,
                        20,
                        isSmall ? 16 : 20,
                        showFooter ? 12 : 24 + bottomInset,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            isSmall ? 18 : 22,
                            24,
                            isSmall ? 18 : 22,
                            22,
                          ),
                          decoration: BoxDecoration(
                            color: p.card,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(p.isDark ? 0.4 : 0.08),
                                blurRadius: 36,
                                offset: const Offset(0, 16),
                                spreadRadius: -6,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ═══════════════════════════════════════════
            //  PINNED FOOTER (always visible)
            // ═══════════════════════════════════════════
            if (showFooter)
              _PinnedFooter(
                palette: p,
                isSmall: isSmall,
                bottomInset: bottomInset,
                isLoading: isLoading,
                showNext: showNext,
                onNext: onNext,
                nextLabel: nextLabel ?? l10n.next,
                bottom: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  PINNED FOOTER (private)
// ============================================================
class _PinnedFooter extends StatelessWidget {
  final RegPalette palette;
  final bool isSmall;
  final double bottomInset;
  final bool isLoading;
  final bool showNext;
  final VoidCallback? onNext;
  final String nextLabel;
  final Widget? bottom;

  const _PinnedFooter({
    required this.palette,
    required this.isSmall,
    required this.bottomInset,
    required this.isLoading,
    required this.showNext,
    required this.onNext,
    required this.nextLabel,
    required this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(palette.isDark ? 0.4 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        isSmall ? 16 : 20,
        12,
        isSmall ? 16 : 20,
        12 + bottomInset,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showNext)
                CustomButton(
                  text: nextLabel,
                  onPressed: isLoading ? null : onNext,
                  isLoading: isLoading,
                  isDisabled: onNext == null || isLoading,
                ),
              if (bottom != null) ...[
                if (showNext) const SizedBox(height: 10),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  COUNTRY PICKER
// ============================================================
Future<Country?> showRegCountryPicker(
    BuildContext context,
    List<Country> countries,
    Country selected,
    ) {
  final p = RegPalette.of(context);
  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: p.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _CountrySheet(countries: countries, selected: selected),
  );
}

class _CountrySheet extends StatefulWidget {
  final List<Country> countries;
  final Country selected;
  const _CountrySheet({required this.countries, required this.selected});

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  late List<Country> _filtered = widget.countries;

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.countries
          : widget.countries
          .where((c) =>
      c.name.toLowerCase().contains(q) || c.dialCode.contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final p = RegPalette.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                onChanged: _filter,
                style: TextStyle(color: p.text),
                decoration: regInputDecoration(
                  context,
                  hint: l10n.regSearchCountry,
                  icon: Icons.search_rounded,
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                child: Text(
                  l10n.regNoCountryFound,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor),
                ),
              )
                  : ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final c = _filtered[i];
                  final sel = c.name == widget.selected.name &&
                      c.dialCode == widget.selected.dialCode;
                  return ListTile(
                    leading: regFlag(c.name, c.flag, 24),
                    title: Text(
                      c.name,
                      style: TextStyle(
                        fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel
                            ? p.link
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.dialCode,
                            style: TextStyle(color: theme.hintColor)),
                        if (sel) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded,
                              size: 18, color: p.link),
                        ],
                      ],
                    ),
                    onTap: () => Navigator.pop(context, c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  LANGUAGE / THEME SHEETS
// ============================================================
void _showLanguageSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final settings = context.read<SettingsProvider>();

  _showSheet(context, l10n.language, [
    _SheetTile(
      title: 'English',
      leading: regFlag('English', '🇬🇧', 18),
      selected: settings.locale == 'en',
      onTap: () async {
        await settings.updateLocale('en');
        if (context.mounted) Navigator.pop(context);
      },
    ),
    const SizedBox(height: 10),
    _SheetTile(
      title: 'Kiswahili',
      leading: regFlag('Tanzania', '🇹🇿', 18),
      selected: settings.locale == 'sw',
      onTap: () async {
        await settings.updateLocale('sw');
        if (context.mounted) Navigator.pop(context);
      },
    ),
  ]);
}

void _showThemeSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final themeProvider = context.read<ThemeProvider>();

  _showSheet(context, l10n.themeLabel, [
    _SheetTile(
      title: l10n.themeLight,
      leading: const Icon(Icons.light_mode_rounded),
      selected: !themeProvider.isDarkMode,
      onTap: () {
        themeProvider.setThemeMode(ThemeMode.light);
        Navigator.pop(context);
      },
    ),
    const SizedBox(height: 10),
    _SheetTile(
      title: l10n.themeDark,
      leading: const Icon(Icons.dark_mode_rounded),
      selected: themeProvider.isDarkMode,
      onTap: () {
        themeProvider.setThemeMode(ThemeMode.dark);
        Navigator.pop(context);
      },
    ),
  ]);
}

void _showSheet(BuildContext context, String title, List<Widget> children) {
  final p = RegPalette.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: p.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.isDark ? AppTheme.darkBorder : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class _SheetTile extends StatelessWidget {
  final String title;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  const _SheetTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final p = RegPalette.of(context);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: selected ? p.link.withOpacity(0.1) : Colors.transparent,
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
                  ? p.link
                  : Theme.of(context).dividerColor.withOpacity(0.35),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              if (selected) ...[
                Icon(Icons.check_circle_rounded, color: p.link, size: 20),
                const SizedBox(width: 12),
              ],
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: selected ? p.link : textColor,
                    size: 20,
                  ),
                  child: leading!,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? p.link : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(onTap == null ? 0.08 : 0.16),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 22,
              color: Colors.white.withOpacity(onTap == null ? 0.5 : 1),
            ),
          ),
        ),
      ),
    );
  }
}