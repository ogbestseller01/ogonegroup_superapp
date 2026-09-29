import 'rate_card.dart';
import 'invoice.dart';

class Subscription {
  final int id;
  final int userId;
  final RateCard? rateCard;
  final String status;
  final String statusLabel;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final int? daysRemaining;
  final String amountPaid;
  final String currency;
  final String? paymentMethod;
  final String? paymentReference;
  final String? paymentProof;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? adminNotes;
  final DateTime createdAt;
  final Invoice? invoice;

  Subscription({
    required this.id,
    required this.userId,
    this.rateCard,
    required this.status,
    required this.statusLabel,
    this.startDate,
    this.expiryDate,
    this.daysRemaining,
    required this.amountPaid,
    required this.currency,
    this.paymentMethod,
    this.paymentReference,
    this.paymentProof,
    this.approvedAt,
    this.approvedBy,
    this.adminNotes,
    required this.createdAt,
    this.invoice,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      rateCard: json['rate_card'] != null ? RateCard.fromJson(json['rate_card']) : null,
      status: json['status'] ?? 'pending',
      statusLabel: json['status_label'] ?? 'Pending',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      daysRemaining: json['days_remaining'],
      amountPaid: json['amount_paid']?.toString() ?? '0',
      currency: json['currency'] ?? 'TZS',
      paymentMethod: json['payment_method'],
      paymentReference: json['payment_reference'],
      paymentProof: json['payment_proof'],
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      approvedBy: json['approved_by'],
      adminNotes: json['admin_notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      invoice: json['invoice'] != null ? Invoice.fromJson(json['invoice']) : null,
    );
  }

  // ✅ FIXED: Check both status AND expiry date
  bool get isPending => status == 'pending';

  bool get isActive => status == 'active' &&
      (expiryDate == null || expiryDate!.isAfter(DateTime.now()));

  bool get isExpired => status == 'expired' ||
      (status == 'active' && expiryDate != null && expiryDate!.isBefore(DateTime.now()));

  bool get isCancelled => status == 'cancelled';

  bool get isApproved => status == 'approved';

  String get statusMessage {
    if (isActive) return 'Active';
    if (isPending) return 'Pending Approval';
    if (isExpired) return 'Expired';
    if (isCancelled) return 'Cancelled';
    return statusLabel;
  }
}