// lib/screens/auth/register_flow/register_step4_screen.dart
// Shows Step 4 (services) then Step 5 (prices) in one screen, then submits.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/app_routes.dart';
import '../../../config/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_provider.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/register_step_scaffold.dart';

class RegisterStep4Screen extends StatefulWidget {
  final int technicianId;
  const RegisterStep4Screen({super.key, required this.technicianId});

  @override
  State<RegisterStep4Screen> createState() => _RegisterStep4ScreenState();
}

class _RegisterStep4ScreenState extends State<RegisterStep4Screen> {
  int _page = 0; // 0 = services (step 4), 1 = prices (step 5)

  final Set<int> _selected = {};
  bool _sameForAll = true;

  final _allMin = TextEditingController();
  final _allMax = TextEditingController();
  final Map<int, TextEditingController> _min = {};
  final Map<int, TextEditingController> _max = {};

  @override
  void initState() {
    super.initState();
    _checkAccess();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().fetchServices();
    });
  }

  @override
  void dispose() {
    _allMin.dispose();
    _allMax.dispose();
    for (final c in [..._min.values, ..._max.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _checkAccess() async {
    final step =
    await context.read<AuthProvider>().getRegistrationStep(widget.technicianId);
    if (!mounted) return;
    if (step == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else if (step < 3) {
      Navigator.pushReplacementNamed(context, AppRoutes.registerStep3,
          arguments: widget.technicianId);
    }
  }

  TextEditingController _minC(int id) =>
      _min.putIfAbsent(id, () => TextEditingController());
  TextEditingController _maxC(int id) =>
      _max.putIfAbsent(id, () => TextEditingController());

  bool _rangeOk(TextEditingController minC, TextEditingController maxC) {
    final min = double.tryParse(minC.text.trim());
    final max = double.tryParse(maxC.text.trim());
    return min != null && max != null && min >= 0 && max >= min;
  }

  bool get _pricesValid {
    if (_selected.isEmpty) return false;
    if (_sameForAll) return _rangeOk(_allMin, _allMax);
    return _selected.every((id) => _rangeOk(_minC(id), _maxC(id)));
  }

  void _back() {
    if (_page == 1) {
      setState(() => _page = 0);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.registerStep3,
          arguments: widget.technicianId);
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final services = _selected.map((id) {
      final minC = _sameForAll ? _allMin : _minC(id);
      final maxC = _sameForAll ? _allMax : _maxC(id);
      return {
        'service_id': id,
        'min_price': double.parse(minC.text.trim()),
        'max_price': double.parse(maxC.text.trim()),
      };
    }).toList();

    // Save services + prices, then submit for admin approval
    var ok = await auth.registerTechnicianStep4(
      technicianId: widget.technicianId,
      services: services,
    );
    if (ok) {
      ok = await auth.submitTechnicianRegistration(widget.technicianId);
    }
    if (!mounted) return;

    if (!ok) {
      if (auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage!), backgroundColor: AppTheme.error),
        );
      }
      return;
    }

    await StorageService.clearTechnicianData();
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text("You're all set!"),
        content: const Text(
          'Your registration is under review. '
              "We'll send you an SMS as soon as your account is approved.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
                  (_) => false,
            ),
            child: const Text('Go to login'),
          ),
        ],
      ),
    );
  }

  // ── Page 0: choose services ─────────────────────────────────────────────
  Widget _servicesPage(ServiceProvider sp, ThemeData theme) {
    if (sp.isLoading && sp.services.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (sp.services.isEmpty) {
      return const Center(child: Text('No services available. Please try again later.'));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sp.services.map((s) {
        final isSel = _selected.contains(s.id);
        return FilterChip(
          label: Text(s.name),
          selected: isSel,
          showCheckmark: false,
          selectedColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          labelStyle: TextStyle(
            color: isSel ? Colors.white : theme.colorScheme.onSurface,
          ),
          onSelected: (v) => setState(() {
            v ? _selected.add(s.id) : _selected.remove(s.id);
          }),
        );
      }).toList(),
    );
  }

  // ── Page 1: price ranges ────────────────────────────────────────────────
  Widget _priceRow(TextEditingController minC, TextEditingController maxC) {
    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      prefixText: 'TZS ',
      border: const OutlineInputBorder(),
    );
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: minC,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: deco('From'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: maxC,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: deco('To'),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _pricesPage(ServiceProvider sp, ThemeData theme) {
    final chosen = sp.services.where((s) => _selected.contains(s.id)).toList();
    final showMax = _allMax.text.isNotEmpty &&
        _allMin.text.isNotEmpty &&
        !_rangeOk(_allMin, _allMax);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (chosen.length > 1)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Same price for all services'),
            value: _sameForAll,
            onChanged: (v) => setState(() => _sameForAll = v),
          ),
        const SizedBox(height: 8),
        if (_sameForAll || chosen.length == 1) ...[
          Text(
            chosen.length == 1 ? chosen.first.name : '${chosen.length} services',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _priceRow(_allMin, _allMax),
          if (showMax)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '"To" must be higher than "From"',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
        ] else
          ...chosen.map(
                (s) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _priceRow(_minC(s.id), _maxC(s.id)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'This is a guide for customers. You can change it later in your profile.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sp = context.watch<ServiceProvider>();
    final theme = Theme.of(context);
    final isServices = _page == 0;

    // keep the "single service" case on the shared pair of fields
    if (!isServices && _selected.length == 1) _sameForAll = true;

    return RegisterStepScaffold(
      step: isServices ? 4 : 5,
      total: 5,
      title: isServices ? 'What do you do?' : 'Set your price range',
      subtitle: isServices
          ? 'Pick every service you offer.'
          : 'Customers see this range before they call you.',
      isLoading: auth.isLoading,
      buttonText: isServices ? 'Continue' : 'Submit registration',
      onNext: isServices
          ? (_selected.isNotEmpty ? () => setState(() => _page = 1) : null)
          : (_pricesValid ? _submit : null),
      onBack: _back,
      child: isServices ? _servicesPage(sp, theme) : _pricesPage(sp, theme),
    );
  }
}