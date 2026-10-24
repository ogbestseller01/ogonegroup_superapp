// lib/screens/fundi/fundi_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/request.dart';
import '../../providers/request_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/location_sharing_service.dar.dart';
import '../chat/chat_screen.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';

class FundiRequestsScreen extends StatefulWidget {
  const FundiRequestsScreen({super.key});

  @override
  State<FundiRequestsScreen> createState() => _FundiRequestsScreenState();
}

class _FundiRequestsScreenState extends State<FundiRequestsScreen> {
  final TextEditingController _filterController = TextEditingController();
  String _filterQuery = '';
  String? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestProvider>().loadMyRequests();
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<ServiceRequest> get _filteredRequests {
    final requests = context.read<RequestProvider>().requests;
    var filtered = requests;

    if (_selectedStatusFilter != null) {
      filtered = filtered.where((r) => r.status == _selectedStatusFilter).toList();
    }

    if (_filterQuery.isNotEmpty) {
      final query = _filterQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.customerName.toLowerCase().contains(query) ||
            r.serviceName.toLowerCase().contains(query) ||
            r.description.toLowerCase().contains(query) ||
            (r.customerPhone?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  // ─── Responsive / theme helpers ─────────────────────────────────────────
  double _hPad(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360 ? 12.0 : 16.0;

  /// Navy is unreadable on the dark background, so gold is used in dark mode.
  Color _accent(bool isDark) => isDark ? AppTheme.secondary : AppTheme.primary;

  Color _cardBg(bool isDark) => isDark ? AppTheme.darkSurface : Colors.white;

  Color _cardBorder(bool isDark) =>
      isDark ? AppTheme.darkBorder : AppTheme.borderLight.withOpacity(0.30);

  Color _ink(bool isDark) => isDark ? Colors.white : AppTheme.primary;

  Color _muted(bool isDark) =>
      isDark ? AppTheme.darkTextSecondary : AppTheme.greyText;

  // ─── Status helpers ─────────────────────────────────────────────────────
  Color _statusColor(String status, bool isDark) {
    switch (status) {
      case 'accepted':
      case 'in_progress':
        return _accent(isDark);
      case 'on_the_way':
        return Colors.green;
      case 'arrived':
        return Colors.teal;
      case 'completed':
        return AppTheme.success;
      case 'rejected':
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  Color _statusBgColor(String status, bool isDark) =>
      _statusColor(status, isDark).withOpacity(0.14);

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
      case 'in_progress':
        return Icons.check_circle_outline_rounded;
      case 'on_the_way':
        return Icons.directions_car_rounded;
      case 'arrived':
        return Icons.location_on_rounded;
      case 'completed':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'cancelled':
        return Icons.do_not_disturb_on_outlined;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'on_the_way':
        return 'On The Way';
      case 'arrived':
        return 'Arrived';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  // ─── EAT helper ─────────────────────────────────────────────────────────
  DateTime _toEAT(DateTime dateTime) {
    return dateTime.toUtc().add(const Duration(hours: 3));
  }

  String _formatRequestDate(DateTime dateTime) {
    final eat = _toEAT(dateTime);
    final day = eat.day.toString().padLeft(2, '0');
    final month = eat.month.toString().padLeft(2, '0');
    final year = eat.year.toString();
    final hour = eat.hour.toString().padLeft(2, '0');
    final minute = eat.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }

  // ─── Call customer ──────────────────────────────────────────────────────
  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showSnack(context, 'Customer phone number not available', isError: true);
      return;
    }

    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleaned');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        _showSnack(context, 'Unable to open phone dialer', isError: true);
      }
    }
  }

  // ─── Chat ───────────────────────────────────────────────────────────────
  Future<void> _startChat(BuildContext context, ServiceRequest request) async {
    try {
      final chatProvider = context.read<ChatProvider>();
      final authProvider = context.read<AuthProvider>();

      final conversation = await chatProvider.getOrCreateConversation(
        customerId: request.customerId,
        fundiId: authProvider.user!.id,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversation: conversation),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Failed to start chat: $e', isError: true);
      }
    }
  }

  // ─── Complete confirmation ──────────────────────────────────────────────
  Future<void> _markCompleted(BuildContext context, int requestId) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.completeRequest, style: theme.textTheme.titleMedium),
        content: Text(l10n.completeConfirmation, style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(l10n.completeRequest),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<RequestProvider>();
      final success = await provider.completeRequest(requestId);

      // Stop live location sharing
      LocationSharingService.stopSharing();

      if (context.mounted) {
        _showSnack(
          context,
          success ? l10n.completedSuccess : (provider.error ?? l10n.failedToComplete),
          isError: !success,
        );
      }
    }
  }

  void _showSnack(BuildContext context, String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();
    final filteredRequests = _filteredRequests;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.25,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTitleRow(context, provider, l10n, isDark),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                  children: [
                    _buildSearchAndFilter(context, theme, isDark),
                    _buildStatsBar(context, provider, isDark),
                    Expanded(
                      child: _buildRequestList(
                        context,
                        provider,
                        filteredRequests,
                        l10n,
                        theme,
                        isDark,
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

  // ─── TITLE ROW (replaces the second app bar) ────────────────────────────
  Widget _buildTitleRow(
      BuildContext context,
      RequestProvider provider,
      AppLocalizations l10n,
      bool isDark,
      ) {
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
              l10n.requests,
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
          Tooltip(
            message: 'Refresh',
            child: Material(
              color: _accent(isDark).withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => provider.refresh(),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.refresh_rounded,
                      color: _accent(isDark), size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH & FILTER ────────────────────────────────────────────────────
  Widget _buildSearchAndFilter(
      BuildContext context, ThemeData theme, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final h = _hPad(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(h, 12, h, 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _cardBg(isDark),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _cardBorder(isDark)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _filterController,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _ink(isDark),
                fontWeight: FontWeight.w600,
              ),
              cursorColor: _accent(isDark),
              decoration: InputDecoration(
                hintText: l10n.filterByCustomerService,
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: _muted(isDark),
                ),
                prefixIcon:
                Icon(Icons.search_rounded, color: _accent(isDark)),
                suffixIcon: _filterQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: _muted(isDark),
                  ),
                  onPressed: () {
                    _filterController.clear();
                    setState(() => _filterQuery = '');
                  },
                )
                    : null,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 16,
                ),
              ),
              onChanged: (value) => setState(() => _filterQuery = value),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('All', null, theme, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending', theme, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Accepted', 'accepted', theme, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('On The Way', 'on_the_way', theme, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed', theme, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected', theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, String? value, ThemeData theme, bool isDark) {
    final isSelected = _selectedStatusFilter == value;
    final selectedBg = isDark ? AppTheme.secondary : AppTheme.primary;
    final selectedFg = isDark ? AppTheme.primary : Colors.white;

    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = isSelected ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : _cardBg(isDark),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? selectedBg : _cardBorder(isDark),
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: selectedBg.withOpacity(0.28),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected ? selectedFg : _ink(isDark),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ─── STATS BAR ──────────────────────────────────────────────────────────
  Widget _buildStatsBar(
      BuildContext context, RequestProvider provider, bool isDark) {
    final h = _hPad(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: 8),
      child: Row(
        children: [
          _buildStatCard('Total', provider.totalCount, _ink(isDark), isDark,
              icon: Icons.list_alt_rounded),
          const SizedBox(width: 8),
          _buildStatCard('Pending', provider.pendingCount, AppTheme.warning, isDark,
              icon: Icons.hourglass_empty_rounded),
          const SizedBox(width: 8),
          _buildStatCard(
              'Accepted', provider.acceptedCount, _accent(isDark), isDark,
              icon: Icons.check_circle_outline_rounded),
          const SizedBox(width: 8),
          _buildStatCard('Done', provider.completedCount, AppTheme.success, isDark,
              icon: Icons.verified_rounded),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label,
      int count,
      Color color,
      bool isDark, {
        required IconData icon,
      }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        decoration: BoxDecoration(
          color: _cardBg(isDark),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cardBorder(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                inherit: true,
                color: _ink(isDark),
                fontSize: 17,
                height: 1.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  inherit: true,
                  color: _muted(isDark),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── REQUEST LIST ──────────────────────────────────────────────────────
  Widget _buildRequestList(
      BuildContext context,
      RequestProvider provider,
      List<ServiceRequest> requests,
      AppLocalizations l10n,
      ThemeData theme,
      bool isDark,
      ) {
    if (provider.requests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        text: l10n.noRequests,
        isDark: isDark,
      );
    }

    if (requests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        text: l10n.noMatchingRequests,
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: LayoutBuilder(
        builder: (context, c) {
          final h = _hPad(context);
          final wide = c.maxWidth >= 640;
          const spacing = 12.0;
          final itemW = (c.maxWidth - 2 * h - spacing) / 2;

          final cards = requests
              .map((r) => _buildRequestCard(context, r, l10n, theme, isDark))
              .toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(h, 6, h, 28),
            children: [
              if (wide)
              // Wide screens show cards in two columns.
                Wrap(
                  spacing: spacing,
                  children: cards
                      .map((card) => SizedBox(width: itemW, child: card))
                      .toList(),
                )
              else
                ...cards,
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: _cardBg(isDark),
              shape: BoxShape.circle,
              border: Border.all(color: _cardBorder(isDark)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, size: 44, color: _muted(isDark)),
          ),
          const SizedBox(height: 18),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              inherit: true,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ─── REQUEST CARD ──────────────────────────────────────────────────────
  Widget _buildRequestCard(
      BuildContext context,
      ServiceRequest request,
      AppLocalizations l10n,
      ThemeData theme,
      bool isDark,
      ) {
    final isPending = request.isPending;
    final isActioned = request.isAccepted ||
        request.isOnTheWay ||
        request.isArrived ||
        request.isInProgress;
    final isCompleted = request.isCompleted;
    final isRejectedOrCancelled = request.isRejected || request.isCancelled;

    final createdDate = _formatRequestDate(request.createdAt);
    final statusColor = _statusColor(request.status, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCompleted
              ? AppTheme.success.withOpacity(0.32)
              : _cardBorder(isDark),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusBgColor(request.status, isDark),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(_statusIcon(request.status),
                      color: statusColor, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    request.serviceName,
                    style: TextStyle(
                      inherit: true,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: _ink(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusBgColor(request.status, isDark),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(request.status).toUpperCase(),
                    style: TextStyle(
                      inherit: true,
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Customer name
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 16, color: _muted(isDark)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.customerName,
                    style: TextStyle(
                      inherit: true,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _ink(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Customer phone
            if (request.customerPhone != null &&
                request.customerPhone!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _callCustomer(request.customerPhone),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.phone_rounded,
                          size: 16, color: _accent(isDark)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          request.customerPhone!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            inherit: true,
                            fontSize: 14,
                            color: _accent(isDark),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.call_made_rounded,
                        size: 13,
                        color: _accent(isDark).withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : AppTheme.navy50.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                request.description,
                style: TextStyle(
                  inherit: true,
                  fontSize: 13,
                  color: isDark
                      ? Colors.white.withOpacity(0.78)
                      : AppTheme.primary.withOpacity(0.78),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 10),

            // Date
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: _muted(isDark)),
                const SizedBox(width: 6),
                Text(
                  createdDate,
                  style: TextStyle(
                    inherit: true,
                    color: _muted(isDark),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Actions
            if (isPending) _buildPendingActions(context, request, l10n),
            if (isActioned) _buildActionedActions(context, request, l10n),
            if (isCompleted) _buildCompletedActions(request, l10n, theme),
            if (isRejectedOrCancelled)
              _buildRejectedActions(request, theme, isDark),
          ],
        ),
      ),
    );
  }

  // ─── ACTION BUTTONS ────────────────────────────────────────────────────
  Widget _buildPendingActions(
      BuildContext context,
      ServiceRequest request,
      AppLocalizations l10n,
      ) {
    return Row(
      children: [
        Expanded(
          child: _PrimaryButton(
            label: l10n.accept,
            color: AppTheme.primary,
            onPressed: () async {
              final provider = context.read<RequestProvider>();
              final success = await provider.acceptRequest(request.id);

              if (context.mounted) {
                _showSnack(
                  context,
                  success
                      ? l10n.requestAccepted
                      : (provider.error ?? 'Failed to accept'),
                  isError: !success,
                );
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PrimaryButton(
            label: l10n.reject,
            color: AppTheme.error,
            outlined: true,
            onPressed: () async {
              final provider = context.read<RequestProvider>();
              final success = await provider.rejectRequest(request.id);

              // Stop any previous sharing
              LocationSharingService.stopSharing();

              if (context.mounted) {
                _showSnack(
                  context,
                  success
                      ? l10n.requestRejected
                      : (provider.error ?? 'Failed to reject'),
                  isError: !success,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionedActions(
      BuildContext context,
      ServiceRequest request,
      AppLocalizations l10n,
      ) {
    return Column(
      children: [
        // Call + Chat
        Row(
          children: [
            if (request.customerPhone != null &&
                request.customerPhone!.trim().isNotEmpty) ...[
              Expanded(
                child: _PrimaryButton(
                  label: 'Call',
                  color: Colors.green.shade700,
                  icon: Icons.phone_rounded,
                  outlined: true,
                  onPressed: () => _callCustomer(request.customerPhone),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _PrimaryButton(
                label: l10n.chatWithCustomer,
                color: AppTheme.primary,
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: () => _startChat(context, request),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ─── I'M ON THE WAY ──────────────────────────────────────────────
        if (request.isAccepted)
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: "I'm On The Way",
              color: Colors.green,
              icon: Icons.directions_car_rounded,
              onPressed: () async {
                final provider = context.read<RequestProvider>();
                final success = await provider.markOnTheWay(request.id);

                if (success) {
                  // Start continuous live location sharing
                  LocationSharingService.startSharing();
                }

                if (context.mounted) {
                  _showSnack(
                    context,
                    success
                        ? 'You are now sharing your live location with the customer'
                        : (provider.error ?? 'Failed to update status'),
                    isError: !success,
                  );
                }
              },
            ),
          ),

        // ─── I HAVE ARRIVED ──────────────────────────────────────────────
        if (request.isOnTheWay)
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: 'I Have Arrived',
              color: Colors.teal,
              icon: Icons.location_on_rounded,
              onPressed: () async {
                final provider = context.read<RequestProvider>();
                final success = await provider.markArrived(request.id);

                // Keep sharing until job is completed
                // (you can stop here if you prefer)
                // LocationSharingService.stopSharing();

                if (context.mounted) {
                  _showSnack(
                    context,
                    success
                        ? 'Marked as arrived'
                        : (provider.error ?? 'Failed to update status'),
                    isError: !success,
                  );
                }
              },
            ),
          ),

        if (request.isAccepted || request.isOnTheWay) const SizedBox(height: 10),

        // ─── MARK COMPLETE ───────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: _PrimaryButton(
            label: l10n.markComplete,
            color: AppTheme.success,
            icon: Icons.verified_rounded,
            outlined: true,
            onPressed: () => _markCompleted(context, request.id),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedActions(
      ServiceRequest request,
      AppLocalizations l10n,
      ThemeData theme,
      ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppTheme.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.completed,
                  style: const TextStyle(
                    inherit: true,
                    color: AppTheme.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                if (request.technicianRating != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        ...List.generate(
                          request.technicianRating!.round().clamp(0, 5),
                              (index) => const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          request.technicianRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            inherit: true,
                            fontSize: 12,
                            color: Colors.amber,
                            fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildRejectedActions(
      ServiceRequest request, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withOpacity(0.20)),
      ),
      child: Center(
        child: Text(
          request.isRejected ? 'Request Rejected' : 'Request Cancelled',
          style: TextStyle(
            inherit: true,
            fontSize: 12.5,
            color: AppTheme.error.withOpacity(isDark ? 0.9 : 0.8),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── PRIMARY BUTTON ──────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool outlined;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Navy buttons turn gold in dark mode so they stay visible.
    final base = (color == AppTheme.primary && isDark) ? AppTheme.secondary : color;
    final onBase = base == AppTheme.secondary ? AppTheme.primary : Colors.white;

    final child = icon == null
        ? Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)
        : Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: outlined ? base : onBase),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    );
    const padding = EdgeInsets.symmetric(vertical: 13, horizontal: 10);
    const textStyle = TextStyle(
      inherit: true,
      fontWeight: FontWeight.w700,
      fontSize: 13.5,
    );
    const minSize = Size(0, 48);

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: base,
          minimumSize: minSize,
          side: BorderSide(color: base.withOpacity(0.5)),
          shape: shape,
          padding: padding,
          textStyle: textStyle,
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: base,
        foregroundColor: onBase,
        minimumSize: minSize,
        elevation: 0,
        shape: shape,
        padding: padding,
        textStyle: textStyle,
      ),
      child: child,
    );
  }
}