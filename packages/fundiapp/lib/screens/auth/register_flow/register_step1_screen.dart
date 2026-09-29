// lib/screens/auth/register_flow/register_step1_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../config/country_codes.dart';
import '../../../providers/auth_provider.dart';
import '../../../config/app_routes.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/country.dart';
import '../../../widgets/flag_icon.dart';
import '../../../services/storage_service.dart';

class RegisterStep1Screen extends StatefulWidget {
  const RegisterStep1Screen({super.key});

  @override
  State<RegisterStep1Screen> createState() => _RegisterStep1ScreenState();
}

class _RegisterStep1ScreenState extends State<RegisterStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  File? _profilePhoto;
  final ImagePicker _picker = ImagePicker();

  late final List<Country> _countries;
  late Country _selectedCountry;

  int _passwordStrength = 0;
  bool _isLoadingCheck = false;

  @override
  void initState() {
    super.initState();
    _checkStepAccess();
    _countries = CountryCodes.all;
    _selectedCountry = _countries.firstWhere(
          (c) => c.dialCode == '+255',
      orElse: () => _countries.first,
    );
    _passwordController.addListener(_updatePasswordStrength);
  }

  // ✅ If step is already >=1, redirect to Step 2
  Future<void> _checkStepAccess() async {
    final storedId = await StorageService.getTechnicianId();
    if (storedId == null) return; // no pending registration
    final auth = context.read<AuthProvider>();
    final step = await auth.getRegistrationStep(storedId);
    if (!mounted) return;
    if (step != null && step >= 1) {
      // Already completed Step 1, go to Step 2
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.registerStep2,
        arguments: storedId,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 8) strength = 1;
    if (password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      strength = 2;
    }
    if (strength == 2 &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      strength = 3;
    }
    setState(() => _passwordStrength = strength);
  }

  Future<void> _pickPhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 80,
                );
                if (picked != null) {
                  setState(() => _profilePhoto = File(picked.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 80,
                );
                if (picked != null) {
                  setState(() => _profilePhoto = File(picked.path));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Country selection (SVG flags via FlagIcon)
  // ─────────────────────────────────────────────
  Future<void> _openCountrySheet() async {
    final picked = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

  Widget _buildCountryButton(ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _openCountrySheet,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlagIcon(emoji: _selectedCountry.flag, height: 20),
            const SizedBox(width: 8),
            Text(
              _selectedCountry.dialCode,
              style: theme.textTheme.bodyMedium,
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isFormValid {
    if (_nameController.text.trim().isEmpty) return false;
    if (!_emailController.text.contains('@')) return false;
    if (_phoneController.text.trim().isEmpty) return false;
    if (_passwordController.text.length < 8) return false;
    if (_confirmController.text != _passwordController.text) return false;
    if (_profilePhoto == null) return false;
    return true;
  }

  Future<void> _nextStep() async {
    // Clear old technician data before creating a new registration
    await StorageService.clearTechnicianData();

    if (!_formKey.currentState!.validate()) return;
    if (_profilePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a profile photo'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final digits = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final dialCode = _selectedCountry.dialCode.replaceAll('+', '');
    final fullPhone = '$dialCode$digits';

    final Map<String, dynamic> data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
      'password_confirmation': _confirmController.text.trim(),
      'phone': fullPhone,
      'profile_photo': _profilePhoto!.path,
    };

    final technicianId = await auth.registerTechnicianStep1(data);

    if (!mounted) return;

    if (technicianId != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.otp,
        arguments: {
          'email': _emailController.text.trim(),
          'technicianId': technicianId,
          'redirectToStep2': true,
        },
      );
    } else {
      if (auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage!),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Step 1: Personal Info'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: LoadingOverlay(
        isLoading: auth.isLoading || _isLoadingCheck,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.colorScheme.surface,
                        child: _profilePhoto != null
                            ? ClipOval(child: Image.file(_profilePhoto!, width: 120, height: 120, fit: BoxFit.cover))
                            : Icon(
                          Icons.person_add_alt_rounded,
                          size: 60,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildField(
                  controller: _nameController,
                  hint: 'Full Name',
                  icon: Icons.person_outline,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Name required',
                ),
                const SizedBox(height: 16),

                _buildField(
                  controller: _emailController,
                  hint: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => v != null && v.contains('@') ? null : 'Enter valid email',
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCountryButton(theme),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: theme.textTheme.bodyMedium,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Phone number',
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
                          if (cleaned.length >= 7 && cleaned.length <= 12) return null;
                          return 'Enter a valid phone number';
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      controller: _passwordController,
                      hint: 'Password (min 8 chars)',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePass,
                      onChanged: (_) => setState(() {}),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                      validator: (v) => v != null && v.length >= 8 ? null : 'Password must be ≥8 chars',
                    ),
                    const SizedBox(height: 6),
                    if (_passwordController.text.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: _passwordStrength >= 1
                                    ? (_passwordStrength >= 2
                                    ? (_passwordStrength >= 3 ? Colors.green : Colors.orange)
                                    : Colors.red)
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _passwordStrength == 0
                                ? 'Too short'
                                : _passwordStrength == 1
                                ? 'Weak'
                                : _passwordStrength == 2
                                ? 'Medium'
                                : 'Strong',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _passwordStrength == 0
                                  ? Colors.grey
                                  : _passwordStrength == 1
                                  ? Colors.red
                                  : _passwordStrength == 2
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),

                _buildField(
                  controller: _confirmController,
                  hint: 'Confirm Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  onChanged: (_) => setState(() {}),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) => v == _passwordController.text ? null : 'Passwords do not match',
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: 'Next →',
                  onPressed: _nextStep,
                  isLoading: auth.isLoading,
                  isDisabled: !_isFormValid || auth.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodySmall,
        prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}

// ─────────────────────────────────────────────
// Searchable country list shown in the bottom sheet
// ─────────────────────────────────────────────
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: const InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                child: Text(
                  'No country found',
                  style: theme.textTheme.bodyMedium,
                ),
              )
                  : ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final c = _filtered[i];
                  // Match on name too: several countries share +1.
                  final isSelected = c.name == widget.selected.name &&
                      c.dialCode == widget.selected.dialCode;
                  return ListTile(
                    leading: FlagIcon(emoji: c.flag, height: 24),
                    title: Text(c.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.dialCode),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: theme.colorScheme.primary,
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