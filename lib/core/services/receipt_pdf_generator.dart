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
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('KEYSTONE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
            pw.SizedBox(height: 2),
            pw.Text('P A Y M E N T   R E C E I P T', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.w500, color: PdfColors.grey500, letterSpacing: 2)),
            pw.SizedBox(height: 4),
            pw.Text('#${data.receiptNumber}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.green700, width: 0.5),
              ),
              child: pw.Text('PAID', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green700, letterSpacing: 3)),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 0.5, color: PdfColors.grey200),
            pw.SizedBox(height: 14),
            _row('Date', DateFormatter.display(data.date)),
            _row('Customer', data.customerName),
            _row('Phone', data.customerPhone),
            _row('Service', data.serviceType.replaceAll('_', ' ').toUpperCase()),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 0.5, color: PdfColors.grey200),
            pw.SizedBox(height: 10),
            _row('Payment', data.paymentMethod.replaceAll('_', ' ').toUpperCase()),
            _row('Amount', CurrencyFormatter.formatShort(data.amountPaid), isBold: true),
            if (data.notes != null && data.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5, color: PdfColors.grey200),
              pw.SizedBox(height: 8),
              pw.Text(data.notes!, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ],
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 0.5, color: PdfColors.grey200),
            pw.SizedBox(height: 8),
            pw.Text('Thank you!', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
          ],
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
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: PdfColors.grey900)),
        ],
      ),
    );
  }
}
