// lib/screens/payments/payment_channel_modal.dart
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../models/job.dart';

class PaymentChannelModal extends StatelessWidget {
  const PaymentChannelModal({super.key, required this.job});

  final Job job;

  static Future<void> show(BuildContext context, Job job) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentChannelModal(job: job),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final ticket = job.ticket;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Modal Header
            Row(
              children: [
                const Icon(Icons.payment_rounded, color: AppTheme.primary, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Payment Channel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Fetched Job & Technician Details Section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _detailRow(
                    Icons.handyman_rounded,
                    'Technician',
                    job.technicianName.isEmpty ? '—' : job.technicianName,
                  ),
                  const Divider(height: 16),
                  _detailRow(
                    Icons.build_outlined,
                    'Service',
                    job.serviceName.isEmpty ? '—' : job.serviceName,
                  ),
                  const Divider(height: 16),
                  _detailRow(
                    Icons.tag_rounded,
                    'Job Number',
                    job.jobNumber.isEmpty ? '—' : job.jobNumber,
                  ),
                  if (ticket != null && ticket.ticketNumber.isNotEmpty) ...[
                    const Divider(height: 16),
                    _detailRow(
                      Icons.confirmation_number_outlined,
                      'Ticket Number',
                      ticket.ticketNumber,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Integration Placeholder Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 44,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Payment Integration Coming Soon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'In-app mobile payment channels (Tigo Pesa, M-Pesa, Airtel Money) are currently under integration.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Payment Button
            FilledButton(
              onPressed: () {
                // TODO: Handle payment confirmation logic here
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Confirm To Payment',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}