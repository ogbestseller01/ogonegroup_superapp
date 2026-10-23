// lib/screens/auth/register_flow/register_step1_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../config/app_routes.dart';
import '../../../config/app_theme.dart';
import '../../../config/country_codes.dart';
import '../../../models/country.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/flag_icon.dart';
import '../../../widgets/register_step_scaffold.dart';

class RegisterStep1Screen extends StatefulWidget {
  const RegisterStep1Screen({super.key});

  @override
  State<RegisterStep1Screen> createState() => _RegisterStep1ScreenState();
}

class _RegisterStep1ScreenState extends State<RegisterStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();
  final _picker = ImagePicker();

  bool _obscure = true;
  File? _photo;

  late final List<Country> _countries = CountryCodes.all;
  late Country _country = _countries.firstWhere(
        (c) => c.dialCode == '+255',
    orElse: () => _countries.first,
  );

  @override
  void initState() {
    super.initState();
    _resumeIfStarted();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  Future<void> _resumeIfStarted() async {
    final storedId = await StorageService.getTechnicianId();
    if (storedId == null || !mounted) return;
    final step = await context.read<AuthProvider>().getRegistrationStep(storedId);
    if (!mounted) return;
    if (step != null && step >= 1) {
      Navigator.pushReplacementNamed(context, AppRoutes.registerStep2,
          arguments: storedId);
    }
  }

  bool get _valid {
    final email = _emailC.text.trim();
    return _nameC.text.trim().isNotEmpty &&
        (email.isEmpty || email.contains('@')) &&
        _phoneC.text.replaceAll(RegExp(r'[^0-9]'), '').length >= 7 &&
        _passC.text.length >= 8 &&
        _confirmC.text == _passC.text;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked != null && mounted) setState(() => _photo = File(picked.path));
  }

  void _photoSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountrySheet(countries: _countries, selected: _country),
    );
    if (picked != null && mounted) setState(() => _country = picked);
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;

    await StorageService.clearTechnicianData();
    final auth = context.read<AuthProvider>();
    auth.clearError();

    // 0679117297 -> 679117297, then prefix the dial code
    final digits = _phoneC.text
        .replaceAll(RegExp(r'[^0-9]'), '')
        .replaceFirst(RegExp(r'^0+'), '');
    final fullPhone = '${_country.dialCode.replaceAll('+', '')}$digits';
    final email = _emailC.text.trim();

    final id = await auth.registerTechnicianStep1({
      'name': _nameC.text.trim(),
      if (email.isNotEmpty) 'email': email,
      'password': _passC.text,
      'password_confirmation': _confirmC.text,
      'phone': fullPhone,
      if (_photo != null) 'profile_photo': _photo!.path,
    });

    if (!mounted) return;

    if (id == null) {
      final msg = auth.errorMessage;
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
        );
      }
      return;
    }

    // The code is always sent by SMS (and by email when given), so always verify.
    Navigator.pushNamed(
      context,
      AppRoutes.otp,
      arguments: {
        'email': email.isNotEmpty ? email : fullPhone, // identifier shown/used on OTP screen
        'phone': fullPhone,
        'technicianId': id,
        'redirectToStep2': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return RegisterStepScaffold(
      step: 1,
      total: 5,
      title: 'Create your account',
      subtitle: "We'll send a code to your phone to verify it.",
      isLoading: auth.isLoading,
      onNext: _valid ? _next : null,
      child: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _photoSheet,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: theme.colorScheme.surface,
                      backgroundImage: _photo != null ? FileImage(_photo!) : null,
                      child: _photo == null
                          ? Icon(Icons.person_outline,
                          size: 44,
                          color: theme.colorScheme.onSurface.withOpacity(0.4))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('Photo (optional)', style: theme.textTheme.bodySmall),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameC,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickCountry,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        FlagIcon(emoji: _country.flag, height: 20),
                        const SizedBox(width: 8),
                        Text(_country.dialCode),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _phoneC,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                      if (d.isEmpty) return 'Phone is required';
                      return (d.length >= 7 && d.length <= 12)
                          ? null
                          : 'Enter a valid phone number';
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailC,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Email (optional)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                final e = (v ?? '').trim();
                if (e.isEmpty) return null;
                return e.contains('@') ? null : 'Enter a valid email';
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passC,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'Password (min 8 characters)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
              (v != null && v.length >= 8) ? null : 'At least 8 characters',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmC,
              obscureText: _obscure,
              decoration: const InputDecoration(
                hintText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) =>
              v == _passC.text ? null : 'Passwords do not match',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Searchable country list ───────────────────────────────────────────────
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
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                onChanged: _filter,
                decoration: const InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('No country found'))
                  : ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final c = _filtered[i];
                  final isSel = c.name == widget.selected.name &&
                      c.dialCode == widget.selected.dialCode;
                  return ListTile(
                    leading: FlagIcon(emoji: c.flag, height: 24),
                    title: Text(c.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.dialCode),
                        if (isSel) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle,
                              size: 18,
                              color: theme.colorScheme.primary),
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