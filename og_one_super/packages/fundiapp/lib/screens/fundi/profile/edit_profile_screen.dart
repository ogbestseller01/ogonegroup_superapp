// lib/screens/fundi/profile/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/technician_provider.dart';
import '../../../utils/image_utils.dart';
import '../../../widgets/custom_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../../config/app_theme.dart';
import 'pick_map_location_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nidaController = TextEditingController();
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _areaController = TextEditingController();

  File? _selectedImage;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final tech = context.read<TechnicianProvider>().technician;
    final user = auth.user;

    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
    _nidaController.text = tech?.nida ?? '';
    _bioController.text = tech?.bio ?? '';
    _hourlyRateController.text = tech?.hourlyRate?.toString() ?? '';
    _areaController.text = tech?.area ?? '';
    _latitude = tech?.latitude;
    _longitude = tech?.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nidaController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _pickLocationOnMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PickMapLocationScreen(
          initialCenter: (_latitude != null && _longitude != null)
              ? LatLng(_latitude!, _longitude!)
              : null,
          initialPlaceName: _areaController.text.trim().isNotEmpty
              ? _areaController.text.trim()
              : null,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _areaController.text = result['name'] as String? ?? '';
        _latitude = result['lat'] as double?;
        _longitude = result['lng'] as double?;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final techProvider = context.read<TechnicianProvider>();

    auth.clearError();

    // 1. Update user basic info
    final userData = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    };
    bool userSuccess = await auth.updateProfile(userData);

    // 2. Update technician profile (including lat/lng when available)
    final techData = <String, dynamic>{
      'nida': _nidaController.text.trim(),
      'bio': _bioController.text.trim(),
      'hourly_rate': double.tryParse(_hourlyRateController.text.trim()),
      'area': _areaController.text.trim(),
      if (_latitude != null) 'latitude': _latitude,
      if (_longitude != null) 'longitude': _longitude,
    };
    techData.removeWhere((key, value) => value == null || value == '');

    bool techSuccess = true;
    if (techData.isNotEmpty) {
      techSuccess = await techProvider.updateProfile(techData);
    }

    // 3. Upload photo if changed
    bool photoSuccess = true;
    if (_selectedImage != null) {
      photoSuccess = await techProvider.uploadProfilePhoto(_selectedImage!);
    }

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (userSuccess && techSuccess && photoSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(l10n.profileUpdated),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? techProvider.error ?? l10n.updateFailed,
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading ||
        context.watch<TechnicianProvider>().isLoading;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tech = context.watch<TechnicianProvider>().technician;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.editProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Photo
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            : (tech?.profilePhoto != null
                            ? Image.network(
                          ImageUtils.getFullImageUrl(
                              tech!.profilePhoto!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildDefaultAvatar(theme),
                        )
                            : _buildDefaultAvatar(theme)),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withOpacity(0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tapToChangePhoto,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 32),

              // Form Fields
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: l10n.name,
                        icon: Icons.person_outline,
                        validator: (v) =>
                        (v != null && v.isNotEmpty) ? null : 'Name required',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: l10n.phone,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nidaController,
                        label: l10n.nidaNumber,
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _bioController,
                        label: l10n.bio,
                        icon: Icons.description_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _hourlyRateController,
                        label: l10n.hourlyRate,
                        icon: Icons.attach_money_rounded,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        prefixText: 'TZS ',
                      ),
                      const SizedBox(height: 16),

                      // ========== AREA SECTION (Type OR Map) ==========
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.area,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _areaController,
                            style: theme.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.location_on_outlined,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.map_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                                tooltip: l10n.pickOnMap,
                                onPressed: _pickLocationOnMap,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                  width: 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2.0,
                                ),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              hintText: l10n.typeAreaOrPickOnMap,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Two clear action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    FocusScope.of(context)
                                        .requestFocus(FocusNode());
                                  },
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: Text(l10n.typeArea),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickLocationOnMap,
                                  icon: const Icon(Icons.map_outlined, size: 18),
                                  label: Text(l10n.pickOnMap),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_latitude != null && _longitude != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '📍 ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // =================================================
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: l10n.saveChanges,
                onPressed: isLoading ? null : _save,
                isLoading: isLoading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          context.read<AuthProvider>().user?.name[0].toUpperCase() ?? 'F',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefixText,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 22),
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}