// lib/screens/jobs/job_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../providers/job_provider.dart';
import '../payments/payment_channel_modal.dart';
import 'confirm_completion_modal.dart';           // <-- Ensure this is present
import 'confirm_completion_prompt_modal.dart';    // <-- Ensure this file physically exists

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
      await context.read<JobProvider>().ensureJob(widget.jobId);
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

    // Step 1: Show prompt dialog to ask user whether to send or cancel
    final shouldSend = await ConfirmCompletionPromptModal.show(context);
    if (shouldSend != true || !mounted) return;

    final provider = context.read<JobProvider>();
    setState(() => _sendingCode = true);

    // Step 2: Request SMS Code Dispatch via backend
    final sent = await provider.requestCompletion(job.id);
    if (!mounted) return;

    if (!sent) {
      setState(() => _sendingCode = false);
      _snack(provider.error ?? 'Could not send verification code via SMS.', error: true);
      return;
    }

    setState(() => _sendingCode = false);

    // Step 3: Open the 6-digit OTP input modal bottom sheet
    final done = await ConfirmCompletionModal.show(context, job.id);

    if (done == true && mounted) {
      _snack('Job completed successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<JobProvider>();
    final job = provider.getJobById(widget.jobId);

    if (job == null) {
      final waiting = !_fetched || provider.isLoading;
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
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
              const Text('Job not found'),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: _retry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final ticket = job.ticket;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
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
        onRefresh: provider.loadJobs,
        color: AppTheme.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.serviceName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      _pill(job.statusLabel, job.statusColor),
                    ],
                  ),
                  if (job.jobNumber.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _row(Icons.tag_rounded, job.jobNumber),
                  ],
                  const SizedBox(height: 10),
                  _row(Icons.handyman_rounded, job.technicianName),
                  if (job.technicianArea != null &&
                      job.technicianArea!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _row(Icons.location_on_outlined, job.technicianArea!),
                  ],
                  const SizedBox(height: 8),
                  _row(Icons.play_circle_outline_rounded,
                      'Started ${_formatDate(job.startedAt)}'),
                  if (job.isCompleted) ...[
                    const SizedBox(height: 8),
                    _row(Icons.check_circle_outline_rounded,
                        'Completed ${_formatDate(job.completedAt)}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.description.isEmpty ? '—' : job.description,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            if (ticket != null) ...[
              const SizedBox(height: 14),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Ticket',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        _pill(ticket.statusLabel, ticket.statusColor),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (ticket.ticketNumber.isNotEmpty) ...[
                      _row(Icons.confirmation_number_outlined,
                          ticket.ticketNumber),
                      const SizedBox(height: 8),
                    ],
                    _row(Icons.handyman_rounded,
                        ticket.technicianName ?? job.technicianName),
                    const SizedBox(height: 8),
                    _row(Icons.schedule_rounded,
                        'Created ${_formatDateTime(ticket.createdAt)}'),
                    if (ticket.isCompleted) ...[
                      const SizedBox(height: 8),
                      _row(Icons.check_circle_outline_rounded,
                          'Completed ${_formatDateTime(ticket.completedAt)}'),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Visible ONLY while the job is ON PROGRESS
            if (job.isOnProgress) ...[
              ElevatedButton.icon(
                onPressed: () => PaymentChannelModal.show(context, job),
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Pay for Job'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                label: Text(_sendingCode ? 'Sending SMS Code…' : 'Confirm Completion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (job.technicianUserId != 0)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.chatScreen,
                    arguments: job.technicianUserId,
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text(l10n.chat),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );

  Widget _row(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey.shade600),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontSize: 13.5, color: Colors.grey.shade800),
        ),
      ),
    ],
  );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.35)),
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