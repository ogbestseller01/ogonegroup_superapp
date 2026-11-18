// lib/models/invoice.dart

// FIXED: Changed from a broken package import to a local relative import.
// If rate_card.dart is in a different folder, adjust this path accordingly.
import 'rate_card.dart';

class Invoice {
  final int id;
  final String invoiceNumber;
  final String amount;
  final String status;
  final String statusLabel;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? pdfUrl;
  final RateCard? rateCard;
  final Map<String, dynamic>? paymentDetails;
  final String? notes;
  final DateTime createdAt;

  // ✅ ADDED: items and currency
  final List<Map<String, dynamic>>? items;
  final String? currency;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.amount,
    required this.status,
    required this.statusLabel,
    this.dueDate,
    this.paidAt,
    this.pdfUrl,
    this.rateCard,
    this.paymentDetails,
    this.notes,
    required this.createdAt,
    this.items,
    this.currency,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    // Safe parsing helpers
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    List<Map<String, dynamic>>? parseItems(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e as Map<String, dynamic>).toList();
      }
      return null;
    }

    return Invoice(
      id: parseInt(json['id']),
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      status: json['status']?.toString() ?? 'pending',
      statusLabel: json['status_label']?.toString() ?? 'Pending',
      dueDate: parseDateTime(json['due_date']),
      paidAt: parseDateTime(json['paid_at']),
      pdfUrl: json['pdf_url']?.toString(),
      rateCard: json['rate_card'] != null
          ? RateCard.fromJson(json['rate_card'] as Map<String, dynamic>)
          : null,
      paymentDetails: json['payment_details'] is Map
          ? json['payment_details'] as Map<String, dynamic>
          : null,
      notes: json['notes']?.toString(),
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      items: parseItems(json['items']),
      currency: json['currency']?.toString() ?? 'TZS',
    );
  }

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';
}