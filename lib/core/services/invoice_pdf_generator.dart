import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class InvoiceData {
  final String invoiceNumber;
  final DateTime date;
  final String customerName;
  final String customerPhone;
  final String? customerLocation;
  final String serviceType;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final int? amountCharged;
  final int? quotedPrice;
  final String? hardwareBrand;
  final String? hardwareKeyway;
  final List<InvoiceService> services;
  final List<InvoicePart> parts;
  final List<InvoiceHardware> hardwareItems;

  const InvoiceData({
    required this.invoiceNumber,
    required this.date,
    required this.customerName,
    required this.customerPhone,
    this.customerLocation,
    required this.serviceType,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.amountCharged,
    this.quotedPrice,
    this.hardwareBrand,
    this.hardwareKeyway,
    this.services = const [],
    this.parts = const [],
    this.hardwareItems = const [],
  });

  int get revenue => amountCharged ?? 0;
  int get totalPartsCost => parts.fold(0, (s, p) => s + p.totalCost);
  int get totalHardwareCost => hardwareItems.fold(0, (s, h) => s + h.totalCost);
  int get totalCost => totalPartsCost + totalHardwareCost;
  int get grossProfit => revenue - totalCost;
}

class InvoiceService {
  final String name;
  final int quantity;
  final int? unitPrice;
  const InvoiceService({required this.name, this.quantity = 1, this.unitPrice});
  int get totalCost => (unitPrice ?? 0) * quantity;
}

class InvoicePart {
  final String name;
  final int quantity;
  final int? unitPrice;
  const InvoicePart({required this.name, this.quantity = 1, this.unitPrice});
  int get totalCost => (unitPrice ?? 0) * quantity;
}

class InvoiceHardware {
  final String name;
  final String? brand;
  final int quantity;
  final int? unitPrice;
  const InvoiceHardware({required this.name, this.brand, this.quantity = 1, this.unitPrice});
  int get totalCost => (unitPrice ?? 0) * quantity;
}

class InvoicePdfGenerator {
  static Future<File> generate(InvoiceData data) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(data),
          pw.SizedBox(height: 8),
          _buildDivider(),
          pw.SizedBox(height: 16),
          _buildCustomerSection(data),
          pw.SizedBox(height: 24),
          _buildServiceSection(data),
          if (data.hardwareItems.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildHardwareSection(data),
          ],
          if (data.parts.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildPartsSection(data),
          ],
          pw.SizedBox(height: 24),
          _buildDivider(),
          pw.SizedBox(height: 16),
          _buildFinancialSummary(data),
          pw.SizedBox(height: 32),
          _buildPaymentInfo(data),
          pw.SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );

    return await doc.save().then((bytes) async {
      final dir = await _getTemporaryDirectory();
      final file = File('${dir.path}/keystone_invoice.pdf');
      await file.writeAsBytes(bytes);
      return file;
    });
  }

  static Future<Directory> _getTemporaryDirectory() async {
    return Directory.systemTemp;
  }

  static pw.Widget _buildHeader(InvoiceData data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('KEYSTONE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
            pw.Text('INVOICE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('#${data.invoiceNumber}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text(DateFormatter.display(data.date), style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDivider() {
    return pw.Divider(thickness: 1, color: PdfColors.grey300);
  }

  static pw.Widget _buildCustomerSection(InvoiceData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('CUSTOMER', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700, letterSpacing: 1)),
        pw.SizedBox(height: 8),
        pw.Text(data.customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text(data.customerPhone, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
        if (data.customerLocation != null && data.customerLocation!.isNotEmpty)
          pw.Text(data.customerLocation!, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
      ],
    );
  }

  static pw.Widget _buildServiceSection(InvoiceData data) {
    final hasAdditional = data.services.isNotEmpty;
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
        children: [
          _cell('SERVICE', isHeader: true),
          _cell('QTY', isHeader: true, align: pw.TextAlign.right),
          _cell('AMOUNT', isHeader: true, align: pw.TextAlign.right),
        ],
      ),
      pw.TableRow(
        children: [
          _cell(data.serviceType.replaceAll('_', ' ').toUpperCase()),
          _cell('1', align: pw.TextAlign.right),
          _cell(data.amountCharged != null ? CurrencyFormatter.formatShort(data.amountCharged!) : '—', align: pw.TextAlign.right),
        ],
      ),
    ];

    if (hasAdditional) {
      for (final s in data.services) {
        rows.add(pw.TableRow(
          children: [
            _cell(s.name.replaceAll('_', ' ').toUpperCase(), style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            _cell('${s.quantity}', align: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10)),
            _cell(s.unitPrice != null ? CurrencyFormatter.formatShort(s.totalCost) : '—', align: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10)),
          ],
        ));
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('SERVICES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700, letterSpacing: 1)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.symmetric(outside: pw.BorderSide(color: PdfColors.grey300), inside: const pw.BorderSide(color: PdfColors.grey200)),
          columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(2)},
          children: rows,
        ),
      ],
    );
  }

  static pw.Widget _buildHardwareSection(InvoiceData data) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
        children: [
          _cell('ITEM', isHeader: true),
          _cell('BRAND', isHeader: true),
          _cell('QTY', isHeader: true, align: pw.TextAlign.right),
          _cell('AMOUNT', isHeader: true, align: pw.TextAlign.right),
        ],
      ),
      for (final h in data.hardwareItems)
        pw.TableRow(
          children: [
            _cell(h.name),
            _cell(h.brand ?? '—'),
            _cell('${h.quantity}', align: pw.TextAlign.right),
            _cell(h.unitPrice != null ? CurrencyFormatter.formatShort(h.totalCost) : '—', align: pw.TextAlign.right),
          ],
        ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('HARDWARE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700, letterSpacing: 1)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.symmetric(outside: pw.BorderSide(color: PdfColors.grey300), inside: const pw.BorderSide(color: PdfColors.grey200)),
          columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(1), 3: pw.FlexColumnWidth(2)},
          children: rows,
        ),
      ],
    );
  }

  static pw.Widget _buildPartsSection(InvoiceData data) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
        children: [
          _cell('PART', isHeader: true),
          _cell('QTY', isHeader: true, align: pw.TextAlign.right),
          _cell('AMOUNT', isHeader: true, align: pw.TextAlign.right),
        ],
      ),
      for (final p in data.parts)
        pw.TableRow(
          children: [
            _cell(p.name),
            _cell('${p.quantity}', align: pw.TextAlign.right),
            _cell(p.unitPrice != null ? CurrencyFormatter.formatShort(p.totalCost) : '—', align: pw.TextAlign.right),
          ],
        ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PARTS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700, letterSpacing: 1)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.symmetric(outside: pw.BorderSide(color: PdfColors.grey300), inside: const pw.BorderSide(color: PdfColors.grey200)),
          columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(2)},
          children: rows,
        ),
      ],
    );
  }

  static pw.Widget _buildFinancialSummary(InvoiceData data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _summaryRow('Total Charged', CurrencyFormatter.formatShort(data.revenue), isBold: true),
            if (data.totalCost > 0) ...[
              pw.SizedBox(height: 4),
              _summaryRow('Cost of Goods', '-${CurrencyFormatter.formatShort(data.totalCost)}', color: PdfColors.red700),
              pw.SizedBox(height: 4),
              _summaryRow('Gross Profit', CurrencyFormatter.formatShort(data.grossProfit), color: PdfColors.green700, isBold: true),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false, PdfColor? color}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 120,
          alignment: pw.Alignment.centerRight,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 11, color: color ?? PdfColors.grey800, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
        pw.Container(
          width: 100,
          alignment: pw.Alignment.centerRight,
          child: pw.Text(value, style: pw.TextStyle(fontSize: 11, color: color ?? PdfColors.grey800, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      ],
    );
  }

  static pw.Widget _buildPaymentInfo(InvoiceData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('PAYMENT STATUS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
          pw.Text(
            data.paymentStatus.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: data.paymentStatus == 'paid' ? PdfColors.green700 : (data.paymentStatus == 'partial' ? PdfColors.orange700 : PdfColors.red700),
            ),
          ),
          pw.Text(
            data.paymentMethod != null ? data.paymentMethod!.replaceAll('_', ' ').toUpperCase() : '',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 12),
        pw.Text('Payment due within 14 days', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
        pw.SizedBox(height: 4),
        pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left, pw.TextStyle? style}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: style ?? pw.TextStyle(
          fontSize: isHeader ? 10 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blueGrey800 : PdfColors.grey800,
        ),
      ),
    );
  }
}
