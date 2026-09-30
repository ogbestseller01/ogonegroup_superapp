// ============================================================
//  FundiApp — Login screen
// ============================================================

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../config/country_codes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/country.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/flag_icon.dart';          // ← added
import '../../widgets/loading_overlay.dart';

/// Package name of this SDK (must match `name:` in pubspec.yaml).
const String _kAssetPackage = 'fundiapp_sdk';

/// Faint brand tint used behind form fields in light mode.
const Color _kFieldTint = Color(0xFFF1F5FB);

// ============================================================
//  FLAG HELPERS
// ============================================================
String? _getFlagAssetPath(String countryName) {
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

Widget _buildFlag(String name, String emoji, double height) {
  final assetPath = _getFlagAssetPath(name);
  if (assetPath != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.asset(
        assetPath,
        package: _kAssetPackage,
        height: height,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          // PNG missing → fall back to proper emoji widget
          return FlagIcon(emoji: emoji, height: height);
        },
      ),
    );
  }
  // No PNG for this country → use FlagIcon (works on iOS + Android)
  return FlagIcon(emoji: emoji, height: height);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _rememberMe = false;
  bool _isEmailLogin = true;

  late final List<Country> _countries;
  late Country _selectedCountry;

  @override
  void initState() {
    super.initState();
    _countries = CountryCodes.all;
    _selectedCountry = _countries.firstWhere(
          (c) => c.dialCode == '+255',
      orElse: () => _countries.first,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────
  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          error ? Theme.of(context).colorScheme.error : AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  // ─────────────────────────────────────────────
  // Login
  // ─────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      _snack('Please accept the Terms & Conditions to continue');
      return;
    }

    final identifier =
    _isEmailLogin ? _emailController.text.trim() : _composedPhone();

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success =
    await auth.login(identifier, _passwordController.text.trim());

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (auth.errorMessage != null) {
      _snack(auth.errorMessage!, error: true);
    }
  }

  String _composedPhone() {
    final digits =
    _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final dialCode = _selectedCountry.dialCode.replaceAll('+', '');
    return '$dialCode$digits';
  }

  // ─────────────────────────────────────────────
  // Sign-up navigation (resumes unfinished registration)
  // ─────────────────────────────────────────────
  Future<void> _handleSignUp() async {
    final storedId = await StorageService.getTechnicianId();
    if (!mounted) return;

    if (storedId != null) {
      final auth = context.read<AuthProvider>();
      final step = await auth.getRegistrationStep(storedId);
      if (!mounted) return;

      if (step != null) {
        switch (step) {
          case 1:
            Navigator.pushNamed(context, AppRoutes.registerStep1);
            return;
          case 2:
            Navigator.pushNamed(context, AppRoutes.registerStep2,
                arguments: storedId);
            return;
          case 3:
            Navigator.pushNamed(context, AppRoutes.registerStep3,
                arguments: storedId);
            return;
          case 4:
            Navigator.pushNamed(context, AppRoutes.registerStep4,
                arguments: storedId);
            return;
          default:
            Navigator.pushNamed(context, AppRoutes.registerStep1);
            return;
        }
      }

      await StorageService.clearTechnicianData();
      if (!mounted) return;
    }

    Navigator.pushNamed(context, AppRoutes.registerStep1);
  }

  // ─────────────────────────────────────────────
  // Country picker
  // ─────────────────────────────────────────────
  Future<void> _openCountrySheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CountrySheet(
        countries: _countries,
        selected: _selectedCountry,
      ),
    );

    if (picked != null && mounted) {
      setState(() => _selectedCountry = picked);
    }
  }

  // ─────────────────────────────────────────────
  // Bottom sheets
  // ─────────────────────────────────────────────
  void _showLanguageSheet(SettingsProvider settings, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _showAppSheet(
      title: l10n.language,
      isDark: isDark,
      children: [
        _SheetTile(
          title: 'English',
          leading: _buildFlag('English', '🇬🇧', 18),
          selected: settings.locale == 'en',
          onTap: () async {
            await settings.updateLocale('en');
            if (mounted) Navigator.pop(context);
          },
        ),
        const SizedBox(height: 10),
        _SheetTile(
          title: 'Kiswahili',
          leading: _buildFlag('Tanzania', '🇹🇿', 18),
          selected: settings.locale == 'sw',
          onTap: () async {
            await settings.updateLocale('sw');
            if (mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showThemeSheet(ThemeProvider themeProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _showAppSheet(
      title: 'Theme',
      isDark: isDark,
      children: [
        _SheetTile(
          title: 'Light',
          leading: const Icon(Icons.light_mode_rounded),
          selected: !themeProvider.isDarkMode,
          onTap: () {
            themeProvider.setThemeMode(ThemeMode.light);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 10),
        _SheetTile(
          title: 'Dark',
          leading: const Icon(Icons.dark_mode_rounded),
          selected: themeProvider.isDarkMode,
          onTap: () {
            themeProvider.setThemeMode(ThemeMode.dark);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showAppSheet({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
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
                  color: isDark ? AppTheme.darkBorder : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  inherit: true,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.primary,
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

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = theme.brightness == Brightness.dark;
    final isSmall = MediaQuery.sizeOf(context).width < 380;

    final canExitToHost =
    Navigator.of(context, rootNavigator: true).canPop();

    final bgGradient = isDark
        ? const [
      AppTheme.navy950,
      AppTheme.navy900,
      AppTheme.navy800,
    ]
        : const [
      AppTheme.navy50,
      Color(0xFFF5F8FC),
      Colors.white,
    ];

    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;
    final primaryText = isDark ? Colors.white : AppTheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgGradient,
          ),
        ),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) => LoadingOverlay(
            isLoading: auth.isLoading,
            child: SafeArea(
              child: Stack(
                children: [
                  // Decorative background circles
                  Positioned(
                    top: -80,
                    right: -60,
                    child: _Blob(
                      size: 220,
                      color: AppTheme.primary
                          .withOpacity(isDark ? 0.25 : 0.08),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    left: -80,
                    child: _Blob(
                      size: 260,
                      color: AppTheme.secondary
                          .withOpacity(isDark ? 0.12 : 0.08),
                    ),
                  ),

                  // Scrollable content
                  Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 16 : 22,
                        vertical: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          children: [
                            // ── Top bar ────────────────────────────
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                if (canExitToHost)
                                  _ElegantIconButton(
                                    icon: Icons.arrow_back_rounded,
                                    tooltip: 'Back to app',
                                    onTap: () => Navigator.of(context,
                                        rootNavigator: true)
                                        .maybePop(),
                                  )
                                else
                                  const SizedBox(width: 44, height: 44),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _ElegantIconButton(
                                      icon: Icons.language_rounded,
                                      tooltip: l10n.language,
                                      onTap: () => _showLanguageSheet(
                                          settings, l10n),
                                    ),
                                    const SizedBox(width: 8),
                                    _ElegantIconButton(
                                      icon: themeProvider.isDarkMode
                                          ? Icons.dark_mode_rounded
                                          : Icons.light_mode_rounded,
                                      tooltip: 'Theme',
                                      onTap: () =>
                                          _showThemeSheet(themeProvider),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // ── Card ──────────────────────────────
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.fromLTRB(
                                isSmall ? 20 : 26,
                                26,
                                isSmall ? 20 : 26,
                                26,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(28),
                                border: isDark
                                    ? Border.all(
                                  color: AppTheme.darkBorder,
                                  width: 0.8,
                                )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                        isDark ? 0.4 : 0.08),
                                    blurRadius: 40,
                                    offset: const Offset(0, 16),
                                    spreadRadius: -4,
                                  ),
                                  BoxShadow(
                                    color: AppTheme.primary
                                        .withOpacity(0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    // FundiApp brand lockup
                                    const _BrandHeader(),

                                    const SizedBox(height: 22),

                                    Text(
                                      l10n.welcomeBack,
                                      style: theme
                                          .textTheme.headlineMedium
                                          ?.copyWith(
                                        inherit: true,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                        fontSize: isSmall ? 24 : 26,
                                        color: primaryText,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.signInManage,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        inherit: true,
                                        color: mutedText,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),

                                    const SizedBox(height: 24),

                                    // Email / Phone toggle
                                    _LoginToggle(
                                      isEmailLogin: _isEmailLogin,
                                      mutedText: mutedText,
                                      isDark: isDark,
                                      onChanged: (isEmail) => setState(
                                              () => _isEmailLogin = isEmail),
                                    ),

                                    const SizedBox(height: 22),

                                    // Email or Phone input
                                    if (_isEmailLogin)
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                        TextInputType.emailAddress,
                                        style: TextStyle(
                                            inherit: true,
                                            color: primaryText),
                                        decoration: _decoration(
                                          context,
                                          hint: 'you@example.com',
                                          icon: Icons.email_outlined,
                                        ),
                                        validator: (v) =>
                                        v != null && v.contains('@')
                                            ? null
                                            : 'Enter a valid email',
                                      )
                                    else
                                      Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          _CountryButton(
                                            country: _selectedCountry,
                                            isDark: isDark,
                                            textColor: primaryText,
                                            mutedText: mutedText,
                                            onTap: _openCountrySheet,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _phoneController,
                                              keyboardType:
                                              TextInputType.phone,
                                              style: TextStyle(
                                                  inherit: true,
                                                  color: primaryText),
                                              decoration: _decoration(
                                                context,
                                                hint: '712345678',
                                                icon:
                                                Icons.phone_outlined,
                                              ),
                                              validator: (v) {
                                                if (v == null ||
                                                    v.trim().isEmpty) {
                                                  return 'Enter phone number';
                                                }
                                                final digits = v
                                                    .trim()
                                                    .replaceAll(
                                                    RegExp(r'[^0-9]'),
                                                    '');
                                                if (digits.length < 7 ||
                                                    digits.length > 15) {
                                                  return '7–15 digits required';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),

                                    const SizedBox(height: 16),

                                    // Password
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: TextStyle(
                                          inherit: true,
                                          color: primaryText),
                                      decoration: _decoration(
                                        context,
                                        hint: l10n.password,
                                        icon: Icons.lock_outline_rounded,
                                        suffix: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons
                                                .visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            size: 22,
                                            color: mutedText,
                                          ),
                                          onPressed: () => setState(() =>
                                          _obscurePassword =
                                          !_obscurePassword),
                                        ),
                                      ),
                                      validator: (v) =>
                                      v != null && v.length >= 6
                                          ? null
                                          : 'Min 6 characters',
                                    ),

                                    const SizedBox(height: 10),

                                    // Remember + Forgot
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          onChanged: (v) => setState(() =>
                                          _rememberMe = v ?? false),
                                          activeColor: AppTheme.primary,
                                          checkColor: Colors.white,
                                          materialTapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap,
                                        ),
                                        Text(
                                          'Remember me',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            inherit: true,
                                            color: mutedText,
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pushNamed(
                                                  context, AppRoutes.forgot),
                                          child: Text(
                                            l10n.forgotPassword,
                                            style: const TextStyle(
                                              inherit: true,
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    // Terms checkbox + links
                                    _TermsRow(
                                      value: _termsAccepted,
                                      mutedText: mutedText,
                                      onChanged: (v) => setState(() =>
                                      _termsAccepted = v ?? false),
                                    ),

                                    const SizedBox(height: 22),

                                    CustomButton(
                                      text: l10n.signIn,
                                      onPressed: _handleLogin,
                                      isLoading: auth.isLoading,
                                    ),

                                    const SizedBox(height: 22),

                                    // Sign up row
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          l10n.dontHaveAccount,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            inherit: true,
                                            color: mutedText,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _handleSignUp,
                                          child: Text(
                                            l10n.signUp,
                                            style: const TextStyle(
                                              inherit: true,
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Footer brand line
                            Text(
                              'FundiApp • powered by Netsaf',
                              style: TextStyle(
                                inherit: true,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4,
                                color: mutedText.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Field decoration
  // ─────────────────────────────────────────────
  InputDecoration _decoration(
      BuildContext context, {
        required String hint,
        required IconData icon,
        Widget? suffix,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        inherit: true,
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
      ),
      prefixIcon: Icon(
        icon,
        color: AppTheme.primary.withOpacity(0.85),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? AppTheme.darkSurfaceLight : _kFieldTint,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark
              ? AppTheme.darkBorder
              : AppTheme.borderLight.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
    );
  }
}

// ============================================================
//  BRAND HEADER
// ============================================================
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.navy900, AppTheme.primary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(isDark ? 0.4 : 0.22),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/fundiapp-logo.png',
            package: _kAssetPackage,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.handyman_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'FundiApp',
          style: TextStyle(
            inherit: true,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Hire. Manage. Get it done.',
          style: TextStyle(
            inherit: true,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkTextSecondary
                : AppTheme.greyText,
          ),
        ),
      ],
    );
  }
}

// ============================================================
//  EMAIL / PHONE TOGGLE
// ============================================================
class _LoginToggle extends StatelessWidget {
  final bool isEmailLogin;
  final Color mutedText;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _LoginToggle({
    required this.isEmailLogin,
    required this.mutedText,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceLight : _kFieldTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment(
            label: 'Email',
            active: isEmailLogin,
            onTap: () => onChanged(true),
          ),
          _segment(
            label: 'Phone',
            active: !isEmailLogin,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              inherit: true,
              color: active ? Colors.white : mutedText,
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  COUNTRY BUTTON
// ============================================================
class _CountryButton extends StatelessWidget {
  final Country country;
  final bool isDark;
  final Color textColor;
  final Color mutedText;
  final VoidCallback onTap;

  const _CountryButton({
    required this.country,
    required this.isDark,
    required this.textColor,
    required this.mutedText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppTheme.darkSurfaceLight : _kFieldTint,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorder
                  : AppTheme.borderLight.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFlag(country.name, country.flag, 20),
              const SizedBox(width: 8),
              Text(
                country.dialCode,
                style: TextStyle(
                  inherit: true,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  TERMS CHECKBOX + RICH TEXT
// ============================================================
class _TermsRow extends StatelessWidget {
  final bool value;
  final Color mutedText;
  final ValueChanged<bool?> onChanged;

  const _TermsRow({
    required this.value,
    required this.mutedText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primary,
          checkColor: Colors.white,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  inherit: true,
                  fontSize: 12,
                  color: mutedText,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: const TextStyle(
                      inherit: true,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () =>
                          Navigator.pushNamed(context, AppRoutes.terms),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      inherit: true,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () =>
                          Navigator.pushNamed(context, AppRoutes.privacy),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
//  SHARED PRIMITIVES
// ============================================================
class _ElegantIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ElegantIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? AppTheme.darkSurfaceLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withOpacity(0.06),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: AppTheme.primary),
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.primary;

    return Material(
      color: selected
          ? AppTheme.primary.withOpacity(isDark ? 0.25 : 0.1)
          : Colors.transparent,
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
                  ? AppTheme.primary
                  : (isDark
                  ? AppTheme.darkBorder
                  : AppTheme.borderLight.withOpacity(0.5)),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              if (selected) ...[
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 12),
              ],
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: selected ? AppTheme.primary : textColor,
                    size: 20,
                  ),
                  child: leading!,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: TextStyle(
                  inherit: true,
                  fontSize: 15.5,
                  fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppTheme.primary : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  COUNTRY SHEET  (searchable)
// ============================================================
class _CountrySheet extends StatefulWidget {
  final List<Country> countries;
  final Country selected;

  const _CountrySheet({required this.countries, required this.selected});

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final _searchController = TextEditingController();
  late List<Country> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.countries
          : widget.countries
          .where((c) =>
      c.name.toLowerCase().contains(q) ||
          c.dialCode.contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.primary;
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBorder : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                style: TextStyle(inherit: true, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  hintStyle: TextStyle(inherit: true, color: mutedText),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.primary.withOpacity(0.85),
                  ),
                  filled: true,
                  fillColor:
                  isDark ? AppTheme.darkSurfaceLight : _kFieldTint,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppTheme.primary, width: 1.8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                child: Text(
                  'No country found',
                  style: TextStyle(
                      inherit: true, color: mutedText),
                ),
              )
                  : ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final c = _filtered[i];
                  final isSelected =
                      c.name == widget.selected.name &&
                          c.dialCode == widget.selected.dialCode;
                  return ListTile(
                    leading: _buildFlag(c.name, c.flag, 24),
                    title: Text(
                      c.name,
                      style: TextStyle(
                        inherit: true,
                        color: textColor,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c.dialCode,
                          style: TextStyle(
                              inherit: true, color: mutedText),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
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