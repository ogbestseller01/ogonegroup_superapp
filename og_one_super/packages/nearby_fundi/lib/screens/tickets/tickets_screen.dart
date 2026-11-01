import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../providers/job_provider.dart';
import '../../widgets/status_ticker.dart';

String _formatDateTime(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year} • '
      '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// Tickets are created automatically with each job and complete with it.
class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<JobProvider>().loadJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hPad = MediaQuery.of(context).size.width > 600 ? 28.0 : 16.0;
    final items = provider.jobsWithTicket;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          l10n.tickets,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: provider.loadJobs,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.loadJobs,
        color: AppTheme.primary,
        child: provider.isLoading && provider.jobs.isEmpty
            ? const Center(
            child: CircularProgressIndicator(color: AppTheme.primary))
            : items.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Icon(Icons.confirmation_number_outlined,
                size: 72, color: theme.hintColor.withOpacity(0.35)),
            const SizedBox(height: 16),
            Center(
              child: Text('No tickets yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                  'A ticket is created when you mark a request as a job.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor)),
            ),
          ],
        )
            : ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 28),
          itemCount: items.length,
          itemBuilder: (_, i) => _ticketCard(items[i]),
        ),
      ),
    );
  }

  Widget _ticketCard(Job job) {
    final t = job.ticket!;
    final color = Job.statusColorFor(t.status);
    final fundi = t.technicianName ?? job.technicianName;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.confirmation_number_outlined,
                    color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B))),
                    if (t.ticketNumber.isNotEmpty)
                      Text(t.ticketNumber,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusTicker(
                label: Job.statusLabelFor(t.status),
                color: color,
                live: !t.isCompleted,
              ),
            ],
          ),
          if (t.description != null && t.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(t.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey.shade700,
                      height: 1.4)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.handyman_rounded,
                  size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 5),
              Expanded(
                child: Text('Fundi: $fundi • ${job.jobNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                    TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 5),
              Text('Created ${_formatDateTime(t.createdAt)}',
                  style:
                  TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
            ],
          ),
          if (t.isCompleted) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 14, color: AppTheme.success),
                const SizedBox(width: 5),
                Text('Completed ${_formatDateTime(t.completedAt)}',
                    style:
                    TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}