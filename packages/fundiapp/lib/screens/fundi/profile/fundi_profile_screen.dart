import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_routes.dart';
import '../../../models/user.dart';
import '../../../models/service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_provider.dart';
import '../../../providers/technician_provider.dart';
import '../../../widgets/confirmation_dialog.dart';
import '../../../utils/image_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../config/app_theme.dart';

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
      context.read<TechnicianProvider>().fetchMyProfile();
      context.read<ServiceProvider>().fetchServices(forceRefresh: true);
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      context.read<TechnicianProvider>().fetchMyProfile(),
      context.read<ServiceProvider>().fetchServices(forceRefresh: true),
    ]);
  }

  // ✅ FIX: ensure the freshest technician data is loaded before
  // navigating into the Edit Profile screen, so it never opens
  // with stale/empty fields.
  Future<void> _goToEditProfile() async {
    await context.read<TechnicianProvider>().fetchMyProfile();
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.editProfile);
  }

  // ✅ NEW: find the matching catalog Service (with categories) for
  // a technician's selected service, by ID. The technician's own
  // servicePrices pivot data doesn't carry category info, but the
  // full service catalog from ServiceProvider does.
  Service? _matchCatalogService(List<Service> catalog, int serviceId) {
    for (final s in catalog) {
      if (s.id == serviceId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tech = context.watch<TechnicianProvider>();
    final servicesProvider = context.watch<ServiceProvider>();
    final user = auth.user;
    final technician = tech.technician;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.profile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
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
              // ---- Modern Header Card ----
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: technician?.profilePhoto != null
                                ? Image.network(
                              ImageUtils.getFullImageUrl(technician!.profilePhoto!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultAvatar(user, theme),
                            )
                                : _defaultAvatar(user, theme),
                          ),
                        ),
                        GestureDetector(
                          onTap: _goToEditProfile,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 16, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? '',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                          ),
                          if (user?.phone != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '📱 ${user!.phone}',
                              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              // ✅ REMOVED: ONLINE/OFFLINE pill per request —
                              // online/offline logic no longer surfaced here.
                              if (technician != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: technician.verified
                                        ? AppTheme.success.withOpacity(0.85)
                                        : Colors.orange.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    technician.verified
                                        ? '✓ VERIFIED'
                                        : (technician.verificationStatus ?? 'pending').toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---- Modern Services Section ----
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.build_circle_outlined, color: theme.colorScheme.primary),
                        ),
                        title: Text(
                          '${l10n.servicesIOffer} (${technician?.servicePrices.length ?? 0})',
                          style: theme.textTheme.titleMedium,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onTap: () => _showServicesDialog(context),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: technician?.servicePrices.isNotEmpty == true
                          ? Column(
                        children: technician!.servicePrices.map((sp) {
                          // ✅ NEW: cross-reference catalog to get this service's category
                          final catalogMatch = _matchCatalogService(servicesProvider.services, sp.id);
                          final categoryLabel = (catalogMatch != null && catalogMatch.categories.isNotEmpty)
                              ? catalogMatch.categories.map((c) => c.name).join(', ')
                              : null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sp.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'TZS ${sp.minPrice.toStringAsFixed(0)} - ${sp.maxPrice.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (categoryLabel != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    categoryLabel,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      )
                          : Text(l10n.noServicesSelected, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---- Profile Details ----
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.profileDetails, style: theme.textTheme.titleMedium),
                      const Divider(height: 24),
                      if (technician?.bio != null && technician!.bio!.isNotEmpty) ...[
                        _detailTile(l10n.bio, technician!.bio!, theme),
                        const Divider(height: 16),
                      ],
                      if (technician?.experience != null) ...[
                        _detailTile(l10n.experience, '${technician!.experience} ${l10n.years}', theme),
                        const Divider(height: 16),
                      ],
                      if (technician?.hourlyRate != null) ...[
                        _detailTile(l10n.hourlyRate, '${l10n.tzs} ${technician!.hourlyRate!.toStringAsFixed(0)}', theme),
                        const Divider(height: 16),
                      ],
                      if (technician?.area != null && technician!.area!.isNotEmpty) ...[
                        _detailTile(l10n.area, technician!.area!, theme),
                        const Divider(height: 16),
                      ],
                      // ✅ NEW: NIDA — now actually parsed and shown, partially masked
                      if (technician?.nida != null && technician!.nida!.isNotEmpty) ...[
                        _detailTile('NIDA', _maskNida(technician.nida!), theme),
                        const Divider(height: 16),
                      ],
                      if (technician?.verificationStatus != null) ...[
                        _detailTile('Verification', technician!.verificationStatus!.toUpperCase(), theme),
                        const Divider(height: 16),
                      ],
                      _detailTile(l10n.accountStatus, l10n.active, theme),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ---- Settings & Logout ----
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: Text(l10n.settings),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.dividerColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showConfirmationDialog(context, l10n.logout, l10n.logoutConfirmation);
                    if (confirm == true) {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
                      }
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(l10n.logout),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showConfirmationDialog(
                    context,
                    l10n.deleteAccount,
                    l10n.deleteAccountConfirmation,
                  );
                  if (confirm == true) {
                    await auth.deleteAccount();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l10n.deleteAccount, style: TextStyle(color: AppTheme.error)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEW: mask NIDA like 1990****3147 so full ID isn't shown in plain sight
  String _maskNida(String nida) {
    if (nida.length <= 8) return nida;
    final start = nida.substring(0, 4);
    final end = nida.substring(nida.length - 4);
    return '$start${'*' * (nida.length - 8)}$end';
  }

  Widget _defaultAvatar(User? user, ThemeData theme) {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Text(
          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'F',
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _detailTile(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: theme.textTheme.bodySmall)),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  void _showServicesDialog(BuildContext context) {
    final provider = context.read<TechnicianProvider>();
    final serviceProvider = context.read<ServiceProvider>();
    final technician = provider.technician;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Pre-fill with current service IDs and Prices
    final Map<int, Map<String, TextEditingController>> priceControllers = {};
    final Set<int> selectedIds = {};

    if (technician != null) {
      for (var sp in technician.servicePrices) {
        selectedIds.add(sp.id);
        priceControllers[sp.id] = {
          'min': TextEditingController(text: sp.minPrice.toStringAsFixed(0)),
          'max': TextEditingController(text: sp.maxPrice.toStringAsFixed(0)),
        };
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.build_circle_outlined, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Text('Edit Services & Prices', style: theme.textTheme.titleLarge),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: serviceProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              shrinkWrap: true,
              itemCount: serviceProvider.services.length,
              itemBuilder: (ctx, i) {
                final service = serviceProvider.services[i];
                final isSelected = selectedIds.contains(service.id);
                final categoryLabel = service.categories.isNotEmpty
                    ? service.categories.map((c) => c.name).join(', ')
                    : null;

                // Initialize controllers if selected and not already present
                if (isSelected && !priceControllers.containsKey(service.id)) {
                  priceControllers[service.id] = {
                    'min': TextEditingController(text: '0'),
                    'max': TextEditingController(text: '0'),
                  };
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary.withOpacity(0.05) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected ? theme.colorScheme.primary.withOpacity(0.3) : Colors.transparent),
                  ),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: Text(service.name, style: theme.textTheme.bodyMedium),
                        subtitle: categoryLabel != null
                            ? Text(categoryLabel, style: theme.textTheme.bodySmall)
                            : null,
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              selectedIds.add(service.id);
                              if (!priceControllers.containsKey(service.id)) {
                                priceControllers[service.id] = {
                                  'min': TextEditingController(text: '0'),
                                  'max': TextEditingController(text: '0'),
                                };
                              }
                            } else {
                              selectedIds.remove(service.id);
                              priceControllers[service.id]?.forEach((key, c) => c.dispose());
                              priceControllers.remove(service.id);
                            }
                          });
                        },
                        activeColor: theme.colorScheme.primary,
                        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (isSelected) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 48, right: 8, bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: priceControllers[service.id]!['min'],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Min Price (TZS)',
                                    prefixText: 'TZS ',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: priceControllers[service.id]!['max'],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Max Price (TZS)',
                                    prefixText: 'TZS ',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (selectedIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.selectAtLeastOneService),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                // Validate prices
                for (var id in selectedIds) {
                  final min = double.tryParse(priceControllers[id]!['min']!.text.trim());
                  final max = double.tryParse(priceControllers[id]!['max']!.text.trim());
                  if (min == null || max == null || min < 0 || max < 0 || max < min) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid price range'), backgroundColor: AppTheme.error),
                    );
                    return;
                  }
                }

                // Prepare Data
                final List<int> ids = selectedIds.toList();
                final List<Map<String, dynamic>> prices = [];
                for (var id in selectedIds) {
                  prices.add({
                    'service_id': id,
                    'min_price': double.parse(priceControllers[id]!['min']!.text.trim()),
                    'max_price': double.parse(priceControllers[id]!['max']!.text.trim()),
                  });
                }

                // Show loader
                Navigator.pop(ctx);
                // Update Services and Prices
                await provider.updateServices(ids);
                await provider.updateServicePrices(prices);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Services & Prices updated successfully'),
                    backgroundColor: theme.colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(l10n.saveChanges),
            ),
          ],
        ),
      ),
    );
  }
}