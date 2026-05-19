import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../storage/hive_service.dart';

class DataExportService {
  DataExportService._();

  static Future<void> exportAsJson() async {
    final data = _collectData();
    final json = const JsonEncoder.withIndent('  ').convert(data);
    final file = await _writeTempFile('keystone_export.json', json);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      text: 'Keystone data export',
    );
  }

  static Future<void> exportAsCsv() async {
    final jobs = HiveService.jobs.values.toList();
    final rawList = jobs.map((j) => Map<String, dynamic>.from(j)).toList();
    final buffer = StringBuffer();
    buffer.writeln('id,serviceType,status,paymentStatus,amountCharged,createdAt,location,notes');
    for (final m in rawList) {
      buffer.writeln([
        _csv(m['id']),
        _csv(m['service_type']),
        _csv(m['status']),
        _csv(m['payment_status']),
        _csv(m['amount_charged']),
        _csv(m['created_at']),
        _csv(m['location']),
        _csv(m['notes']),
      ].join(','));
    }
    final file = await _writeTempFile('keystone_jobs.csv', buffer.toString());
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'Keystone jobs export',
    );
  }

  static Future<void> exportJobsAsCsv(dynamic selectedJobs) async {
    final buffer = StringBuffer();
    buffer.writeln('id,serviceType,status,paymentStatus,amountCharged,createdAt,location,notes,customerId,partsSummary,partsCost,expensesSummary,expensesTotal,grossProfit');
    for (final job in selectedJobs) {
      final jobId = job.id;

      String partsSummary = '';
      int partsCost = 0;
      final partMaps = HiveService.jobParts.values
          .map((j) => Map<String, dynamic>.from(j))
          .where((p) => p['job_id'] == jobId)
          .toList();
      if (partMaps.isNotEmpty) {
        partsSummary = partMaps.map((p) {
          final qty = p['quantity'] ?? 1;
          final price = p['unit_price'] != null ? (p['unit_price'] as num) / 100.0 : 0;
          partsCost += (qty as int) * price.toInt();
          return '${p['part_name']}x$qty';
        }).join('; ');
      }

      String expensesSummary = '';
      int expensesTotal = 0;
      final expMaps = HiveService.jobExpenses.values
          .map((j) => Map<String, dynamic>.from(j))
          .where((e) => e['job_id'] == jobId)
          .toList();
      if (expMaps.isNotEmpty) {
        expensesSummary = expMaps.map((e) {
          final amt = (e['amount'] as num?)?.toInt() ?? 0;
          expensesTotal += amt;
          return '${e['category']}:${(amt / 100.0).toStringAsFixed(2)}';
        }).join('; ');
      }

      final amt = (job.amountCharged ?? 0) as int;
      final grossProfit = amt - partsCost - expensesTotal;

      buffer.writeln([
        _csv(jobId),
        _csv(job.serviceType),
        _csv(job.status),
        _csv(job.paymentStatus),
        _csv((job.amountCharged ?? 0) / 100.0),
        _csv(job.jobDate.toIso8601String()),
        _csv(job.location),
        _csv(job.notes),
        _csv(job.customerId),
        _csv(partsSummary),
        _csv(partsCost / 100.0),
        _csv(expensesSummary),
        _csv(expensesTotal / 100.0),
        _csv(grossProfit / 100.0),
      ].join(','));
    }
    final file = await _writeTempFile('keystone_selected_jobs.csv', buffer.toString());
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'Selected jobs export',
    );
  }

  static Future<void> _exportJobCsv(List<dynamic> jobs, String filename) async {
    final buffer = StringBuffer();
    buffer.writeln('id,serviceType,status,paymentStatus,amountCharged,createdAt,location,notes');
    for (final raw in jobs) {
      final m = Map<String, dynamic>.from(raw);
      buffer.writeln([
        _csv(m['id']),
        _csv(m['service_type']),
        _csv(m['status']),
        _csv(m['payment_status']),
        _csv(m['amount_charged']),
        _csv(m['created_at']),
        _csv(m['location']),
        _csv(m['notes']),
      ].join(','));
    }
    final file = await _writeTempFile(filename, buffer.toString());
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'Keystone jobs export',
    );
  }

  static Map<String, dynamic> _collectData() {
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'jobs': HiveService.jobs.values.map((e) => Map<String, dynamic>.from(e)).toList(),
      'customers': HiveService.customers.values.map((e) => Map<String, dynamic>.from(e)).toList(),
      'notes': HiveService.notes.values.map((e) => Map<String, dynamic>.from(e)).toList(),
      'service_types': HiveService.serviceTypes.values.map((e) => Map<String, dynamic>.from(e)).toList(),
      'job_parts': HiveService.jobParts.values.map((e) => Map<String, dynamic>.from(e)).toList(),
    };
  }

  static Future<void> exportCustomersAsCsv() async {
    final customers = HiveService.customers.values.toList();
    final buffer = StringBuffer();
    buffer.writeln('name,phone,propertyType,leadSource,location,totalJobs,lastJobDate,notes');
    for (final raw in customers) {
      final m = Map<String, dynamic>.from(raw);
      buffer.writeln([
        _csv(m['full_name']),
        _csv(m['phone_number']),
        _csv(m['property_type']),
        _csv(m['lead_source']),
        _csv(m['location']),
        _csv(m['total_jobs'] ?? 0),
        _csv(m['last_job_at']),
        _csv(m['notes']),
      ].join(','));
    }
    final file = await _writeTempFile('keystone_customers.csv', buffer.toString());
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'Customers export',
    );
  }

  static Future<File> _writeTempFile(String name, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
    return file;
  }

  static String _csv(dynamic value) {
    if (value == null) return '';
    final s = value.toString().replaceAll('"', '""');
    return s.contains(',') || s.contains('"') || s.contains('\n') ? '"$s"' : s;
  }
}
