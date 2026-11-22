// packages/nearby_fundi/lib/screens/auth/login_screen.dart
//
// NearbyFundi (customer) login screen.

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
import '../../widgets/flag_icon.dart';

const String _kAssetPackage = 'nearbyfundi_sdk';
const String _kAppIconAsset = 'assets/icons/app_icon.png';
const String _kAppIconForegroundAsset = 'assets/icons/app_icon_foreground.png';
const String _kGoogleIconAsset = 'assets/icons/google_logo.png';

const Color _kFieldTint = Color(0xFFF4F7F6);

final RegExp _emailPattern = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
final RegExp _nonDigits = RegExp(r'[^0-9]');

/// Strips everything except digits and a single leading zero.
String _digitsOnly(String value) {
  final digits = value.trim().replaceAll(_nonDigits, '');
  return digits.startsWith('0') ? digits.substring(1) : digits;
}

// ============================================================
// PALETTE
// ============================================================

class _Palette {
  const _Palette._({
    required this.isDark,
    required this.card,
    required this.muted,
    required this.text,
    required this.link,
  });

  factory _Palette.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _Palette._(
      isDark: isDark,
      card: isDark ? AppTheme.darkSurface : Colors.white,
      muted: isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
      text: theme.colorScheme.onSurface,
      link: isDark ? AppTheme.secondary : AppTheme.primary,
    );
  }

  final bool isDark;
  final Color card;
  final Color muted;
  final Color text;
  final Color link;

  Color get field => isDark ? Colors.white.withOpacity(0.05) : _kFieldTint;
}

// ============================================================
// SCREEN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<Country> _countries = CountryCodes.all;
  late Country _selectedCountry;

  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _isLoading = false;
  bool _isEmailMode = true;

  @override
  void initState() {
    super.initState();
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

  // ----------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------

  void _snack(String message, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppTheme.error : AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  bool _requireTerms() {
    if (_termsAccepted) return true;
    _snack(AppLocalizations.of(context)!.pleaseAcceptTerms, error: false);
    return false;
  }

  String get _fullPhone {
    final dialCode = _selectedCountry.dialCode.replaceAll('+', '');
    return '$dialCode${_digitsOnly(_identifierController.text)}';
  }

  void _openHome() =>
      Navigator.pushReplacementNamed(context, AppRoutes.home);

  /// Back goes to the previous NearbyFundi screen; if there is none,
  /// it leaves NearbyFundi and returns to the host app.
  Future<void> _goBack() async {
    final local = Navigator.of(context);
    if (local.canPop()) {
      local.pop();
      return;
    }
    await Navigator.of(context, rootNavigator: true).maybePop();
  }

  // ----------------------------------------------------------
  // Email / phone login
  // ----------------------------------------------------------

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate() || !_requireTerms()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>()..clearError();

    try {
      final identifier =
      _isEmailMode ? _identifierController.text.trim() : _fullPhone;

      final success = await auth.login(
        identifier,
        _passwordController.text.trim(),
      );
      if (!mounted) return;

      if (success) {
        _openHome();
        return;
      }
      _snack(auth.errorMessage ?? 'Login failed. Please try again.');
    } catch (e) {
      debugPrint('Login failed: $e');
      if (!mounted) return;
      _snack('Login failed. Please try again.');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ----------------------------------------------------------
  // Google sign-in (all work happens inside AuthProvider)
  // ----------------------------------------------------------

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || !_requireTerms()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>()..clearError();

    try {
      final outcome = await auth.signInWithGoogle();
      if (!mounted) return;

      switch (outcome) {
        case GoogleLoginOutcome.success:
          _openHome();
          return;
        case GoogleLoginOutcome.cancelled:
          break;
        case GoogleLoginOutcome.failed:
          _snack(
            auth.errorMessage ?? 'Google sign-in failed. Please try again.',
          );
      }
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      if (!mounted) return;
      _snack('Google sign-in failed. Please try again.');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ----------------------------------------------------------
  // Country / language / theme
  // ----------------------------------------------------------

  Future<void> _openCountrySheet() async {
    final p = _Palette.of(context);

    final picked = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: p.card,
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

  Future<void> _changeLanguage(String code) async {
    final settings = context.read<SettingsProvider>();
    final auth = context.read<AuthProvider>();
    final services = context.read<ServiceProvider>();

    try {
      await settings.updateLocale(code);
      await auth.updateLocale(code);
      await services.fetchServices(locale: code);
    } catch (e) {
      debugPrint('Language change failed: $e');
      _snack('Failed to change language: $e');
    }
  }

  void _showLanguageSheet() {
    final l10n = AppLocalizations.of(context)!;
    final current = context.read<SettingsProvider>().locale;

    Widget tile(String code, String title, String flag) => _SheetTile(
      title: title,
      leading: FlagIcon(emoji: flag, height: 18),
      selected: current == code,
      onTap: () {
        Navigator.pop(context);
        _changeLanguage(code);
      },
    );

    _showAppSheet(
      title: l10n.language,
      children: [
        tile('en', 'English', '🇬🇧'),
        tile('sw', 'Kiswahili', '🇹🇿'),
      ],
    );
  }

  void _showThemeSheet() {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.read<ThemeProvider>();

    Widget tile(ThemeMode mode, String title, IconData icon) => _SheetTile(
      title: title,
      leading: Icon(icon),
      selected: themeProvider.themeMode == mode,
      onTap: () {
        themeProvider.setThemeMode(mode);
        Navigator.pop(context);
      },
    );

    _showAppSheet(
      title: l10n.theme,
      children: [
        tile(ThemeMode.light, 'Light', Icons.light_mode_rounded),
        tile(ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
        tile(ThemeMode.system, 'System', Icons.brightness_auto_rounded),
      ],
    );
  }

  void _showAppSheet({required String title, required List<Widget> children}) {
    final p = _Palette.of(context);

    showModalBottomSheet<void>(
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
                  color: p.isDark ? Colors.white : AppTheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Build
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final isSmall = MediaQuery.sizeOf(context).width < 380;
    final topInset = MediaQuery.paddingOf(context).top;
    final sidePad = isSmall ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor:
      p.isDark ? AppTheme.darkBackground : AppTheme.scaffoldLight,
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
                padding: EdgeInsets.fromLTRB(sidePad, 12, sidePad, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      _topBar(),
                      const SizedBox(height: 14),
                      const _BrandHeader(),
                      const SizedBox(height: 26),
                      _formCard(p, isSmall),
                      const SizedBox(height: 16),
                      Text(
                        'NearbyFundi • trusted technicians near you',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                          color: p.muted.withOpacity(0.8),
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

  Widget _topBar() {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = context.watch<ThemeProvider>().themeMode;
    context.watch<SettingsProvider>(); // rebuild on locale change

    final canGoBack = Navigator.of(context).canPop() ||
        Navigator.of(context, rootNavigator: true).canPop();

    final themeIcon = switch (themeMode) {
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (canGoBack)
          _GlassIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: _goBack,
          )
        else
          const SizedBox(width: 44, height: 44),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlassIconButton(
              icon: Icons.language_rounded,
              tooltip: l10n.language,
              onTap: _showLanguageSheet,
            ),
            const SizedBox(width: 8),
            _GlassIconButton(
              icon: themeIcon,
              tooltip: l10n.theme,
              onTap: _showThemeSheet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _formCard(_Palette p, bool isSmall) {
    final l10n = AppLocalizations.of(context)!;
    final padH = isSmall ? 20.0 : 24.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(padH, 26, padH, 22),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(p.isDark ? 0.4 : 0.10),
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
                color: p.text,
                letterSpacing: -0.6,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.signInToContinue,
              style: TextStyle(fontSize: 14.5, color: p.muted),
            ),
            const SizedBox(height: 22),
            _LoginToggle(
              isEmailMode: _isEmailMode,
              palette: p,
              enabled: !_isLoading,
              onChanged: (isEmail) => setState(() {
                _isEmailMode = isEmail;
                _identifierController.clear();
              }),
            ),
            const SizedBox(height: 18),
            _isEmailMode ? _emailField(p, l10n) : _phoneRow(p),
            const SizedBox(height: 16),
            _passwordField(p, l10n),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pushNamed(context, AppRoutes.forgot),
                child: Text(
                  l10n.forgotPassword,
                  style: TextStyle(
                    color: p.link,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _TermsRow(
              value: _termsAccepted,
              enabled: !_isLoading,
              palette: p,
              onChanged: (v) => setState(() => _termsAccepted = v ?? false),
              onTermsTap: () => Navigator.pushNamed(context, AppRoutes.terms),
              onPrivacyTap: () =>
                  Navigator.pushNamed(context, AppRoutes.privacyPolicy),
            ),
            const SizedBox(height: 22),
            _PrimaryButton(
              label: l10n.signIn,
              loading: _isLoading,
              onPressed: _isLoading ? null : _handleLogin,
            ),
            const SizedBox(height: 20),
            _OrDivider(label: 'or continue with', color: p.muted),
            const SizedBox(height: 16),
            _SocialButton(
              label: 'Continue with Google',
              assetPath: _kGoogleIconAsset,
              fallbackIcon: Icons.g_mobiledata_rounded,
              enabled: !_isLoading,
              onPressed: _handleGoogleSignIn,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    l10n.dontHaveAccount,
                    style: TextStyle(fontSize: 14, color: p.muted),
                  ),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pushNamed(context, AppRoutes.register),
                  child: Text(
                    l10n.signUp,
                    style: TextStyle(
                      color: p.link,
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
    );
  }

  Widget _emailField(_Palette p, AppLocalizations l10n) {
    return TextFormField(
      controller: _identifierController,
      enabled: !_isLoading,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 15),
      decoration: _inputDecoration(
        context,
        hint: 'you@example.com',
        icon: Icons.email_outlined,
      ),
      validator: (value) {
        final email = value?.trim() ?? '';
        if (email.isEmpty) return l10n.enterEmail;
        if (!_emailPattern.hasMatch(email)) return l10n.enterValidEmail;
        return null;
      },
    );
  }

  Widget _phoneRow(_Palette p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CountryButton(
          country: _selectedCountry,
          palette: p,
          enabled: !_isLoading,
          onTap: _openCountrySheet,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _identifierController,
            enabled: !_isLoading,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecoration(
              context,
              hint: '679117291',
              icon: Icons.phone_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter phone number';
              }
              if (!RegExp(r'^[67]\d{8}$').hasMatch(_digitsOnly(value))) {
                return 'Enter a valid 9-digit number';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _passwordField(_Palette p, AppLocalizations l10n) {
    return TextFormField(
      controller: _passwordController,
      enabled: !_isLoading,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      style: const TextStyle(fontSize: 15),
      decoration: _inputDecoration(
        context,
        hint: l10n.enterPassword,
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            size: 20,
            color: p.muted,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return l10n.enterPassword;
        if (value.length < 6) return l10n.passwordMinLength;
        return null;
      },
    );
  }
}

// ============================================================
// INPUT DECORATION
// ============================================================

InputDecoration _inputDecoration(
    BuildContext context, {
      required String hint,
      required IconData icon,
      Widget? suffix,
    }) {
  final theme = Theme.of(context);
  final p = _Palette.of(context);

  OutlineInputBorder border([BorderSide side = BorderSide.none]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: side,
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: theme.hintColor.withOpacity(0.65),
      fontSize: 14.5,
    ),
    prefixIcon: Icon(icon, size: 20, color: theme.hintColor),
    suffixIcon: suffix,
    filled: true,
    fillColor: p.field,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(),
    enabledBorder: border(),
    focusedBorder: border(BorderSide(color: p.link, width: 1.8)),
    errorBorder: border(const BorderSide(color: Colors.redAccent, width: 1.4)),
    focusedErrorBorder:
    border(const BorderSide(color: Colors.redAccent, width: 1.8)),
  );
}

// ============================================================
// HERO BACKGROUND
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

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

// ============================================================
// BRAND HEADER
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
              errorBuilder: (_, __, ___) => Image.asset(
                _kAppIconForegroundAsset,
                package: _kAssetPackage,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Colors.white,
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 36,
                    color: AppTheme.primary,
                  ),
                ),
              ),
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
// BUTTONS
// ============================================================

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.primary.withOpacity(0.55),
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
            valueColor: AlwaysStoppedAnimation(Colors.white),
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.assetPath,
    required this.fallbackIcon,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final String assetPath;
  final IconData fallbackIcon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = Theme.of(context).colorScheme.onSurface;

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
              child: Image.asset(
                assetPath,
                package: _kAssetPackage,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(fallbackIcon, size: 24, color: foreground),
              ),
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

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

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

// ============================================================
// EMAIL / PHONE TOGGLE
// ============================================================

class _LoginToggle extends StatelessWidget {
  const _LoginToggle({
    required this.isEmailMode,
    required this.palette,
    required this.enabled,
    required this.onChanged,
  });

  final bool isEmailMode;
  final _Palette palette;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.white.withOpacity(0.06) : _kFieldTint,
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
    final color = active ? Colors.white : palette.muted;

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
// COUNTRY BUTTON + SHEET
// ============================================================

class _CountryButton extends StatelessWidget {
  const _CountryButton({
    required this.country,
    required this.palette,
    required this.enabled,
    required this.onTap,
  });

  final Country country;
  final _Palette palette;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.field,
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
              Icon(Icons.arrow_drop_down, color: palette.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.countries, required this.selected});

  final List<Country> countries;
  final Country selected;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final _searchController = TextEditingController();
  late List<Country> _filtered = widget.countries;

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
    final p = _Palette.of(context);

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
                controller: _searchController,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: p.field,
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
                itemBuilder: (context, index) {
                  final country = _filtered[index];
                  final isSelected =
                      country.name == widget.selected.name &&
                          country.dialCode == widget.selected.dialCode;

                  return ListTile(
                    leading: FlagIcon(emoji: country.flag, height: 24),
                    title: Text(
                      country.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? p.link : p.text,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          country.dialCode,
                          style: TextStyle(color: theme.hintColor),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: p.link,
                          ),
                        ],
                      ],
                    ),
                    onTap: () => Navigator.pop(context, country),
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
// TERMS + CHECKBOX + DIVIDER + SHEET TILE
// ============================================================

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.value,
    required this.enabled,
    required this.palette,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final bool value;
  final bool enabled;
  final _Palette palette;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final linkStyle = TextStyle(
      color: palette.link,
      fontWeight: FontWeight.w700,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: palette.text.withOpacity(0.7),
              ),
              children: [
                TextSpan(text: '${l10n.iAgreeToThe} '),
                TextSpan(
                  text: l10n.termsAndConditions,
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()..onTap = onTermsTap,
                ),
                TextSpan(text: ' ${l10n.and} '),
                TextSpan(
                  text: l10n.privacyPolicy,
                  style: linkStyle,
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

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: color.withOpacity(0.25), thickness: 1),
    );

    return Row(
      children: [
        line,
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
        line,
      ],
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String title;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final active = p.link;

    return Material(
      color: selected ? active.withOpacity(0.1) : Colors.transparent,
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
                  ? active
                  : Theme.of(context).dividerColor.withOpacity(0.35),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              if (selected) ...[
                Icon(Icons.check_circle_rounded, color: active, size: 20),
                const SizedBox(width: 12),
              ],
              if (leading != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: selected ? active : p.text,
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
                  color: selected ? active : p.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}