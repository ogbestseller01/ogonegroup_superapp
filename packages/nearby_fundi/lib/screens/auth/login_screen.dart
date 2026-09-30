// packages/nearby_fundi/lib/screens/auth/login_screen.dart
// ============================================================
//  NearbyFundi — Login screen
//
//  Runs two ways:
//    * Standalone  (root MaterialApp of this SDK)
//    * Embedded    (mounted inside the super app via NearbyFundiMiniApp)
//
//  When embedded, a back arrow appears top-left so the user can pop
//  back to the super-app dashboard.
// ============================================================

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../config/country_codes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/country.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/flag_icon.dart';

/// Package name of this SDK (must match `name:` in pubspec.yaml).
/// Needed so assets resolve when this code runs inside the super app.
const String _kAssetPackage = 'nearbyfundi_sdk';

/// Faint brand tint used behind form fields in light mode.
const Color _kFieldTint = Color(0xFFF4F7F6);

/// Google OAuth server client ID — replace with your own per environment.
const String _kGoogleServerClientId =
    '217153819583-i53f9rsb46uiid53ikuiv6r68o93qe4s.apps.googleusercontent.com';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isEmailMode = true;

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
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────
  void _snack(String message, {bool error = true}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppTheme.error : AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  /// Full phone ready for backend (e.g. 255679117291).
  /// Strips a leading 0 so users can type either 0679… or 679…
  String get _fullPhone {
    String digits = _identifierController.text
        .trim()
        .replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    final dialCode = _selectedCountry.dialCode.replaceAll('+', '');
    return '$dialCode$digits';
  }

  // ─────────────────────────────────────────────
  // Email / Phone login
  // ─────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      _snack(AppLocalizations.of(context)!.pleaseAcceptTerms,
          error: false);
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final identifier =
    _isEmailMode ? _identifierController.text.trim() : _fullPhone;

    final success = await auth.login(
      identifier,
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (auth.errorMessage != null) {
      _snack(auth.errorMessage!);
    }
  }

  // ─────────────────────────────────────────────
  // Google Sign-In
  // ─────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    auth.clearError();

    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: _kGoogleServerClientId,
        scopes: const ['email', 'profile'],
      );

      await googleSignIn.signOut(); // force account picker
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to obtain ID token');
      }

      final success = await auth.loginWithGoogle(idToken);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else if (auth.errorMessage != null) {
        _snack(auth.errorMessage!);
      }
    } catch (e) {
      debugPrint('❌ Google sign-in failed: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('Google sign-in failed: $e');
    }
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
  // Language / Theme sheets
  // ─────────────────────────────────────────────
  Future<void> _changeLanguage(
      BuildContext sheetCtx,
      String code,
      SettingsProvider settings,
      AuthProvider auth,
      ServiceProvider serviceProvider,
      ) async {
    try {
      await settings.updateLocale(code);
      await auth.updateLocale(code);
      await serviceProvider.fetchServices(locale: code);
    } catch (e) {
      debugPrint('⚠️ Language change to "$code" failed: $e');
    }
    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
  }

  void _showLanguageSheet(
      SettingsProvider settings,
      AuthProvider auth,
      ServiceProvider serviceProvider,
      AppLocalizations l10n,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _showAppSheet(
      title: l10n.language,
      isDark: isDark,
      children: [
        _SheetTile(
          title: 'English',
          leading: const FlagIcon(emoji: '🇬🇧', height: 18),
          selected: settings.locale == 'en',
          onTap: () => _changeLanguage(
              context, 'en', settings, auth, serviceProvider),
        ),
        const SizedBox(height: 10),
        _SheetTile(
          title: 'Kiswahili',
          leading: const FlagIcon(emoji: '🇹🇿', height: 18),
          selected: settings.locale == 'sw',
          onTap: () => _changeLanguage(
              context, 'sw', settings, auth, serviceProvider),
        ),
      ],
    );
  }

  void _showThemeSheet(ThemeProvider themeProvider, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _showAppSheet(
      title: l10n.theme,
      isDark: isDark,
      children: [
        _SheetTile(
          title: 'Light',
          leading: const Icon(Icons.light_mode_rounded),
          selected: themeProvider.themeMode == ThemeMode.light,
          onTap: () {
            themeProvider.setThemeMode(ThemeMode.light);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 10),
        _SheetTile(
          title: 'Dark',
          leading: const Icon(Icons.dark_mode_rounded),
          selected: themeProvider.themeMode == ThemeMode.dark,
          onTap: () {
            themeProvider.setThemeMode(ThemeMode.dark);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 10),
        _SheetTile(
          title: 'System',
          leading: const Icon(Icons.brightness_auto_rounded),
          selected: themeProvider.themeMode == ThemeMode.system,
          onTap: () {
            themeProvider.setThemeMode(ThemeMode.system);
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
    final auth = context.read<AuthProvider>();
    final serviceProvider = context.read<ServiceProvider>();

    final isDark = theme.brightness == Brightness.dark;
    final isSmall = MediaQuery.sizeOf(context).width < 380;

    // True only when embedded inside the host super-app.
    final canExitToHost =
    Navigator.of(context, rootNavigator: true).canPop();

    final bgGradient = isDark
        ? const [
      AppTheme.darkBackground,
      AppTheme.darkSurface,
      AppTheme.navy900,
    ]
        : const [
      AppTheme.scaffoldLight,
      AppTheme.navy50,
      AppTheme.light,
    ];

    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final mutedText = isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;
    final primaryText = theme.colorScheme.onSurface;

    final themeIcon = switch (themeProvider.themeMode) {
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative blobs
              Positioned(
                top: -80,
                right: -60,
                child: _Blob(
                  size: 220,
                  color:
                  AppTheme.primary.withOpacity(isDark ? 0.12 : 0.06),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: _Blob(
                  size: 260,
                  color:
                  AppTheme.primary.withOpacity(isDark ? 0.08 : 0.05),
                ),
              ),

              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 18 : 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        // ── Top bar ────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (canExitToHost)
                              _ElegantIconButton(
                                icon: Icons.arrow_back_rounded,
                                tooltip: 'Back',
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
                                    settings,
                                    auth,
                                    serviceProvider,
                                    l10n,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _ElegantIconButton(
                                  icon: themeIcon,
                                  tooltip: l10n.theme,
                                  onTap: () =>
                                      _showThemeSheet(themeProvider, l10n),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ── Card ──────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            isSmall ? 22 : 28,
                            28,
                            isSmall ? 22 : 28,
                            28,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                    isDark ? 0.35 : 0.08),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                                spreadRadius: -4,
                              ),
                              BoxShadow(
                                color:
                                AppTheme.primary.withOpacity(0.06),
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
                                // NearbyFundi brand lockup
                                const _BrandHeader(),

                                const SizedBox(height: 22),

                                Text(
                                  l10n.welcomeBack,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmall ? 26 : 28,
                                    fontWeight: FontWeight.w800,
                                    color: primaryText,
                                    letterSpacing: -0.6,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.signInToContinue,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: mutedText,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Email / Phone toggle
                                _LoginToggle(
                                  isEmailMode: _isEmailMode,
                                  isDark: isDark,
                                  mutedText: mutedText,
                                  enabled: !_isLoading,
                                  onChanged: (isEmail) => setState(() {
                                    _isEmailMode = isEmail;
                                    _identifierController.clear();
                                  }),
                                ),

                                const SizedBox(height: 20),

                                // Identifier (email or phone)
                                if (_isEmailMode)
                                  TextFormField(
                                    controller: _identifierController,
                                    enabled: !_isLoading,
                                    keyboardType:
                                    TextInputType.emailAddress,
                                    textInputAction:
                                    TextInputAction.next,
                                    style: const TextStyle(fontSize: 15),
                                    decoration: _modernInputDecoration(
                                      context,
                                      hint: 'you@example.com',
                                      icon: Icons.email_outlined,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return l10n.enterEmail;
                                      }
                                      final isEmail = RegExp(
                                          r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$')
                                          .hasMatch(v.trim());
                                      if (!isEmail) {
                                        return l10n.enterValidEmail;
                                      }
                                      return null;
                                    },
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
                                        enabled: !_isLoading,
                                        onTap: _openCountrySheet,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextFormField(
                                          controller:
                                          _identifierController,
                                          enabled: !_isLoading,
                                          keyboardType:
                                          TextInputType.phone,
                                          textInputAction:
                                          TextInputAction.next,
                                          style: const TextStyle(
                                              fontSize: 15),
                                          decoration:
                                          _modernInputDecoration(
                                            context,
                                            hint: '679117291',
                                            icon:
                                            Icons.phone_outlined,
                                          ),
                                          validator: (v) {
                                            if (v == null ||
                                                v.trim().isEmpty) {
                                              return 'Please enter phone number';
                                            }
                                            var digits = v
                                                .trim()
                                                .replaceAll(
                                                RegExp(r'[^0-9]'),
                                                '');
                                            if (digits.startsWith('0')) {
                                              digits =
                                                  digits.substring(1);
                                            }
                                            if (!RegExp(r'^[67]\d{8}$')
                                                .hasMatch(digits)) {
                                              return 'Enter a valid 9-digit number (e.g. 679117291)';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 18),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  enabled: !_isLoading,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: _modernInputDecoration(
                                    context,
                                    hint: l10n.enterPassword,
                                    icon: Icons.lock_outline_rounded,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons
                                            .visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        size: 20,
                                        color: mutedText,
                                      ),
                                      onPressed: () => setState(() =>
                                      _obscurePassword =
                                      !_obscurePassword),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return l10n.enterPassword;
                                    }
                                    if (v.length < 6) {
                                      return l10n.passwordMinLength;
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 10),

                                // Remember + Forgot
                                Row(
                                  children: [
                                    _CompactCheckbox(
                                      value: _rememberMe,
                                      onChanged: _isLoading
                                          ? null
                                          : (v) => setState(
                                              () => _rememberMe =
                                              v ?? false),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: primaryText
                                            .withOpacity(0.75),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => Navigator.pushNamed(
                                        context,
                                        AppRoutes.forgot,
                                      ),
                                      style: TextButton.styleFrom(
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                        MaterialTapTargetSize
                                            .shrinkWrap,
                                      ),
                                      child: Text(
                                        l10n.forgotPassword,
                                        style: TextStyle(
                                          color: isDark
                                              ? AppTheme.secondary
                                              : AppTheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Terms
                                _TermsRow(
                                  value: _termsAccepted,
                                  enabled: !_isLoading,
                                  isDark: isDark,
                                  textColor: primaryText,
                                  onChanged: (v) => setState(
                                          () => _termsAccepted = v ?? false),
                                  onTermsTap: () => Navigator.pushNamed(
                                      context, AppRoutes.terms),
                                  onPrivacyTap: () => Navigator.pushNamed(
                                      context, AppRoutes.privacyPolicy),
                                ),

                                const SizedBox(height: 24),

                                // Sign In
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      disabledBackgroundColor:
                                      AppTheme.primary
                                          .withOpacity(0.55),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shadowColor: AppTheme.primary
                                          .withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child:
                                      CircularProgressIndicator(
                                        strokeWidth: 2.6,
                                        valueColor:
                                        AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    )
                                        : Text(
                                      l10n.signIn,
                                      style: const TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Google sign-in (secondary)
                                _GoogleButton(
                                  enabled: !_isLoading,
                                  onPressed: _handleGoogleSignIn,
                                ),

                                const SizedBox(height: 22),

                                // Sign up
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n.dontHaveAccount,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: mutedText,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => Navigator.pushNamed(
                                        context,
                                        AppRoutes.register,
                                      ),
                                      style: TextButton.styleFrom(
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                        MaterialTapTargetSize
                                            .shrinkWrap,
                                      ),
                                      child: Text(
                                        l10n.signUp,
                                        style: TextStyle(
                                          color: isDark
                                              ? AppTheme.secondary
                                              : AppTheme.primary,
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

                        const SizedBox(height: 14),

                        // Footer brand line — reinforces NearbyFundi
                        Text(
                          'NearbyFundi • trusted technicians near you',
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
    );
  }
}

// ============================================================
//  BRAND HEADER  — this is what makes it clearly NearbyFundi
// ============================================================
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Circular badge with NearbyFundi logo (falls back to location pin)
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
            'assets/images/app_icon.png',
            package: _kAssetPackage,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.location_on_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Wordmark
        Text(
          'NearbyFundi',
          style: TextStyle(
            inherit: true,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : AppTheme.primary,
          ),
        ),
        const SizedBox(height: 2),

        // Tagline
        Text(
          'Trusted technicians near you',
          style: TextStyle(
            inherit: true,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
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
  final bool isEmailMode;
  final bool isDark;
  final Color mutedText;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _LoginToggle({
    required this.isEmailMode,
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
            active: isEmailMode,
            onTap: enabled ? () => onChanged(true) : null,
          ),
          _seg(
            label: 'Phone',
            active: !isEmailMode,
            onTap: enabled ? () => onChanged(false) : null,
          ),
        ],
      ),
    );
  }

  Widget _seg({
    required String label,
    required bool active,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: active ? Colors.white : mutedText,
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
              FlagIcon(emoji: country.flag, height: 20),
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
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  const _TermsRow({
    required this.value,
    required this.enabled,
    required this.isDark,
    required this.textColor,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                TextSpan(text: '${l10n.iAgreeToThe} '),
                TextSpan(
                  text: l10n.termsAndConditions,
                  style: TextStyle(
                    color: linkColor,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onTermsTap,
                ),
                TextSpan(text: ' ${l10n.and} '),
                TextSpan(
                  text: l10n.privacyPolicy,
                  style: TextStyle(
                    color: linkColor,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = onPrivacyTap,
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
//  GOOGLE BUTTON
// ============================================================
class _GoogleButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _GoogleButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
        label: const Text(
          'Continue with Google',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
          isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.12),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
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
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withOpacity(0.06),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 22,
              color: isDark ? AppTheme.secondary : AppTheme.primary,
            ),
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
                Icon(Icons.check_circle_rounded,
                    color: activeColor, size: 20),
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
                  fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
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
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : _kFieldTint,
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
                  final isSelected =
                      c.name == widget.selected.name &&
                          c.dialCode == widget.selected.dialCode;
                  return ListTile(
                    leading: FlagIcon(emoji: c.flag, height: 24),
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

// ============================================================
//  INPUT DECORATION
// ============================================================
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