// lib/payments/model/payment_models.dart

enum PaymentStatus { idle, processing, success, failed, cancelled }

enum PaymentTier {
  single(requests: 1, priceKey: 'tier_1'),
  bundle3(requests: 3, priceKey: 'tier_3'),
  bundle5(requests: 5, priceKey: 'tier_5');

  const PaymentTier({required this.requests, required this.priceKey});
  final int requests;
  final String priceKey;

  static PaymentTier fromRequests(int n) {
    if (n <= 0) return PaymentTier.single;
    if (n >= 5) return PaymentTier.bundle5;
    if (n >= 3) return PaymentTier.bundle3;
    return PaymentTier.single;
  }
}

class PaymentPlan {
  final PaymentTier tier;
  final int requests;
  final double amount;
  final String currency;
  final String label;

  const PaymentPlan({
    required this.tier,
    required this.requests,
    required this.amount,
    required this.currency,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
    'tier': tier.priceKey,
    'requests': requests,
    'amount': amount,
    'currency': currency,
    'label': label,
  };
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? message;

  const PaymentResult({required this.success, this.transactionId, this.message});

  const PaymentResult.ok(String id)
      : success = true, transactionId = id, message = null;

  const PaymentResult.fail(String msg)
      : success = false, transactionId = null, message = msg;
}