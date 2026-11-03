// FILE: lib/screens/tickets/tickets_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../models/job.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/work_status_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'ticket_detail_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  // Raw status slugs (must match backend values). Labels are localized below.
  static const _filters = ['all', 'on-progress', 'completed'];

  String _filter = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadTickets();
    });
  }

  List<WorkTicket> _apply(List<WorkTicket> all) {
    final q = _query.trim().toLowerCase();
    return all.where((t) {
      if (_filter != 'all' && t.status != _filter) return false;
      if (q.isEmpty) return true;
      return t.ticketNumber.toLowerCase().contains(q) ||
          t.title.toLowerCase().contains(q) ||
          (t.jobNumber ?? '').toLowerCase().contains(q) ||
          (t.customerName ?? '').toLowerCase().contains(q) ||
          (t.serviceName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  /// Localizes the filter bar labels while keeping the raw slug as the value.
  Map<String, String> _filterLabels(AppLocalizations l10n) => {
    'all': l10n.filterAll,
    'on-progress': l10n.filterOnProgress,
    'completed': l10n.filterCompleted,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<TicketProvider>();
    final filtered = _apply(provider.tickets);

    final counts = <String, int>{
      'all': provider.tickets.length,
      for (final s in _filters.skip(1)) s: provider.countByStatus(s),
    };

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: Row(
          children: [
            _AppBarButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.home),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.tickets,
                style: const TextStyle(
                  inherit: true,
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _AppBarButton(
              icon: Icons.refresh_rounded,
              onTap: provider.isLoading ? () {} : () => provider.loadTickets(),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          WorkSearchField(
            hint: l10n.searchTicketsHint,
            onChanged: (v) => setState(() => _query = v),
          ),
          WorkFilterBar(
            options: _filters,
            selected: _filter,
            counts: counts,
            // Localized labels; the raw slug is still the option value.
            labels: _filterLabels(l10n),
            onSelected: (v) => setState(() => _filter = v),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(provider, filtered, l10n)),
        ],
      ),
    );
  }

  Widget _buildBody(
      TicketProvider provider,
      List<WorkTicket> filtered,
      AppLocalizations l10n,
      ) {
    if (provider.isLoading && provider.tickets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }
    if (provider.error != null && provider.tickets.isEmpty) {
      return WorkEmptyState(
        icon: Icons.error_outline_rounded,
        message: provider.error!,
        onRetry: provider.loadTickets,
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: provider.loadTickets,
      child: filtered.isEmpty
          ? ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          WorkEmptyState(
            icon: Icons.confirmation_number_outlined,
            message: l10n.noTicketsFound,
          ),
        ],
      )
          : ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _TicketCard(ticket: filtered[i]),
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final WorkTicket ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? Colors.white : AppTheme.primary;
    final color = workStatusColor(ticket.status);

    return WorkCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.confirmation_number_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.ticketNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          inherit: true,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    WorkStatusBadge(status: ticket.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    inherit: true,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                WorkMetaLine(
                  icon: Icons.work_outline_rounded,
                  text: ticket.jobNumber ?? '—',
                ),
                WorkMetaLine(
                  icon: Icons.person_outline_rounded,
                  text: ticket.customerName ?? '—',
                ),
                WorkMetaLine(
                  icon: Icons.build_outlined,
                  text: ticket.serviceName ?? '—',
                ),
                if (ticket.createdAt != null)
                  WorkMetaLine(
                    icon: Icons.access_time_rounded,
                    text:
                    '${l10n.created} ${formatEAT(ticket.createdAt)}',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}