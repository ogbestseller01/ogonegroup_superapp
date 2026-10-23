// lib/screens/auth/register_flow/register_step2_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../../../config/app_routes.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/register_step_scaffold.dart';

class RegisterStep2Screen extends StatefulWidget {
  final int technicianId;
  const RegisterStep2Screen({super.key, required this.technicianId});

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
    final step =
    await context.read<AuthProvider>().getRegistrationStep(widget.technicianId);
    if (!mounted) return;
    if (step == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else if (step < 1) {
      Navigator.pushReplacementNamed(context, AppRoutes.registerStep1);
    }
  }

  String? _validateId(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Enter the ID number';
    switch (_idType) {
      case 'nida':
        return digits.length == 20 ? null : 'NIDA must be exactly 20 digits';
      case 'voter_id':
        return digits.length == 12 ? null : 'Voter ID must be exactly 12 digits';
      default:
        return digits.length >= 10 ? null : 'License must be at least 10 digits';
    }
  }

  String get _hint {
    switch (_idType) {
      case 'nida':
        return 'NIDA number (20 digits)';
      case 'voter_id':
        return 'Voter ID (12 digits)';
      default:
        return 'License number (min 10 digits)';
    }
  }

  bool get _valid => _validateId(_idC.text) == null && _idImage != null;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280, // large enough for the admin to read the ID
      imageQuality: 85,
    );
    if (picked != null && mounted) setState(() => _idImage = File(picked.path));
  }

  void _imageSheet() {
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
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scan() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _ScannerScreen()),
    );
    if (result != null && mounted) {
      setState(() => _idC.text = result.replaceAll(RegExp(r'\D'), ''));
    }
  }

  Future<void> _next() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.registerTechnicianStep2(
      technicianId: widget.technicianId,
      nida: _idC.text.replaceAll(RegExp(r'\D'), ''),
      idDocumentType: _idType,
      idDocumentImage: _idImage!,
    );
    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.registerStep3,
          arguments: widget.technicianId);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return RegisterStepScaffold(
      step: 2,
      total: 5,
      title: 'Verify your identity',
      subtitle: 'Used only by our team to approve your account.',
      isLoading: auth.isLoading,
      onNext: _valid ? _next : null,
      onBack: () => Navigator.pushReplacementNamed(context, AppRoutes.registerStep1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _idType,
            items: const [
              DropdownMenuItem(value: 'nida', child: Text('NIDA')),
              DropdownMenuItem(value: 'drivers_license', child: Text("Driver's license")),
              DropdownMenuItem(value: 'voter_id', child: Text("Voter's ID (KURA)")),
            ],
            onChanged: (v) => setState(() => _idType = v ?? 'nida'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.assignment_ind_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _idC,
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: _validateId,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _hint,
              prefixIcon: const Icon(Icons.badge_outlined),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Scan barcode / QR',
                onPressed: _scan,
              ),
            ),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _imageSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
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
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 36,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  const Text('Tap to add a photo of your ID'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barcode / QR scanner ──────────────────────────────────────────────────
class _ScannerScreen extends StatefulWidget {
  const _ScannerScreen();

  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'ID_QR');
  QRViewController? _controller;
  bool _flash = false;
  bool _done = false;

  @override
  void reassemble() {
    super.reassemble();
    _controller?.pauseCamera();
    _controller?.resumeCamera();
  }

  void _onCreated(QRViewController c) {
    _controller = c;
    c.scannedDataStream.listen((scan) {
      final code = scan.code;
      if (_done || code == null || code.isEmpty) return;
      _done = true;
      c.pauseCamera();
      Navigator.pop(context, code);
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
            icon: Icon(_flash ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              await _controller?.toggleFlash();
              final s = await _controller?.getFlashStatus();
              if (mounted) setState(() => _flash = s ?? false);
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
            key: _qrKey,
            onQRViewCreated: _onCreated,
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
              child: Text('Align barcode / QR here',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}