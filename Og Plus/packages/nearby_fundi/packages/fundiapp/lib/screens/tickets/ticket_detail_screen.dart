// FILE: lib/screens/tickets/ticket_detail_screen.dart

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/job.dart';
import '../../widgets/work_status_widgets.dart';
import '../../l10n/app_localizations.dart';

class TicketDetailScreen extends StatelessWidget {
  final WorkTicket ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  void _downloadTicket(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.downloadingTicket(ticket.ticketNumber)),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryText = isDark ? Colors.white : AppTheme.primary;
    final color = workStatusColor(ticket.status);

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
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.ticketDetails,
                style: const TextStyle(
                  inherit: true,
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _AppBarButton(
              icon: Icons.download_rounded,
              onTap: () => _downloadTicket(context),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WorkCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.confirmation_number_rounded,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.ticketNumber,
                        style: TextStyle(
                          inherit: true,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      WorkStatusBadge(status: ticket.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          WorkCard(
            child: Column(
              children: [
                WorkInfoRow(
                  icon: Icons.tag_rounded,
                  label: l10n.ticketNumber,
                  value: ticket.ticketNumber,
                ),
                WorkInfoRow(
                  icon: Icons.title_rounded,
                  label: l10n.title,
                  value: ticket.title,
                ),
                if (ticket.description != null)
                  WorkInfoRow(
                    icon: Icons.description_outlined,
                    label: l10n.description,
                    value: ticket.description!,
                  ),
                WorkInfoRow(
                  icon: Icons.work_outline_rounded,
                  label: l10n.jobs,
                  value: ticket.jobNumber ?? '—',
                ),
                if (ticket.jobStatus != null)
                  WorkInfoRow(
                    icon: Icons.flag_outlined,
                    label: l10n.jobStatus,
                    value: workStatusLabel(ticket.jobStatus!),
                  ),
                WorkInfoRow(
                  icon: Icons.person_outline_rounded,
                  label: l10n.customer,
                  value: ticket.customerName ?? '—',
                ),
                WorkInfoRow(
                  icon: Icons.build_outlined,
                  label: l10n.service,
                  value: ticket.serviceName ?? '—',
                ),
                WorkInfoRow(
                  icon: Icons.flag_circle_outlined,
                  label: l10n.ticketStatus,
                  value: workStatusLabel(ticket.status),
                ),
                // ── only show when a date exists ──
                if (ticket.createdAt != null)
                  WorkInfoRow(
                    icon: Icons.access_time_rounded,
                    label: l10n.created,
                    value: formatEAT(ticket.createdAt),
                  ),
                if (ticket.completedAt != null)
                  WorkInfoRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: l10n.completedLabel,
                    value: formatEAT(ticket.completedAt),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.download_rounded),
              label: Text(
                l10n.downloadTicket,
                style: const TextStyle(
                  inherit: true,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              onPressed: () => _downloadTicket(context),
            ),
          ),
        ],
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