// lib/screens/requests/my_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/request.dart';
import '../../providers/request_provider.dart';
import '../../widgets/confirmation_dialog.dart';

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
  String? _statusFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RequestProvider>().loadMyRequests();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  int _statusPriority(String status) {
    switch (status) {
      case ServiceRequest.pendingStatus:
        return 0;
      case ServiceRequest.acceptedStatus:
        return 1;
      case ServiceRequest.rejectedStatus:
        return 2;
      case ServiceRequest.cancelledStatus:
        return 3;
      default:
        return 4;
    }
  }

  String _formatAgo(DateTime date, AppLocalizations l10n) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return l10n.timeAgoDays(diff.inDays);
    if (diff.inHours > 0) return l10n.timeAgoHours(diff.inHours);
    if (diff.inMinutes > 0) return l10n.timeAgoMinutes(diff.inMinutes);
    return l10n.timeAgoJustNow;
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    }
  }

  void _showDetails(ServiceRequest r, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: true,
      builder: (_) => _RequestDetailModal(request: r, l10n: l10n),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────
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
          SnackBar(content: Text(provider.error ?? l10n.couldNotCancelRequest)),
        );
      }
    }
  }

  void _openChat(ServiceRequest r) {
    if (r.technicianUserId == 0) return;
    Navigator.pushNamed(
      context,
      AppRoutes.chatScreen,
      arguments: r.technicianUserId,
    );
  }

  /// The job is created automatically when the fundi accepts.
  void _openJob(ServiceRequest r) {
    final jobId = r.jobId;
    if (jobId == null) return;
    Navigator.pushNamed(context, AppRoutes.jobDetail, arguments: jobId);
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RequestProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.myRequests,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: _handleBack,
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
          // Search
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  hintText: l10n.filterByFundiOrService,
                  hintStyle:
                  TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: colors.onSurfaceVariant, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: colors.onSurfaceVariant),
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

          // Status chips
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hPad),
              children: [
                _filterChip(null, l10n.allLabel),
                _filterChip(ServiceRequest.pendingStatus, l10n.statusPending),
                _filterChip(ServiceRequest.acceptedStatus, l10n.statusAccepted),
                _filterChip(ServiceRequest.rejectedStatus, l10n.statusRejected),
                _filterChip(ServiceRequest.cancelledStatus, l10n.statusCancelled),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Stats (Closed card removed — only 3 cards now)
          if (provider.requests.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  Expanded(
                      child: _statCard(Icons.list_alt_rounded,
                          '${provider.totalCount}', l10n.statTotal,
                          colors.onSurfaceVariant)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(Icons.hourglass_empty_rounded,
                          '${provider.pendingCount}', l10n.statusPending,
                          colors.tertiary)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(Icons.check_circle_outline_rounded,
                          '${provider.acceptedCount}', l10n.statusAccepted,
                          colors.primary)),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.loadMyRequests,
              color: colors.primary,
              child: _buildList(provider, filtered, theme, l10n, hPad),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String? value, String label) {
    final colors = Theme.of(context).colorScheme;
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _statusFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
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
              color: color.withValues(alpha: 0.12),
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
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      RequestProvider provider,
      List<ServiceRequest> filtered,
      ThemeData theme,
      AppLocalizations l10n,
      double hPad,
      ) {
    final colors = theme.colorScheme;
    if (provider.isLoading && provider.requests.isEmpty) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (provider.requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.inbox_outlined,
              size: 72, color: colors.onSurfaceVariant.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              provider.error ?? l10n.noRequestsYet,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(l10n.requestsWillAppear,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant)),
          ),
        ],
      );
    }

    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.filter_alt_off_rounded,
              size: 56, color: colors.onSurfaceVariant.withValues(alpha: 0.45)),
          const SizedBox(height: 14),
          Center(
            child: Text(l10n.noRequestsMatchFilter,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant)),
          ),
        ],
      );
    }

    final open = filtered.where((r) => !r.isClosed).toList();
    final closed = filtered.where((r) => r.isClosed).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 28),
      children: [
        if (open.isNotEmpty) ...[
          _sectionTitle(l10n.sectionActiveRequests, open.length),
          const SizedBox(height: 10),
          ...open.map((r) => _requestCard(r, provider, l10n)),
        ],
        if (closed.isNotEmpty) ...[
          if (open.isNotEmpty) const SizedBox(height: 8),
          _sectionTitle(l10n.sectionClosedRequests, closed.length),
          const SizedBox(height: 10),
          ...closed.map((r) => _requestCard(r, provider, l10n)),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, int count) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.onSurface),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.primary),
          ),
        ),
      ],
    );
  }

  Widget _requestCard(
      ServiceRequest r, RequestProvider provider, AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = r.statusColor;
    final statusBg = statusColor.withValues(alpha: 0.12);
    final cancelling = provider.isCancelling(r.id);
    final category = r.categoryName;
    final area = r.technicianArea;

    ButtonStyle outlined(Color c) => OutlinedButton.styleFrom(
      foregroundColor: c,
      side: BorderSide(color: c.withValues(alpha: 0.45)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    final actions = <Widget>[
      if (r.canBeCancelled)
        OutlinedButton(
          onPressed: cancelling ? null : () => _confirmCancel(r),
          style: outlined(colors.error),
          child: cancelling
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(l10n.cancelAction,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      // The job is created automatically when the request is accepted.
      if (r.hasJob)
        OutlinedButton.icon(
          onPressed: () => _openJob(r),
          icon: const Icon(Icons.work_outline_rounded, size: 16),
          label: Text(l10n.viewJob,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          style: outlined(colors.primary),
        ),
      if (r.technicianUserId != 0)
        OutlinedButton.icon(
          onPressed: () => _openChat(r),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
          label: Text(l10n.chatAction,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          style: outlined(colors.primary),
        ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
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
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface),
                      ),
                      if (category != null && category.isNotEmpty)
                        Text(
                          category,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: colors.primary,
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

            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 16, color: colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.technicianName,
                    style: TextStyle(
                        fontSize: 13.5,
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (area != null && area.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 15, color: colors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      area,
                      style: TextStyle(
                          fontSize: 13, color: colors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                r.description,
                style: TextStyle(
                    fontSize: 13.5,
                    color: colors.onSurfaceVariant,
                    height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: colors.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  _formatAgo(r.createdAt, l10n),
                  style:
                  TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
                ),
              ],
            ),

            if (actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showDetails(r, l10n),
                style: outlined(colors.primary),
                child: Text(l10n.detailsAction,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail Modal ──────────────────────────────────────────────────────────
class _RequestDetailModal extends StatelessWidget {
  final ServiceRequest request;
  final AppLocalizations l10n;

  const _RequestDetailModal({required this.request, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = request.statusColor;
    final statusBg = statusColor.withValues(alpha: 0.12);
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = size.width > 480 ? 480.0 : size.width - 40;
    final category = request.categoryName;
    final area = request.technicianArea;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: colors.surface,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: size.height * 0.88),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.request_page_rounded,
                      color: colors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.requestDetailsTitle,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 22),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _infoTile(context, Icons.construction_rounded,
                        l10n.fieldService, request.serviceName),
                    if (category != null && category.isNotEmpty)
                      _infoTile(context, Icons.category_rounded,
                          l10n.fieldCategory, category),
                    _statusTile(context, statusColor, statusBg),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_outlined,
                                  size: 17, color: colors.primary),
                              const SizedBox(width: 7),
                              Text(l10n.fieldDescription,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSurfaceVariant)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(request.description,
                              style: const TextStyle(fontSize: 14, height: 1.5)),
                        ],
                      ),
                    ),
                    _infoTile(context, Icons.handyman_rounded, l10n.fieldFundi,
                        request.technicianName),
                    if (area != null && area.isNotEmpty)
                      _infoTile(context, Icons.location_on_outlined,
                          l10n.fieldArea, area),
                    _infoTile(context, Icons.calendar_today_outlined,
                        l10n.fieldRequestedOn,
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
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                ),
                child: Text(l10n.closeAction,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
      BuildContext context, IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
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

  Widget _statusTile(BuildContext context, Color color, Color bg) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(request.statusIcon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.fieldStatus,
                  style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
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