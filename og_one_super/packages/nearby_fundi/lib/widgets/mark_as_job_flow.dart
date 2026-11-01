import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../models/request.dart';
import '../providers/job_provider.dart';
import '../providers/request_provider.dart';
import '../utils/home_tabs.dart';
import 'confirmation_dialog.dart';

/// "Mark as Job" flow:
///   1. confirm  →  2. progress dialog with % (backend creates Job + Ticket)
///   3. close dialog and jump to the Jobs tab.
Future<void> startMarkAsJobFlow(BuildContext context, ServiceRequest r) async {
  final confirmed = await showConfirmationDialog(
    context,
    'Mark as Job',
    'Start this work as a job with ${r.technicianName}? '
        'A job and a ticket will be created for you to follow.',
  );
  if (confirmed != true || !context.mounted) return;

  final jobs = context.read<JobProvider>();
  final requests = context.read<RequestProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final progress = ValueNotifier<double>(0);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: _ProgressDialog(progress: progress),
    ),
  );

  // Ease towards 90% while the server works, then jump to 100% on success.
  final ticker = Timer.periodic(const Duration(milliseconds: 120), (_) {
    if (progress.value < 0.9) {
      progress.value += (0.9 - progress.value) * 0.08 + 0.004;
    }
  });

  final job = await jobs.markAsJob(r.id);
  ticker.cancel();

  if (job != null) {
    progress.value = 1;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await requests.loadMyRequests();
  }

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop(); // close progress dialog

  if (job == null) {
    messenger.showSnackBar(
      SnackBar(content: Text(jobs.error ?? 'Could not create the job.')),
    );
    return;
  }

  homeTabRequest.value = HomeTabs.jobs;
}

class _ProgressDialog extends StatelessWidget {
  final ValueNotifier<double> progress;
  const _ProgressDialog({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        child: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (_, v, __) {
            final pct = (v * 100).clamp(0, 100).round();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.engineering_rounded,
                    size: 40, color: AppTheme.primary),
                const SizedBox(height: 14),
                const Text(
                  'Creating your job…',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 10,
                    color: AppTheme.primary,
                    backgroundColor: AppTheme.primary.withOpacity(0.12),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
