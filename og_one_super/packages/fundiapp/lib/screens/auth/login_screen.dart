// ============================================================
//  FundiApp — Login screen (refined UI – NearbyFundi style)
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
import '../../widgets/flag_icon.dart';
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
          return FlagIcon(emoji: emoji, height: height);
        },
      ),
    );
  }
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
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
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
    final auth = context.watch<AuthProvider>();

    final isDark = theme.brightness == Brightness.dark;
    final isSmall = MediaQuery.sizeOf(context).width < 380;
    final topInset = MediaQuery.paddingOf(context).top;

    final canExitToHost =
    Navigator.of(context, rootNavigator: true).canPop();

    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;
    final primaryText = isDark ? Colors.white : AppTheme.primary;
    final linkColor = isDark ? AppTheme.secondary : AppTheme.primary;

    return Scaffold(
      backgroundColor:
      isDark ? AppTheme.darkBackground : AppTheme.scaffoldLight,
      body: LoadingOverlay(
        isLoading: auth.isLoading,
        child: Stack(
          children: [
            // ── Hero gradient ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topInset + 250,
              child: const _HeroBackground(),
            ),

            // ── Scrolling content ──
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isSmall ? 16 : 20,
                    12,
                    isSmall ? 16 : 20,
                    24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        // ── Top bar ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (canExitToHost)
                              _GlassIconButton(
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
                                _GlassIconButton(
                                  icon: Icons.language_rounded,
                                  tooltip: l10n.language,
                                  onTap: () =>
                                      _showLanguageSheet(settings, l10n),
                                ),
                                const SizedBox(width: 8),
                                _GlassIconButton(
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

                        const SizedBox(height: 14),

                        // ── Brand on hero ──
                        const _BrandHeader(),

                        const SizedBox(height: 26),

                        // ── Form card ──
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            isSmall ? 20 : 24,
                            26,
                            isSmall ? 20 : 24,
                            22,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.4 : 0.10),
                                blurRadius: 40,
                                offset: const Offset(0, 18),
                                spreadRadius: -6,
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.welcomeBack,
                                  style: TextStyle(
                                    fontSize: isSmall ? 24 : 26,
                                    fontWeight: FontWeight.w800,
                                    color: primaryText,
                                    letterSpacing: -0.6,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.signInManage,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: mutedText,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // Email / Phone toggle
                                _LoginToggle(
                                  isEmailLogin: _isEmailLogin,
                                  isDark: isDark,
                                  mutedText: mutedText,
                                  enabled: !auth.isLoading,
                                  onChanged: (isEmail) => setState(() {
                                    _isEmailLogin = isEmail;
                                  }),
                                ),

                                const SizedBox(height: 18),

                                // Identifier
                                if (_isEmailLogin)
                                  TextFormField(
                                    controller: _emailController,
                                    enabled: !auth.isLoading,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    style: TextStyle(
                                        fontSize: 15, color: primaryText),
                                    decoration: _modernInputDecoration(
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
                                        mutedText: mutedText,
                                        enabled: !auth.isLoading,
                                        onTap: _openCountrySheet,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _phoneController,
                                          enabled: !auth.isLoading,
                                          keyboardType: TextInputType.phone,
                                          textInputAction:
                                          TextInputAction.next,
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: primaryText),
                                          decoration: _modernInputDecoration(
                                            context,
                                            hint: '712345678',
                                            icon: Icons.phone_outlined,
                                          ),
                                          validator: (v) {
                                            if (v == null ||
                                                v.trim().isEmpty) {
                                              return 'Enter phone number';
                                            }
                                            final digits = v
                                                .trim()
                                                .replaceAll(
                                                RegExp(r'[^0-9]'), '');
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
                                  enabled: !auth.isLoading,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(
                                      fontSize: 15, color: primaryText),
                                  decoration: _modernInputDecoration(
                                    context,
                                    hint: l10n.password,
                                    icon: Icons.lock_outline_rounded,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        size: 20,
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
                                    _CompactCheckbox(
                                      value: _rememberMe,
                                      onChanged: auth.isLoading
                                          ? null
                                          : (v) => setState(
                                              () => _rememberMe = v ?? false),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: primaryText.withOpacity(0.75),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: auth.isLoading
                                          ? null
                                          : () => Navigator.pushNamed(
                                        context,
                                        AppRoutes.forgot,
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        l10n.forgotPassword,
                                        style: TextStyle(
                                          color: linkColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Terms
                                _TermsRow(
                                  value: _termsAccepted,
                                  enabled: !auth.isLoading,
                                  isDark: isDark,
                                  textColor: primaryText,
                                  onChanged: (v) => setState(
                                          () => _termsAccepted = v ?? false),
                                ),

                                const SizedBox(height: 22),

                                // Sign In
                                CustomButton(
                                  text: l10n.signIn,
                                  onPressed:
                                  auth.isLoading ? null : _handleLogin,
                                  isLoading: auth.isLoading,
                                ),

                                const SizedBox(height: 20),

                                // Sign up
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n.dontHaveAccount,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: mutedText,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: auth.isLoading
                                          ? null
                                          : _handleSignUp,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        l10n.signUp,
                                        style: TextStyle(
                                          color: linkColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _modernInputDecoration(
      BuildContext context, {
        required String hint,
        required IconData icon,
        Widget? suffix,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.hintColor.withOpacity(0.65),
        fontSize: 14.5,
      ),
      prefixIcon: Icon(icon, size: 20, color: theme.hintColor),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : _kFieldTint,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: BorderSide(
          color: isDark ? AppTheme.secondary : AppTheme.primary,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
    );
  }
}

// ============================================================
//  HERO BACKGROUND
// ============================================================
class _HeroBackground extends StatelessWidget {
  const _HeroBackground();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.navy900, AppTheme.primary],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: _Blob(size: 200, color: Colors.white.withOpacity(0.07)),
            ),
            Positioned(
              bottom: -70,
              left: -50,
              child: _Blob(size: 190, color: Colors.white.withOpacity(0.05)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  BRAND HEADER (on the hero)
// ============================================================
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.14),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Image.asset(
            'assets/images/fundiapp-logo.png',
            package: _kAssetPackage,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.handyman_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FundiApp',
                style: TextStyle(
                  inherit: true,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Hire. Manage. Get it done.',
                style: TextStyle(
                  inherit: true,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  color: Colors.white.withOpacity(0.78),
                ),
              ),
            ],
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
  final bool isDark;
  final Color mutedText;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _LoginToggle({
    required this.isEmailLogin,
    required this.isDark,
    required this.mutedText,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : _kFieldTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _seg(
            label: 'Email',
            icon: Icons.email_outlined,
            active: isEmailLogin,
            onTap: enabled ? () => onChanged(true) : null,
          ),
          _seg(
            label: 'Phone',
            icon: Icons.phone_outlined,
            active: !isEmailLogin,
            onTap: enabled ? () => onChanged(false) : null,
          ),
        ],
      ),
    );
  }

  Widget _seg({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback? onTap,
  }) {
    final color = active ? Colors.white : mutedText;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: color,
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
//  COUNTRY BUTTON
// ============================================================
class _CountryButton extends StatelessWidget {
  final Country country;
  final bool isDark;
  final Color mutedText;
  final bool enabled;
  final VoidCallback onTap;

  const _CountryButton({
    required this.country,
    required this.isDark,
    required this.mutedText,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? Colors.white.withOpacity(0.05) : _kFieldTint,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFlag(country.name, country.flag, 20),
              const SizedBox(width: 6),
              Text(
                country.dialCode,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: mutedText, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  TERMS ROW
// ============================================================
class _TermsRow extends StatelessWidget {
  final bool value;
  final bool enabled;
  final bool isDark;
  final Color textColor;
  final ValueChanged<bool?> onChanged;

  const _TermsRow({
    required this.value,
    required this.enabled,
    required this.isDark,
    required this.textColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final linkColor = isDark ? AppTheme.secondary : AppTheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompactCheckbox(
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: textColor.withOpacity(0.7),
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(
                    color: linkColor,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap =
                        () => Navigator.pushNamed(context, AppRoutes.terms),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: linkColor,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () =>
                        Navigator.pushNamed(context, AppRoutes.privacy),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const _CompactCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ============================================================
//  SHARED PRIMITIVES
// ============================================================
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

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
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
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
    final activeColor = isDark ? AppTheme.secondary : AppTheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: selected ? activeColor.withOpacity(0.1) : Colors.transparent,
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
                  : Theme.of(context).dividerColor.withOpacity(0.35),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              if (selected) ...[
                Icon(Icons.check_circle_rounded, color: activeColor, size: 20),
                const SizedBox(width: 12),
              ],
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: selected ? activeColor : textColor,
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
                  color: selected ? activeColor : textColor,
                ),
              ),
            ],
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

// ============================================================
//  COUNTRY SHEET
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
      c.name.toLowerCase().contains(q) || c.dialCode.contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? AppTheme.secondary : AppTheme.primary;
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
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor:
                  isDark ? Colors.white.withOpacity(0.05) : _kFieldTint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                child: Text(
                  'No country found',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor),
                ),
              )
                  : ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final c = _filtered[i];
                  final isSelected = c.name == widget.selected.name &&
                      c.dialCode == widget.selected.dialCode;
                  return ListTile(
                    leading: _buildFlag(c.name, c.flag, 24),
                    title: Text(
                      c.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? activeColor
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c.dialCode,
                          style: TextStyle(color: theme.hintColor),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded,
                              size: 18, color: activeColor),
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