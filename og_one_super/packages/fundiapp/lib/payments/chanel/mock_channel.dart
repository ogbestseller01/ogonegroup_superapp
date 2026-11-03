// lib/payments/channel/mock_channel.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fundiapp_sdk/payments/chanel/payment_channel.dart';
import '../model/payment_models.dart';

class MockPaymentChannel implements PaymentChannel {
  MockPaymentChannel({
    this.simulatedDelay = const Duration(milliseconds: 1200),
    this.alwaysSucceed = true,
  });

  final Duration simulatedDelay;
  final bool alwaysSucceed;

  @override
  String get name => 'Mock';

  @override
  Future<PaymentResult> pay({
    required String reference,
    required PaymentPlan plan,
    String? customerPhone,
  }) async {
    debugPrint('💳 [MockChannel] pay(reference=$reference, plan=$plan)');
    await Future.delayed(simulatedDelay);

    if (!alwaysSucceed) {
      return const PaymentResult.fail('Mock channel configured to fail');
    }

    final txId = 'MOCK-${DateTime.now().millisecondsSinceEpoch}-$reference';
    return PaymentResult.ok(txId);
  }

  @override
  Future<PaymentResult> checkStatus(String transactionId) async {
    return PaymentResult.ok(transactionId);
  }
}