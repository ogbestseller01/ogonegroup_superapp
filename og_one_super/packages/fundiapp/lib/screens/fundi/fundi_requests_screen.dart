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

  // ─── Status helpers ─────────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
      case 'in_progress':
        return AppTheme.primary;
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

  Color _statusBgColor(String status) => _statusColor(status).withOpacity(0.12);

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                borderRadius: BorderRadius.circular(12),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();
    final filteredRequests = _filteredRequests;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.requests,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => provider.refresh(),
            tooltip: 'Refresh',
          ),
        ],
        backgroundColor: AppTheme.primary,
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilter(context, theme),
            _buildStatsBar(provider, theme),
            Expanded(
              child: _buildRequestList(
                context,
                provider,
                filteredRequests,
                l10n,
                theme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SEARCH & FILTER ────────────────────────────────────────────────────
  Widget _buildSearchAndFilter(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _filterController,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: l10n.filterByCustomerService,
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary),
                suffixIcon: _filterQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                  ),
                  onPressed: () {
                    _filterController.clear();
                    setState(() => _filterQuery = '');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
              onChanged: (value) => setState(() => _filterQuery = value),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null, theme),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending', theme),
                const SizedBox(width: 8),
                _buildFilterChip('Accepted', 'accepted', theme),
                const SizedBox(width: 8),
                _buildFilterChip('On The Way', 'on_the_way', theme),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed', theme),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected', theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, ThemeData theme) {
    final isSelected = _selectedStatusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = isSelected ? null : value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.primary : theme.dividerColor.withOpacity(0.6),
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── STATS BAR ──────────────────────────────────────────────────────────
  Widget _buildStatsBar(RequestProvider provider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard('Total', provider.totalCount, Colors.grey.shade800, theme,
              Colors.white, forceFixed: true),
          const SizedBox(width: 8),
          _buildStatCard('Pending', provider.pendingCount, AppTheme.warning, theme,
              AppTheme.warning.withOpacity(0.12)),
          const SizedBox(width: 8),
          _buildStatCard('Accepted', provider.acceptedCount, AppTheme.primary, theme,
              AppTheme.primary.withOpacity(0.12)),
          const SizedBox(width: 8),
          _buildStatCard('Done', provider.completedCount, AppTheme.success, theme,
              AppTheme.success.withOpacity(0.12)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label,
      int count,
      Color textColor,
      ThemeData theme,
      Color bgColor, {
        bool forceFixed = false,
      }) {
    final effectiveBg = forceFixed ? Colors.white : bgColor;
    final effectiveText = forceFixed ? Colors.black87 : textColor;
    final borderColor = forceFixed ? Colors.grey.shade300 : textColor.withOpacity(0.22);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: theme.textTheme.titleMedium?.copyWith(
                color: effectiveText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: effectiveText.withOpacity(0.75),
                fontWeight: FontWeight.w600,
                fontSize: 11,
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
      ) {
    if (provider.requests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        text: l10n.noRequests,
        theme: theme,
      );
    }

    if (requests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        text: l10n.noMatchingRequests,
        theme: theme,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        itemCount: requests.length,
        itemBuilder: (ctx, i) => _buildRequestCard(context, requests[i], l10n, theme),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String text,
    required ThemeData theme,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 46,
              color: theme.colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
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
      ) {
    final isPending = request.isPending;
    final isActioned = request.isAccepted ||
        request.isOnTheWay ||
        request.isArrived ||
        request.isInProgress;
    final isCompleted = request.isCompleted;
    final isRejectedOrCancelled = request.isRejected || request.isCancelled;

    final createdDate = _formatRequestDate(request.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted
              ? AppTheme.success.withOpacity(0.28)
              : theme.dividerColor.withOpacity(0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                Expanded(
                  child: Text(
                    request.serviceName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusBgColor(request.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(request.status),
                        size: 13,
                        color: _statusColor(request.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusLabel(request.status).toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(request.status),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Customer name
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    request.customerName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
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
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 15, color: AppTheme.primary),
                      const SizedBox(width: 7),
                      Text(
                        request.customerPhone!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.call_made_rounded,
                        size: 13,
                        color: AppTheme.primary.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Description
            Text(
              request.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.72),
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 13, color: theme.hintColor),
                const SizedBox(width: 6),
                Text(
                  createdDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Actions
            if (isPending) _buildPendingActions(context, request, l10n),
            if (isActioned) _buildActionedActions(context, request, l10n),
            if (isCompleted) _buildCompletedActions(request, l10n, theme),
            if (isRejectedOrCancelled) _buildRejectedActions(request, theme),
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
        color: AppTheme.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.success.withOpacity(0.22)),
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
                    color: AppTheme.success,
                    fontWeight: FontWeight.w700,
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
                            fontSize: 12,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
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

  Widget _buildRejectedActions(ServiceRequest request, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: Center(
        child: Text(
          request.isRejected ? 'Request Rejected' : 'Request Cancelled',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.55),
            fontWeight: FontWeight.w500,
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
    final child = icon == null
        ? Text(label)
        : Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: outlined ? color : Colors.white),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
    );
    final padding = const EdgeInsets.symmetric(vertical: 12);
    const textStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5);

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.45)),
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
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: shape,
        padding: padding,
        textStyle: textStyle,
      ),
      child: child,
    );
  }
}