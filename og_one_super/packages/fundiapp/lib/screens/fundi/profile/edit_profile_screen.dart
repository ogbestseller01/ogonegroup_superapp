// lib/screens/fundi/profile/edit_profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../config/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/technician_provider.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/custom_button.dart';
import 'pick_map_location_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController();
  final _nidaC = TextEditingController();
  final _bioC = TextEditingController();
  final _hourlyC = TextEditingController();
  final _areaC = TextEditingController();

  File? _photo;
  double? _lat;
  double? _lng;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    final tech = context.read<TechnicianProvider>().technician;

    _nameC.text = user?.name ?? '';
    _phoneC.text = user?.phone ?? '';
    _bioC.text = tech?.bio ?? '';
    _areaC.text = tech?.area ?? '';
    _lat = tech?.latitude;
    _lng = tech?.longitude;

    final nida = tech?.nida ?? '';
    _nidaC.text = nida.length > 8
        ? '${nida.substring(0, 4)}${'*' * (nida.length - 8)}${nida.substring(nida.length - 4)}'
        : nida;

    final rate = tech?.hourlyRate;
    if (rate != null && rate > 0) {
      _hourlyC.text = rate == rate.roundToDouble()
          ? rate.toStringAsFixed(0)
          : rate.toString();
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _nidaC.dispose();
    _bioC.dispose();
    _hourlyC.dispose();
    _areaC.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked != null && mounted) setState(() => _photo = File(picked.path));
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PickMapLocationScreen(
          initialCenter:
          (_lat != null && _lng != null) ? LatLng(_lat!, _lng!) : null,
          initialPlaceName:
          _areaC.text.trim().isNotEmpty ? _areaC.text.trim() : null,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _areaC.text = result['name'] as String? ?? '';
        _lat = result['lat'] as double?;
        _lng = result['lng'] as double?;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final tech = context.read<TechnicianProvider>();
    final l10n = AppLocalizations.of(context)!;

    setState(() => _saving = true);
    auth.clearError();

    // 1) account basics
    final userOk = await auth.updateProfile({
      'name': _nameC.text.trim(),
      'phone': _phoneC.text.trim(),
    });
    if (!userOk) return _fail(auth.errorMessage ?? l10n.updateFailed);

    // 2) technician details. Area text without coordinates is geocoded server-side.
    final hourly = double.tryParse(_hourlyC.text.trim());
    final area = _areaC.text.trim();
    final techOk = await tech.updateProfile({
      'bio': _bioC.text.trim(),
      if (hourly != null) 'hourly_rate': hourly,
      if (area.isNotEmpty) 'area': area,
      if (area.isNotEmpty && _lat != null && _lng != null) ...{
        'latitude': _lat,
        'longitude': _lng,
      },
    });
    if (!techOk) return _fail(tech.error ?? l10n.updateFailed);

    // 3) photo, only if changed
    if (_photo != null) {
      final photoOk = await tech.uploadProfilePhoto(_photo!);
      if (!photoOk) return _fail(tech.error ?? l10n.updateFailed);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    _snack(l10n.profileUpdated);
    Navigator.pop(context);
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _saving = false);
    _snack(message, error: true);
  }

  Widget _avatar(ThemeData theme) {
    final name = context.read<AuthProvider>().user?.name ?? '';
    final initial = Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'F',
        style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary),
      ),
    );

    if (_photo != null) return Image.file(_photo!, fit: BoxFit.cover);

    final current = context.watch<TechnicianProvider>().technician?.profilePhoto;
    return AppNetworkImage(path: current, fallback: initial);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.editProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(child: _avatar(theme)),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.camera_alt,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.tapToChangePhoto, style: theme.textTheme.bodySmall),
              const SizedBox(height: 28),
              TextFormField(
                controller: _nameC,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneC,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nidaC,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: l10n.nidaNumber,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  helperText: 'Set during registration. Contact support to change.',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioC,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.bio,
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hourlyC,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.hourlyRate,
                  prefixText: 'TZS ',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaC,
                textCapitalization: TextCapitalization.words,
                // Typed text invalidates old map coordinates; backend re-geocodes.
                onChanged: (_) => setState(() {
                  _lat = null;
                  _lng = null;
                }),
                decoration: InputDecoration(
                  labelText: l10n.area,
                  hintText: l10n.typeAreaOrPickOnMap,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.map_outlined,
                        color: theme.colorScheme.primary),
                    tooltip: l10n.pickOnMap,
                    onPressed: _pickOnMap,
                  ),
                ),
              ),
              if (_lat != null && _lng != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text('Location set on map',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.green)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              CustomButton(
                text: l10n.saveChanges,
                onPressed: _save,
                isLoading: _saving,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}