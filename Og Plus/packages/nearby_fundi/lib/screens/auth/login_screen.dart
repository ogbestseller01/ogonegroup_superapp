
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
import '../../services/social_auth_service.dart';
import '../../widgets/flag_icon.dart';

/// SDK package name.
const String _kAssetPackage = 'nearbyfundi_sdk';

/// SDK assets.
const String _kAppIconAsset = 'assets/icons/app_icon.png';
const String _kAppIconForegroundAsset =
    'assets/icons/app_icon_foreground.png';
const String _kGoogleIconAsset = 'assets/icons/google_signin.png';
const String _kAppleIconAsset = 'assets/icons/apple_signin.png';

const Color _kFieldTint = Color(0xFFF4F7F6);

const bool _kAppleSignInEnabled = true;
const bool _kStrictPlatformSplit = true;
const bool _kShowAppleOnAndroid = false;

bool get _isApplePlatform =>
    defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

bool get _showAppleButton {
  if (!_kAppleSignInEnabled) return false;

  if (_isApplePlatform) return true;

  if (defaultTargetPlatform == TargetPlatform.android) {
    return _kShowAppleOnAndroid;
  }

  return false;
}

bool get _showGoogleButton {
  if (_isApplePlatform) return !_kStrictPlatformSplit;
  return true;
}

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
          (country) => country.dialCode == '+255',
      orElse: () => _countries.first,
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          error ? AppTheme.error : AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  String get _fullPhone {
    var digits = _identifierController.text
        .trim()
        .replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    final dialCode =
    _selectedCountry.dialCode.replaceAll('+', '');

    return '$dialCode$digits';
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      _snack(
        AppLocalizations.of(context)!.pleaseAcceptTerms,
        error: false,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      auth.clearError();

      final identifier = _isEmailMode
          ? _identifierController.text.trim()
          : _fullPhone;

      final success = await auth.login(
        identifier,
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.home,
        );
      } else {
        setState(() => _isLoading = false);

        if (auth.errorMessage != null) {
          _snack(auth.errorMessage!);
        }
      }
    } catch (e) {
      debugPrint('Login failed: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);
      _snack('Login failed. Please try again.');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      auth.clearError();

      final credential = await SocialAuthService.google();

      final success = await auth.loginWithGoogle(
        credential.token,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.home,
        );
      } else {
        setState(() => _isLoading = false);

        if (auth.errorMessage != null) {
          _snack(auth.errorMessage!);
        }
      }
    } on SocialAuthCancelled {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Google sign-in failed: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);
      _snack('Google sign-in failed. Please try again.');
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      auth.clearError();

      if (!await SocialAuthService.appleAvailable()) {
        throw Exception(
          'Sign in with Apple is not available on this device.',
        );
      }

      final credential = await SocialAuthService.apple();

      final success = await auth.loginWithApple(
        identityToken: credential.token,
        nonce: credential.nonce,
        name: credential.name,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.home,
        );
      } else {
        setState(() => _isLoading = false);

        if (auth.errorMessage != null) {
          _snack(auth.errorMessage!);
        }
      }
    } on SocialAuthCancelled {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Apple sign-in failed: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);
      _snack('Apple sign-in failed. Please try again.');
    }
  }

  Future<void> _openCountrySheet() async {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final picked = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor:
      isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
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

  Future<void> _changeLanguage(
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
      debugPrint('Language change failed: $e');

      if (mounted) {
        _snack('Failed to change language: $e');
      }
    }
  }

  void _showLanguageSheet(
      SettingsProvider settings,
      AuthProvider auth,
      ServiceProvider serviceProvider,
      AppLocalizations l10n,
      ) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    _showAppSheet(
      title: l10n.language,
      isDark: isDark,
      children: [
        _SheetTile(
          title: 'English',
          leading: const FlagIcon(
            emoji: '🇬🇧',
            height: 18,
          ),
          selected: settings.locale == 'en',
          onTap: () async {
            Navigator.pop(context);
            await _changeLanguage(
              'en',
              settings,
              auth,
              serviceProvider,
            );
          },
        ),
        const SizedBox(height: 10),
        _SheetTile(
          title: 'Kiswahili',
          leading: const FlagIcon(
            emoji: '🇹🇿',
            height: 18,
          ),
          selected: settings.locale == 'sw',
          onTap: () async {
            Navigator.pop(context);
            await _changeLanguage(
              'sw',
              settings,
              auth,
              serviceProvider,
            );
          },
        ),
      ],
    );
  }

  void _showThemeSheet(
      ThemeProvider themeProvider,
      AppLocalizations l10n,
      ) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    _showAppSheet(
      title: l10n.theme,
      isDark: isDark,
      children: [
        _SheetTile(
          title: 'Light',
          leading: const Icon(Icons.light_mode_rounded),
          selected:
          themeProvider.themeMode == ThemeMode.light,
          onTap: () {
            themeProvider.setThemeMode(ThemeMode.light);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 10),
        _SheetTile(
          title: 'Dark',
          leading: const Icon(Icons.dark_mode_rounded),
          selected:
          themeProvider.themeMode == ThemeMode.dark,
          onTap: () {
            themeProvider.setThemeMode(ThemeMode.dark);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 10),
        _SheetTile(
          title: 'System',
          leading: const Icon(Icons.brightness_auto_rounded),
          selected:
          themeProvider.themeMode == ThemeMode.system,
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
      backgroundColor:
      isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBorder
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white
                      : AppTheme.primary,
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
    final topInset = MediaQuery.paddingOf(context).top;

    final canExitToHost =
    Navigator.of(context, rootNavigator: true).canPop();

    final cardColor =
    isDark ? AppTheme.darkSurface : Colors.white;

    final mutedText =
    isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;

    final primaryText = theme.colorScheme.onSurface;
    final linkColor =
    isDark ? AppTheme.secondary : AppTheme.primary;

    final themeIcon = switch (themeProvider.themeMode) {
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };

    final showGoogle = _showGoogleButton;
    final showApple = _showAppleButton;
    final showSocial = showGoogle || showApple;
    final bothSocial = showGoogle && showApple;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.scaffoldLight,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset + 250,
            child: const _HeroBackground(),
          ),
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
                  constraints:
                  const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          if (canExitToHost)
                            _GlassIconButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Back',
                              onTap: () =>
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).maybePop(),
                            )
                          else
                            const SizedBox(
                              width: 44,
                              height: 44,
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _GlassIconButton(
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
                              _GlassIconButton(
                                icon: themeIcon,
                                tooltip: l10n.theme,
                                onTap: () => _showThemeSheet(
                                  themeProvider,
                                  l10n,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      const _BrandHeader(),

                      const SizedBox(height: 26),

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
                          borderRadius:
                          BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.4 : 0.10,
                              ),
                              blurRadius: 40,
                              offset: const Offset(0, 18),
                              spreadRadius: -6,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
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
                                l10n.signInToContinue,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: mutedText,
                                ),
                              ),

                              const SizedBox(height: 22),

                              _LoginToggle(
                                isEmailMode: _isEmailMode,
                                isDark: isDark,
                                mutedText: mutedText,
                                enabled: !_isLoading,
                                onChanged: (isEmail) {
                                  setState(() {
                                    _isEmailMode = isEmail;
                                    _identifierController.clear();
                                  });
                                },
                              ),

                              const SizedBox(height: 18),

                              if (_isEmailMode)
                                TextFormField(
                                  controller: _identifierController,
                                  enabled: !_isLoading,
                                  keyboardType:
                                  TextInputType.emailAddress,
                                  textInputAction:
                                  TextInputAction.next,
                                  style: const TextStyle(
                                    fontSize: 15,
                                  ),
                                  decoration:
                                  _modernInputDecoration(
                                    context,
                                    hint: 'you@example.com',
                                    icon: Icons.email_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return l10n.enterEmail;
                                    }

                                    if (!RegExp(
                                      r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$',
                                    ).hasMatch(value.trim())) {
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
                                          fontSize: 15,
                                        ),
                                        decoration:
                                        _modernInputDecoration(
                                          context,
                                          hint: '679117291',
                                          icon: Icons.phone_outlined,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter phone number';
                                          }

                                          var digits = value
                                              .trim()
                                              .replaceAll(
                                            RegExp(r'[^0-9]'),
                                            '',
                                          );

                                          if (digits.startsWith('0')) {
                                            digits =
                                                digits.substring(1);
                                          }

                                          if (!RegExp(r'^[67]\d{8}$')
                                              .hasMatch(digits)) {
                                            return 'Enter a valid 9-digit number';
                                          }

                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _passwordController,
                                enabled: !_isLoading,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  fontSize: 15,
                                ),
                                decoration: _modernInputDecoration(
                                  context,
                                  hint: l10n.enterPassword,
                                  icon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 20,
                                      color: mutedText,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword =
                                        !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty) {
                                    return l10n.enterPassword;
                                  }

                                  if (value.length < 6) {
                                    return l10n.passwordMinLength;
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  _CompactCheckbox(
                                    value: _rememberMe,
                                    onChanged: _isLoading
                                        ? null
                                        : (value) {
                                      setState(() {
                                        _rememberMe =
                                            value ?? false;
                                      });
                                    },
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

                              _TermsRow(
                                value: _termsAccepted,
                                enabled: !_isLoading,
                                isDark: isDark,
                                textColor: primaryText,
                                onChanged: (value) {
                                  setState(() {
                                    _termsAccepted =
                                        value ?? false;
                                  });
                                },
                                onTermsTap: () =>
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.terms,
                                    ),
                                onPrivacyTap: () =>
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.privacyPolicy,
                                    ),
                              ),

                              const SizedBox(height: 22),

                              _PrimaryButton(
                                label: l10n.signIn,
                                loading: _isLoading,
                                onPressed: _isLoading
                                    ? null
                                    : _handleLogin,
                              ),

                              if (showSocial) ...[
                                const SizedBox(height: 20),
                                _OrDivider(
                                  label: 'or continue with',
                                  color: mutedText,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    if (showGoogle)
                                      Expanded(
                                        child: _SocialButton(
                                          label: bothSocial
                                              ? 'Google'
                                              : 'Continue with Google',
                                          assetPath:
                                          _kGoogleIconAsset,
                                          fallbackIcon:
                                          Icons.g_mobiledata_rounded,
                                          enabled: !_isLoading,
                                          onPressed:
                                          _handleGoogleSignIn,
                                        ),
                                      ),
                                    if (bothSocial)
                                      const SizedBox(width: 12),
                                    if (showApple)
                                      Expanded(
                                        child: _SocialButton(
                                          label: bothSocial
                                              ? 'Apple'
                                              : 'Continue with Apple',
                                          assetPath:
                                          _kAppleIconAsset,
                                          fallbackIcon:
                                          Icons.apple_rounded,
                                          tintInDark: true,
                                          enabled: !_isLoading,
                                          onPressed:
                                          _handleAppleSignIn,
                                        ),
                                      ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      l10n.dontHaveAccount,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: mutedText,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () =>
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.register,
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

                      const SizedBox(height: 16),

                      Text(
                        'NearbyFundi • trusted technicians near you',
                        style: TextStyle(
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
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HERO BACKGROUND
// ============================================================

class _HeroBackground extends StatelessWidget {
  const _HeroBackground();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(40),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.navy900,
              AppTheme.primary,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: _Blob(
                size: 200,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
            Positioned(
              bottom: -70,
              left: -50,
              child: _Blob(
                size: 190,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BRAND HEADER - PACKAGE ASSET LOADING
// ============================================================

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 68,
          height: 68,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              _kAppIconAsset,
              package: _kAssetPackage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('App icon error: $error');

                return Image.asset(
                  _kAppIconForegroundAsset,
                  package: _kAssetPackage,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint(
                      'App foreground icon error: $error',
                    );

                    return const ColoredBox(
                      color: Colors.white,
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 36,
                        color: AppTheme.primary,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NearbyFundi',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Trusted technicians near you',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  color: Colors.white70,
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
// PRIMARY BUTTON
// ============================================================

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor:
          AppTheme.primary.withOpacity(0.55),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            valueColor:
            AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : Text(
          label,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMAIL / PHONE TOGGLE
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
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : _kFieldTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment(
            label: 'Email',
            icon: Icons.email_outlined,
            active: isEmailMode,
            onTap: enabled ? () => onChanged(true) : null,
          ),
          _segment(
            label: 'Phone',
            icon: Icons.phone_outlined,
            active: !isEmailMode,
            onTap: enabled ? () => onChanged(false) : null,
          ),
        ],
      ),
    );
  }

  Widget _segment({
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
            color: active
                ? AppTheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
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
// COUNTRY BUTTON
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
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : _kFieldTint,
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
              FlagIcon(
                emoji: country.flag,
                height: 20,
              ),
              const SizedBox(width: 6),
              Text(
                country.dialCode,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: mutedText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TERMS ROW
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
    final linkColor =
    isDark ? AppTheme.secondary : AppTheme.primary;

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
                  recognizer: TapGestureRecognizer()
                    ..onTap = onTermsTap,
                ),
                TextSpan(text: ' ${l10n.and} '),
                TextSpan(
                  text: l10n.privacyPolicy,
                  style: TextStyle(
                    color: linkColor,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = onPrivacyTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CHECKBOX
// ============================================================

class _CompactCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const _CompactCheckbox({
    required this.value,
    required this.onChanged,
  });

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
        materialTapTargetSize:
        MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ============================================================
// OR DIVIDER
// ============================================================

class _OrDivider extends StatelessWidget {
  final String label;
  final Color color;

  const _OrDivider({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: color.withOpacity(0.25),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: color.withOpacity(0.25),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SOCIAL BUTTON
// ============================================================

class _SocialButton extends StatelessWidget {
  final String label;
  final String assetPath;
  final IconData fallbackIcon;
  final bool enabled;
  final bool tintInDark;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.assetPath,
    required this.fallbackIcon,
    required this.enabled,
    required this.onPressed,
    this.tintInDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final foreground =
        Theme.of(context).colorScheme.onSurface;

    Widget icon = Image.asset(
      assetPath,
      package: _kAssetPackage,
      width: 22,
      height: 22,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('$assetPath failed to load: $error');

        return Icon(
          fallbackIcon,
          size: 24,
          color: foreground,
        );
      },
    );

    if (tintInDark && isDark) {
      icon = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.white,
          BlendMode.srcIn,
        ),
        child: icon,
      );
    }

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.12),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: enabled ? 1 : 0.5,
              child: icon,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// GLASS ICON BUTTON
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
            child: Icon(
              icon,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SHEET TILE
// ============================================================

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
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final activeColor =
    isDark ? AppTheme.secondary : AppTheme.primary;

    final textColor =
        Theme.of(context).colorScheme.onSurface;

    return Material(
      color: selected
          ? activeColor.withOpacity(0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? activeColor
                  : Theme.of(context)
                  .dividerColor
                  .withOpacity(0.35),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              if (selected) ...[
                Icon(
                  Icons.check_circle_rounded,
                  color: activeColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: selected
                        ? activeColor
                        : textColor,
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
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: selected
                      ? activeColor
                      : textColor,
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
// BACKGROUND BLOB
// ============================================================

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ============================================================
// COUNTRY SHEET
// ============================================================

class _CountrySheet extends StatefulWidget {
  final List<Country> countries;
  final Country selected;

  const _CountrySheet({
    required this.countries,
    required this.selected,
  });

  @override
  State<_CountrySheet> createState() =>
      _CountrySheetState();
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
    final search = query.trim().toLowerCase();

    setState(() {
      _filtered = search.isEmpty
          ? widget.countries
          : widget.countries.where((country) {
        return country.name.toLowerCase().contains(search) ||
            country.dialCode.contains(search);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor =
    isDark ? AppTheme.secondary : AppTheme.primary;

    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom;

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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final country = _filtered[index];

                  final isSelected =
                      country.name == widget.selected.name &&
                          country.dialCode ==
                              widget.selected.dialCode;

                  return ListTile(
                    leading: FlagIcon(
                      emoji: country.flag,
                      height: 24,
                    ),
                    title: Text(
                      country.name,
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
                          country.dialCode,
                          style: TextStyle(
                            color: theme.hintColor,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: activeColor,
                          ),
                        ],
                      ],
                    ),
                    onTap: () =>
                        Navigator.pop(context, country),
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
// INPUT DECORATION
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
    prefixIcon: Icon(
      icon,
      size: 20,
      color: theme.hintColor,
    ),
    suffixIcon: suffix,
    filled: true,
    fillColor: isDark
        ? Colors.white.withOpacity(0.05)
        : _kFieldTint,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
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
        color: isDark
            ? AppTheme.secondary
            : AppTheme.primary,
        width: 1.8,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: Colors.redAccent,
        width: 1.4,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: Colors.redAccent,
        width: 1.8,
      ),
    ),
  );
}
