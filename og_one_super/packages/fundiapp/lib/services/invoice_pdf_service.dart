// lib/services/invoice_pdf_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/invoice.dart';
import '../models/user.dart';
import '../models/rate_card.dart';
import '../config/app_theme.dart';

class InvoicePdfService {
  // Colors from AppTheme
  static PdfColor get _primaryColor => _toPdfColor(AppTheme.primary);
  static PdfColor get _secondaryColor => _toPdfColor(AppTheme.dark);
  static PdfColor get _accentColor => _toPdfColor(AppTheme.success);
  static PdfColor get _dangerColor => _toPdfColor(AppTheme.error);
  static PdfColor get _warningColor => _toPdfColor(AppTheme.warning);
  static PdfColor get _greyColor => _toPdfColor(AppTheme.greyText);
  static PdfColor get _lightBg => _toPdfColor(AppTheme.scaffoldLight);

  static PdfColor _toPdfColor(Color color) {
    return PdfColor(
      color.red / 255.0,
      color.green / 255.0,
      color.blue / 255.0,
      color.alpha / 255.0,
    );
  }

  static PdfColor _withOpacity(PdfColor color, double opacity) {
    return PdfColor(
      color.red,
      color.green,
      color.blue,
      opacity,
    );
  }

  static Future<String?> generateInvoicePdf(Invoice invoice, User user) async {
    try {
      final pdf = await _buildPdf(invoice, user);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/invoice_${invoice.invoiceNumber}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      print('✅ PDF Generated: $path');
      return path;
    } catch (e) {
      print('❌ PDF Generation Error: $e');
      return null;
    }
  }

  static Future<pw.Document> _buildPdf(Invoice invoice, User user) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildHeader(invoice, user),
            pw.SizedBox(height: 20),
            _buildInvoiceDetails(invoice),
            pw.SizedBox(height: 20),
            _buildBillTo(user),
            pw.SizedBox(height: 30),
            _buildItemsTable(invoice),
            pw.SizedBox(height: 20),
            _buildPaymentInfo(invoice),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(Invoice invoice, User user) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'FundiApp',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            pw.Text(
              'Professional Services Platform',
              style: pw.TextStyle(
                fontSize: 12,
                color: _greyColor,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: _secondaryColor,
              ),
            ),
            pw.Text(
              '#${invoice.invoiceNumber}',
              style: pw.TextStyle(
                fontSize: 14,
                color: _greyColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceDetails(Invoice invoice) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _lightBg,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Invoice Date',
                  '${invoice.createdAt.day}/${invoice.createdAt.month}/${invoice.createdAt.year}'),
              pw.SizedBox(height: 8),
              _buildDetailRow('Due Date',
                  invoice.dueDate != null
                      ? '${invoice.dueDate!.day}/${invoice.dueDate!.month}/${invoice.dueDate!.year}'
                      : 'N/A'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildDetailRow('Status', invoice.statusLabel.toUpperCase()),
              pw.SizedBox(height: 8),
              _buildStatusBadge(invoice.status),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBillTo(User user) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _withOpacity(_greyColor, 0.3)),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Bill To',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _secondaryColor,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            user.name,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            user.email,
            style: pw.TextStyle(
              fontSize: 12,
              color: _greyColor,
            ),
          ),
          if (user.phone != null)
            pw.Text(
              user.phone!,
              style: pw.TextStyle(
                fontSize: 12,
                color: _greyColor,
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice) {
    // ✅ Use safe access with defaults
    final items = invoice.items ?? [];
    final rateCard = invoice.rateCard;
    final currency = invoice.currency ?? 'TZS';

    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _withOpacity(_greyColor, 0.3)),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Order Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _secondaryColor,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _withOpacity(_greyColor, 0.2)),
              bottom: pw.BorderSide(color: _withOpacity(_greyColor, 0.3)),
            ),
            columnWidths: {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _lightBg),
                children: [
                  _buildTableHeader('Description'),
                  _buildTableHeader('Duration'),
                  _buildTableHeader('Amount', align: pw.TextAlign.right),
                ],
              ),
              if (items.isNotEmpty)
                ...items.map((item) => pw.TableRow(
                  children: [
                    _buildTableCell(item['description']?.toString() ?? ''),
                    _buildTableCell(item['duration']?.toString() ?? 'N/A'),
                    _buildTableCell(
                      '${item['amount']?.toString() ?? '0'} $currency',
                      align: pw.TextAlign.right,
                    ),
                  ],
                )),
              if (items.isEmpty && rateCard != null)
                pw.TableRow(
                  children: [
                    _buildTableCell(rateCard.name),
                    _buildTableCell('${rateCard.durationDays} days'),
                    _buildTableCell(
                      '${rateCard.price} $currency',
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
              // Total Row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _lightBg),
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Total',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.SizedBox(),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      invoice.amount,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                        color: _primaryColor,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentInfo(Invoice invoice) {
    final paymentDetails = invoice.paymentDetails;

    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _lightBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _withOpacity(_greyColor, 0.2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Payment Instructions',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _secondaryColor,
            ),
          ),
          pw.SizedBox(height: 8),
          if (paymentDetails != null) ...[
            _buildInfoRow('Payment Method',
                paymentDetails['payment_method']?.toString() ?? 'N/A'),
            _buildInfoRow('Phone Number',
                paymentDetails['phone_number']?.toString() ?? 'N/A'),
            if (paymentDetails['account_name'] != null)
              _buildInfoRow('Account Name',
                  paymentDetails['account_name']?.toString() ?? 'N/A'),
          ],
          pw.SizedBox(height: 8),
          pw.Text(
            'Please send the exact amount to the above number.',
            style: pw.TextStyle(
              fontSize: 10,
              color: _greyColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: pw.EdgeInsets.only(top: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _withOpacity(_greyColor, 0.3))),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _secondaryColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'This invoice was generated automatically. Please contact support if you have any questions.',
            style: pw.TextStyle(
              fontSize: 10,
              color: _greyColor,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'FundiApp © ${DateTime.now().year} - All rights reserved.',
            style: pw.TextStyle(
              fontSize: 9,
              color: _greyColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============ HELPER WIDGETS ============

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 12,
            color: _greyColor,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStatusBadge(String status) {
    PdfColor color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = _accentColor;
        break;
      case 'pending':
        color = _warningColor;
        break;
      case 'cancelled':
        color = _dangerColor;
        break;
      default:
        color = _greyColor;
    }

    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _withOpacity(color, 0.1),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Text(
        status.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 12,
            color: _greyColor,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }
}