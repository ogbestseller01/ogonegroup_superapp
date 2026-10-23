import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                const Icon(
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
                    elevation: 0,
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroProfile(tech, l10n, theme),
                if (tech.bio != null && tech.bio!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildBioSection(tech.bio!, l10n, theme),
                ],
                const SizedBox(height: 24),
                _buildServicesSection(tech, l10n, theme),
                const SizedBox(height: 24),
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
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
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
      scrolledUnderElevation: 0,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROFILE CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeroProfile(
      Technician tech,
      AppLocalizations l10n,
      ThemeData theme,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppTheme.primary.withOpacity(0.10),
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
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                )
                    : null,
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: tech.isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  tech.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                  ),
                ),
              ),
              if (tech.verified)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.verified_rounded,
                    color: AppTheme.accent,
                    size: 20,
                  ),
                ),
            ],
          ),
          if (tech.area != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AppTheme.error,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    tech.area!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.hintColor,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.4)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  Icons.star_rounded,
                  tech.rating.toStringAsFixed(1),
                  l10n.rating,
                  AppTheme.secondary,
                  theme,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: theme.dividerColor.withOpacity(0.4),
              ),
              Expanded(
                child: _statItem(
                  Icons.work_history_rounded,
                  tech.completedJobsCount.toString(),
                  l10n.jobsCompleted,
                  AppTheme.primary,
                  theme,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: theme.dividerColor.withOpacity(0.4),
              ),
              Expanded(
                child: _statItem(
                  Icons.work_outline_rounded,
                  '${tech.experience} ${l10n.years}',
                  l10n.experience,
                  AppTheme.primary,
                  theme,
                ),
              ),
            ],
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
      ThemeData theme,
      ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: theme.hintColor, fontSize: 12),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION TITLE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text, ThemeData theme, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
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
        _sectionTitle(l10n.about, theme),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
          ),
          child: Text(
            bio,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              fontSize: 14.5,
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
        _sectionTitle(l10n.servicesAndRate, theme),
        if (tech.servicePrices.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < tech.servicePrices.length; i++) ...[
                  if (i != 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.dividerColor.withOpacity(0.3),
                    ),
                  _servicePriceRow(tech.servicePrices[i], l10n, theme),
                ],
              ],
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
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  service,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
        if (tech.hourlyRate != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.hourlyRate,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${l10n.tzs} ${tech.hourlyRate!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
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

  Widget _servicePriceRow(
      dynamic sp,
      AppLocalizations l10n,
      ThemeData theme,
      ) {
    final hasPrice = sp.minPrice > 0 || sp.maxPrice > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          const Icon(
            Icons.construction_rounded,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sp.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              hasPrice
                  ? '${sp.minPrice.toStringAsFixed(0)} - ${sp.maxPrice.toStringAsFixed(0)} ${l10n.tzs}'
                  : 'No fixed price',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: hasPrice ? AppTheme.primary : theme.hintColor,
                fontWeight: hasPrice ? FontWeight.w800 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
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
        _sectionTitle(
          l10n.portfolio,
          theme,
          trailing: items.isNotEmpty
              ? Text(
            '${items.length} ${l10n.items}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontSize: 13,
            ),
          )
              : null,
        ),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 44,
                  color: theme.hintColor.withOpacity(0.6),
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
              childAspectRatio: 0.78,
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
      height: 52,
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
          Flexible(
            child: Text(
              l10n.requestAlreadySent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w600,
              ),
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

    return Hero(
      tag: 'portfolio_${item.id}',
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IMAGE (tap opens viewer)
              Expanded(
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Image.network(
                    ImageUtils.getFullImageUrl(item.image),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 36,
                          color: theme.hintColor,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // DESCRIPTION
              if (desc.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        desc,
                        maxLines: _isExpanded ? 6 : 1,
                        overflow: TextOverflow.ellipsis,
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
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _isExpanded ? 'Read less' : 'Read more',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
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
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentIndex + 1} / $totalItems',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // PAGES
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: totalItems,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: InteractiveViewer(
                          child: Center(
                            child: Image.network(
                              ImageUtils.getFullImageUrl(item.image),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 64,
                                    color: Colors.white54,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                        child: Text(
                          item.description!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // DOTS
          if (totalItems > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 8),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalItems, (i) {
                    final active = i == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white30,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}