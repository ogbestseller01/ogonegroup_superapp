// lib/screens/jobs/job_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../providers/job_provider.dart';
// TODO(payments): re-add this import when the Pay button is enabled again.
// import '../payments/payment_channel_modal.dart';
import 'confirm_completion_modal.dart';
import 'confirm_completion_prompt_modal.dart';
import 'job_review_sheet.dart';

String _formatDate(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/'
      '${l.month.toString().padLeft(2, '0')}/${l.year}';
}

String _formatDateTime(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${_formatDate(l)} '
      '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final int jobId;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _fetched = false;
  bool _sendingCode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<JobProvider>();

      if (provider.getJobById(widget.jobId) == null) {
        // Not cached (e.g. opened from a notification): load the list.
        await provider.ensureJob(widget.jobId);
      } else {
        // Cached from the list: show it now, refresh this job in the background
        // so the review / status are never stale.
        provider.refreshJob(widget.jobId);
      }

      if (mounted) setState(() => _fetched = true);
    });
  }

  Future<void> _retry() async {
    setState(() => _fetched = false);
    await context.read<JobProvider>().loadJobs();
    if (mounted) setState(() => _fetched = true);
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.jobs);
    }
  }

  Widget _backButton() => IconButton(
    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: _goBack,
  );

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.error : AppTheme.success,
      ));
  }

  Future<void> _markComplete(Job job) async {
    if (_sendingCode) return;
    final l10n = AppLocalizations.of(context)!;

    final shouldSend = await ConfirmCompletionPromptModal.show(context);
    if (shouldSend != true || !mounted) return;

    final provider = context.read<JobProvider>();
    setState(() => _sendingCode = true);

    final sent = await provider.requestCompletion(job.id);
    if (!mounted) return;

    if (!sent) {
      setState(() => _sendingCode = false);
      _snack(provider.error ?? l10n.couldNotSendSms, error: true);
      return;
    }

    setState(() => _sendingCode = false);

    final done = await ConfirmCompletionModal.show(context, job.id);
    if (done == true && mounted) {
      _snack(l10n.jobCompletedSuccess);

      // Job is completed → invite the customer to rate it.
      final updated = context.read<JobProvider>().getJobById(job.id);
      if (updated != null && updated.canReview) {
        await _openReview(updated);
      }
    }
  }

  /// Opens the review sheet, then re-fetches this job so the screen shows
  /// the submitted review instead of the "Rate this job" prompt.
  Future<void> _openReview(Job job) async {
    final submitted = await showJobReviewSheet(context, job);
    if (submitted == true && mounted) {
      await context.read<JobProvider>().refreshJob(job.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<JobProvider>();
    final theme = Theme.of(context);
    final job = provider.getJobById(widget.jobId);

    if (job == null) {
      final waiting = !_fetched || provider.isLoading;
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: _backButton(),
          title: Text(l10n.jobs),
        ),
        body: Center(
          child: waiting
              ? const CircularProgressIndicator(color: AppTheme.primary)
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.jobNotFound),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _retry, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }

    final ticket = job.ticket;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _backButton(),
        title: Text(
          job.serviceName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: _sendingCode
            ? const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            backgroundColor: Colors.white24,
            color: Colors.amberAccent,
          ),
        )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshJob(widget.jobId),
        color: AppTheme.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ── Summary ──────────────────────────────────────────────
            _card(
              theme: theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.serviceName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      _pill(job.statusLabel, job.statusColor),
                    ],
                  ),
                  if (job.jobNumber.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _row(Icons.tag_rounded, job.jobNumber, theme),
                  ],
                  const SizedBox(height: 10),
                  _row(Icons.handyman_rounded, job.technicianName, theme),
                  if (job.technicianArea != null &&
                      job.technicianArea!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _row(Icons.location_on_outlined, job.technicianArea!, theme),
                  ],
                  if (job.startedAt != null) ...[
                    const SizedBox(height: 8),
                    _row(
                      Icons.play_circle_outline_rounded,
                      '${l10n.startedOn} ${_formatDate(job.startedAt)}',
                      theme,
                    ),
                  ],
                  if (job.isCompleted) ...[
                    const SizedBox(height: 8),
                    _row(
                      Icons.check_circle_outline_rounded,
                      '${l10n.completedOnLabel} ${_formatDate(job.completedAt)}',
                      theme,
                    ),
                  ],
                ],
              ),
            ),

            // ── Description ──────────────────────────────────────────
            const SizedBox(height: 14),
            _card(
              theme: theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.descriptionLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.description.isEmpty ? '—' : job.description,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),

            // ── Ticket ───────────────────────────────────────────────
            if (ticket != null) ...[
              const SizedBox(height: 14),
              _card(
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.ticketLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        _pill(ticket.statusLabel, ticket.statusColor),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (ticket.ticketNumber.isNotEmpty) ...[
                      _row(Icons.confirmation_number_outlined,
                          ticket.ticketNumber, theme),
                      const SizedBox(height: 8),
                    ],
                    _row(Icons.handyman_rounded,
                        ticket.technicianName ?? job.technicianName, theme),
                    const SizedBox(height: 8),
                    _row(
                      Icons.schedule_rounded,
                      '${l10n.createdOn} ${_formatDateTime(ticket.createdAt)}',
                      theme,
                    ),
                    if (ticket.isCompleted) ...[
                      const SizedBox(height: 8),
                      _row(
                        Icons.check_circle_outline_rounded,
                        '${l10n.completedOnLabel} ${_formatDateTime(ticket.completedAt)}',
                        theme,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── Review (only for completed jobs) ─────────────────────
            if (job.isCompleted) ...[
              const SizedBox(height: 14),
              _card(
                theme: theme,
                child: job.review != null
                    ? JobReviewCard(review: job.review!)
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your review',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How was the job? Rate ${job.technicianName} and leave a remark.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Actions: in progress ─────────────────────────────────
            if (job.isOnProgress) ...[
              // Pay button is faded + disabled for now (payments come later).
              // TODO(payments): enable with
              //   onPressed: () => PaymentChannelModal.show(context, job),
              // and switch the style back to _btnStyle(AppTheme.primary).
              ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.payment_rounded),
                label: Text(l10n.payForJob),
                style: _btnStyle(AppTheme.primary).copyWith(
                  backgroundColor: WidgetStatePropertyAll(
                    AppTheme.primary.withValues(alpha: 0.30),
                  ),
                  foregroundColor: const WidgetStatePropertyAll(Colors.white70),
                  iconColor: const WidgetStatePropertyAll(Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _sendingCode ? null : () => _markComplete(job),
                icon: _sendingCode
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.verified_user_rounded),
                label: Text(
                    _sendingCode ? l10n.sendingSmsCode : l10n.confirmCompletion),
                style: _btnStyle(AppTheme.success),
              ),
              const SizedBox(height: 10),
            ],

            // ── Action: completed, not reviewed yet ──────────────────
            if (job.canReview) ...[
              ElevatedButton.icon(
                onPressed: () => _openReview(job),
                icon: const Icon(Icons.star_rounded),
                label: const Text('Rate this job'),
                style: _btnStyle(Colors.amber.shade700),
              ),
              const SizedBox(height: 10),
            ],

            // ── Chat ─────────────────────────────────────────────────
            if (job.technicianUserId != 0)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.chatScreen,
                      arguments: job.technicianUserId);
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text(l10n.chat),
                style: _btnStyle(AppTheme.accent),
              ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _btnStyle(Color bg) => ElevatedButton.styleFrom(
    backgroundColor: bg,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  Widget _card({required Widget child, required ThemeData theme}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );

  Widget _row(IconData icon, String text, ThemeData theme) => Row(
    children: [
      Icon(icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    ],
  );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}