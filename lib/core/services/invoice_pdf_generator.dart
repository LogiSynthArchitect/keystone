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
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 44),
        build: (context) => [
          _buildHeader(data),
          pw.SizedBox(height: 32),
          _buildCustomerSection(data),
          pw.SizedBox(height: 36),
          _buildServiceSection(data),
          if (data.hardwareItems.isNotEmpty) ...[
            pw.SizedBox(height: 28),
            _buildHardwareSection(data),
          ],
          if (data.parts.isNotEmpty) ...[
            pw.SizedBox(height: 28),
            _buildPartsSection(data),
          ],
          pw.SizedBox(height: 36),
          _buildFinancialSummary(data),
          pw.SizedBox(height: 32),
          _buildPaymentInfo(data),
          pw.SizedBox(height: 48),
          _buildFooter(data),
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
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('KEYSTONE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
            pw.SizedBox(height: 4),
            pw.Text('I N V O I C E', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.normal, color: PdfColors.grey600, letterSpacing: 3)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('#${data.invoiceNumber}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
            pw.SizedBox(height: 2),
            pw.Text(DateFormatter.display(data.date), style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCustomerSection(InvoiceData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('BILL TO', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal, color: PdfColors.grey500, letterSpacing: 2)),
        pw.SizedBox(height: 8),
        pw.Text(data.customerName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
        pw.SizedBox(height: 2),
        pw.Text(data.customerPhone, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
        if (data.customerLocation != null && data.customerLocation!.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(data.customerLocation!, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
          ),
      ],
    );
  }

  static pw.Widget _buildServiceSection(InvoiceData data) {
    final hasAdditional = data.services.isNotEmpty;
    final rows = <pw.TableRow>[
      pw.TableRow(
        children: [
          _cell('Service', isHeader: true),
          _cell('Qty', isHeader: true, align: pw.TextAlign.right),
          _cell('Amount', isHeader: true, align: pw.TextAlign.right),
        ],
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
        ),
      ),
      pw.TableRow(
        children: [
          _cell(data.serviceType.replaceAll('_', ' ').toUpperCase(), weight: pw.FontWeight.bold),
          _cell('1', align: pw.TextAlign.right),
          _cell(data.amountCharged != null ? CurrencyFormatter.formatShort(data.amountCharged!) : '—', align: pw.TextAlign.right, weight: pw.FontWeight.bold),
        ],
      ),
    ];

    if (hasAdditional) {
      for (final s in data.services) {
        rows.add(pw.TableRow(
          children: [
            _cell(s.name.replaceAll('_', ' ').toUpperCase(), color: PdfColors.grey600),
            _cell('${s.quantity}', align: pw.TextAlign.right, color: PdfColors.grey600),
            _cell(s.unitPrice != null ? CurrencyFormatter.formatShort(s.totalCost) : '—', align: pw.TextAlign.right, color: PdfColors.grey600),
          ],
        ));
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('SERVICES', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal, color: PdfColors.grey500, letterSpacing: 2)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder(
            bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
          ),
          columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(2)},
          children: rows,
        ),
      ],
    );
  }

  static pw.Widget _buildHardwareSection(InvoiceData data) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        children: [
          _cell('Item', isHeader: true),
          _cell('Brand', isHeader: true),
          _cell('Qty', isHeader: true, align: pw.TextAlign.right),
          _cell('Amount', isHeader: true, align: pw.TextAlign.right),
        ],
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
        ),
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
        pw.Text('HARDWARE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal, color: PdfColors.grey500, letterSpacing: 2)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder(
            bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
          ),
          columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(1), 3: pw.FlexColumnWidth(2)},
          children: rows,
        ),
      ],
    );
  }

  static pw.Widget _buildPartsSection(InvoiceData data) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        children: [
          _cell('Part', isHeader: true),
          _cell('Qty', isHeader: true, align: pw.TextAlign.right),
          _cell('Amount', isHeader: true, align: pw.TextAlign.right),
        ],
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
        ),
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
        pw.Text('PARTS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal, color: PdfColors.grey500, letterSpacing: 2)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder(
            bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
          ),
          columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(2)},
          children: rows,
        ),
      ],
    );
  }

  static pw.Widget _buildFinancialSummary(InvoiceData data) {
    final cols = <pw.Widget>[
      _summaryRow('Total Charged', CurrencyFormatter.formatShort(data.revenue), isBold: true, size: 12),
    ];

    if (data.totalCost > 0) {
      cols.add(pw.SizedBox(height: 3));
      cols.add(_summaryRow('Cost of Goods', CurrencyFormatter.formatShort(data.totalCost), color: PdfColors.grey600, size: 10));
      cols.add(pw.SizedBox(height: 3));
      cols.add(_summaryRow('Gross Profit', CurrencyFormatter.formatShort(data.grossProfit), color: PdfColors.grey900, size: 10));
    }

    if (data.quotedPrice != null && data.amountCharged != null) {
      final quotedPesewas = (data.quotedPrice! * 100).round();
      if (quotedPesewas != data.amountCharged) {
        cols.add(pw.SizedBox(height: 3));
        cols.add(_summaryRow('Quoted', CurrencyFormatter.formatShort(quotedPesewas), color: PdfColors.grey600, size: 10));
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: cols,
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false, PdfColor? color, double size = 11}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 110,
          alignment: pw.Alignment.centerRight,
          child: pw.Text(label, style: pw.TextStyle(fontSize: size, color: color ?? PdfColors.grey800, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
        pw.SizedBox(width: 12),
        pw.Container(
          width: 90,
          alignment: pw.Alignment.centerRight,
          child: pw.Text(value, style: pw.TextStyle(fontSize: size, color: color ?? PdfColors.grey800, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      ],
    );
  }

  static pw.Widget _buildPaymentInfo(InvoiceData data) {
    final statusColor = data.paymentStatus == 'paid'
        ? PdfColors.green700
        : (data.paymentStatus == 'partial' ? PdfColors.orange700 : PdfColors.grey600);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('PAYMENT STATUS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.normal, color: PdfColors.grey500, letterSpacing: 2)),
          pw.Text(
            data.paymentStatus.toUpperCase().replaceAll('_', ' '),
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: statusColor),
          ),
          if (data.paymentMethod != null)
            pw.Text(
              data.paymentMethod!.replaceAll('_', ' ').toUpperCase(),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(InvoiceData data) {
    final isPaid = data.paymentStatus == 'paid';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey200),
        pw.SizedBox(height: 14),
        pw.Text(
          isPaid ? 'Payment received. Thank you!' : 'Payment due within 14 days.',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
        ),
        pw.SizedBox(height: 2),
        pw.Text('Thank you for your business.', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left, PdfColor? color, pw.FontWeight? weight}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 10,
          fontWeight: weight ?? (isHeader ? pw.FontWeight.bold : pw.FontWeight.normal),
          color: color ?? (isHeader ? PdfColors.grey700 : PdfColors.grey800),
        ),
      ),
    );
  }
}
