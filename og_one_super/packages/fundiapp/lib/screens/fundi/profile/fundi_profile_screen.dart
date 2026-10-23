import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../config/app_routes.dart';
import '../../../config/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/service.dart';
import '../../../models/technician.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_provider.dart';
import '../../../providers/technician_provider.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/confirmation_dialog.dart';
import '../../../widgets/custom_button.dart';

class FundiProfileScreen extends StatefulWidget {
  const FundiProfileScreen({super.key});

  @override
  State<FundiProfileScreen> createState() => _FundiProfileScreenState();
}

class _FundiProfileScreenState extends State<FundiProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TechnicianProvider>().fetchMyProfile();
      context.read<ServiceProvider>().fetchServices(forceRefresh: true);
    });
  }

  Future<void> _refreshAll() => Future.wait([
    context.read<TechnicianProvider>().fetchMyProfile(),
    context.read<ServiceProvider>().fetchServices(forceRefresh: true),
  ]);

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.error : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _goToEditProfile() async {
    await context.read<TechnicianProvider>().fetchMyProfile();
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.editProfile);
  }

  Future<void> _editServices() async {
    final tech = context.read<TechnicianProvider>();
    final catalog = context.read<ServiceProvider>().services;

    final prices = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ServicesEditorSheet(
        current: tech.technician?.servicePrices ?? const [],
        catalog: catalog,
      ),
    );
    if (prices == null || !mounted) return;

    final ok = await tech.updateServicePrices(prices);
    if (!mounted) return;
    _snack(ok ? 'Services & prices updated' : (tech.error ?? 'Update failed'),
        error: !ok);
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm =
    await showConfirmationDialog(context, l10n.logout, l10n.logoutConfirmation);
    if (confirm != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showConfirmationDialog(
        context, l10n.deleteAccount, l10n.deleteAccountConfirmation);
    if (confirm != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.deleteAccount();
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } else {
      _snack(auth.errorMessage ?? 'Could not delete account', error: true);
    }
  }

  String _maskNida(String nida) {
    if (nida.length <= 8) return nida;
    return '${nida.substring(0, 4)}${'*' * (nida.length - 8)}${nida.substring(nida.length - 4)}';
  }

  String? _categoryLabel(List<Service> catalog, int serviceId) {
    for (final s in catalog) {
      if (s.id == serviceId && s.categories.isNotEmpty) {
        return s.categories.map((c) => c.name).join(', ');
      }
    }
    return null;
  }

  // ───────────── SECTIONS ─────────────

  Widget _header(ThemeData theme, AuthProvider auth, Technician? t) {
    final user = auth.user;
    final name = user?.name ?? '';
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';

    final initial = Container(
      color: Colors.white.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'F',
        style: const TextStyle(
            fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );

    final verified = t?.verified ?? false;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white),
                child: ClipOval(
                  child: AppNetworkImage(
                    path: t?.profilePhoto,
                    fallback: initial,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _goToEditProfile,
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.edit, size: 16, color: AppTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                if (email.isNotEmpty)
                  Text(email,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85))),
                if (phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(phone,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85))),
                  ),
                if (t != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: verified
                          ? AppTheme.success.withValues(alpha: 0.9)
                          : Colors.orange.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      verified
                          ? '✓ VERIFIED'
                          : (t.verificationStatus ?? 'pending').toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _servicesCard(ThemeData theme, AppLocalizations l10n, Technician? t,
      List<Service> catalog) {
    final prices = t?.servicePrices ?? const <TechnicianServicePrice>[];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.build_circle_outlined,
                  color: theme.colorScheme.primary),
            ),
            title: Text('${l10n.servicesIOffer} (${prices.length})',
                style: theme.textTheme.titleMedium),
            trailing: const Icon(Icons.edit_outlined, size: 20),
            onTap: _editServices,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: prices.isEmpty
                ? Text(l10n.noServicesSelected, style: theme.textTheme.bodySmall)
                : Column(
              children: [
                for (final sp in prices)
                  _servicePriceTile(
                      theme, sp, _categoryLabel(catalog, sp.id)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _servicePriceTile(
      ThemeData theme, TechnicianServicePrice sp, String? category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(sp.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(
                'TZS ${sp.minPrice.toStringAsFixed(0)} - ${sp.maxPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (category != null) ...[
            const SizedBox(height: 4),
            Text(category,
                style: theme.textTheme.bodySmall?.copyWith(
                    color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ],
      ),
    );
  }

  Widget _detailsCard(ThemeData theme, AppLocalizations l10n, Technician? t) {
    final rows = <MapEntry<String, String>>[];

    if (t != null) {
      if ((t.bio ?? '').isNotEmpty) rows.add(MapEntry(l10n.bio, t.bio!));
      if (t.experience > 0) {
        rows.add(MapEntry(l10n.experience, '${t.experience} ${l10n.years}'));
      }
      if ((t.hourlyRate ?? 0) > 0) {
        rows.add(MapEntry(
            l10n.hourlyRate, '${l10n.tzs} ${t.hourlyRate!.toStringAsFixed(0)}'));
      }
      if ((t.area ?? '').isNotEmpty) rows.add(MapEntry(l10n.area, t.area!));
      if ((t.nida ?? '').isNotEmpty) rows.add(MapEntry('NIDA', _maskNida(t.nida!)));
      rows.add(MapEntry(
        l10n.accountStatus,
        t.verified ? l10n.active : (t.verificationStatus ?? 'pending').toUpperCase(),
      ));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.profileDetails, style: theme.textTheme.titleMedium),
          const Divider(height: 24),
          for (var i = 0; i < rows.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: 100,
                    child: Text(rows[i].key, style: theme.textTheme.bodySmall)),
                Expanded(
                    child:
                    Text(rows[i].value, style: theme.textTheme.bodyMedium)),
              ],
            ),
            if (i < rows.length - 1) const Divider(height: 16),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tech = context.watch<TechnicianProvider>();
    final catalog = context.watch<ServiceProvider>().services;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final t = tech.technician;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.profile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.home),
        ),
      ),
      body: tech.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _header(theme, auth, t),
              const SizedBox(height: 20),
              _servicesCard(theme, l10n, t, catalog),
              const SizedBox(height: 20),
              _detailsCard(theme, l10n, t),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.settings),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: Text(l10n.settings),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.dividerColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(l10n.logout),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(
                        color: AppTheme.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _deleteAccount,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l10n.deleteAccount),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════ SERVICES & PRICES EDITOR ═══════════════════════════════

class _ServicesEditorSheet extends StatefulWidget {
  final List<TechnicianServicePrice> current;
  final List<Service> catalog;

  const _ServicesEditorSheet({required this.current, required this.catalog});

  @override
  State<_ServicesEditorSheet> createState() => _ServicesEditorSheetState();
}

class _ServicesEditorSheetState extends State<_ServicesEditorSheet> {
  final Set<int> _selected = {};
  final Map<int, TextEditingController> _min = {};
  final Map<int, TextEditingController> _max = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final sp in widget.current) {
      _selected.add(sp.id);
      _min[sp.id] = TextEditingController(text: sp.minPrice.toStringAsFixed(0));
      _max[sp.id] = TextEditingController(text: sp.maxPrice.toStringAsFixed(0));
    }
  }

  @override
  void dispose() {
    for (final c in [..._min.values, ..._max.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggle(int id, bool on) {
    setState(() {
      _error = null;
      if (on) {
        _selected.add(id);
        _min.putIfAbsent(id, () => TextEditingController());
        _max.putIfAbsent(id, () => TextEditingController());
      } else {
        _selected.remove(id);
      }
    });
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    if (_selected.isEmpty) {
      setState(() => _error = l10n.selectAtLeastOneService);
      return;
    }

    final result = <Map<String, dynamic>>[];
    for (final id in _selected) {
      final min = double.tryParse(_min[id]!.text.trim());
      final max = double.tryParse(_max[id]!.text.trim());
      if (min == null || max == null || max < min) {
        setState(() => _error = 'Enter a valid price range for every service');
        return;
      }
      result.add({'service_id': id, 'min_price': min, 'max_price': max});
    }
    Navigator.pop(context, result);
  }

  Widget _priceField(TextEditingController c, String label) {
    return Expanded(
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() => _error = null),
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'TZS ',
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final height = MediaQuery.of(context).size.height * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Edit services & prices',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
            Expanded(
              child: widget.catalog.isEmpty
                  ? const Center(child: Text('No services available.'))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.catalog.length,
                itemBuilder: (context, i) {
                  final s = widget.catalog[i];
                  final on = _selected.contains(s.id);
                  final category = s.categories.isNotEmpty
                      ? s.categories.map((c) => c.name).join(', ')
                      : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: on
                          ? theme.colorScheme.primary
                          .withValues(alpha: 0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: on
                            ? theme.colorScheme.primary
                            .withValues(alpha: 0.3)
                            : theme.dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.name),
                          subtitle: category != null
                              ? Text(category,
                              style: theme.textTheme.bodySmall)
                              : null,
                          value: on,
                          onChanged: (v) => _toggle(s.id, v == true),
                        ),
                        if (on)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                            child: Row(
                              children: [
                                _priceField(_min[s.id]!, 'From'),
                                const SizedBox(width: 10),
                                _priceField(_max[s.id]!, 'To'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: CustomButton(
                text: l10n.saveChanges,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}