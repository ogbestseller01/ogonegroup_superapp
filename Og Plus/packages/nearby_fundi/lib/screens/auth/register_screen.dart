import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../config/country_codes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/country.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/flag_icon.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static final RegExp _emailRegExp = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$',
  );

  final _formKey = GlobalKey<FormState>();
  final _confirmFieldKey = GlobalKey<FormFieldState<String>>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;
  bool _termsError = false;
  bool _submitting = false;

  late final List<Country> _countries;
  late Country _selectedCountry;
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();

    _countries = CountryCodes.all;

    _selectedCountry = _countries.firstWhere(
          (country) => country.dialCode == '+255',
      orElse: () => _countries.first,
    );

    _termsTap = TapGestureRecognizer()
      ..onTap = () => Navigator.pushNamed(context, AppRoutes.terms);

    _privacyTap = TapGestureRecognizer()
      ..onTap = () =>
          Navigator.pushNamed(context, AppRoutes.privacyPolicy);
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // Phone helpers
  // ------------------------------------------------------------

  String get _dial => _selectedCountry.dialCode.replaceAll('+', '');

  String get _nationalDigits {
    var digits = _phoneController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    digits = digits.replaceFirst(RegExp(r'^0+'), '');

    if (digits.startsWith(_dial) &&
        digits.length > _dial.length + 8) {
      digits = digits.substring(_dial.length);
    }

    return digits;
  }

  String get _fullPhone => '$_dial$_nationalDigits';

  // ------------------------------------------------------------
  // Password rules
  // ------------------------------------------------------------

  bool get _ruleLen => _passwordController.text.length >= 8;

  bool get _ruleUpper =>
      RegExp(r'[A-Z]').hasMatch(_passwordController.text);

  bool get _ruleLower =>
      RegExp(r'[a-z]').hasMatch(_passwordController.text);

  bool get _ruleDigit =>
      RegExp(r'\d').hasMatch(_passwordController.text);

  // ------------------------------------------------------------
  // Form validators
  // ------------------------------------------------------------

  String? _validateName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final name = (value ?? '').trim();

    if (name.isEmpty) return l10n.nameRequired;
    if (name.length < 2) return l10n.registerNameTooShort;

    return null;
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final email = (value ?? '').trim();

    if (email.isEmpty) return l10n.registerEmailRequired;

    if (!_emailRegExp.hasMatch(email)) {
      return l10n.enterValidEmail;
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.trim().isEmpty) {
      return l10n.registerPhoneRequired;
    }

    final national = _nationalDigits;
    final full = _fullPhone;

    if (_dial == '255') {
      if (national.length != 9 ||
          !(national.startsWith('6') ||
              national.startsWith('7'))) {
        return l10n.registerValidTanzaniaPhone;
      }

      return null;
    }

    if (full.length < 9 || full.length > 15) {
      return l10n.registerValidPhone;
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final password = value ?? '';

    if (password.isEmpty) {
      return l10n.registerPasswordRequired;
    }

    if (password.length < 8) {
      return l10n.registerPasswordMinLength;
    }

    if (!_ruleUpper || !_ruleLower || !_ruleDigit) {
      return l10n.registerPasswordStrength;
    }

    return null;
  }

  String? _validateConfirm(String? value) {
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.isEmpty) {
      return l10n.registerConfirmPasswordRequired;
    }

    if (value != _passwordController.text) {
      return l10n.registerPasswordsMismatch;
    }

    return null;
  }

  // ------------------------------------------------------------
  // UI feedback
  // ------------------------------------------------------------

  void _showSnackBar(
      String message, {
        bool error = true,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          error ? AppTheme.error : AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ------------------------------------------------------------
  // Registration
  // ------------------------------------------------------------

  Future<void> _handleRegister() async {
    if (_submitting) return;

    FocusScope.of(context).unfocus();

    final formOk = _formKey.currentState!.validate();

    if (!_termsAccepted) {
      setState(() => _termsError = true);
    }

    if (!formOk || !_termsAccepted) return;

    final auth = context.read<AuthProvider>();

    auth.clearError();

    setState(() => _submitting = true);

    try {
      final email = _emailController.text.trim().toLowerCase();

      final result = await auth.register(
        _nameController.text.trim(),
        email,
        _passwordController.text,
        _confirmController.text,
        phone: _fullPhone,
      );

      if (!mounted) return;

      if (!result.success) {
        final message = result.message.isNotEmpty
            ? result.message
            : AppLocalizations.of(context)!.registerFailedRetry;

        _showSnackBar(message);
        return;
      }

      if (!result.otpSent) {
        _showSnackBar(
          AppLocalizations.of(context)!.registerOtpSendFailed,
          error: false,
        );
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            sentTo: result.sentTo,
            channel: result.channel,
            otpSent: result.otpSent,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  // ------------------------------------------------------------
  // Navigation
  // ------------------------------------------------------------

  void _goToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.login,
      );
    }
  }

  // ------------------------------------------------------------
  // Country selector
  // ------------------------------------------------------------

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

  Widget _buildCountryButton(
      ThemeData theme,
      bool isDark,
      ) {
    return Material(
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : AppTheme.navy50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _submitting ? null : _openCountrySheet,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlagIcon(
                emoji: _selectedCountry.flag,
                height: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedCountry.dialCode,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: theme.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Reusable field label
  // ------------------------------------------------------------

  Widget _buildFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withOpacity(0.6),
        letterSpacing: 0.8,
      ),
    );
  }

  // ------------------------------------------------------------
  // Password checklist
  // ------------------------------------------------------------

  Widget _buildPasswordRules() {
    final l10n = AppLocalizations.of(context)!;

    if (_passwordController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          _RuleRow(
            ok: _ruleLen,
            text: l10n.registerRuleLength,
          ),
          _RuleRow(
            ok: _ruleUpper,
            text: l10n.registerRuleUppercase,
          ),
          _RuleRow(
            ok: _ruleLower,
            text: l10n.registerRuleLowercase,
          ),
          _RuleRow(
            ok: _ruleDigit,
            text: l10n.registerRuleNumber,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Register screen
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.scaffoldLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurface
                    : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      isDark ? 0.35 : 0.04,
                    ),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                autovalidateMode:
                AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_add_rounded,
                          size: 36,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        'NearbyFundi',
                        style:
                        theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    Center(
                      child: Text(
                        l10n.createAccount,
                        style:
                        theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Full name
                    _buildFieldLabel(l10n.fullName),
                    const SizedBox(height: 6),

                    TextFormField(
                      controller: _nameController,
                      enabled: !_submitting,
                      textCapitalization:
                      TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.name,
                      ],
                      decoration: _inputDecoration(
                        context,
                        hintText: l10n.enterFullName,
                        prefixIcon:
                        Icons.person_outline_rounded,
                      ),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 22),

                    // Email
                    _buildFieldLabel(l10n.emailAddress),
                    const SizedBox(height: 6),

                    TextFormField(
                      controller: _emailController,
                      enabled: !_submitting,
                      keyboardType:
                      TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [
                        AutofillHints.email,
                      ],
                      decoration: _inputDecoration(
                        context,
                        hintText: l10n.emailHint,
                        prefixIcon: Icons.email_outlined,
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 22),

                    // Phone
                    _buildFieldLabel(l10n.phoneNumber),
                    const SizedBox(height: 6),

                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        _buildCountryButton(theme, isDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            enabled: !_submitting,
                            keyboardType: TextInputType.phone,
                            textInputAction:
                            TextInputAction.next,
                            autofillHints: const [
                              AutofillHints
                                  .telephoneNumberNational,
                            ],
                            decoration: _inputDecoration(
                              context,
                              hintText: l10n.registerPhoneHint,
                              prefixIcon:
                              Icons.phone_outlined,
                            ),
                            validator: _validatePhone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Password
                    _buildFieldLabel(l10n.password),
                    const SizedBox(height: 6),

                    TextFormField(
                      controller: _passwordController,
                      enabled: !_submitting,
                      obscureText: _obscurePass,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        context,
                        hintText: l10n.registerPasswordHint,
                        prefixIcon:
                        Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: theme.hintColor,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePass = !_obscurePass;
                            });
                          },
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {});

                        if (_confirmController.text.isNotEmpty) {
                          _confirmFieldKey.currentState
                              ?.validate();
                        }
                      },
                      validator: _validatePassword,
                    ),

                    _buildPasswordRules(),
                    const SizedBox(height: 22),

                    // Confirm password
                    _buildFieldLabel(l10n.confirmPassword),
                    const SizedBox(height: 6),

                    TextFormField(
                      key: _confirmFieldKey,
                      controller: _confirmController,
                      enabled: !_submitting,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) =>
                          _handleRegister(),
                      decoration: _inputDecoration(
                        context,
                        hintText: l10n.registerRepeatPassword,
                        prefixIcon:
                        Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: theme.hintColor,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirm =
                              !_obscureConfirm;
                            });
                          },
                        ),
                      ),
                      validator: _validateConfirm,
                    ),
                    const SizedBox(height: 22),

                    // Terms and conditions
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _termsAccepted,
                            onChanged: _submitting
                                ? null
                                : (value) {
                              setState(() {
                                _termsAccepted =
                                    value ?? false;

                                if (_termsAccepted) {
                                  _termsError = false;
                                }
                              });
                            },
                            activeColor: theme.primaryColor,
                            side: _termsError
                                ? const BorderSide(
                              color: AppTheme.error,
                              width: 2,
                            )
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(4),
                            ),
                            materialTapTargetSize:
                            MaterialTapTargetSize
                                .shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.8),
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text: '${l10n.iAgreeToThe} ',
                                ),
                                TextSpan(
                                  text:
                                  l10n.termsAndConditions,
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w700,
                                    decoration:
                                    TextDecoration.underline,
                                    decorationColor: theme
                                        .primaryColor
                                        .withOpacity(0.4),
                                  ),
                                  recognizer: _termsTap,
                                ),
                                TextSpan(
                                  text: ' ${l10n.and} ',
                                ),
                                TextSpan(
                                  text: l10n.privacyPolicy,
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w700,
                                    decoration:
                                    TextDecoration.underline,
                                    decorationColor: theme
                                        .primaryColor
                                        .withOpacity(0.4),
                                  ),
                                  recognizer: _privacyTap,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_termsError)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 6,
                          left: 32,
                        ),
                        child: Text(
                          l10n.pleaseAcceptTerms,
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 28),

                    // Register button and loading indicator
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: _submitting
                          ? const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2.8,
                          ),
                        ),
                      )
                          : CustomButton(
                        text: l10n.signUp,
                        onPressed: _handleRegister,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Login navigation
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.registerAlreadyHaveAccount,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        TextButton(
                          onPressed:
                          _submitting ? null : _goToLogin,
                          style: TextButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            minimumSize: const Size(0, 30),
                            tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.signIn,
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Password rule item
// ------------------------------------------------------------

class _RuleRow extends StatelessWidget {
  final bool ok;
  final String text;

  const _RuleRow({
    required this.ok,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ok ? AppTheme.success : theme.hintColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// Searchable country selector
// ------------------------------------------------------------

class _CountrySheet extends StatefulWidget {
  final List<Country> countries;
  final Country selected;

  const _CountrySheet({
    required this.countries,
    required this.selected,
  });

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
    final search = query.trim().toLowerCase();

    setState(() {
      _filtered = search.isEmpty
          ? widget.countries
          : widget.countries
          .where(
            (country) =>
        country.name.toLowerCase().contains(search) ||
            country.dialCode.contains(search),
      )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor =
    isDark ? AppTheme.secondary : AppTheme.primary;

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
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                8,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: _inputDecoration(
                  context,
                  hintText: l10n.registerSearchCountry,
                  prefixIcon: Icons.search_rounded,
                ),
              ),
            ),

            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                child: Text(
                  l10n.registerNoCountryFound,
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

// ------------------------------------------------------------
// Shared input decoration
// ------------------------------------------------------------

InputDecoration _inputDecoration(
    BuildContext context, {
      required String hintText,
      required IconData prefixIcon,
      Widget? suffixIcon,
    }) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return InputDecoration(
    hintText: hintText,
    hintStyle: theme.textTheme.bodyMedium?.copyWith(
      color: theme.hintColor.withOpacity(0.7),
      fontWeight: FontWeight.w400,
    ),
    prefixIcon: Icon(
      prefixIcon,
      color: theme.hintColor,
      size: 20,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: isDark
        ? Colors.white.withOpacity(0.05)
        : AppTheme.navy50,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 18,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: isDark
            ? AppTheme.secondary
            : AppTheme.primary,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: AppTheme.error,
        width: 1.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: AppTheme.error,
        width: 2,
      ),
    ),
  );
}