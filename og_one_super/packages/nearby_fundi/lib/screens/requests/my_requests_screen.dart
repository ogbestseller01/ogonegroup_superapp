// screens/requests/my_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/request.dart';
import '../../providers/request_provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_routes.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';

String formatDateFull(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} • ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  String? _selectedStatusFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestProvider>().loadMyRequests();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Status helpers ──────────────────────────────────────────────────────
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
        return Colors.orange.shade700;
      case 'arrived':
        return Colors.teal.shade700;
      default:
        return AppTheme.warning;
    }
  }

  Color _statusBg(String status) => _statusColor(status).withOpacity(0.12);

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

  int _statusPriority(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'accepted':
        return 1;
      case 'on_the_way':
        return 2;
      case 'arrived':
        return 3;
      case 'in_progress':
        return 4;
      case 'completed':
        return 5;
      case 'rejected':
      case 'cancelled':
        return 6;
      default:
        return 7;
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

  // ── Dialogs ─────────────────────────────────────────────────────────────
  void _showRequestDetails(BuildContext context, ServiceRequest request) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _RequestDetailModal(request: request),
    );
  }

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
            title: const Row(
              children: [
                Icon(Icons.rate_review_rounded, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Rate & Review'),
              ],
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(thickness: 2, color: Theme.of(context).dividerColor.withOpacity(0.6)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Your Rating:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
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
                    Text('$rating / 5', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).hintColor)),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Review', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        hintStyle: TextStyle(color: Theme.of(context).hintColor),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 1.5, color: AppTheme.primary)),
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted!')));
                    context.read<RequestProvider>().loadMyRequests();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message ?? 'Failed to submit review')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hPad = MediaQuery.of(context).size.width > 600 ? 28.0 : 16.0;

    // Filter + Search
    List<ServiceRequest> filtered = provider.requests.where((r) {
      if (_selectedStatusFilter != null && r.status != _selectedStatusFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchService = r.serviceName.toLowerCase().contains(q);
        final matchTech = r.technicianName.toLowerCase().contains(q);
        final matchCustomer = (r.customerName ?? '').toLowerCase().contains(q);
        final matchDesc = r.description.toLowerCase().contains(q);
        if (!matchService && !matchTech && !matchCustomer && !matchDesc) return false;
      }
      return true;
    }).toList();

    // Sort: Active first → newest
    filtered.sort((a, b) {
      final pA = _statusPriority(a.status);
      final pB = _statusPriority(b.status);
      if (pA != pB) return pA.compareTo(pB);
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
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
          // ── Search ────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Filter by technician or service...',
                  hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.7), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: theme.hintColor, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: theme.hintColor),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ── Status Chips (like Dashboard) ─────────────────────────
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hPad),
              children: [
                _filterChip(null, 'All'),
                _filterChip('pending', 'Pending'),
                _filterChip('accepted', 'Accepted'),
                _filterChip('on_the_way', 'On The Way'),
                _filterChip('arrived', 'Arrived'),
                _filterChip('in_progress', 'In Progress'),
                _filterChip('completed', 'Completed'),
                _filterChip('cancelled', 'Cancelled'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Stats Cards ───────────────────────────────────────────
          if (provider.requests.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  Expanded(child: _statCard(Icons.list_alt_rounded, '${provider.requests.length}', 'Total', theme.hintColor)),
                  const SizedBox(width: 10),
                  Expanded(child: _statCard(Icons.hourglass_empty_rounded, '${provider.pendingCount}', 'Pending', AppTheme.warning)),
                  const SizedBox(width: 10),
                  Expanded(child: _statCard(Icons.check_circle_outline_rounded, '${provider.acceptedCount}', 'Accepted', AppTheme.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: _statCard(Icons.verified_outlined, '${provider.completedCount}', 'Done', AppTheme.success)),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── List ──────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.loadMyRequests,
              color: AppTheme.primary,
              child: _buildList(provider, filtered, theme, l10n, hPad),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Chip ───────────────────────────────────────────────────────
  Widget _filterChip(String? value, String label) {
    final selected = _selectedStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatusFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppTheme.primary : Colors.grey.shade200,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade700,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ── Stat Card ─────────────────────────────────────────────────────────
  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────
  Widget _buildList(
      RequestProvider provider,
      List<ServiceRequest> filtered,
      ThemeData theme,
      AppLocalizations l10n,
      double hPad,
      ) {
    if (provider.isLoading && provider.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (provider.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 72, color: theme.hintColor.withOpacity(0.35)),
            const SizedBox(height: 16),
            Text(l10n.noRequestsYet, style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(l10n.requestsWillAppear, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off_rounded, size: 56, color: theme.hintColor.withOpacity(0.45)),
            const SizedBox(height: 14),
            Text('No requests match your filter', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          ],
        ),
      );
    }

    final active = filtered.where((r) => _statusPriority(r.status) <= 4).toList();
    final past = filtered.where((r) => _statusPriority(r.status) > 4).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 28),
      children: [
        if (active.isNotEmpty) ...[
          _sectionTitle('Active Requests', active.length),
          const SizedBox(height: 10),
          ...active.map((r) => _requestCard(r, theme, l10n, provider)),
        ],
        if (past.isNotEmpty) ...[
          if (active.isNotEmpty) const SizedBox(height: 8),
          _sectionTitle('Past Requests', past.length),
          const SizedBox(height: 10),
          ...past.map((r) => _requestCard(r, theme, l10n, provider)),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  // ── Request Card (Dashboard style) ────────────────────────────────────
  Widget _requestCard(
      ServiceRequest r,
      ThemeData theme,
      AppLocalizations l10n,
      RequestProvider provider,
      ) {
    final isPending = r.isPending;
    final isCompleted = r.isCompleted;
    final statusColor = _statusColor(r.status);
    final statusBg = _statusBg(r.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Title + Badge
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_statusIcon(r.status), color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.serviceName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      if (r.categoryName != null && r.categoryName!.isNotEmpty)
                        Text(
                          r.categoryName!,
                          style: TextStyle(fontSize: 12.5, color: AppTheme.primary, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(r.status).toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Person
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.technicianName.isNotEmpty ? r.technicianName : (r.customerName ?? '—'),
                    style: TextStyle(fontSize: 13.5, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Location
            if (r.technicianArea != null && r.technicianArea!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.technicianArea!,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Description box
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                r.description,
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Date
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 5),
                Text(
                  _formatDate(r.createdAt),
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),

            // Completed badge
            if (isCompleted) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 14, color: AppTheme.success),
                    const SizedBox(width: 5),
                    Text('Completed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.success)),
                    if (r.technicianRating != null && r.technicianRating! > 0) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade600),
                      const SizedBox(width: 2),
                      Text(
                        r.technicianRating!.toStringAsFixed(1),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade700),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Actions
            const SizedBox(height: 14),
            Row(
              children: [
                if (isPending)
                  Expanded(
                    child: OutlinedButton(
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (r.isAccepted || r.isOnTheWay || r.isArrived)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.tracking, arguments: r.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Track', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (isCompleted && !r.hasReview)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(context, r),
                      icon: Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade700),
                      label: Text('Review', style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (isPending || r.isAccepted || r.isOnTheWay || r.isArrived || (isCompleted && !r.hasReview))
                  const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRequestDetails(context, r),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(color: AppTheme.primary.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Details', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail Modal (kept clean) ─────────────────────────────────────────────
class _RequestDetailModal extends StatelessWidget {
  final ServiceRequest request;
  const _RequestDetailModal({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(request.status);
    final statusBg = statusColor.withOpacity(0.12);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final dialogWidth = MediaQuery.sizeOf(context).width > 480 ? 480.0 : MediaQuery.sizeOf(context).width - 40;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: Colors.white,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.request_page_rounded, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Request Details', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: theme.hintColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 22),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _infoTile(Icons.construction_rounded, 'Service', request.serviceName),
                    if (request.categoryName != null && request.categoryName!.isNotEmpty)
                      _infoTile(Icons.category_rounded, 'Category', request.categoryName!),
                    _statusTile(statusColor, statusBg),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_outlined, size: 17, color: AppTheme.primary),
                              const SizedBox(width: 7),
                              Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(request.description, style: const TextStyle(fontSize: 14, height: 1.5)),
                        ],
                      ),
                    ),
                    _infoTile(Icons.person_outline_rounded, 'Customer', request.customerName ?? 'N/A'),
                    _infoTile(Icons.handyman_rounded, 'Technician', request.technicianName),
                    if (request.technicianArea != null && request.technicianArea!.isNotEmpty)
                      _infoTile(Icons.location_on_outlined, 'Area', request.technicianArea!),
                    _infoTile(Icons.calendar_today_outlined, 'Requested On', formatDateFull(request.createdAt)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                ),
                child: const Text('Close', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTile(Color color, Color bg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(_statusIcon(request.status), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _getStatusLabel(request.status).toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
        return Colors.orange.shade700;
      case 'arrived':
        return Colors.teal.shade700;
      default:
        return AppTheme.warning;
    }
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