// lib/payments/channel/payment_channel.dart

import '../model/payment_models.dart';

abstract class PaymentChannel {
  String get name;

  Future<PaymentResult> pay({
    required String reference,
    required PaymentPlan plan,
    String? customerPhone,
  });

  Future<PaymentResult> checkStatus(String transactionId) async {
    return const PaymentResult.fail('checkStatus not implemented');
  }
}