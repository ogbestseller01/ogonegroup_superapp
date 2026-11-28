// FILE: lib/screens/jobs/job_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/job.dart';
import '../../providers/job_provider.dart';
import '../../widgets/work_status_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../tickets/ticket_detail_screen.dart';

/// Localized label for a known status, or null for an unknown one.
String? jobStatusText(String status, AppLocalizations l10n) {
  switch (status) {
    case 'pending':
      return l10n.statusPending;
    case 'on-progress':
      return l10n.jobStatusOnProgress;
    case 'completed':
      return l10n.jobStatusCompleted;
    case 'cancelled':
      return l10n.statusCancelled;
    default:
      return null;
  }
}

/// Status badge with a localized label.
class JobStatusBadge extends StatelessWidget {
  final String status;
  const JobStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final label = jobStatusText(status, AppLocalizations.of(context)!);
    // Unknown statuses keep the shared badge.
    if (label == null) return WorkStatusBadge(status: status);

    final color = workStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          inherit: true,
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class JobDetailDialog extends StatefulWidget {
  final WorkJob job;
  const JobDetailDialog({super.key, required this.job});

  static Future<void> show(BuildContext context, WorkJob job) {
    return showDialog<void>(
      context: context,
      // Stay inside FundiApp's navigator so its providers, theme and
      // translations remain available when embedded in the host app.
      useRootNavigator: false,
      builder: (_) => JobDetailDialog(job: job),
    );
  }

  @override
  State<JobDetailDialog> createState() => _JobDetailDialogState();
}

class _JobDetailDialogState extends State<JobDetailDialog> {
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
    final l10n = AppLocalizations.of(context)!;
    final primaryText = isDark ? Colors.white : AppTheme.primary;
    final color = workStatusColor(_job.status);

    return Dialog(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : Theme.of(context).scaffoldBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title bar ───────────────────────────
            Container(
              color: AppTheme.primary,
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.jobDetails,
                      style: const TextStyle(
                        inherit: true,
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.jobDialogClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: _refresh,
                child: ListView(
                  shrinkWrap: true,
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
                            child: Icon(
                              workStatusIcon(_job.status),
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
                                  _job.jobNumber,
                                  style: TextStyle(
                                    inherit: true,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                JobStatusBadge(status: _job.status),
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
                            label: l10n.jobNumber,
                            value: _job.jobNumber,
                          ),
                          WorkInfoRow(
                            icon: Icons.person_outline_rounded,
                            label: l10n.customer,
                            value: _job.customerName ?? '—',
                          ),
                          WorkInfoRow(
                            icon: Icons.build_outlined,
                            label: l10n.service,
                            value: _job.serviceName ?? '—',
                          ),
                          if (_job.categoryName != null)
                            WorkInfoRow(
                              icon: Icons.category_outlined,
                              label: l10n.category,
                              value: _job.categoryName!,
                            ),
                          if (_job.description != null)
                            WorkInfoRow(
                              icon: Icons.description_outlined,
                              label: l10n.requestDescription,
                              value: _job.description!,
                            ),
                          WorkInfoRow(
                            icon: Icons.flag_outlined,
                            label: l10n.jobStatus,
                            value: jobStatusText(_job.status, l10n) ?? _job.status,
                          ),
                          WorkInfoRow(
                            icon: Icons.access_time_rounded,
                            label: l10n.created,
                            value: formatEAT(_job.createdAt),
                          ),
                          WorkInfoRow(
                            icon: Icons.play_circle_outline_rounded,
                            label: l10n.started,
                            value: formatEAT(_job.startedAt),
                          ),
                          WorkInfoRow(
                            icon: Icons.check_circle_outline_rounded,
                            label: l10n.completedLabel,
                            value: formatEAT(_job.completedAt),
                          ),
                          if (_job.notes != null)
                            WorkInfoRow(
                              icon: Icons.sticky_note_2_outlined,
                              label: l10n.notes,
                              value: _job.notes!,
                            ),
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
                        Text(
                          l10n.ticketsCount(_job.tickets.length),
                          style: TextStyle(
                            inherit: true,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_job.tickets.isEmpty)
                      WorkEmptyState(
                        icon: Icons.confirmation_number_outlined,
                        message: l10n.noTicketsForJob,
                      )
                    else
                      ..._job.tickets.map(
                            (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: WorkCard(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TicketDetailScreen(ticket: t),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.ticketNumber,
                                        style: TextStyle(
                                          inherit: true,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                          color: primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        t.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          inherit: true,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      WorkMetaLine(
                                        icon: Icons.access_time_rounded,
                                        text: formatEAT(t.createdAt),
                                      ),
                                    ],
                                  ),
                                ),
                                JobStatusBadge(status: t.status),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}