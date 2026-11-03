// lib/payments/provider/payment_provider.dart

import 'package:flutter/foundation.dart';
import '../chanel/payment_channel.dart';
import '../model/payment_models.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider({required PaymentChannel channel}) : _channel = channel;

  final PaymentChannel _channel;

  PaymentStatus _status = PaymentStatus.idle;
  String? _lastTransactionId;
  String? _error;
  PaymentTier? _selectedTier;

  // ─── THE WALLET (Track how many requests they can unlock) ───
  int _availableRequestsBalance = 0; // 0 means they MUST pay to accept new ones

  int get availableRequestsBalance => _availableRequestsBalance;
  bool get hasBalance => _availableRequestsBalance > 0;

  PaymentStatus get status => _status;
  String? get lastTransactionId => _lastTransactionId;
  String? get error => _error;
  PaymentTier? get selectedTier => _selectedTier;
  bool get isBusy => _status == PaymentStatus.processing;
  bool get isSuccess => _status == PaymentStatus.success;
  String get channelName => _channel.name;

  // If you later fetch this from the backend, update it here
  void setBalance(int amount) {
    _availableRequestsBalance = amount;
    notifyListeners();
  }

  // Deduct 1 when fundi accepts a request
  void consumeOneRequest() {
    if (_availableRequestsBalance > 0) {
      _availableRequestsBalance--;
      notifyListeners();
    }
  }

  static const Map<PaymentTier, PaymentPlan> _catalog = {
    PaymentTier.single: PaymentPlan(tier: PaymentTier.single, requests: 1, amount: 5000, currency: 'TZS', label: '1 Request'),
    PaymentTier.bundle3: PaymentPlan(tier: PaymentTier.bundle3, requests: 3, amount: 13500, currency: 'TZS', label: '3 Requests'),
    PaymentTier.bundle5: PaymentPlan(tier: PaymentTier.bundle5, requests: 5, amount: 20000, currency: 'TZS', label: '5 Requests'),
  };

  List<PaymentPlan> get plans => _catalog.values.toList();
  PaymentPlan planFor(PaymentTier tier) => _catalog[tier] ?? _catalog[PaymentTier.single]!;
  PaymentPlan planForRequestCount(int n) => _catalog[PaymentTier.fromRequests(n)]!;

  void selectTier(PaymentTier? tier) {
    if (_selectedTier == tier) return;
    _selectedTier = tier;
    _error = null;
    notifyListeners();
  }

  void autoSelectForRequestCount(int n) {
    selectTier(PaymentTier.fromRequests(n));
  }

  Future<bool> payForRequests({
    required int requestsCount,
    required String reference,
    String? customerPhone,
    PaymentTier? tier,
  }) async {
    if (_status == PaymentStatus.processing) return false;

    _status = PaymentStatus.processing;
    _error = null;
    notifyListeners();

    final chosenTier = tier ?? _selectedTier ?? PaymentTier.fromRequests(requestsCount);
    final plan = planFor(chosenTier);

    try {
      final result = await _channel.pay(
        reference: reference,
        plan: plan,
        customerPhone: customerPhone,
      );

      if (result.success) {
        _status = PaymentStatus.success;
        _lastTransactionId = result.transactionId;

        // ADD THE BOUGHT REQUESTS TO THE WALLET
        _availableRequestsBalance += plan.requests;

        notifyListeners();
        return true;
      } else {
        _status = PaymentStatus.failed;
        _error = result.message ?? 'Payment failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = PaymentStatus.failed;
      _error = 'Payment error: $e';
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _status = PaymentStatus.idle;
    _lastTransactionId = null;
    _error = null;
    notifyListeners();
  }
}