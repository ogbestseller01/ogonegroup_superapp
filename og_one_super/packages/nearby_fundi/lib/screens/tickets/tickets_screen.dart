import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/job.dart';
import '../../providers/job_provider.dart';
import '../../widgets/status_ticker.dart';

String _formatDateTime(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year} '
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

  Future<void> _printOrDownloadPdf(Job job, AppLocalizations l10n) async {
    final t = job.ticket!;
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NEARBYFUNDI TICKET',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(t.ticketNumber,
                        style: const pw.TextStyle(
                            fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
                pw.Divider(height: 30),
                pw.Text(t.title,
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Status: ${Job.statusLabelFor(t.status)}',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                if (t.description != null && t.description!.isNotEmpty) ...[
                  pw.SizedBox(height: 15),
                  pw.Text('Description:',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.SizedBox(height: 5),
                  pw.Text(t.description!,
                      style: const pw.TextStyle(
                          fontSize: 13, color: PdfColors.grey800)),
                ],
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                    '${l10n.fundiLabel}: ${t.technicianName ?? job.technicianName}'),
                pw.SizedBox(height: 5),
                pw.Text('Job Number: ${job.jobNumber}'),
                pw.SizedBox(height: 5),
                pw.Text('${l10n.createdOn}: ${_formatDateTime(t.createdAt)}'),
                if (t.isCompleted) ...[
                  pw.SizedBox(height: 5),
                  pw.Text(
                      '${l10n.completedOn}: ${_formatDateTime(t.completedAt)}'),
                ],
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ticket_${t.ticketNumber.isNotEmpty ? t.ticketNumber : job.jobNumber}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hPad = MediaQuery.of(context).size.width > 600 ? 28.0 : 16.0;
    final items = provider.jobsWithTicket;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
              child: Text(l10n.noTicketsYet,
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(l10n.noTicketsHint,
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
          itemBuilder: (_, i) =>
              _ticketCard(items[i], l10n, theme),
        ),
      ),
    );
  }

  Widget _ticketCard(Job job, AppLocalizations l10n, ThemeData theme) {
    final t = job.ticket!;
    final color = Job.statusColorFor(t.status);
    final fundi = t.technicianName ?? job.technicianName;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
                        style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface)),
                    if (t.ticketNumber.isNotEmpty)
                      Text(t.ticketNumber,
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusTicker(
                    label: Job.statusLabelFor(t.status),
                    color: color,
                    live: !t.isCompleted,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 28,
                    child: TextButton.icon(
                      onPressed: () => _printOrDownloadPdf(job, l10n),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(Icons.print_rounded,
                          size: 14, color: theme.colorScheme.primary),
                      label: Text(
                        'PDF',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (t.description != null && t.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(t.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13.5,
                      color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      height: 1.4)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.handyman_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${l10n.fundiLabel}: $fundi\n${job.jobNumber}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 5),
              Text('${l10n.createdOn} ${_formatDateTime(t.createdAt)}',
                  style: TextStyle(
                      fontSize: 12.5,
                      color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
          if (t.isCompleted) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 14, color: AppTheme.success),
                const SizedBox(width: 5),
                Text('${l10n.completedOn} ${_formatDateTime(t.completedAt)}',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}