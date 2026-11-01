// screens/requests/my_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/request.dart';
import '../../providers/request_provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_routes.dart';
import '../../utils/home_tabs.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/mark_as_job_flow.dart';
import '../../l10n/app_localizations.dart';

String formatDateFull(DateTime date) {
  final l = date.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year} • '
      '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  String? _statusFilter; // null = all
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

  // ── Helpers ─────────────────────────────────────────────────────────────
  /// pending, accepted, in progress, then rejected / cancelled
  int _statusPriority(String status) {
    switch (status) {
      case ServiceRequest.pendingStatus:
        return 0;
      case ServiceRequest.acceptedStatus:
        return 1;
      case ServiceRequest.inProgressStatus:
        return 2;
      case ServiceRequest.rejectedStatus:
        return 3;
      case ServiceRequest.cancelledStatus:
        return 4;
      default:
        return 5;
    }
  }

  String _formatAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Future<void> _confirmCancel(ServiceRequest r) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<RequestProvider>();

    if (!r.canBeCancelled) return;

    final confirmed = await showConfirmationDialog(
      context,
      l10n.cancelRequest,
      l10n.areYouSureCancel,
    );

    if (confirmed == true && mounted) {
      final ok = await provider.cancelRequest(r.id);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Could not cancel request.')),
        );
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hPad = MediaQuery.of(context).size.width > 600 ? 28.0 : 16.0;

    final filtered = provider.requests.where((r) {
      if (_statusFilter != null && r.status != _statusFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return r.serviceName.toLowerCase().contains(q) ||
            r.technicianName.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q);
      }
      return true;
    }).toList()
      ..sort((a, b) {
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
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
          // ── Search ──
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
                  hintText: 'Filter by fundi or service...',
                  hintStyle: TextStyle(
                      color: theme.hintColor.withOpacity(0.7), fontSize: 14),
                  prefixIcon:
                  Icon(Icons.search_rounded, color: theme.hintColor, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: theme.hintColor),
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

          // ── Status chips ──
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hPad),
              children: [
                _filterChip(null, 'All'),
                _filterChip(ServiceRequest.pendingStatus, 'Pending'),
                _filterChip(ServiceRequest.acceptedStatus, 'Accepted'),
                _filterChip(ServiceRequest.inProgressStatus, 'In progress'),
                _filterChip(ServiceRequest.rejectedStatus, 'Rejected'),
                _filterChip(ServiceRequest.cancelledStatus, 'Cancelled'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Stats ──
          if (provider.requests.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  Expanded(
                      child: _statCard(Icons.list_alt_rounded,
                          '${provider.totalCount}', 'Total', theme.hintColor)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(Icons.hourglass_empty_rounded,
                          '${provider.pendingCount}', 'Pending', AppTheme.warning)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(Icons.check_circle_outline_rounded,
                          '${provider.acceptedCount}', 'Accepted', AppTheme.success)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(Icons.engineering_rounded,
                          '${provider.inProgressCount}', 'In progress', AppTheme.accent)),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── List ──
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

  // ── Filter chip ─────────────────────────────────────────────────────────
  Widget _filterChip(String? value, String label) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _statusFilter = value),
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

  // ── Stat card ───────────────────────────────────────────────────────────
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
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ── List ────────────────────────────────────────────────────────────────
  Widget _buildList(
      RequestProvider provider,
      List<ServiceRequest> filtered,
      ThemeData theme,
      AppLocalizations l10n,
      double hPad,
      ) {
    if (provider.isLoading && provider.requests.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (provider.requests.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.inbox_outlined,
              size: 72, color: theme.hintColor.withOpacity(0.35)),
          const SizedBox(height: 16),
          Center(
            child: Text(l10n.noRequestsYet,
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.hintColor, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(l10n.requestsWillAppear,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor)),
          ),
        ],
      );
    }

    if (filtered.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.filter_alt_off_rounded,
              size: 56, color: theme.hintColor.withOpacity(0.45)),
          const SizedBox(height: 14),
          Center(
            child: Text('No requests match your filter',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor)),
          ),
        ],
      );
    }

    final open = filtered
        .where((r) => r.isPending || r.isAccepted || r.isInProgress)
        .toList();
    final closed = filtered.where((r) => r.isRejected || r.isCancelled).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 28),
      children: [
        if (open.isNotEmpty) ...[
          _sectionTitle('Active Requests', open.length),
          const SizedBox(height: 10),
          ...open.map((r) => _requestCard(r, provider)),
        ],
        if (closed.isNotEmpty) ...[
          if (open.isNotEmpty) const SizedBox(height: 8),
          _sectionTitle('Closed Requests', closed.length),
          const SizedBox(height: 10),
          ...closed.map((r) => _requestCard(r, provider)),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B)),
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
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  // ── Request card ────────────────────────────────────────────────────────
  Widget _requestCard(ServiceRequest r, RequestProvider provider) {
    final statusColor = r.statusColor;
    final statusBg = statusColor.withOpacity(0.12);
    final cancelling = provider.isCancelling(r.id);

    ButtonStyle outlined(Color c) => OutlinedButton.styleFrom(
      foregroundColor: c,
      side: BorderSide(color: c.withOpacity(0.45)),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    // Second row of buttons: Cancel (pending) · Track · View Job · Details
    final secondary = <Widget>[
      if (r.canBeCancelled)
        Expanded(
          child: OutlinedButton(
            onPressed: cancelling ? null : () => _confirmCancel(r),
            style: outlined(AppTheme.error),
            child: cancelling
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      if (r.isAccepted || r.isInProgress)
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.tracking,
              arguments: r.id,
            ),
            style: outlined(AppTheme.primary),
            child: const Text('Track',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      if (r.isInProgress)
        Expanded(
          child: OutlinedButton(
            onPressed: () => homeTabRequest.value = HomeTabs.jobs,
            style: outlined(AppTheme.accent),
            child: const Text('View Job',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      Expanded(
        child: OutlinedButton(
          onPressed: () => showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => _RequestDetailModal(request: r),
          ),
          style: outlined(AppTheme.primary),
          child: const Text('Details',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    ];

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
            // Header
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(r.statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.serviceName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B)),
                      ),
                      if (r.categoryName != null && r.categoryName!.isNotEmpty)
                        Text(
                          r.categoryName!,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    r.statusLabel.toUpperCase(),
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

            // Fundi
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.technicianName,
                    style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (r.technicianArea != null && r.technicianArea!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.technicianArea!,
                      style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Description
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
                style: TextStyle(
                    fontSize: 13.5, color: Colors.grey.shade700, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Time
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 5),
                Text(
                  _formatAgo(r.createdAt),
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),

            // Accepted → next step hint
            if (r.canMarkAsJob) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded,
                        size: 14, color: AppTheme.success),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Accepted — it can no longer be cancelled. '
                            'Mark it as a job to start the work.',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // PRIMARY: Mark as Job (accepted only)
            if (r.canMarkAsJob) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => startMarkAsJobFlow(context, r),
                  icon: const Icon(Icons.engineering_rounded, size: 18),
                  label: const Text('Mark as Job',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Secondary buttons
            Row(
              children: [
                for (var i = 0; i < secondary.length; i++) ...[
                  if (i != 0) const SizedBox(width: 10),
                  secondary[i],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail Modal (no contact info) ────────────────────────────────────────
class _RequestDetailModal extends StatelessWidget {
  final ServiceRequest request;
  const _RequestDetailModal({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = request.statusColor;
    final statusBg = statusColor.withOpacity(0.12);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final dialogWidth = MediaQuery.sizeOf(context).width > 480
        ? 480.0
        : MediaQuery.sizeOf(context).width - 40;

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
                  child: const Icon(Icons.request_page_rounded,
                      color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Request Details',
                      style:
                      TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
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
                    _infoTile(Icons.construction_rounded, 'Service',
                        request.serviceName),
                    if (request.categoryName != null &&
                        request.categoryName!.isNotEmpty)
                      _infoTile(Icons.category_rounded, 'Category',
                          request.categoryName!),
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
                              const Icon(Icons.description_outlined,
                                  size: 17, color: AppTheme.primary),
                              const SizedBox(width: 7),
                              Text('Description',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(request.description,
                              style:
                              const TextStyle(fontSize: 14, height: 1.5)),
                        ],
                      ),
                    ),
                    _infoTile(Icons.handyman_rounded, 'Fundi',
                        request.technicianName),
                    if (request.technicianArea != null &&
                        request.technicianArea!.isNotEmpty)
                      _infoTile(Icons.location_on_outlined, 'Area',
                          request.technicianArea!),
                    _infoTile(Icons.calendar_today_outlined, 'Requested On',
                        formatDateFull(request.createdAt)),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                ),
                child: const Text('Close',
                    style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
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
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTile(Color color, Color bg) {
    return Container(
      width: double.infinity,
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
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(request.statusIcon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  request.statusLabel.toUpperCase(),
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
