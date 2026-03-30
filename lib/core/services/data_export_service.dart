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
    final file = await _writeTempFile('keystone_jobs.csv', buffer.toString());
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
