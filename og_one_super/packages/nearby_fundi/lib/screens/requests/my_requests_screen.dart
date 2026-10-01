// screens/requests/my_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/request.dart';
import '../../providers/request_provider.dart';
import '../../providers/technician_provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_routes.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';

// ─── Helper function to format full date with timezone conversion ───
String formatDateFull(DateTime date) {
  final local = date.toLocal();
  return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  String? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestProvider>().loadMyRequests();
    });
  }

  // ---- Status helpers ----
  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppTheme.primary;
      case 'completed':
        return AppTheme.success;
      case 'rejected':
      case 'cancelled':
        return AppTheme.error;
      case 'in_progress':
        return Colors.purple.shade700;
      default:
        return AppTheme.warning;
    }
  }

  Color _statusBackgroundColor(String status) {
    final color = _statusColor(status);
    return color.withOpacity(0.12);
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'completed':
        return Icons.verified_outlined;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'cancelled':
        return Icons.do_not_disturb_on_outlined;
      case 'in_progress':
        return Icons.hourglass_top_rounded;
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
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'in_progress':
        return 'In Progress';
      case 'on_the_way':
        return 'On The Way';
      case 'arrived':
        return 'Arrived';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // ---- Show Request Details Modal ----
  void _showRequestDetails(BuildContext context, ServiceRequest request) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _RequestDetailModal(request: request),
    );
  }

  // ---- Review Dialog (vertical layout, taller comment field) ----
  Future<void> _showReviewDialog(BuildContext context, ServiceRequest request) async {
    final api = ApiService();
    final controller = TextEditingController();
    int rating = 5;
    bool submitting = false;

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.rate_review_rounded, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text('Rate & Review'),
              ],
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  thickness: 2,
                  color: Theme.of(context).dividerColor.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Your Rating:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: List.generate(5, (i) {
                        return GestureDetector(
                          onTap: () => setState(() => rating = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 30,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$rating / 5',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Review',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        hintStyle: TextStyle(color: Theme.of(context).hintColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(width: 1.0, color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(width: 1.0, color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(width: 1.5, color: AppTheme.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                  setState(() => submitting = true);
                  final res = await api.submitReview(
                    requestId: request.id,
                    rating: rating,
                    comment: controller.text.trim().isNotEmpty ? controller.text.trim() : null,
                  );
                  setState(() => submitting = false);
                  if (res.success) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review submitted!')),
                    );
                    context.read<RequestProvider>().loadMyRequests();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.message ?? 'Failed to submit review')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? 32.0 : 16.0;
    final cardMargin = isTablet ? 12.0 : 8.0;

    final filteredRequests = provider.requests.where((r) {
      if (_selectedStatusFilter == null) return true;
      return r.status == _selectedStatusFilter;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.myRequests,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: provider.loadMyRequests,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context, theme, l10n, horizontalPadding),
          if (provider.requests.isNotEmpty) _buildStatsRow(context, provider, theme, horizontalPadding),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.loadMyRequests,
              color: AppTheme.primary,
              child: _buildContent(
                provider,
                filteredRequests,
                theme,
                l10n,
                horizontalPadding,
                cardMargin,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Filter Bar ----
  Widget _buildFilterBar(BuildContext context, ThemeData theme, AppLocalizations l10n, double hPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12.0),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, size: 20, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            'Filter:',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _selectedStatusFilter,
              isDense: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                suffixIcon: Icon(Icons.arrow_drop_down, color: theme.hintColor),
              ),
              style: theme.textTheme.bodyMedium,
              items: const [
                DropdownMenuItem<String?>(value: null, child: Text('All')),
                DropdownMenuItem<String?>(value: 'pending', child: Text('Pending')),
                DropdownMenuItem<String?>(value: 'accepted', child: Text('Accepted')),
                DropdownMenuItem<String?>(value: 'on_the_way', child: Text('On The Way')),
                DropdownMenuItem<String?>(value: 'arrived', child: Text('Arrived')),
                DropdownMenuItem<String?>(value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem<String?>(value: 'completed', child: Text('Completed')),
                DropdownMenuItem<String?>(value: 'rejected', child: Text('Rejected')),
                DropdownMenuItem<String?>(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (newValue) => setState(() => _selectedStatusFilter = newValue),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Stats Row ----
  Widget _buildStatsRow(BuildContext context, RequestProvider provider, ThemeData theme, double hPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: Row(
        children: [
          _buildStatChip('📋 ${provider.requests.length}', theme.hintColor.withOpacity(0.1), theme.hintColor),
          const SizedBox(width: 8),
          _buildStatChip('⏳ ${provider.pendingCount}', AppTheme.warning.withOpacity(0.15), AppTheme.warning),
          const SizedBox(width: 8),
          _buildStatChip('✅ ${provider.acceptedCount}', AppTheme.primary.withOpacity(0.15), AppTheme.primary),
          const SizedBox(width: 8),
          _buildStatChip('✔️ ${provider.completedCount}', AppTheme.success.withOpacity(0.15), AppTheme.success),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  // ---- Content ----
  Widget _buildContent(
      RequestProvider provider,
      List<ServiceRequest> filteredRequests,
      ThemeData theme,
      AppLocalizations l10n,
      double hPadding,
      double cardMargin,
      ) {
    if (provider.isLoading && provider.requests.isEmpty) {
      return Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (provider.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 72, color: theme.hintColor.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              l10n.noRequestsYet,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.requestsWillAppear,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      );
    }

    if (filteredRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off, size: 60, color: theme.hintColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No requests match the selected filter',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 16),
      itemCount: filteredRequests.length,
      itemBuilder: (ctx, i) {
        final r = filteredRequests[i];
        final isCompleted = r.isCompleted;
        final isPending = r.isPending;
        final statusColor = _statusColor(r.status);
        final statusBg = _statusBackgroundColor(r.status);

        return Card(
          margin: EdgeInsets.only(bottom: cardMargin + 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          shadowColor: theme.shadowColor.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.serviceName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          if (r.categoryName != null && r.categoryName!.isNotEmpty)
                            Text(
                              '📂 ${r.categoryName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(r.status), size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusLabel(r.status).toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        r.technicianName,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ),
                    Icon(Icons.schedule, size: 16, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(r.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
                if (r.technicianArea != null && r.technicianArea!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Text(
                          r.technicianArea!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isCompleted) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.success.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 16, color: AppTheme.success),
                        const SizedBox(width: 6),
                        Text(
                          'Completed ✓',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.success),
                        ),
                        if (r.technicianRating != null && r.technicianRating! > 0) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
                          Text(
                            r.technicianRating!.toStringAsFixed(1),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade700),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Track button
                    if (r.isAccepted || r.isOnTheWay || r.isArrived)
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.tracking,
                          arguments: r.id,
                        ),
                        icon: Icon(Icons.track_changes_rounded, size: 18, color: AppTheme.primary),
                        label: Text(
                          'Track',
                          style: TextStyle(color: AppTheme.primary, fontSize: 13),
                        ),
                      ),
                    // Cancel button (only for pending)
                    if (isPending)
                      TextButton.icon(
                        onPressed: provider.isLoading
                            ? null
                            : () async {
                          final confirmed = await showConfirmationDialog(
                            context,
                            l10n.cancelRequest,
                            l10n.areYouSureCancel,
                          );
                          if (confirmed == true && context.mounted) {
                            await context.read<RequestProvider>().cancelRequest(r.id);
                          }
                        },
                        icon: Icon(Icons.cancel_outlined, size: 18, color: AppTheme.error),
                        label: Text(
                          l10n.cancelRequest,
                          style: TextStyle(color: AppTheme.error, fontSize: 13),
                        ),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                      ),
                    // ─── REVIEW BUTTON ─────────────────────────────────────
                    // Only show if completed AND NOT reviewed
                    if (isCompleted && !r.hasReview)
                      TextButton.icon(
                        onPressed: () => _showReviewDialog(context, r),
                        icon: Icon(Icons.star_rate_rounded, size: 18, color: Colors.amber.shade700),
                        label: Text(
                          'Review',
                          style: TextStyle(color: Colors.amber.shade700, fontSize: 13),
                        ),
                      ),
                    // ─── VIEW DETAILS ──────────────────────────────────────
                    TextButton.icon(
                      onPressed: () => _showRequestDetails(context, r),
                      icon: Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primary),
                      label: Text(
                        'View Details',
                        style: TextStyle(color: AppTheme.primary, fontSize: 13),
                      ),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── REQUEST DETAIL MODAL (IMPROVED UI + FULL DESCRIPTION) ──────────────
class _RequestDetailModal extends StatelessWidget {
  final ServiceRequest request;
  const _RequestDetailModal({required this.request});

  String _formatDateFull(DateTime date) => formatDateFull(date);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(request.status);
    final statusBg = _statusBackgroundColor(request.status);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final dialogWidth = screenWidth > 480 ? 480.0 : screenWidth - 40.0;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: theme.cardColor,
      elevation: 12,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.88,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.request_page_rounded, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Request Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 28, color: theme.hintColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 28, thickness: 1.2),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service & Category
                    _buildInfoCard(
                      context,
                      icon: Icons.construction_rounded,
                      label: 'Service',
                      value: request.serviceName,
                    ),
                    const SizedBox(height: 12),
                    if (request.categoryName != null && request.categoryName!.isNotEmpty)
                      _buildInfoCard(
                        context,
                        icon: Icons.category_rounded,
                        label: 'Category',
                        value: request.categoryName!,
                      ),
                    if (request.categoryName != null) const SizedBox(height: 12),

                    // Status card
                    _buildStatusCard(context, statusColor, statusBg),

                    const SizedBox(height: 12),

                    // Description (FULL, no truncation)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_outlined, size: 20, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Description',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            request.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Customer, Technician, Area, Date
                    _buildInfoCard(
                      context,
                      icon: Icons.person_outline_rounded,
                      label: 'Customer',
                      value: request.customerName ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.handyman_rounded,
                      label: 'Technician',
                      value: request.technicianName,
                    ),
                    const SizedBox(height: 12),
                    if (request.technicianArea != null && request.technicianArea!.isNotEmpty)
                      _buildInfoCard(
                        context,
                        icon: Icons.location_on_outlined,
                        label: 'Area',
                        value: request.technicianArea!,
                      ),
                    if (request.technicianArea != null) const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.calendar_today_outlined,
                      label: 'Requested On',
                      value: _formatDateFull(request.createdAt),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Close button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ---- Info card (icon + label + value) ----
  Widget _buildInfoCard(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
      }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Status card ----
  Widget _buildStatusCard(BuildContext context, Color statusColor, Color statusBg) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon(request.status), size: 22, color: statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(request.status).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Helper functions (copied from main state) ----
  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppTheme.primary;
      case 'completed':
        return AppTheme.success;
      case 'rejected':
      case 'cancelled':
        return AppTheme.error;
      case 'in_progress':
        return Colors.purple.shade700;
      case 'on_the_way':
        return Colors.orange;
      case 'arrived':
        return Colors.teal;
      default:
        return AppTheme.warning;
    }
  }

  Color _statusBackgroundColor(String status) {
    final color = _statusColor(status);
    return color.withOpacity(0.12);
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'completed':
        return Icons.verified_outlined;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'cancelled':
        return Icons.do_not_disturb_on_outlined;
      case 'in_progress':
        return Icons.hourglass_top_rounded;
      case 'on_the_way':
        return Icons.directions_car_rounded;
      case 'arrived':
        return Icons.location_on_rounded;
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
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'in_progress':
        return 'In Progress';
      case 'on_the_way':
        return 'On The Way';
      case 'arrived':
        return 'Arrived';
      default:
        return status.toUpperCase();
    }
  }
}