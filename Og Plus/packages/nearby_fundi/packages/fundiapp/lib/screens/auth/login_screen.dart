// packages/nearby_fundi/packages/fundiapp/lib/screens/auth/login_screen.dart
//
// FundiApp (technician) login screen: password login, remember me,
// one-tap "Continue as [User]". No hardcoded UI language.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../config/country_codes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/country.dart';
import '../../providers/auth_issue_text.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/continue_as_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/flag_icon.dart';
import '../../widgets/loading_overlay.dart';

/// Must match `name:` in pubspec.yaml.
const String _kAssetPackage = 'fundiapp_sdk';

const Color _kFieldTint = Color(0xFFF1F5FB);

final RegExp _nonDigits = RegExp(r'[^0-9]');

/// Digits only, without a single leading zero (0712… -> 712…).
String _digitsOnly(String value) {
  final digits = value.trim().replaceAll(_nonDigits, '');
  return digits.startsWith('0') ? digits.substring(1) : digits;
}

// ============================================================
// FLAG HELPERS
// ============================================================

String? _flagAssetFor(String countryName) {
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
  final asset = _flagAssetFor(name);
  if (asset == null) return FlagIcon(emoji: emoji, height: height);

  return ClipRRect(
    borderRadius: BorderRadius.circular(3),
    child: Image.asset(
      asset,
      package: _kAssetPackage,
      height: height,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => FlagIcon(emoji: emoji, height: height),
    ),
  );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Palette._(
      isDark: isDark,
      card: isDark ? AppTheme.darkSurface : Colors.white,
      muted: isDark ? AppTheme.darkTextSecondary : AppTheme.greyText,
      text: isDark ? Colors.white : AppTheme.primary,
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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<Country> _countries = CountryCodes.all;
  late Country _selectedCountry;

  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _isEmailLogin = true;

  // Remember me / one-tap login
  bool _rememberMe = true;
  bool _quickLoading = false;

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
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          error ? Theme.of(context).colorScheme.error : AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  String _composedPhone() {
    final dialCode = _selectedCountry.dialCode.replaceAll('+', '');
    return '$dialCode${_digitsOnly(_phoneController.text)}';
  }

  /// Back goes to the previous Fundi screen; if there is none,
  /// it leaves FundiApp and returns to the host app.
  Future<void> _goBack() async {
    final local = Navigator.of(context);
    if (local.canPop()) {
      local.pop();
      return;
    }
    await Navigator.of(context, rootNavigator: true).maybePop();
  }

  /// Leaves FundiApp entirely and lands on the host app's first screen.
  void _goHost() {
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);
  }

  void _openHome() =>
      Navigator.pushReplacementNamed(context, AppRoutes.home);

  // ----------------------------------------------------------
  // Password login
  // ----------------------------------------------------------

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    if (auth.isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      _snack(l10n.loginAcceptTerms, error: true);
      return;
    }

    final identifier =
    _isEmailLogin ? _emailController.text.trim() : _composedPhone();

    auth.clearError();
    final success = await auth.login(
      identifier,
      _passwordController.text.trim(),
      rememberMe: _rememberMe,
    );
    if (!mounted) return;

    if (success) {
      _openHome();
    } else {
      _snack(auth.errorText(l10n), error: true);
    }
  }

  // ----------------------------------------------------------
  // One-tap login ("Continue as [User]")
  // ----------------------------------------------------------

  Future<void> _handleQuickLogin() async {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    if (auth.isLoading) return;

    setState(() => _quickLoading = true);
    auth.clearError();

    final success = await auth.quickLogin();
    if (!mounted) return;

    setState(() => _quickLoading = false);

    if (success) {
      _openHome();
    } else {
      _snack(auth.errorText(l10n), error: true);
    }
  }

  // ----------------------------------------------------------
  // Sign-up: resume an unfinished registration or start a new one
  // ----------------------------------------------------------

  Future<void> _handleSignUp() async {
    final auth = context.read<AuthProvider>();
    final storedId = await StorageService.getTechnicianId();
    if (!mounted) return;

    if (storedId != null) {
      final step = await auth.getRegistrationStep(storedId);
      if (!mounted) return;

      if (step != null) {
        _resumeRegistration(storedId, step);
        return;
      }

      await StorageService.clearTechnicianData();
      if (!mounted) return;
    }

    Navigator.pushNamed(context, AppRoutes.registerStep1);
  }

  void _resumeRegistration(int technicianId, int step) {
    if (step < 1) {
      Navigator.pushNamed(context, AppRoutes.registerStep1);
      return;
    }

    if (step >= 5) {
      Navigator.pushNamed(
        context,
        AppRoutes.registerReview,
        arguments: {'technicianId': technicianId},
      );
      return;
    }

    // step 1 -> Step 2 screen, step 2 -> Step 3 screen, ... step 4 -> Step 5.
    final routes = [
      AppRoutes.registerStep2,
      AppRoutes.registerStep3,
      AppRoutes.registerStep4,
      AppRoutes.registerStep5,
    ];
    Navigator.pushNamed(context, routes[step - 1], arguments: technicianId);
  }

  // ----------------------------------------------------------
  // Country / language / theme
  // ----------------------------------------------------------

  Future<void> _openCountrySheet() async {
    final p = _Palette.of(context);
    final l10n = AppLocalizations.of(context)!;

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
        searchHint: l10n.loginSearchCountry,
        noResultsText: l10n.loginNoCountry,
      ),
    );

    if (picked != null && mounted) {
      setState(() => _selectedCountry = picked);
    }
  }

  void _showLanguageSheet() {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.read<SettingsProvider>();

    // Language names are shown in their own language on purpose.
    Widget tile(String code, String title, String country, String emoji) =>
        _SheetTile(
          title: title,
          leading: _buildFlag(country, emoji, 18),
          selected: settings.locale == code,
          onTap: () async {
            await settings.updateLocale(code);
            if (mounted) Navigator.pop(context);
          },
        );

    _showAppSheet(
      title: l10n.language,
      children: [
        tile('en', 'English', 'English', '🇬🇧'),
        tile('sw', 'Kiswahili', 'Tanzania', '🇹🇿'),
      ],
    );
  }

  void _showThemeSheet() {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.read<ThemeProvider>();

    Widget tile(ThemeMode mode, String title, IconData icon, bool selected) =>
        _SheetTile(
          title: title,
          leading: Icon(icon),
          selected: selected,
          onTap: () {
            themeProvider.setThemeMode(mode);
            Navigator.pop(context);
          },
        );

    _showAppSheet(
      title: l10n.loginTheme,
      children: [
        tile(ThemeMode.light, l10n.loginThemeLight, Icons.light_mode_rounded,
            !themeProvider.isDarkMode),
        tile(ThemeMode.dark, l10n.loginThemeDark, Icons.dark_mode_rounded,
            themeProvider.isDarkMode),
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
                  color: p.text,
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
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final isSmall = MediaQuery.sizeOf(context).width < 380;
    final topInset = MediaQuery.paddingOf(context).top;
    final sidePad = isSmall ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor:
      p.isDark ? AppTheme.darkBackground : AppTheme.scaffoldLight,
      body: LoadingOverlay(
        isLoading: auth.isLoading && !_quickLoading,
        child: Stack(
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
                        _topBar(l10n),
                        const SizedBox(height: 14),
                        _BrandHeader(tagline: l10n.loginBrandTagline),
                        const SizedBox(height: 26),
                        _formCard(p, isSmall, auth, l10n),
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

  Widget _topBar(AppLocalizations l10n) {
    final themeProvider = context.watch<ThemeProvider>();
    context.watch<SettingsProvider>(); // rebuild on locale change

    final embedded = Navigator.of(context, rootNavigator: true).canPop();
    final canGoBack = embedded || Navigator.of(context).canPop();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (canGoBack)
          Row(
            children: [
              _GlassIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: l10n.loginBack,
                onTap: _goBack,
              ),
              if (embedded) ...[
                const SizedBox(width: 8),
                _HomePillButton(label: l10n.loginHome, onTap: _goHost),
              ],
            ],
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
              icon: themeProvider.isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              tooltip: l10n.loginTheme,
              onTap: _showThemeSheet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _formCard(
      _Palette p,
      bool isSmall,
      AuthProvider auth,
      AppLocalizations l10n,
      ) {
    final padH = isSmall ? 20.0 : 24.0;
    final busy = auth.isLoading;
    final acc = auth.remembered;

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
              l10n.signInManage,
              style: TextStyle(fontSize: 14.5, color: p.muted),
            ),
            const SizedBox(height: 22),

            // One-tap "Continue as [User]". The X forgets the saved account
            // and shows the normal credential form again.
            if (acc != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: ContinueAsCard(
                  account: acc,
                  title: l10n.loginContinueAs(
                    acc.name.trim().split(' ').first,
                  ),
                  cancelTooltip: l10n.loginUseAnother,
                  loading: _quickLoading,
                  onContinue: busy ? null : _handleQuickLogin,
                  onSwitch: busy ? null : () => auth.forgetRemembered(),
                ),
              ),

            _LoginToggle(
              isEmailLogin: _isEmailLogin,
              palette: p,
              enabled: !busy,
              emailLabel: l10n.loginEmail,
              phoneLabel: l10n.loginPhone,
              onChanged: (isEmail) => setState(() => _isEmailLogin = isEmail),
            ),
            const SizedBox(height: 18),
            _isEmailLogin ? _emailField(p, busy, l10n) : _phoneRow(p, busy, l10n),
            const SizedBox(height: 16),
            _passwordField(p, l10n, busy),
            const SizedBox(height: 8),

            // Remember me (left) + Forgot password (right)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: busy
                        ? null
                        : () => setState(() => _rememberMe = !_rememberMe),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: busy
                                  ? null
                                  : (v) => setState(
                                    () => _rememberMe = v ?? false,
                              ),
                              activeColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n.loginRememberMe,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: p.text.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.pushNamed(context, AppRoutes.forgot),
                  style: TextButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.forgotPassword,
                    style: TextStyle(
                      color: p.link,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _TermsRow(
              value: _termsAccepted,
              enabled: !busy,
              palette: p,
              onChanged: (v) => setState(() => _termsAccepted = v ?? false),
            ),
            const SizedBox(height: 22),
            CustomButton(
              text: l10n.signIn,
              onPressed: busy ? null : _handleLogin,
              isLoading: busy && !_quickLoading,
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
                  onPressed: busy ? null : _handleSignUp,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
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

  Widget _emailField(_Palette p, bool busy, AppLocalizations l10n) {
    return TextFormField(
      controller: _emailController,
      enabled: !busy,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: TextStyle(fontSize: 15, color: p.text),
      decoration: _inputDecoration(
        context,
        hint: l10n.loginEmailHint,
        icon: Icons.email_outlined,
      ),
      validator: (v) {
        final email = v?.trim() ?? '';
        return email.contains('@') && email.contains('.')
            ? null
            : l10n.loginEnterValidEmail;
      },
    );
  }

  Widget _phoneRow(_Palette p, bool busy, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CountryButton(
          country: _selectedCountry,
          palette: p,
          enabled: !busy,
          onTap: _openCountrySheet,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _phoneController,
            enabled: !busy,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: TextStyle(fontSize: 15, color: p.text),
            decoration: _inputDecoration(
              context,
              hint: l10n.loginPhoneHint,
              icon: Icons.phone_outlined,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.loginEnterPhone;
              final length = v.trim().replaceAll(_nonDigits, '').length;
              return length < 7 || length > 15 ? l10n.loginPhoneDigits : null;
            },
          ),
        ),
      ],
    );
  }

  Widget _passwordField(_Palette p, AppLocalizations l10n, bool busy) {
    return TextFormField(
      controller: _passwordController,
      enabled: !busy,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      style: TextStyle(fontSize: 15, color: p.text),
      decoration: _inputDecoration(
        context,
        hint: l10n.password,
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
      validator: (v) =>
      v != null && v.length >= 6 ? null : l10n.loginPasswordMin,
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
// HERO + BRAND
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.tagline});

  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icons/app_icon.png',
              package: _kAssetPackage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.handyman_rounded,
                size: 32,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FundiApp', // brand name
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tagline,
                style: TextStyle(
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
// TOP-BAR BUTTONS
// ============================================================

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

class _HomePillButton extends StatelessWidget {
  const _HomePillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home_rounded, size: 20, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
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
// EMAIL / PHONE TOGGLE
// ============================================================

class _LoginToggle extends StatelessWidget {
  const _LoginToggle({
    required this.isEmailLogin,
    required this.palette,
    required this.enabled,
    required this.emailLabel,
    required this.phoneLabel,
    required this.onChanged,
  });

  final bool isEmailLogin;
  final _Palette palette;
  final bool enabled;
  final String emailLabel;
  final String phoneLabel;
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
            label: emailLabel,
            icon: Icons.email_outlined,
            active: isEmailLogin,
            onTap: enabled ? () => onChanged(true) : null,
          ),
          _segment(
            label: phoneLabel,
            icon: Icons.phone_outlined,
            active: !isEmailLogin,
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
              _buildFlag(country.name, country.flag, 20),
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
  const _CountrySheet({
    required this.countries,
    required this.selected,
    required this.searchHint,
    required this.noResultsText,
  });

  final List<Country> countries;
  final Country selected;
  final String searchHint;
  final String noResultsText;

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
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  hintText: widget.searchHint,
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
                  widget.noResultsText,
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
                            ? p.link
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
// TERMS + SHEET TILE
// ============================================================

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.value,
    required this.enabled,
    required this.palette,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final _Palette palette;
  final ValueChanged<bool?> onChanged;

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
                TextSpan(text: '${l10n.loginIAgree} '),
                TextSpan(
                  text: l10n.loginTerms,
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()
                    ..onTap =
                        () => Navigator.pushNamed(context, AppRoutes.terms),
                ),
                TextSpan(text: ' ${l10n.loginAnd} '),
                TextSpan(
                  text: l10n.loginPrivacy,
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()
                    ..onTap =
                        () => Navigator.pushNamed(context, AppRoutes.privacy),
                ),
              ],
            ),
          ),
        ),
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
    final textColor = Theme.of(context).colorScheme.onSurface;
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
                    color: selected ? active : textColor,
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
                  color: selected ? active : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}