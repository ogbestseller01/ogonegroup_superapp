import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice.dart';
import '../models/payment_method.dart';
import '../models/rate_card.dart';
import '../models/subscription.dart';
import '../services/api_service.dart';
import '../services/invoice_pdf_service.dart';
import 'auth_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<RateCard> _rateCards = [];
  List<PaymentMethod> _paymentMethods = [];
  List<Subscription> _subscriptions = [];
  List<Invoice> _invoices = [];
  List<DownloadedInvoice> _downloadedInvoices = [];
  Subscription? _currentSubscription;

  bool _isLoading = false;
  bool _hasActiveSubscription = false;
  DateTime? _expiryDate;
  String _subscriptionStatus = 'inactive';
  String? _error;
  String? _downloadProgress;

  // ============================================================
  // GETTERS
  // ============================================================
  List<RateCard> get rateCards => _rateCards;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  List<Subscription> get subscriptions => _subscriptions;
  List<Invoice> get invoices => _invoices;
  List<DownloadedInvoice> get downloadedInvoices => _downloadedInvoices;
  Subscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;

  /// ✅ FIXED: Always prioritizes the active subscription list over the cached status.
  bool get hasActiveSubscription {
    // 1. PRIMARY SOURCE OF TRUTH: Check the actual subscription list.
    try {
      final activeSub = _subscriptions.firstWhere((s) => s.isActive);
      return true;
    } catch (_) {
      // No active subscription found in the list.
    }

    // 2. SECONDARY: Fallback to the parsed status/expiry date.
    if (_subscriptionStatus == 'active') {
      if (_expiryDate == null) return true;
      return _expiryDate!.isAfter(DateTime.now());
    }
    return _hasActiveSubscription;
  }

  DateTime? get expiryDate => _expiryDate;
  String get subscriptionStatus => _subscriptionStatus;
  String? get error => _error;
  String? get downloadProgress => _downloadProgress;

  bool get isLocked => !hasActiveSubscription && _subscriptionStatus == 'expired';
  bool get isPending => _subscriptionStatus == 'pending' ||
      _subscriptions.any((s) => s.status == 'pending');

  int? get daysRemaining {
    if (_expiryDate == null) return null;
    final diff = _expiryDate!.difference(DateTime.now());
    return diff.isNegative ? 0 : diff.inDays;
  }

  List<PaymentMethod> get activePaymentMethods {
    return _paymentMethods.where((m) => m.isActive).toList();
  }

  // ============================================================
  // LOAD PAYMENT METHODS
  // ============================================================
  Future<void> loadPaymentMethods() async {
    _setLoading(true);
    _error = null;
    try {
      debugPrint('🔄 Loading payment methods...');
      final response = await _api.getPaymentMethods();

      if (response.success && response.data != null) {
        final data = response.data;
        List<dynamic> rawData = [];

        if (data is List) {
          rawData = data;
        } else if (data is Map && data['data'] is List) {
          rawData = data['data'] as List;
        } else if (data is Map && data['data'] is Map && data['data']['data'] is List) {
          rawData = data['data']['data'] as List;
        }

        _paymentMethods = rawData.map((e) => PaymentMethod.fromJson(e)).toList();
        _error = null;
      } else {
        _error = response.message;
        _paymentMethods = [];
      }
    } catch (e) {
      _error = 'Failed to load payment methods: $e';
      _paymentMethods = [];
    }
    _setLoading(false);
  }

  // ============================================================
  // LOAD RATE CARDS
  // ============================================================
  Future<void> loadRateCards() async {
    _setLoading(true);
    try {
      final response = await _api.getRateCards();
      if (response.success && response.data != null) {
        _rateCards = _extractList(response.data)
            .map((e) => RateCard.fromJson(e))
            .toList();
        _error = null;
      } else {
        _error = response.message;
        _rateCards = [];
      }
    } catch (e) {
      _error = 'Failed to load rate cards: $e';
      _rateCards = [];
    }
    _setLoading(false);
  }

  // ============================================================
  // CREATE SUBSCRIPTION
  // ============================================================
  Future<ApiResponse> createSubscription({
    required int rateCardId,
    required int paymentMethodId,
    File? paymentProof,
    String? paymentReference,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      final response = await _api.createSubscription(
        rateCardId: rateCardId,
        paymentMethodId: paymentMethodId,
        paymentProof: paymentProof,
        paymentReference: paymentReference,
        notes: notes,
      );
      if (response.success) {
        await loadMySubscriptions();
        await checkSubscriptionStatus();
        _error = null;
      } else {
        _error = response.message;
      }
      _setLoading(false);
      return response;
    } catch (e) {
      _error = 'Failed to create subscription: $e';
      _setLoading(false);
      return ApiResponse(
        success: false,
        message: 'Failed to create subscription: $e',
      );
    }
  }

  // ============================================================
  // LOAD MY SUBSCRIPTIONS
  // ============================================================
  Future<void> loadMySubscriptions() async {
    _setLoading(true);
    try {
      final response = await _api.getMySubscriptions();
      print('📦 Subscriptions API Response: ${response.data}');

      if (response.success && response.data != null) {
        final data = response.data;

        if (data is Map) {
          if (data['subscriptions'] is List) {
            _subscriptions = (data['subscriptions'] as List)
                .map((e) => Subscription.fromJson(e))
                .toList();
          } else {
            _subscriptions = [];
          }

          if (data['current_status'] is Map) {
            final status = data['current_status'];
            _hasActiveSubscription = status['has_active'] ?? false;
            _subscriptionStatus = status['status'] ?? 'inactive';
            _expiryDate = status['expires_at'] != null
                ? DateTime.parse(status['expires_at'])
                : null;

            if (_subscriptionStatus == 'active' && _expiryDate != null) {
              _hasActiveSubscription = _expiryDate!.isAfter(DateTime.now());
              if (!_hasActiveSubscription) {
                _subscriptionStatus = 'expired';
              }
            }
          }

          // ✅ Fallback: Ensure if the list has an active sub, we mark it.
          if (!_hasActiveSubscription) {
            try {
              final activeSub = _subscriptions.firstWhere((s) => s.isActive);
              _hasActiveSubscription = true;
              _subscriptionStatus = 'active';
              _expiryDate = activeSub.expiryDate;
            } catch (e) {
              // No active subscription found.
            }
          }
        } else if (data is List) {
          _subscriptions = data.map((e) => Subscription.fromJson(e)).toList();
        } else {
          _subscriptions = [];
        }
        _error = null;
        notifyListeners();
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load subscriptions: $e';
      print('❌ Subscription error: $e');
    }
    _setLoading(false);
  }

  // ============================================================
  // LOAD MY INVOICES
  // ============================================================
  Future<void> loadMyInvoices() async {
    _setLoading(true);
    try {
      final response = await _api.getMyInvoices();
      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map && data['invoices'] is List) {
          _invoices = (data['invoices'] as List)
              .map((e) => Invoice.fromJson(e))
              .toList();
        } else if (data is List) {
          _invoices = data.map((e) => Invoice.fromJson(e)).toList();
        } else {
          _invoices = [];
        }
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load invoices: $e';
    }
    _setLoading(false);
  }

  // ============================================================
  // CHECK SUBSCRIPTION STATUS
  // ============================================================
  Future<void> checkSubscriptionStatus() async {
    try {
      final response = await _api.checkSubscriptionStatus();
      print('📦 Status API Response: ${response.data}');

      if (response.success && response.data != null) {
        final data = response.data;
        _subscriptionStatus = data['subscription_status'] ?? 'inactive';
        _expiryDate = data['expires_at'] != null
            ? DateTime.parse(data['expires_at'])
            : null;
        _hasActiveSubscription = data['has_active_subscription'] ?? false;

        if (_subscriptionStatus == 'active' && _expiryDate != null) {
          _hasActiveSubscription = _expiryDate!.isAfter(DateTime.now());
          if (!_hasActiveSubscription) {
            _subscriptionStatus = 'expired';
          }
        }

        print('✅ Status: $_subscriptionStatus, Active: $_hasActiveSubscription');
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Status check error: $e');
    }
  }

  // ============================================================
  // DOWNLOAD INVOICE - Save to Downloads Folder
  // ============================================================
  Future<String?> downloadInvoice(int invoiceId) async {
    _downloadProgress = 'Starting download...';
    notifyListeners();

    try {
      final invoice = _invoices.firstWhere(
            (inv) => inv.id == invoiceId,
        orElse: () => throw Exception('Invoice not found'),
      );

      Directory? downloadsDir;
      if (Platform.isAndroid) {
        final docDir = await getApplicationDocumentsDirectory();
        downloadsDir = Directory('${docDir.path}/Downloads');
      } else if (Platform.isIOS) {
        final docDir = await getApplicationDocumentsDirectory();
        downloadsDir = Directory('${docDir.path}/Downloads');
      } else {
        final docDir = await getApplicationDocumentsDirectory();
        downloadsDir = Directory('${docDir.path}/Downloads');
      }

      if (downloadsDir == null) {
        throw Exception('Could not access downloads directory');
      }

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName = 'invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${downloadsDir.path}/$fileName';

      _downloadProgress = 'Downloading from server...';
      notifyListeners();

      final apiResult = await _api.downloadInvoice(invoiceId);
      if (apiResult != null) {
        final tempFile = File(apiResult);
        if (await tempFile.exists()) {
          final savedFile = await tempFile.copy(filePath);
          await tempFile.delete();
          await _addDownloadedInvoice(invoice, filePath);
          _downloadProgress = 'Download complete! ✅';
          notifyListeners();
          Future.delayed(const Duration(seconds: 2), () {
            _downloadProgress = null;
            notifyListeners();
          });
          return filePath;
        }
      }

      _downloadProgress = 'Generating PDF locally...';
      notifyListeners();

      final authProvider = ProviderRegistry.get<AuthProvider>();
      final user = authProvider.user;
      if (user == null) throw Exception('User not found');

      final pdfPath = await InvoicePdfService.generateInvoicePdf(invoice, user);

      if (pdfPath != null) {
        final tempFile = File(pdfPath);
        if (await tempFile.exists()) {
          final savedFile = await tempFile.copy(filePath);
          await tempFile.delete();
          await _addDownloadedInvoice(invoice, filePath);
          _downloadProgress = 'PDF generated successfully! ✅';
          notifyListeners();
          Future.delayed(const Duration(seconds: 2), () {
            _downloadProgress = null;
            notifyListeners();
          });
          return filePath;
        }
      }

      _downloadProgress = null;
      notifyListeners();
      return null;
    } catch (e) {
      _downloadProgress = null;
      debugPrint('❌ Download invoice error: $e');
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  // ✅ Add downloaded invoice to list
  // ============================================================
  Future<void> _addDownloadedInvoice(Invoice invoice, String filePath) async {
    String rateCardName = 'Subscription';

    if (invoice.rateCard != null) {
      rateCardName = invoice.rateCard!.name;
    } else {
      try {
        final sub = _subscriptions.firstWhere(
              (s) => s.invoice?.id == invoice.id,
          orElse: () => throw Exception('No matching subscription'),
        );
        if (sub.rateCard != null) {
          rateCardName = sub.rateCard!.name;
        }
      } catch (e) {
        // Keep fallback value
      }
    }

    final downloaded = DownloadedInvoice(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      amount: invoice.amount,
      filePath: filePath,
      downloadedAt: DateTime.now(),
      rateCardName: rateCardName,
      status: invoice.status,
    );

    final exists = _downloadedInvoices.any((d) => d.id == invoice.id);
    if (!exists) {
      _downloadedInvoices.add(downloaded);
      await _saveDownloadedInvoices();
      notifyListeners();
    }
  }

  // ============================================================
  // ✅ Save downloaded invoices to SharedPreferences
  // ============================================================
  Future<void> _saveDownloadedInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _downloadedInvoices.map((d) => d.toJson()).toList();
      await prefs.setString('downloaded_invoices', jsonEncode(list));
    } catch (e) {
      debugPrint('❌ Failed to save downloaded invoices: $e');
    }
  }

  // ============================================================
  // ✅ Load downloaded invoices from SharedPreferences
  // ============================================================
  Future<void> loadDownloadedInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('downloaded_invoices');
      if (data != null) {
        final list = jsonDecode(data) as List;
        _downloadedInvoices = list.map((e) => DownloadedInvoice.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Failed to load downloaded invoices: $e');
    }
  }

  // ============================================================
  // ✅ Delete downloaded invoice
  // ============================================================
  Future<void> deleteDownloadedInvoice(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      _downloadedInvoices.removeWhere((d) => d.filePath == filePath);
      await _saveDownloadedInvoices();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to delete invoice: $e');
    }
  }

  // ============================================================
  // ✅ Open downloaded invoice
  // ============================================================
  Future<bool> openDownloadedInvoice(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        final invoice = _downloadedInvoices.firstWhere(
              (d) => d.filePath == filePath,
          orElse: () => throw Exception('Invoice not found'),
        );
        if (invoice == null) return false;
        final newFile = File(invoice.filePath);
        if (!await newFile.exists()) {
          return false;
        }
      }
      final result = await OpenFile.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('❌ Error opening invoice: $e');
      return false;
    }
  }

  // ============================================================
  // DOWNLOAD AND OPEN INVOICE
  // ============================================================
  Future<bool> downloadAndOpenInvoice(int invoiceId) async {
    try {
      final pdfPath = await downloadInvoice(invoiceId);
      if (pdfPath == null) return false;
      final result = await OpenFile.open(pdfPath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('❌ Open invoice error: $e');
      return false;
    }
  }

  // ============================================================
  // SHARE INVOICE
  // ============================================================
  Future<bool> shareInvoice(int invoiceId) async {
    try {
      final pdfPath = await downloadInvoice(invoiceId);
      if (pdfPath == null) return false;
      final invoice = _invoices.firstWhere(
            (inv) => inv.id == invoiceId,
        orElse: () => throw Exception('Invoice not found'),
      );
      await Share.shareXFiles(
        [XFile(pdfPath)],
        text: 'Invoice #${invoice.invoiceNumber} from FundiApp',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Share invoice error: $e');
      return false;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Invoice? getInvoiceById(int id) {
    try {
      return _invoices.firstWhere((inv) => inv.id == id);
    } catch (e) {
      return null;
    }
  }

  Subscription? getSubscriptionById(int id) {
    try {
      return _subscriptions.firstWhere((sub) => sub.id == id);
    } catch (e) {
      return null;
    }
  }

  PaymentMethod? getPaymentMethodById(int id) {
    try {
      return _paymentMethods.firstWhere((method) => method.id == id);
    } catch (e) {
      return null;
    }
  }

  RateCard? getRateCardById(int id) {
    try {
      return _rateCards.firstWhere((card) => card.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      checkSubscriptionStatus(),
      loadMySubscriptions(),
      loadMyInvoices(),
      loadRateCards(),
      loadPaymentMethods(),
      loadDownloadedInvoices(),
    ]);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'];
    return [];
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearDownloadProgress() {
    _downloadProgress = null;
    notifyListeners();
  }
}

// ============================================================
// ✅ Downloaded Invoice Model
// ============================================================
class DownloadedInvoice {
  final int id;
  final String invoiceNumber;
  final String amount;
  final String filePath;
  final DateTime downloadedAt;
  final String rateCardName;
  final String status;

  DownloadedInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.amount,
    required this.filePath,
    required this.downloadedAt,
    required this.rateCardName,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoiceNumber': invoiceNumber,
    'amount': amount,
    'filePath': filePath,
    'downloadedAt': downloadedAt.toIso8601String(),
    'rateCardName': rateCardName,
    'status': status,
  };

  factory DownloadedInvoice.fromJson(Map<String, dynamic> json) => DownloadedInvoice(
    id: json['id'] ?? 0,
    invoiceNumber: json['invoiceNumber'] ?? '',
    amount: json['amount'] ?? '0 TZS',
    filePath: json['filePath'] ?? '',
    downloadedAt: DateTime.parse(json['downloadedAt'] ?? DateTime.now().toIso8601String()),
    rateCardName: json['rateCardName'] ?? 'Subscription',
    status: json['status'] ?? 'paid',
  );
}

class ProviderRegistry {
  static AuthProvider? _authProvider;
  static void registerAuthProvider(AuthProvider provider) {
    _authProvider = provider;
  }
  static AuthProvider get<AuthProvider>() {
    if (_authProvider == null) {
      throw Exception('AuthProvider not registered');
    }
    return _authProvider! as AuthProvider;
  }
}