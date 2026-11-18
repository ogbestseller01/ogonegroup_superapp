// lib/payments/channel/mpesa_channel.dart

import 'package:fundiapp_sdk/payments/chanel/payment_channel.dart';

import '../model/payment_models.dart';

class MpesaPaymentChannel implements PaymentChannel {
  MpesaPaymentChannel({required this.baseUrl, required this.authToken});

  final String baseUrl;
  final String authToken;

  @override
  String get name => 'M-Pesa';

  @override
  Future<PaymentResult> pay({
    required String reference,
    required PaymentPlan plan,
    String? customerPhone,
  }) async {
    throw UnimplementedError('MpesaPaymentChannel.pay() not wired yet.');
  }

  @override
  Future<PaymentResult> checkStatus(String transactionId) async {
    throw UnimplementedError('MpesaPaymentChannel.checkStatus() not wired yet');
  }
}