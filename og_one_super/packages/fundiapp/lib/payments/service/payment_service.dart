// lib/payments/service/payment_service.dart

import 'package:flutter/foundation.dart';
import '../model/payment_models.dart';
import '../provider/payment_provider.dart';

class PaymentService {
  PaymentService(this._provider);
  final PaymentProvider _provider;

  PaymentPlan planForRequests(int n) => _provider.planForRequestCount(n);

  Future<bool> chargeForRequests({
    required int requestsCount,
    required String reference,
    String? customerPhone,
    PaymentTier? tier,
  }) async {
    final ok = await _provider.payForRequests(
      requestsCount: requestsCount,
      reference: reference,
      customerPhone: customerPhone,
      tier: tier,
    );

    if (ok) {
      debugPrint('💳 chargeForRequests OK ref=$reference tx=${_provider.lastTransactionId}');
    } else {
      debugPrint('❌ chargeForRequests FAILED ref=$reference err=${_provider.error}');
    }
    return ok;
  }
}