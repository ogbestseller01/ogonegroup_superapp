import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../providers/job_provider.dart';
import '../../utils/home_tabs.dart';
import '../../widgets/completion_otp_dialog.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/status_ticker.dart';

String _formatDate(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
}

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initialLoadDone = true;
      context.read<JobProvider>().loadJobs();
    });
  }

  // ── Back: ALWAYS go to Home dashboard ──────────────────────────────────
  void _handleBack() {
    homeTabRequest.value = HomeTabs.home;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  // ── Mark Complete → server creates OTP → customer enters it ─────────────
  Future<void> _markComplete(Job job) async {
    final provider = context.read<JobProvider>();
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      l10n.markComplete,
      'Is the work finished? A one-time code will be sent to ${job.technicianName}. '
          'Enter it to close the job.',
    );
    if (confirmed != true || !mounted) return;

    final sent = await provider.requestCompletion(job.id);
    if (!mounted) return;

    if (!sent) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.error ?? l10n.couldNotStartCompletion)),
      );
      return;
    }

    final done = await showCompletionOtpDialog(context, job);
    if (done && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.jobCompletedMsg)),
      );
    }
  }

  // ── Chat with the fundi by fundi (user) id only ─────────────────────────
  void _openChat(Job job) {
    Navigator.pushNamed(
      context,
      AppRoutes.chatScreen,
      arguments: job.technicianUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hPad = MediaQuery.of(context).size.width > 600 ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          l10n.jobs,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: _handleBack,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
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
        child: _body(provider, theme, l10n, hPad),
      ),
    );
  }

  Widget _body(
      JobProvider provider,
      ThemeData theme,
      AppLocalizations l10n,
      double hPad,
      ) {
    if (provider.isLoading && provider.jobs.isEmpty && !_initialLoadDone) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (provider.jobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.work_outline_rounded,
            size: 72,
            color: theme.hintColor.withOpacity(0.35),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.noJobsYet,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              l10n.noJobsHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
          ),
        ],
      );
    }

    final active = provider.activeJobs;
    final done = provider.completedJobs;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 28),
      children: [
        if (active.isNotEmpty) ...[
          _sectionTitle(l10n.activeJobs, active.length),
          const SizedBox(height: 10),
          ...active.map((j) => _jobCard(j, provider, l10n)),
        ],
        if (done.isNotEmpty) ...[
          if (active.isNotEmpty) const SizedBox(height: 8),
          _sectionTitle(l10n.completedJobs, done.length),
          const SizedBox(height: 10),
          ...done.map((j) => _jobCard(j, provider, l10n)),
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
            color: Color(0xFF1E293B),
          ),
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
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _jobCard(Job job, JobProvider provider, AppLocalizations l10n) {
    final busy = provider.isBusy(job.id);

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.serviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.jobNumber,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusTicker(
                  label: job.statusLabel,
                  color: job.statusColor,
                  live: job.isOnProgress,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.handyman_rounded,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job.technicianName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (job.technicianArea != null && job.technicianArea!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.technicianArea!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
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
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 5),
                Text(
                  'Started ${_formatDate(job.startedAt)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (job.isCompleted) ...[
                  const SizedBox(width: 14),
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 14,
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Done ${_formatDate(job.completedAt)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (job.technicianUserId != 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openChat(job),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                      ),
                      label: Text(
                        l10n.chat,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(
                          color: AppTheme.primary.withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (job.canMarkComplete) ...[
                  if (job.technicianUserId != 0) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: busy ? null : () => _markComplete(job),
                      icon: busy
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.task_alt_rounded, size: 18),
                      label: Text(
                        l10n.markComplete,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}