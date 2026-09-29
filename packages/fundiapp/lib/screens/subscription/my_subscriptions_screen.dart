import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../../config/app_theme.dart';
import '../../config/app_routes.dart';
import '../../providers/subscription_provider.dart';
import '../../models/subscription.dart';
import '../../models/invoice.dart';
import '../../widgets/custom_button.dart';
import '../../l10n/app_localizations.dart';

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SubscriptionProvider>();
      provider.loadMySubscriptions();
      provider.loadMyInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final provider = context.watch<SubscriptionProvider>();
    final isDownloading = provider.downloadProgress != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mySubscriptions),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              provider.loadMySubscriptions();
              provider.loadMyInvoices();
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await provider.loadMySubscriptions();
          await provider.loadMyInvoices();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(context, provider, l10n),
              const SizedBox(height: 24),

              if (provider.hasActiveSubscription)
                _buildActiveSubscription(context, provider, l10n),

              Text(
                l10n.subscriptionHistory,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (provider.subscriptions.isEmpty)
                _buildEmptyState(context, l10n)
              else
                ...provider.subscriptions.map(
                      (sub) => _buildSubscriptionItem(context, sub, provider, l10n),
                ),

              const SizedBox(height: 32),

              if (provider.isLocked || provider.isPending)
                CustomButton(
                  text: l10n.subscribeNow,
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.rateCards),
                ),

              if (isDownloading)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.downloadProgress ?? 'Downloading...',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================
  Widget _buildStatusCard(BuildContext context, SubscriptionProvider provider, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isActive = provider.hasActiveSubscription;
    final daysLeft = provider.daysRemaining;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isActive) {
      statusColor = Colors.green;
      statusText = l10n.subscriptionActive;
      statusIcon = Icons.check_circle_rounded;
    } else if (provider.isPending) {
      statusColor = Colors.orange;
      statusText = l10n.subscriptionPending;
      statusIcon = Icons.hourglass_top_rounded;
    } else if (provider.isLocked) {
      statusColor = Colors.red;
      statusText = l10n.subscriptionExpired;
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = Colors.grey;
      statusText = l10n.subscriptionInactive;
      statusIcon = Icons.remove_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.subscriptionStatus, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                Text(statusText, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: statusColor)),
                if (isActive && daysLeft != null)
                  Text(l10n.daysRemaining(daysLeft), style: theme.textTheme.bodyMedium?.copyWith(
                    color: daysLeft < 7 ? Colors.orange : Colors.green,
                  )),
                if (provider.expiryDate != null && isActive)
                  Text(l10n.expiresOn(provider.expiryDate!), style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVE SUBSCRIPTION
  // ============================================================
  Widget _buildActiveSubscription(BuildContext context, SubscriptionProvider provider, AppLocalizations l10n) {
    final theme = Theme.of(context);

    Subscription? activeSub;
    try {
      activeSub = provider.subscriptions.firstWhere((s) => s.isActive);
    } catch (e) {
      return const SizedBox.shrink();
    }

    if (activeSub == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: Colors.green),
              const SizedBox(width: 8),
              Text(l10n.activePlan, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Text(activeSub.rateCard?.name ?? 'Unknown Plan', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(activeSub.rateCard?.formattedPrice ?? '', style: theme.textTheme.titleMedium?.copyWith(color: theme.primaryColor)),
          if (activeSub.startDate != null)
            Row(
              children: [
                Icon(Icons.play_circle_outline, size: 14, color: theme.hintColor),
                const SizedBox(width: 4),
                Text(
                  'Started: ${_formatDate(activeSub.startDate!)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          if (activeSub.expiryDate != null)
            Row(
              children: [
                Icon(Icons.event, size: 14, color: theme.hintColor),
                const SizedBox(width: 4),
                Text(
                  l10n.validUntil(activeSub.expiryDate!),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBSCRIPTION ITEM (now has "View Invoices" action)
  // ============================================================
  Widget _buildSubscriptionItem(
      BuildContext context,
      Subscription sub,
      SubscriptionProvider provider,
      AppLocalizations l10n,
      ) {
    final theme = Theme.of(context);
    final isActive = sub.isActive;
    final isExpired = sub.isExpired;

    Color statusColor;
    String statusText;

    if (isActive) {
      statusColor = Colors.green;
      statusText = l10n.subscriptionActive;
    } else if (sub.isPending) {
      statusColor = Colors.orange;
      statusText = l10n.subscriptionPending;
    } else if (isExpired) {
      statusColor = Colors.red;
      statusText = l10n.subscriptionExpired;
    } else if (sub.isCancelled) {
      statusColor = Colors.grey;
      statusText = l10n.cancelled;
    } else {
      statusColor = Colors.grey;
      statusText = sub.statusLabel;
    }

    // Count invoices belonging to this subscription (safe lookup)
    final invoiceCount = _invoicesForSubscription(provider, sub).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(isActive ? Icons.check_circle : Icons.history, color: statusColor, size: 24),
            ),
            title: Text(sub.rateCard?.name ?? 'Subscription', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l10n.amountPaid}: ${sub.amountPaid}'),
                if (sub.startDate != null)
                  Text('Created: ${_formatDate(sub.startDate!)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                if (sub.expiryDate != null)
                  Text(l10n.expiresOn(sub.expiryDate!), style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(statusText, style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
            ),
            isThreeLine: true,
          ),
          // Certificate/Approval Details (if approved)
          if (sub.approvedAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.blue.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Approved on ${_formatDate(sub.approvedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // View Invoices button (per subscription)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showInvoicesModal(context, provider, sub, l10n),
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: Text(
                  invoiceCount > 0 ? '${l10n.invoices} ($invoiceCount)' : l10n.invoices,
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INVOICES MODAL (bottom sheet) — shows invoices for ONE subscription
  // ============================================================
  void _showInvoicesModal(
      BuildContext context,
      SubscriptionProvider provider,
      Subscription sub,
      AppLocalizations l10n,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                final invoices = _invoicesForSubscription(provider, sub);
                final theme = Theme.of(context);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${l10n.invoices} · ${sub.rateCard?.name ?? 'Subscription'}',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: invoices.isEmpty
                            ? Center(
                          child: Text(
                            l10n.noInvoices,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                          ),
                        )
                            : ListView.builder(
                          controller: scrollController,
                          itemCount: invoices.length,
                          itemBuilder: (context, index) {
                            return _buildInvoiceItem(context, invoices[index], provider, l10n);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Helper: get invoices belonging to [sub]
  // ============================================================
  List<Invoice> _invoicesForSubscription(SubscriptionProvider provider, Subscription sub) {
    final linkedId = sub.invoice?.id;
    if (linkedId == null) return [];
    return provider.invoices.where((invoice) => invoice.id == linkedId).toList();
  }

  // ============================================================
  // INVOICE ITEM (used inside the per-subscription modal)
  // ============================================================
  Widget _buildInvoiceItem(BuildContext context, Invoice invoice, SubscriptionProvider provider, AppLocalizations l10n) {
    final theme = Theme.of(context);

    final bool isPaid = invoice.isPaid;
    final bool hasPdf = invoice.pdfUrl != null && invoice.pdfUrl!.isNotEmpty;
    final bool isPending = invoice.isPending;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPaid ? Colors.green.withOpacity(0.15) : isPending ? Colors.orange.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPaid ? Icons.paid_rounded : isPending ? Icons.pending_rounded : Icons.cancel_rounded,
                color: isPaid ? Colors.green : isPending ? Colors.orange : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice #${invoice.invoiceNumber}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text('${l10n.amountPaid}: ${invoice.amount}'),
                  Text(
                    'Created: ${_formatDate(invoice.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                  if (invoice.paidAt != null && isPaid)
                    Text(
                      'Paid: ${_formatDate(invoice.paidAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                    ),
                  if (invoice.dueDate != null && !isPaid)
                    Text(
                      'Due: ${_formatDate(invoice.dueDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.withOpacity(0.15) : isPending ? Colors.orange.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid ? l10n.paid : isPending ? l10n.pending : 'Cancelled',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isPaid ? Colors.green : isPending ? Colors.orange : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    hasPdf ? Icons.download_rounded : Icons.file_download_outlined,
                    color: hasPdf ? theme.primaryColor : Colors.grey,
                    size: 20,
                  ),
                  enabled: hasPdf,
                  onSelected: (value) {
                    switch (value) {
                      case 'download': _downloadInvoice(context, invoice, provider); break;
                      case 'share': _shareInvoice(context, invoice, provider); break;
                      case 'open': _openInvoice(context, invoice, provider); break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'download', child: Row(children: [Icon(Icons.download_rounded, color: Colors.blue), SizedBox(width: 12), Text('Download PDF')])),
                    PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_rounded, color: Colors.green), SizedBox(width: 12), Text('Share PDF')])),
                    PopupMenuItem(value: 'open', child: Row(children: [Icon(Icons.visibility_rounded, color: Colors.purple), SizedBox(width: 12), Text('Open PDF')])),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INVOICE ACTIONS
  // ============================================================
  Future<void> _downloadInvoice(BuildContext context, Invoice invoice, SubscriptionProvider provider) async {
    try {
      final result = await provider.downloadInvoice(invoice.id);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text('Invoice downloaded successfully!'))
            ]),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareInvoice(BuildContext context, Invoice invoice, SubscriptionProvider provider) async {
    try {
      await provider.shareInvoice(invoice.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openInvoice(BuildContext context, Invoice invoice, SubscriptionProvider provider) async {
    try {
      final pdfPath = await provider.downloadInvoice(invoice.id);
      if (pdfPath != null) {
        await OpenFile.open(pdfPath);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    try {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  // ============================================================
  // EMPTY STATES
  // ============================================================
  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.subscriptions_outlined, size: 48, color: theme.hintColor),
            const SizedBox(height: 8),
            Text(l10n.noSubscriptions, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          ],
        ),
      ),
    );
  }
}