// lib/screens/fundi/profile/fundi_profile_screen.dart
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

// ─── Shared look helpers ─────────────────────────────────────────────────
/// Navy is unreadable on the dark background, so gold is used in dark mode.
Color _accent(bool isDark) => isDark ? AppTheme.secondary : AppTheme.primary;
Color _cardBg(bool isDark) => isDark ? AppTheme.darkSurface : Colors.white;
Color _cardBorder(bool isDark) =>
    isDark ? AppTheme.darkBorder : AppTheme.borderLight.withValues(alpha: 0.30);
Color _ink(bool isDark) => isDark ? Colors.white : AppTheme.primary;
Color _muted(bool isDark) =>
    isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;
double _hPad(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 360 ? 12.0 : 16.0;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      constraints: const BoxConstraints(maxWidth: 560),
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

  Widget _titleRow(AppLocalizations l10n, bool isDark) {
    final h = _hPad(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(h + 2, 16, h, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.secondary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.profile,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                inherit: true,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: _ink(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(bool isDark, AuthProvider auth, Technician? t) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final user = auth.user;
    final name = user?.name ?? '';
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';
    final avatarSize = compact ? 68.0 : 84.0;

    final initial = Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'F',
        style: TextStyle(
          inherit: true,
          fontSize: compact ? 30 : 38,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
        ),
      ),
    );

    final verified = t?.verified ?? false;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(compact ? 16 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondary.withValues(alpha: 0.30),
                    AppTheme.secondary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.secondary, width: 2),
                    ),
                    child: SizedBox(
                      width: avatarSize,
                      height: avatarSize,
                      child: ClipOval(
                        child: AppNetworkImage(
                          path: t?.profilePhoto,
                          fallback: initial,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: AppTheme.secondary,
                      shape: const CircleBorder(
                        side: BorderSide(color: AppTheme.primary, width: 2),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _goToEditProfile,
                        child: const SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(Icons.edit_rounded,
                              size: 16, color: AppTheme.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        inherit: true,
                        fontSize: compact ? 17 : 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.mail_outline_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.75)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                inherit: true,
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.75)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                inherit: true,
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (t != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: verified
                              ? AppTheme.success
                              : AppTheme.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          verified
                              ? '✓ VERIFIED'
                              : (t.verificationStatus ?? 'pending')
                              .toUpperCase(),
                          style: TextStyle(
                            inherit: true,
                            color: verified ? Colors.white : AppTheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card shell. Uses Material so ink splashes of children stay visible
  /// (this is what fixes the "ListTile background color or ink splashes may
  /// be invisible" assertion).
  Widget _card(bool isDark, {required Widget child}) {
    return Material(
      color: _cardBg(isDark),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _cardBorder(isDark)),
      ),
      child: child,
    );
  }

  Widget _servicesCard(bool isDark, AppLocalizations l10n, Technician? t,
      List<Service> catalog) {
    final prices = t?.servicePrices ?? const <TechnicianServicePrice>[];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _card(
        isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _editServices,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _accent(isDark).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(Icons.build_circle_outlined,
                          color: _accent(isDark)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${l10n.servicesIOffer} (${prices.length})',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          inherit: true,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ink(isDark),
                        ),
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _accent(isDark).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(Icons.edit_outlined,
                          size: 19, color: _accent(isDark)),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: prices.isEmpty
                  ? Text(
                l10n.noServicesSelected,
                style: TextStyle(
                  inherit: true,
                  fontSize: 13,
                  color: _muted(isDark),
                ),
              )
                  : Column(
                children: [
                  for (final sp in prices)
                    _servicePriceTile(
                        isDark, sp, _categoryLabel(catalog, sp.id)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicePriceTile(
      bool isDark, TechnicianServicePrice sp, String? category) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppTheme.navy50.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent(isDark).withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            spacing: 10,
            children: [
              Text(
                sp.name,
                style: TextStyle(
                  inherit: true,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _ink(isDark),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent(isDark).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'TZS ${sp.minPrice.toStringAsFixed(0)} - ${sp.maxPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    inherit: true,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _accent(isDark),
                  ),
                ),
              ),
            ],
          ),
          if (category != null) ...[
            const SizedBox(height: 5),
            Text(
              category,
              style: TextStyle(
                inherit: true,
                fontSize: 12,
                color: _muted(isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailsCard(bool isDark, AppLocalizations l10n, Technician? t) {
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

    final compact = MediaQuery.sizeOf(context).width < 360;
    final labelW = compact ? 86.0 : 108.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.profileDetails,
                  style: TextStyle(
                    inherit: true,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _ink(isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < rows.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: labelW,
                  child: Text(
                    rows[i].key,
                    style: TextStyle(
                      inherit: true,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _muted(isDark),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    rows[i].value,
                    style: TextStyle(
                      inherit: true,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: _ink(isDark),
                    ),
                  ),
                ),
              ],
            ),
            if (i < rows.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Divider(
                  height: 1,
                  color: _cardBorder(isDark),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final c = color ?? _ink(isDark);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          minimumSize: const Size(0, 52),
          backgroundColor: _cardBg(isDark),
          side: BorderSide(
            color: color != null ? color.withValues(alpha: 0.5) : _cardBorder(isDark),
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
            inherit: true,
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
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
    final isDark = theme.brightness == Brightness.dark;
    final t = tech.technician;
    final h = _hPad(context);

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.25,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _titleRow(l10n, isDark),
              Expanded(
                child: tech.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(h, 12, h, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          children: [
                            _header(isDark, auth, t),
                            const SizedBox(height: 18),
                            _servicesCard(isDark, l10n, t, catalog),
                            const SizedBox(height: 18),
                            _detailsCard(isDark, l10n, t),
                            const SizedBox(height: 22),
                            _actionButton(
                              isDark: isDark,
                              icon: Icons.settings_outlined,
                              label: l10n.settings,
                              onPressed: () => Navigator.pushNamed(
                                  context, AppRoutes.settings),
                            ),
                            const SizedBox(height: 12),
                            _actionButton(
                              isDark: isDark,
                              icon: Icons.logout_rounded,
                              label: l10n.logout,
                              color: AppTheme.error,
                              onPressed: _logout,
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: _deleteAccount,
                              icon: const Icon(Icons.delete_outline,
                                  size: 18),
                              label: Text(l10n.deleteAccount),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.error,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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

  Widget _priceField(TextEditingController c, String label, bool isDark) {
    return Expanded(
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() => _error = null),
        cursorColor: _accent(isDark),
        style: TextStyle(
          inherit: true,
          fontWeight: FontWeight.w700,
          color: _ink(isDark),
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'TZS ',
          isDense: true,
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _cardBorder(isDark)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _cardBorder(isDark)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _accent(isDark), width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final height = MediaQuery.sizeOf(context).height * 0.8;

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.25,
      child: Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Edit services & prices',
                    style: TextStyle(
                      inherit: true,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: _ink(isDark),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: widget.catalog.isEmpty
                    ? Center(
                  child: Text(
                    'No services available.',
                    style: TextStyle(color: _muted(isDark)),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.catalog.length,
                  itemBuilder: (context, i) {
                    final s = widget.catalog[i];
                    final on = _selected.contains(s.id);
                    final category = s.categories.isNotEmpty
                        ? s.categories.map((c) => c.name).join(', ')
                        : null;

                    // Material (not Container) so the checkbox tile's
                    // ink splash is visible – fixes the ListTile assertion.
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: on
                            ? _accent(isDark).withValues(alpha: 0.07)
                            : Colors.transparent,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: on
                                ? _accent(isDark).withValues(alpha: 0.4)
                                : _cardBorder(isDark),
                          ),
                        ),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                              activeColor: _accent(isDark),
                              checkColor:
                              isDark ? AppTheme.primary : Colors.white,
                              title: Text(
                                s.name,
                                style: TextStyle(
                                  inherit: true,
                                  fontWeight: FontWeight.w700,
                                  color: _ink(isDark),
                                ),
                              ),
                              subtitle: category != null
                                  ? Text(
                                category,
                                style: TextStyle(
                                  inherit: true,
                                  fontSize: 12,
                                  color: _muted(isDark),
                                ),
                              )
                                  : null,
                              value: on,
                              onChanged: (v) => _toggle(s.id, v == true),
                            ),
                            if (on)
                              Padding(
                                padding:
                                const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: Row(
                                  children: [
                                    _priceField(_min[s.id]!, 'From', isDark),
                                    const SizedBox(width: 10),
                                    _priceField(_max[s.id]!, 'To', isDark),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
      ),
    );
  }
}