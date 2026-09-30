// reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/service_provider.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.resetPassword(
      widget.email,
      _otpController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.resetPasswordButton),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
            (_) => false,
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
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
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 380;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              AppTheme.darkBackground,
              AppTheme.darkSurface,
              AppTheme.navy900,
            ]
                : [
              AppTheme.scaffoldLight,
              AppTheme.navy50,
              AppTheme.light,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(isDark ? 0.12 : 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(isDark ? 0.08 : 0.05),
                  ),
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
                        // Top right controls
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ElegantIconButton(
                                icon: Icons.language_rounded,
                                tooltip: l10n.language,
                                onTap: () => _showLanguageSheet(
                                    context, settings, auth, serviceProvider, l10n),
                              ),
                              const SizedBox(width: 8),
                              _ElegantIconButton(
                                icon: themeProvider.themeMode == ThemeMode.dark
                                    ? Icons.dark_mode_rounded
                                    : themeProvider.themeMode == ThemeMode.light
                                    ? Icons.light_mode_rounded
                                    : Icons.brightness_auto_rounded,
                                tooltip: l10n.theme,
                                onTap: () => _showThemeSheet(
                                    context, themeProvider, l10n),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Floating card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                              isSmall ? 22 : 28, 28, isSmall ? 22 : 28, 28),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.35 : 0.08),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                                spreadRadius: -4,
                              ),
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Icon badge
                                Center(
                                  child: Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.09),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.lock_reset_rounded,
                                      size: 42,
                                      color: isDark
                                          ? AppTheme.secondary
                                          : AppTheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Title
                                Text(
                                  l10n.resetPassword,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isSmall ? 26 : 28,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${l10n.otpSentTo} ${widget.email}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // OTP
                                _buildLabel(l10n.otpCode),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _otpController,
                                  enabled: !_isLoading,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 8,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  decoration: _modernInputDecoration(
                                    context,
                                    hint: '------',
                                    icon: Icons.pin_rounded,
                                  ),
                                  validator: (v) =>
                                  v != null && v.length == 6
                                      ? null
                                      : 'Enter 6-digit OTP',
                                ),
                                const SizedBox(height: 18),

                                // New Password
                                _buildLabel(l10n.newPassword),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  enabled: !_isLoading,
                                  obscureText: _obscurePass,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: _modernInputDecoration(
                                    context,
                                    hint: 'Minimum 8 characters',
                                    icon: Icons.lock_outline_rounded,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePass
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        size: 20,
                                        color: theme.hintColor,
                                      ),
                                      onPressed: () => setState(
                                              () => _obscurePass = !_obscurePass),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return l10n.enterPassword;
                                    }
                                    if (v.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Confirm Password
                                _buildLabel(l10n.confirmPassword),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _confirmController,
                                  enabled: !_isLoading,
                                  obscureText: _obscureConfirm,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: _modernInputDecoration(
                                    context,
                                    hint: 'Repeat your password',
                                    icon: Icons.lock_outline_rounded,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        size: 20,
                                        color: theme.hintColor,
                                      ),
                                      onPressed: () => setState(() =>
                                      _obscureConfirm = !_obscureConfirm),
                                    ),
                                  ),
                                  validator: (v) =>
                                  v == _passwordController.text
                                      ? null
                                      : 'Passwords do not match',
                                ),
                                const SizedBox(height: 32),

                                // Reset button
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed:
                                    _isLoading ? null : _handleReset,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      disabledBackgroundColor:
                                      AppTheme.primary.withOpacity(0.55),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.6,
                                        valueColor:
                                        AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    )
                                        : Text(
                                      l10n.resetPasswordButton,
                                      style: const TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Back to sign in
                                Center(
                                  child: TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: Text(
                                      l10n.backToSignIn,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppTheme.secondary
                                            : AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
      ),
    );
  }

  // ───────────────── Language Sheet ─────────────────
  void _showLanguageSheet(
      BuildContext context,
      SettingsProvider settings,
      AuthProvider auth,
      ServiceProvider serviceProvider,
      AppLocalizations l10n,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(l10n.language,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                _SheetTile(
                  title: 'English 🇬🇧',
                  selected: settings.locale == 'en',
                  onTap: () async {
                    await settings.updateLocale('en');
                    await auth.updateLocale('en');
                    await serviceProvider.fetchServices(locale: 'en');
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 10),
                _SheetTile(
                  title: 'Kiswahili 🇹🇿',
                  selected: settings.locale == 'sw',
                  onTap: () async {
                    await settings.updateLocale('sw');
                    await auth.updateLocale('sw');
                    await serviceProvider.fetchServices(locale: 'sw');
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────── Theme Sheet ─────────────────
  void _showThemeSheet(
      BuildContext context,
      ThemeProvider themeProvider,
      AppLocalizations l10n,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(l10n.theme,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                _SheetTile(
                  title: 'Light ☀️',
                  selected: themeProvider.themeMode == ThemeMode.light,
                  onTap: () {
                    themeProvider.setThemeMode(ThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 10),
                _SheetTile(
                  title: 'Dark 🌙',
                  selected: themeProvider.themeMode == ThemeMode.dark,
                  onTap: () {
                    themeProvider.setThemeMode(ThemeMode.dark);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 10),
                _SheetTile(
                  title: 'System ⚙️',
                  selected: themeProvider.themeMode == ThemeMode.system,
                  onTap: () {
                    themeProvider.setThemeMode(ThemeMode.system);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ───────────────── Elegant Icon Button ─────────────────
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
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
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

// ───────────────── Sheet Tile ─────────────────
class _SheetTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _SheetTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppTheme.secondary : AppTheme.primary;

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
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? activeColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────── Input Decoration ─────────────────
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
    counterText: '',
    filled: true,
    fillColor: isDark
        ? Colors.white.withOpacity(0.05)
        : AppTheme.navy50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      borderSide: const BorderSide(color: AppTheme.error, width: 1.4),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.error, width: 1.8),
    ),
  );
}