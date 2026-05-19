import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class ReceiptData {
  final String receiptNumber;
  final DateTime date;
  final String customerName;
  final String customerPhone;
  final String serviceType;
  final String paymentMethod;
  final int amountPaid;
  final String? notes;

  const ReceiptData({
    required this.receiptNumber,
    required this.date,
    required this.customerName,
    required this.customerPhone,
    required this.serviceType,
    required this.paymentMethod,
    required this.amountPaid,
    this.notes,
  });
}

class ReceiptPdfGenerator {
  static Future<File> generate(ReceiptData data) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            children: [
              pw.Text('KEYSTONE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
              pw.Text('PAYMENT RECEIPT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
              pw.SizedBox(height: 4),
              pw.Text('#${data.receiptNumber}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                child: pw.Text('PAID', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green700, letterSpacing: 2)),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 12),
              _row('Date', DateFormatter.display(data.date)),
              _row('Customer', data.customerName),
              _row('Phone', data.customerPhone),
              _row('Service', data.serviceType.replaceAll('_', ' ').toUpperCase()),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              _row('Payment', data.paymentMethod.replaceAll('_', ' ').toUpperCase()),
              _row('Amount', CurrencyFormatter.formatShort(data.amountPaid), isBold: true),
              if (data.notes != null && data.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Text('Notes: ${data.notes}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
              ],
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Text('Thank you!', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
            ],
          ),
        ),
      ),
    );

    return await doc.save().then((bytes) async {
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/keystone_receipt_${data.receiptNumber}.pdf');
      await file.writeAsBytes(bytes);
      return file;
    });
  }

  static pw.Widget _row(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: PdfColors.grey900)),
        ],
      ),
    );
  }
}
