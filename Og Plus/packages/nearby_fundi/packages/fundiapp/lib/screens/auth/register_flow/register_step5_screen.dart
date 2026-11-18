// lib/screens/auth/register_flow/register_step5_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/register_shell.dart';

class RegisterStep5Screen extends StatefulWidget {
  final int draftId;
  const RegisterStep5Screen({super.key, required this.draftId});

  @override
  State<RegisterStep5Screen> createState() => _RegisterStep5ScreenState();
}

class _RegisterStep5ScreenState extends State<RegisterStep5Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _relationC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _relationC.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    final auth = context.read<AuthProvider>();

    if (!auth.hasRegistrationToken) {
      await auth.abandonDraft();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.registerStep1);
      return;
    }

    final step = await auth.getRegistrationStep(widget.draftId);
    if (!mounted) return;

    if (step == null) {
      await auth.abandonDraft();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.registerStep1);
    } else if (step < 4) {
      Navigator.pushReplacementNamed(context, AppRoutes.registerStep4,
          arguments: widget.draftId);
    }
  }

  bool get _valid =>
      _nameC.text.trim().isNotEmpty &&
          _phoneC.text.trim().isNotEmpty &&
          _relationC.text.trim().isNotEmpty;

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.registerTechnicianStep5(
      nextOfKinName: _nameC.text.trim(),
      nextOfKinPhone: _phoneC.text.trim(),
      nextOfKinRelationship: _relationC.text.trim(),
    );
    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.registerReview,
        arguments: {
          'draftId': widget.draftId,
          'nextOfKinName': _nameC.text.trim(),
          'nextOfKinPhone': _phoneC.text.trim(),
          'nextOfKinRelationship': _relationC.text.trim(),
        },
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
      step: 5,
      total: 6,
      title: l10n.regKinTitle,
      subtitle: l10n.regKinSubtitle,
      isLoading: busy,
      onNext: _valid ? _next : null,
      nextLabel: l10n.regContinue,
      onBack: () => Navigator.pushReplacementNamed(
        context,
        AppRoutes.registerStep4,
        arguments: widget.draftId,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: () => setState(() {}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameC,
              enabled: !busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              style: TextStyle(fontSize: 15, color: p.text),
              decoration: regInputDecoration(context,
                  hint: l10n.regFullName, icon: Icons.person_outline_rounded),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.regNameRequired
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneC,
              enabled: !busy,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              style: TextStyle(fontSize: 15, color: p.text),
              decoration: regInputDecoration(context,
                  hint: l10n.regPhoneHint, icon: Icons.phone_outlined),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.regPhoneRequired
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _relationC,
              enabled: !busy,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(fontSize: 15, color: p.text),
              decoration: regInputDecoration(context,
                  hint: l10n.regKinRelationship, icon: Icons.people_outline_rounded),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.regKinRelationRequired
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}