// lib/screens/auth/register_flow/register_step1_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../config/app_routes.dart';
import '../../../config/country_codes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/country.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/register_shell.dart';

class RegisterStep1Screen extends StatefulWidget {
  /// When the user backs out of Services, this carries the account data
  /// back here so the fields re-populate instead of starting blank.
  final Map<String, dynamic>? initialData;

  const RegisterStep1Screen({super.key, this.initialData});

  @override
  State<RegisterStep1Screen> createState() => _RegisterStep1ScreenState();
}

class _RegisterStep1ScreenState extends State<RegisterStep1Screen> {
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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
    _restoreFromArgs();
    _resumeIfDraftExists();
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

  // ── Restore fields when navigating back from Services ───────
  void _restoreFromArgs() {
    final d = widget.initialData;
    if (d == null) return;

    _nameC.text = d['name']?.toString() ?? '';
    _emailC.text = d['email']?.toString() ?? '';
    _phoneC.text = d['phone_local_raw']?.toString() ?? '';
    _passC.text = d['password']?.toString() ?? '';
    _confirmC.text = d['password_confirmation']?.toString() ?? '';

    final cc = d['phone_country_code']?.toString();
    if (cc != null) {
      _country = _countries.firstWhere(
            (c) => c.dialCode == cc,
        orElse: () => _countries.first,
      );
    }

    final photoPath = d['profile_photo']?.toString();
    if (photoPath != null && photoPath.isNotEmpty) {
      _photo = File(photoPath);
    }
  }

  // ── Resume into later step if a server draft exists ─────────
  Future<void> _resumeIfDraftExists() async {
    final storedId = await StorageService.getTechnicianId();
    if (storedId == null || !mounted) return;

    final auth = context.read<AuthProvider>();
    if (!auth.hasRegistrationToken) {
      await auth.abandonDraft();
      return;
    }

    final step = await auth.getRegistrationStep(storedId);
    if (!mounted) return;

    if (step == null) {
      await auth.abandonDraft();
      return;
    }

    if (step >= 5) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.registerReview,
        arguments: {'draftId': storedId},
      );
      return;
    }

    final route = step <= 1
        ? AppRoutes.registerStep2
        : step == 2
        ? AppRoutes.registerStep3
        : step == 3
        ? AppRoutes.registerStep4
        : AppRoutes.registerStep5;
    Navigator.pushReplacementNamed(context, route, arguments: storedId);
  }

  // ── Validation ──────────────────────────────────────────────
  String get _phoneDigits => _phoneC.text
      .replaceAll(RegExp(r'[^0-9]'), '')
      .replaceFirst(RegExp(r'^0+'), '');

  String? _validatePhone(String? v, AppLocalizations l10n) {
    final raw = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return l10n.regPhoneRequired;
    final d = raw.replaceFirst(RegExp(r'^0+'), '');
    if (_country.dialCode == '+255') {
      return RegExp(r'^[67]\d{8}$').hasMatch(d) ? null : l10n.regPhoneInvalidTz;
    }
    return (d.length >= 7 && d.length <= 12) ? null : l10n.regPhoneInvalid;
  }

  String? _validateEmail(String? v, AppLocalizations l10n) {
    final e = (v ?? '').trim();
    if (e.isEmpty) return null;
    return _emailRe.hasMatch(e) ? null : l10n.regEmailInvalid;
  }

  bool _isValid(AppLocalizations l10n) =>
      _nameC.text.trim().length >= 2 &&
          _validatePhone(_phoneC.text, l10n) == null &&
          _validateEmail(_emailC.text, l10n) == null &&
          _passC.text.length >= 8 &&
          _confirmC.text == _passC.text;

  // ── Photo / country pickers ─────────────────────────────────
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
    final l10n = AppLocalizations.of(context)!;
    final p = RegPalette.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: p.link),
              title: Text(l10n.regChooseGallery,
                  style: TextStyle(color: p.text)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: p.link),
              title:
              Text(l10n.regTakePhoto, style: TextStyle(color: p.text)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            if (_photo != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title: Text(l10n.regRemovePhoto,
                    style: TextStyle(color: p.text)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _photo = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCountry() async {
    final picked = await showRegCountryPicker(context, _countries, _country);
    if (picked != null && mounted) {
      setState(() => _country = picked);
      _formKey.currentState?.validate();
    }
  }

  // ── Next → Services ─────────────────────────────────────────
  void _next() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailC.text.trim().toLowerCase();
    final fullPhone = '${_country.dialCode.replaceAll('+', '')}$_phoneDigits';

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.registerServices,
      arguments: <String, dynamic>{
        'name': _nameC.text.trim(),
        'email': email,
        'phone_local_raw': _phoneC.text,
        'phone_country_code': _country.dialCode,
        'phone_full': fullPhone,
        'password': _passC.text,
        'password_confirmation': _confirmC.text,
        if (_photo != null) 'profile_photo': _photo!.path,
      },
    );
  }

  // ── UI ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final p = RegPalette.of(context);
    final busy = auth.isLoading;

    return RegisterShell(
      step: 1,
      total: 8,
      title: l10n.regCreateAccountTitle,
      subtitle: l10n.regCreateAccountSubtitle,
      isLoading: busy,
      onNext: (_isValid(l10n) && !busy) ? _next : null,
      nextLabel: l10n.regContinue,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo
            Center(
              child: GestureDetector(
                onTap: busy ? null : _photoSheet,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: p.field,
                      backgroundImage:
                      _photo != null ? FileImage(_photo!) : null,
                      child: _photo == null
                          ? Icon(Icons.person_outline_rounded,
                          size: 44, color: theme.hintColor)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: AppThemeAccent.of(context),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(l10n.regPhotoOptional,
                  style: theme.textTheme.bodySmall?.copyWith(color: p.muted)),
            ),
            const SizedBox(height: 20),

            // Name
            TextFormField(
              controller: _nameC,
              enabled: !busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              style: TextStyle(fontSize: 15, color: p.text),
              decoration: regInputDecoration(context,
                  hint: l10n.regFullName, icon: Icons.person_outline_rounded),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? l10n.regNameRequired
                  : null,
            ),
            const SizedBox(height: 14),

            // Phone + country
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: p.field,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: busy ? null : _pickCountry,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          regFlag(_country.name, _country.flag, 20),
                          const SizedBox(width: 6),
                          Text(_country.dialCode,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.5,
                                  color: p.text)),
                          Icon(Icons.arrow_drop_down, color: p.muted),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _phoneC,
                    enabled: !busy,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(fontSize: 15, color: p.text),
                    decoration: regInputDecoration(context,
                        hint: l10n.regPhoneHint, icon: Icons.phone_outlined),
                    validator: (v) => _validatePhone(v, l10n),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Email
            TextFormField(
              controller: _emailC,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: TextStyle(fontSize: 15, color: p.text),
              decoration: regInputDecoration(context,
                  hint: l10n.regEmailOptional, icon: Icons.email_outlined),
              validator: (v) => _validateEmail(v, l10n),
            ),
            const SizedBox(height: 14),

            // Password
            TextFormField(
              controller: _passC,
              enabled: !busy,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              style: TextStyle(fontSize: 15, color: p.text),
              decoration: regInputDecoration(
                context,
                hint: l10n.regPasswordHint,
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                    color: p.muted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
              (v != null && v.length >= 8) ? null : l10n.regPasswordMin,
            ),
            const SizedBox(height: 14),

            // Confirm password
            TextFormField(
              controller: _confirmC,
              enabled: !busy,
              obscureText: _obscure,
              style: TextStyle(fontSize: 15, color: p.text),
              decoration: regInputDecoration(context,
                  hint: l10n.regConfirmPasswordHint,
                  icon: Icons.lock_outline_rounded),
              validator: (v) =>
              v == _passC.text ? null : l10n.regPasswordMismatch,
            ),
          ],
        ),
      ),
    );
  }
}

class AppThemeAccent {
  static Color of(BuildContext context) => RegPalette.of(context).link;
}