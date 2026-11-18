import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../config/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/register_shell.dart';

class RegisterStep2Screen extends StatefulWidget {
  final int draftId;
  const RegisterStep2Screen({super.key, required this.draftId});

  @override
  State<RegisterStep2Screen> createState() => _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends State<RegisterStep2Screen> {
  final _idC = TextEditingController();
  final _picker = ImagePicker();

  String _idType = 'nida';
  File? _idImage;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  @override
  void dispose() {
    _idC.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    final auth = context.read<AuthProvider>();

    debugPrint('🔎 Step2 access check → '
        'hasToken=${auth.hasRegistrationToken}, '
        'draftId=${widget.draftId}');

    // 1) No registration token → the OTP step didn't issue one.
    if (!auth.hasRegistrationToken) {
      debugPrint('❌ No registration token — abandoning draft. '
          'Did the OTP screen call auth.verifyDraftOtp() and not '
          'auth.verifyOtp() or a direct API call?');
      await auth.abandonDraft();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.registerStep1);
      return;
    }

    // 2) Check server-side draft state via the public status endpoint.
    final res = await auth.api.getRegistrationStatus(widget.draftId);
    debugPrint('🔎 getRegistrationStatus → '
        'success=${res.success}, msg=${res.message}, data=${res.data}');

    if (!mounted) return;

    final data = (res.success && res.data is Map)
        ? Map<String, dynamic>.from(res.data as Map)
        : null;

    if (data == null || data['can_proceed'] == false) {
      debugPrint('❌ Draft not usable — '
          'data=${data?.toString() ?? "null"}');
      await auth.abandonDraft();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.registerStep1);
      return;
    }

    final step = (data['registration_step'] as num?)?.toInt() ?? 0;
    debugPrint('✅ Draft OK at step $step — allowing Step 2 screen');

    // If the server has progressed beyond step 1, jump to the correct step.
    if (step > 1 && step < 5) {
      final route = step == 2
          ? AppRoutes.registerStep3
          : step == 3
          ? AppRoutes.registerStep4
          : AppRoutes.registerStep5;
      Navigator.pushReplacementNamed(context, route,
          arguments: widget.draftId);
      return;
    }
    if (step >= 5) {
      Navigator.pushReplacementNamed(context, AppRoutes.registerReview,
          arguments: {'draftId': widget.draftId});
    }
  }

  String get _digits => _idC.text.replaceAll(RegExp(r'\D'), '');

  String? _validateId(String? value, AppLocalizations l10n) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return l10n.regEnterId;
    switch (_idType) {
      case 'nida':
        return digits.length == 20 ? null : l10n.regNidaLen;
      case 'voter_id':
        return digits.length == 12 ? null : l10n.regVoterLen;
      default:
        return digits.length >= 10 ? null : l10n.regLicenseLen;
    }
  }

  String _hint(AppLocalizations l10n) {
    switch (_idType) {
      case 'nida':
        return l10n.regNidaHint;
      case 'voter_id':
        return l10n.regVoterHint;
      default:
        return l10n.regLicenseHint;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _idImage = File(picked.path));
    }
  }

  void _showImageSheet() {
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
              title:
              Text(l10n.regChooseGallery, style: TextStyle(color: p.text)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: p.link),
              title: Text(l10n.regTakePhoto, style: TextStyle(color: p.text)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_idImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title: Text(l10n.regRemovePhoto,
                    style: TextStyle(color: p.text)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _idImage = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _next() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.registerTechnicianStep2(
      nida: _digits,
      idDocumentType: _idType,
      idDocumentImage: _idImage,
    );
    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.registerStep3,
        arguments: widget.draftId,
      );
    } else if (auth.errorMessage != null) {
      regSnack(context, auth.errorMessage!, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final p = RegPalette.of(context);
    final busy = auth.isLoading;

    return RegisterShell(
      step: 2,
      total: 6,
      title: l10n.regIdentityTitle,
      subtitle: l10n.regIdentitySubtitle,
      isLoading: busy,
      onNext: _validateId(_idC.text, l10n) == null ? _next : null,
      nextLabel: l10n.regContinue,
      onBack: () =>
          Navigator.pushReplacementNamed(context, AppRoutes.registerStep1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _idType,
            dropdownColor: p.card,
            style: TextStyle(fontSize: 15, color: p.text),
            iconEnabledColor: p.muted,
            items: [
              DropdownMenuItem(value: 'nida', child: Text(l10n.regIdNida)),
              DropdownMenuItem(
                  value: 'drivers_license', child: Text(l10n.regIdLicense)),
              DropdownMenuItem(value: 'voter_id', child: Text(l10n.regIdVoter)),
            ],
            onChanged: busy
                ? null
                : (v) => setState(() => _idType = v ?? 'nida'),
            decoration: regInputDecoration(context,
                hint: '', icon: Icons.assignment_ind_outlined),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _idC,
            enabled: !busy,
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) => _validateId(v, l10n),
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontSize: 15, color: p.text),
            decoration: regInputDecoration(context,
                hint: _hint(l10n), icon: Icons.badge_outlined),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: busy ? null : _showImageSheet,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: p.field,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.4)),
              ),
              child: _idImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_idImage!,
                    fit: BoxFit.cover, width: double.infinity),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 36, color: p.muted),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.regAddIdPhoto,
                      textAlign: TextAlign.center,
                      style:
                      TextStyle(color: p.muted, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}