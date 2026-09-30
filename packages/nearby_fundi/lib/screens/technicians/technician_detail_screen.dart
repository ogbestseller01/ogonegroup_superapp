import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/service.dart';
import '../../providers/technician_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/service_provider.dart';
import '../../utils/image_utils.dart';
import '../../models/technician.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_theme.dart';
import '../../config/app_routes.dart';
import '../../widgets/request_dialog.dart';

// ──────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ──────────────────────────────────────────────────────────────────────────

class TechnicianDetailScreen extends StatefulWidget {
  final int technicianId;

  const TechnicianDetailScreen({
    super.key,
    required this.technicianId,
  });

  @override
  State<TechnicianDetailScreen> createState() =>
      _TechnicianDetailScreenState();
}

class _TechnicianDetailScreenState extends State<TechnicianDetailScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final technicianProvider = context.read<TechnicianProvider>();

      await technicianProvider.fetchTechnicianWithPortfolios(
        widget.technicianId,
      );

      await Future.wait([
        context.read<RequestProvider>().loadMyRequests(),
        context.read<ServiceProvider>().fetchServices(),
      ]);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ─── CRITICAL FIX for package / mini-app embedding ─────────────────────
  void _showRequestModal(Technician tech) {
    showDialog(
      context: context,
      useRootNavigator: false, // stay inside mini-app navigator (has providers)
      barrierDismissible: false,
      builder: (dialogContext) => RequestDialog(
        technician: tech,
      ),
    );
  }

  void _showPortfolioModal(
      PortfolioItem item,
      List<PortfolioItem> items,
      int initialIndex,
      ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: false, // same reason
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PortfolioModal(
        items: items,
        initialIndex: initialIndex,
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (_) {}
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    final whatsappUri = Uri.parse('whatsapp://send?phone=$cleanNumber');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return;
      }

      final fallbackUri = Uri.parse('https://wa.me/$cleanNumber');
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _launchSocialUrl(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final technicianProvider = context.watch<TechnicianProvider>();
    final requestProvider = context.watch<RequestProvider>();

    final tech = technicianProvider.currentTechnician;

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final horizontalPadding = isTablet ? 32.0 : 16.0;
    final portfolioColumns = isTablet ? 3 : 2;

    // ─── LOADING ──────────────────────────────────────────────────────────
    if (_isLoading || technicianProvider.isLoading) {
      return Scaffold(
        appBar: _buildAppBar(l10n, theme),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ─── ERROR ────────────────────────────────────────────────────────────
    if (_error != null ||
        technicianProvider.error != null ||
        tech == null) {
      return Scaffold(
        appBar: _buildAppBar(l10n, theme),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: AppTheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  technicianProvider.error ??
                      _error ??
                      l10n.technicianNotFound,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ─── MAIN UI ──────────────────────────────────────────────────────────
    return Scaffold(
      appBar: _buildAppBar(l10n, theme, techName: tech.name),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroProfile(tech, l10n, theme),
              const SizedBox(height: 20),
              _buildContactChips(tech, theme, l10n),
              const SizedBox(height: 20),
              if (tech.bio != null && tech.bio!.isNotEmpty)
                _buildBioSection(tech.bio!, l10n, theme),
              if (tech.bio != null && tech.bio!.isNotEmpty)
                const SizedBox(height: 20),
              _buildServicesSection(tech, l10n, theme),
              const SizedBox(height: 20),
              _buildPortfolioSection(
                tech,
                portfolioColumns,
                l10n,
                theme,
                _showPortfolioModal,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: requestProvider.hasActiveRequest(tech.id)
              ? _buildAlreadySentWidget(l10n, theme)
              : ElevatedButton.icon(
            onPressed: () => _showRequestModal(tech),
            icon: const Icon(
              Icons.handyman_rounded,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              l10n.requestThisFundi,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
      AppLocalizations l10n,
      ThemeData theme, {
        String? techName,
      }) {
    return AppBar(
      title: Text(
        techName ?? l10n.technician,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadData,
          tooltip: l10n.refresh,
        ),
      ],
      backgroundColor: AppTheme.primary,
      elevation: 0,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HERO PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeroProfile(
      Technician tech,
      AppLocalizations l10n,
      ThemeData theme,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: tech.profilePhoto != null
                    ? NetworkImage(
                  ImageUtils.getFullImageUrl(tech.profilePhoto!),
                )
                    : null,
                child: tech.profilePhoto == null
                    ? Text(
                  tech.name.isNotEmpty
                      ? tech.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
                    : null,
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: tech.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tech.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (tech.area != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  tech.area!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem(
                  Icons.star_rounded,
                  tech.rating.toStringAsFixed(1),
                  l10n.rating,
                  Colors.amber,
                ),
                Container(width: 1, height: 28, color: Colors.white24),
                _statItem(
                  Icons.work_history_rounded,
                  tech.completedJobsCount.toString(),
                  l10n.jobsCompleted,
                  Colors.white70,
                ),
                Container(width: 1, height: 28, color: Colors.white24),
                _statItem(
                  Icons.work_outline_rounded,
                  '${tech.experience} ${l10n.years}',
                  l10n.experience,
                  Colors.white70,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (tech.verified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade700.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white54, width: 0.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statItem(
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONTACT CHIPS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildContactChips(
      Technician tech,
      ThemeData theme,
      AppLocalizations l10n,
      ) {
    final hasPhone = tech.phone != null && tech.phone!.isNotEmpty;
    final hasEmail = tech.email != null && tech.email!.isNotEmpty;

    if (!hasPhone && !hasEmail) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (hasPhone)
          _contactChip(
            icon: Icons.phone_rounded,
            label: l10n.call,
            color: Colors.green.shade700,
            onTap: () => _makePhoneCall(tech.phone!),
          ),
        if (hasPhone)
          _contactChip(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            color: Colors.green.shade600,
            onTap: () => _launchWhatsApp(tech.phone!),
          ),
        if (hasEmail)
          _contactChip(
            icon: Icons.email_rounded,
            label: l10n.email,
            color: Colors.blue.shade700,
            onTap: () async {
              final uri = Uri.parse('mailto:${tech.email}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
      ],
    );
  }

  Widget _contactChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: color),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      onPressed: onTap,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BIO
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBioSection(
      String bio,
      AppLocalizations l10n,
      ThemeData theme,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.about,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            bio,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SERVICES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildServicesSection(
      Technician tech,
      AppLocalizations l10n,
      ThemeData theme,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.servicesAndRate,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 8),
        if (tech.servicePrices.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: tech.servicePrices.map((sp) {
                final hasPrice = sp.minPrice > 0 || sp.maxPrice > 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.construction_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sp.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          hasPrice
                              ? '${sp.minPrice.toStringAsFixed(0)} - ${sp.maxPrice.toStringAsFixed(0)} ${l10n.tzs}'
                              : 'No fixed price',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasPrice
                                ? AppTheme.primary
                                : theme.hintColor,
                            fontWeight:
                            hasPrice ? FontWeight.bold : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        else if (tech.services.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tech.services.map((service) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  service,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
        if (tech.hourlyRate != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.hourlyRate,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 20,
                  color: theme.hintColor.withOpacity(0.3),
                ),
                const SizedBox(width: 8),
                Text(
                  '${l10n.tzs} ${tech.hourlyRate!.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PORTFOLIO
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPortfolioSection(
      Technician tech,
      int columns,
      AppLocalizations l10n,
      ThemeData theme,
      Function(PortfolioItem, List<PortfolioItem>, int) onTap,
      ) {
    final items = tech.portfolios;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.portfolio,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const Spacer(),
            if (items.isNotEmpty)
              Text(
                '${items.length} ${l10n.items}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: theme.hintColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noPortfolioItems,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return PortfolioGridCard(
                item: item,
                onTap: () => onTap(item, items, index),
                theme: theme,
              );
            },
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIVE REQUEST MESSAGE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAlreadySentWidget(
      AppLocalizations l10n,
      ThemeData theme,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 20,
            color: theme.hintColor,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.requestAlreadySent,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// PORTFOLIO GRID CARD
// ──────────────────────────────────────────────────────────────────────────

class PortfolioGridCard extends StatefulWidget {
  final PortfolioItem item;
  final VoidCallback onTap;
  final ThemeData theme;

  const PortfolioGridCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.theme,
  });

  @override
  State<PortfolioGridCard> createState() => _PortfolioGridCardState();
}

class _PortfolioGridCardState extends State<PortfolioGridCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = widget.theme;
    final desc = item.description ?? '';
    final shouldShowReadMore = desc.length > 60;

    return GestureDetector(
      onTap: widget.onTap,
      child: Hero(
        tag: 'portfolio_${item.id}',
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          shadowColor: theme.shadowColor.withOpacity(0.15),
          color: theme.cardColor,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        ImageUtils.getFullImageUrl(item.image),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.broken_image,
                              size: 40,
                              color: theme.hintColor,
                            ),
                          );
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (desc.isNotEmpty) ...[
                        Text(
                          desc,
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            height: 1.3,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (shouldShowReadMore)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Text(
                              _isExpanded ? 'Read less' : 'Read more',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fullscreen_rounded,
                              size: 14,
                              color: theme.hintColor.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'View',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.hintColor.withOpacity(0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// PORTFOLIO MODAL
// ──────────────────────────────────────────────────────────────────────────

class PortfolioModal extends StatefulWidget {
  final List<PortfolioItem> items;
  final int initialIndex;

  const PortfolioModal({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  @override
  State<PortfolioModal> createState() => _PortfolioModalState();
}

class _PortfolioModalState extends State<PortfolioModal> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalItems = widget.items.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF0D1F1F)
            : Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentIndex + 1} / $totalItems',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: totalItems,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: InteractiveViewer(
                          child: Image.network(
                            ImageUtils.getFullImageUrl(item.image),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              return const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 64,
                                  color: Colors.white54,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          item.description!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}