import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/job.dart';
import '../../providers/job_provider.dart';
import '../../widgets/work_status_widgets.dart';
import '../tickets/ticket_detail_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final WorkJob job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late WorkJob _job;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
  }

  Future<void> _refresh() async {
    final fresh = await context.read<JobProvider>().fetchJob(_job.id);
    if (fresh != null && mounted) setState(() => _job = fresh);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppTheme.primary;
    final color = workStatusColor(_job.status);

    return Scaffold(
      backgroundColor:
      isDark ? AppTheme.darkBackground : Theme.of(context).scaffoldBackgroundColor,
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
            const Expanded(
              child: Text(
                'Job Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ── Header ──────────────────────────────
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
                    child: Icon(workStatusIcon(_job.status),
                        color: color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_job.jobNumber,
                            style: TextStyle(
                                inherit: true,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: primaryText)),
                        const SizedBox(height: 6),
                        WorkStatusBadge(status: _job.status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Details ─────────────────────────────
            WorkCard(
              child: Column(
                children: [
                  WorkInfoRow(
                      icon: Icons.tag_rounded,
                      label: 'Job number',
                      value: _job.jobNumber),
                  WorkInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Customer',
                      value: _job.customerName ?? '—'),
                  WorkInfoRow(
                      icon: Icons.build_outlined,
                      label: 'Service',
                      value: _job.serviceName ?? '—'),
                  if (_job.categoryName != null)
                    WorkInfoRow(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: _job.categoryName!),
                  if (_job.description != null)
                    WorkInfoRow(
                        icon: Icons.description_outlined,
                        label: 'Request description',
                        value: _job.description!),
                  WorkInfoRow(
                      icon: Icons.flag_outlined,
                      label: 'Status',
                      value: workStatusLabel(_job.status)),
                  WorkInfoRow(
                      icon: Icons.access_time_rounded,
                      label: 'Created',
                      value: formatEAT(_job.createdAt)),
                  WorkInfoRow(
                      icon: Icons.play_circle_outline_rounded,
                      label: 'Started',
                      value: formatEAT(_job.startedAt)),
                  WorkInfoRow(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Completed',
                      value: formatEAT(_job.completedAt)),
                  if (_job.notes != null)
                    WorkInfoRow(
                        icon: Icons.sticky_note_2_outlined,
                        label: 'Notes',
                        value: _job.notes!),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Tickets ─────────────────────────────
            Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Tickets (${_job.tickets.length})',
                    style: TextStyle(
                        inherit: true,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: primaryText)),
              ],
            ),
            const SizedBox(height: 12),
            if (_job.tickets.isEmpty)
              const WorkEmptyState(
                icon: Icons.confirmation_number_outlined,
                message: 'No tickets for this job',
              )
            else
              ..._job.tickets.map(
                    (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: WorkCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TicketDetailScreen(ticket: t)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.ticketNumber,
                                  style: TextStyle(
                                      inherit: true,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: primaryText)),
                              const SizedBox(height: 3),
                              Text(t.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      inherit: true,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              WorkMetaLine(
                                  icon: Icons.access_time_rounded,
                                  text: formatEAT(t.createdAt)),
                            ],
                          ),
                        ),
                        WorkStatusBadge(status: t.status),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
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