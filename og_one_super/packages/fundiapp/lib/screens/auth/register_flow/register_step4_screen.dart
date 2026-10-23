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
  String _locale = 'en'; // default English

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
      context.read<ServiceProvider>().fetchServices(locale: _locale);
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

  void _setLocale(String locale) {
    if (_locale == locale) return;
    setState(() => _locale = locale);
    // Re-fetch so backend returns localized names if needed
    context.read<ServiceProvider>().fetchServices(
      forceRefresh: true,
      locale: locale,
    );
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
          SnackBar(
            content: Text(auth.errorMessage!),
            backgroundColor: AppTheme.error,
          ),
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

  // ── Language toggle ───────────────────────────────────────────────────
  Widget _languageToggle(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _locale == 'sw' ? 'Lugha:' : 'Language:',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(width: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'en', label: Text('EN')),
            ButtonSegment(value: 'sw', label: Text('SW')),
          ],
          selected: {_locale},
          onSelectionChanged: (selected) => _setLocale(selected.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  // ── Page 0: choose services ───────────────────────────────────────────
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
      return Center(
        child: Text(
          _locale == 'sw'
              ? 'Hakuna huduma zinazopatikana. Jaribu tena baadaye.'
              : 'No services available. Please try again later.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _languageToggle(theme),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sp.services.map((s) {
            final isSel = _selected.contains(s.id);
            final label = s.localizedName(_locale);
            return FilterChip(
              label: Text(label),
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
        ),
      ],
    );
  }

  // ── Page 1: price ranges ──────────────────────────────────────────────
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
            decoration: deco(_locale == 'sw' ? 'Kutoka' : 'From'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: maxC,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: deco(_locale == 'sw' ? 'Hadi' : 'To'),
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
            title: Text(
              _locale == 'sw'
                  ? 'Bei sawa kwa huduma zote'
                  : 'Same price for all services',
            ),
            value: _sameForAll,
            onChanged: (v) => setState(() => _sameForAll = v),
          ),
        const SizedBox(height: 8),
        if (_sameForAll || chosen.length == 1) ...[
          Text(
            chosen.length == 1
                ? chosen.first.localizedName(_locale)
                : (_locale == 'sw'
                ? '${chosen.length} huduma'
                : '${chosen.length} services'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _priceRow(_allMin, _allMax),
          if (showMax)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _locale == 'sw'
                    ? '"Hadi" lazima iwe juu ya "Kutoka"'
                    : '"To" must be higher than "From"',
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
                  Text(
                    s.localizedName(_locale),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _priceRow(_minC(s.id), _maxC(s.id)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          _locale == 'sw'
              ? 'Hii ni mwongozo kwa wateja. Unaweza kuibadilisha baadaye kwenye wasifu wako.'
              : 'This is a guide for customers. You can change it later in your profile.',
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

    if (!isServices && _selected.length == 1) _sameForAll = true;

    return RegisterStepScaffold(
      step: isServices ? 4 : 5,
      total: 5,
      title: isServices
          ? (_locale == 'sw' ? 'Unatoa huduma gani?' : 'What do you do?')
          : (_locale == 'sw' ? 'Weka bei yako' : 'Set your price range'),
      subtitle: isServices
          ? (_locale == 'sw'
          ? 'Chagua kila huduma unayotoa.'
          : 'Pick every service you offer.')
          : (_locale == 'sw'
          ? 'Wateja wanaona bei hii kabla ya kukupigia simu.'
          : 'Customers see this range before they call you.'),
      isLoading: auth.isLoading,
      buttonText: isServices
          ? (_locale == 'sw' ? 'Endelea' : 'Continue')
          : (_locale == 'sw' ? 'Wasilisha usajili' : 'Submit registration'),
      onNext: isServices
          ? (_selected.isNotEmpty ? () => setState(() => _page = 1) : null)
          : (_pricesValid ? _submit : null),
      onBack: _back,
      child: isServices ? _servicesPage(sp, theme) : _pricesPage(sp, theme),
    );
  }
}