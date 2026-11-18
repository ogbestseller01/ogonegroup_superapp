// lib/payments/screens/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../chanel/mock_channel.dart';
import '../model/payment_models.dart';
import '../provider/payment_provider.dart';

class PaymentScreen extends StatelessWidget {
  final int? requestsCount;
  final String reference;
  final String? customerPhone;
  final void Function(String? transactionId)? onSuccess;

  const PaymentScreen({
    super.key,
    required this.reference,
    this.requestsCount,
    this.customerPhone,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    // ── BULLETPROOF PROVIDER WRAPPER ──
    try {
      context.read<PaymentProvider>();
      return _PaymentScreenBody(
        reference: reference,
        requestsCount: requestsCount,
        customerPhone: customerPhone,
        onSuccess: onSuccess,
      );
    } catch (_) {
      return ChangeNotifierProvider(
        create: (_) => PaymentProvider(channel: MockPaymentChannel()),
        child: _PaymentScreenBody(
          reference: reference,
          requestsCount: requestsCount,
          customerPhone: customerPhone,
          onSuccess: onSuccess,
        ),
      );
    }
  }
}

class _PaymentScreenBody extends StatefulWidget {
  final int? requestsCount;
  final String reference;
  final String? customerPhone;
  final void Function(String? transactionId)? onSuccess;

  const _PaymentScreenBody({
    required this.reference,
    this.requestsCount,
    this.customerPhone,
    this.onSuccess,
  });

  @override
  State<_PaymentScreenBody> createState() => _PaymentScreenBodyState();
}

class _PaymentScreenBodyState extends State<_PaymentScreenBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PaymentProvider>();
      provider.reset();
      if (widget.requestsCount != null) {
        provider.autoSelectForRequestCount(widget.requestsCount!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay for Requests'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Text(
              'via ${provider.channelName}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : theme.colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reference', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text(widget.reference, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  if (widget.requestsCount != null) ...[
                    const SizedBox(height: 10),
                    Text('Requests to cover: ${widget.requestsCount}', style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Choose a plan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...provider.plans.map((plan) {
              final selected = provider.selectedTier == plan.tier;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlanTile(
                  plan: plan,
                  selected: selected,
                  disabled: provider.isBusy,
                  onTap: () => provider.selectTier(plan.tier),
                ),
              );
            }),
            const SizedBox(height: 20),
            if (provider.isBusy)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else
              ElevatedButton.icon(
                onPressed: provider.selectedTier == null ? null : () => _onPay(context, provider),
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Pay Now'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            if (provider.error != null) ...[
              const SizedBox(height: 14),
              Text(provider.error!, style: const TextStyle(color: Colors.red)),
            ],
            if (provider.isSuccess) ...[
              const SizedBox(height: 14),
              const Text('Payment Successful!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _onPay(BuildContext context, PaymentProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await provider.payForRequests(
      requestsCount: widget.requestsCount ?? 1,
      reference: widget.reference,
      customerPhone: widget.customerPhone,
    );

    if (!context.mounted) return;

    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Paid successfully'), backgroundColor: Colors.green));
      widget.onSuccess?.call(provider.lastTransactionId);
      await Future.delayed(const Duration(milliseconds: 900));
      if (context.mounted) navigator.pop(true);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(provider.error ?? 'Payment failed'), backgroundColor: Colors.red));
    }
  }
}

class _PlanTile extends StatelessWidget {
  final PaymentPlan plan;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _PlanTile({required this.plan, required this.selected, required this.disabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: selected ? primary.withOpacity(0.08) : theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? primary : theme.dividerColor, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Radio<bool>(value: true, groupValue: selected, onChanged: disabled ? null : (_) => onTap(), activeColor: primary),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${plan.requests} request(s)', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Text('${plan.currency} ${plan.amount.toStringAsFixed(0)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}