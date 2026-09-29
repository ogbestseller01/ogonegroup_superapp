// lib/screens/auth/register_flow/register_step2_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../config/app_routes.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/loading_overlay.dart';

class RegisterStep2Screen extends StatefulWidget {
  final int technicianId;
  const RegisterStep2Screen({super.key, required this.technicianId});

  @override
  State<RegisterStep2Screen> createState() => _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends State<RegisterStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  String _idType = 'nida';
  File? _idImage;
  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;
  bool _isLoadingCheck = false;

  @override
  void initState() {
    super.initState();
    _checkStepAccess();
  }

  // ============================================================
  // 🔥 FIXED: Allow access if Step 1 is done (step >= 1)
  // ============================================================
  Future<void> _checkStepAccess() async {
    final auth = context.read<AuthProvider>();
    final step = await auth.getRegistrationStep(widget.technicianId);
    if (!mounted) return;
    if (step == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }
    // If Step 1 is NOT completed, go back to Step 1
    if (step < 1) {
      Navigator.pushReplacementNamed(context, AppRoutes.registerStep1);
    }
    // Otherwise stay (even if step >= 2, they can edit)
    // No automatic forward redirection – let the user use the "Next" button.
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  bool get _isFormValid => _formKey.currentState?.validate() ?? false;

  Future<void> _pickIdImage() async {
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
                  imageQuality: 80,
                );
                if (picked != null) {
                  setState(() => _idImage = File(picked.path));
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
                  imageQuality: 80,
                );
                if (picked != null) {
                  setState(() => _idImage = File(picked.path));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _ScannerScreen()),
    );
    setState(() => _isScanning = false);
    if (result != null) {
      final digits = result.replaceAll(RegExp(r'\D'), '');
      _idController.text = digits;
      _formKey.currentState?.validate();
    }
  }

  String? _validateId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the ID number';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'ID must contain digits only';
    }
    switch (_idType) {
      case 'nida':
        if (digits.length != 20) {
          return 'NIDA must be exactly 20 digits';
        }
        break;
      case 'voter_id':
        if (digits.length != 12) {
          return 'Voter ID must be exactly 12 digits';
        }
        break;
      case 'drivers_license':
        if (digits.length < 10) {
          return 'Driver\'s License must be at least 10 digits';
        }
        break;
    }
    return null;
  }

  Future<void> _nextStep() async {
    if (!_isFormValid) return;
    if (_idImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your ID document'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    auth.clearError();

    // ✅ Use provider method – sets isLoading = true
    final success = await auth.registerTechnicianStep2(
      technicianId: widget.technicianId,
      nida: _idController.text.trim(),
      idDocumentType: _idType,
      idDocumentImage: _idImage!,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.registerStep3,
        arguments: widget.technicianId,
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

  void _goBack() {
    Navigator.pushReplacementNamed(context, AppRoutes.registerStep1);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Step 2: Identification'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: auth.isLoading ? null : _goBack,
          tooltip: 'Back to Step 1',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: (auth.isLoading || _isLoadingCheck || !_isFormValid || _idImage == null)
                ? null
                : _nextStep,
            tooltip: 'Next',
          ),
        ],
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
                      Container(
                        width: 160,
                        height: 100,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: _idImage != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_idImage!, fit: BoxFit.cover),
                        )
                            : const Center(child: Text('Tap to upload ID')),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _pickIdImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                DropdownButtonFormField<String>(
                  value: _idType,
                  items: const [
                    DropdownMenuItem(value: 'nida', child: Text('NIDA')),
                    DropdownMenuItem(
                      value: 'drivers_license',
                      child: Text('Driver\'s License'),
                    ),
                    DropdownMenuItem(
                      value: 'voter_id',
                      child: Text('Voter\'s ID (KURA)'),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _idType = val!;
                      _formKey.currentState?.validate();
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Select ID Type',
                    prefixIcon: Icon(Icons.assignment_ind_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(
                    hintText: _getHintText(),
                    prefixIcon: const Icon(Icons.badge_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _isScanning ? null : _startScan,
                      tooltip: 'Scan barcode / QR code',
                    ),
                  ),
                  validator: _validateId,
                  keyboardType: TextInputType.text,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: 'Next →',
                  onPressed: _nextStep,
                  isLoading: auth.isLoading,
                  isDisabled: !_isFormValid || _idImage == null || auth.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getHintText() {
    switch (_idType) {
      case 'nida':
        return 'NIDA Number (20 digits)';
      case 'voter_id':
        return 'Voter ID (12 digits)';
      case 'drivers_license':
        return 'Driver\'s License (min 10 digits)';
      default:
        return 'Enter ID number';
    }
  }
}

// ============================================================
// Scanner screen — now using qr_code_scanner_plus instead of
// mobile_scanner (avoids the iOS 15.5+ deployment requirement).
// ============================================================
class _ScannerScreen extends StatefulWidget {
  const _ScannerScreen({super.key});

  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'ID_QR');
  QRViewController? _controller;
  bool _isFlashOn = false;
  bool _hasPopped = false;

  @override
  void reassemble() {
    super.reassemble();
    // Required workaround for hot reload on Android.
    if (_controller != null) {
      _controller!.pauseCamera();
      _controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_hasPopped) return;
      final rawValue = scanData.code;
      if (rawValue != null && rawValue.isNotEmpty) {
        _hasPopped = true;
        controller.pauseCamera();
        Navigator.pop(context, rawValue);
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan ID'),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              await _controller?.toggleFlash();
              final status = await _controller?.getFlashStatus();
              setState(() => _isFlashOn = status ?? false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller?.flipCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.white,
              borderRadius: 12,
              borderLength: 30,
              borderWidth: 6,
              cutOutWidth: 250,
              cutOutHeight: 100,
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align barcode/QR here',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}