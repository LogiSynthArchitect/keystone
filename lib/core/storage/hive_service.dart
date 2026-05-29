import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  HiveService._();

  static const String jobsBox            = 'jobs';
  static const String customersBox       = 'customers';
  static const String notesBox           = 'notes';
  static const String followUpsBox       = 'follow_ups';
  static const String profileBox         = 'profile';
  static const String settingsBox        = 'settings';
  static const String serviceTypesBox    = 'service_types';
  static const String jobPartsBox        = 'job_parts';
  static const String jobPhotosBox       = 'job_photos';
  static const String jobAuditLogBox     = 'job_audit_log';
  static const String keyCodeHistoryBox  = 'key_code_history';
  static const String noteJobLinksBox    = 'note_job_links';
  static const String remindersBox       = 'reminders';
  static const String activityEventsBox  = 'activity_events';
  static const String jobServicesBox     = 'job_services';
  static const String jobHardwareBox     = 'job_hardware';
  static const String jobExpensesBox     = 'job_expenses';
  static const String jobTemplatesBox    = 'job_templates';
  static const String inventoryItemsBox  = 'inventory_items';
  static const String inventoryStockAdjustmentsBox = 'inventory_stock_adjustments';
  static const String inventoryRestocksBox = 'inventory_restocks';
  static const String recurringSchedulesBox = 'recurring_schedules';
  static const String authBox = 'auth';
  static const String pendingMediaUploadsBox = 'pending_media_uploads';
  static const String metaBox = '_meta';
  static const String lastOnlineSyncKey   = 'last_online_sync';
  static const String backupDirName      = 'hive_backups';

  static final List<String> allBoxNames = [
    jobsBox, customersBox, notesBox, followUpsBox, profileBox,
    settingsBox, serviceTypesBox, jobPartsBox, jobPhotosBox,
    jobAuditLogBox, keyCodeHistoryBox, noteJobLinksBox,
    remindersBox, activityEventsBox, jobServicesBox, jobHardwareBox, jobExpensesBox, jobTemplatesBox, inventoryItemsBox, inventoryStockAdjustmentsBox, inventoryRestocksBox, recurringSchedulesBox, authBox, pendingMediaUploadsBox,
  ];

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await _openBoxes();
  }

  /// Per-box recovery: only the corrupted box is deleted, not all data.
  static Future<void> _openBoxes() async {
    Box? jobs;
    Box? customers;

    for (final name in allBoxNames) {
      try {
        final box = await Hive.openBox(name);
        if (name == jobsBox) jobs = box;
        if (name == customersBox) customers = box;
      } on HiveError catch (e) {
        debugPrint('[KS:HIVE] Per-box recovery: deleting corrupt "$name": $e');
        try {
          await Hive.deleteBoxFromDisk(name);
          final box = await Hive.openBox(name);
          if (name == jobsBox) jobs = box;
          if (name == customersBox) customers = box;
        } catch (e2) {
          debugPrint('[KS:HIVE] Fatal: could not recover "$name": $e2');
        }
      }
    }

    try { await jobs?.compact(); } catch (_) {}
    try { await customers?.compact(); } catch (_) {}

    // Open meta box as untyped for version tracking etc.
    await Hive.openBox(metaBox);

    // Create a backup after successful init
    try { await _createBackup(); } catch (_) {}
  }

  /// Backs up all Hive files to a backup directory.
  /// Keeps last 3 backups, deletes older ones.
  static Future<void> _createBackup() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupRoot = Directory('${dir.path}/$backupDirName');
    if (!await backupRoot.exists()) await backupRoot.create(recursive: true);

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final thisBackup = Directory('${backupRoot.path}/$timestamp');
    await thisBackup.create();

    final hiveDir = await _hiveDir();
    if (hiveDir == null) return;

    for (final name in allBoxNames) {
      final src = File('${hiveDir.path}/$name.hive');
      if (await src.exists()) {
        await src.copy('${thisBackup.path}/$name.hive');
      }
    }

    // Keep last 3 backups
    final allBackups = await backupRoot.list().toList();
    if (allBackups.length > 3) {
      allBackups.sort((a, b) => a.path.compareTo(b.path));
      for (int i = 0; i < allBackups.length - 3; i++) {
        if (allBackups[i] is Directory) {
          await (allBackups[i] as Directory).delete(recursive: true);
        }
      }
    }
  }

  /// Find the Hive storage directory.
  static Future<Directory?> _hiveDir() async {
    final dir = await getApplicationDocumentsDirectory();
    // Hive default directory on mobile
    final docDir = Directory(dir.path);
    if (await docDir.exists()) return docDir;
    return null;
  }

  static Future<void> clearAll() async {
    for (final name in allBoxNames) {
      try {
        final box = Hive.box(name);
        await box.clear();
      } catch (_) {}
    }
  }

  static Future<void> clearDataBoxes() async {
    final keep = {authBox, pendingMediaUploadsBox, metaBox};
    for (final name in allBoxNames) {
      if (keep.contains(name)) continue;
      try {
        final box = Hive.box(name);
        await box.clear();
      } catch (_) {}
    }
  }

  static Box get jobs            => Hive.box(jobsBox);
  static Box get customers       => Hive.box(customersBox);
  static Box get notes           => Hive.box(notesBox);
  static Box get followUps       => Hive.box(followUpsBox);
  static Box get profile         => Hive.box(profileBox);
  static Box get serviceTypes    => Hive.box(serviceTypesBox);
  static Box get jobParts        => Hive.box(jobPartsBox);
  static Box get jobPhotos       => Hive.box(jobPhotosBox);
  static Box get jobAuditLog     => Hive.box(jobAuditLogBox);
  static Box get keyCodeHistory  => Hive.box(keyCodeHistoryBox);
  static Box get noteJobLinks    => Hive.box(noteJobLinksBox);
  static Box get reminders       => Hive.box(remindersBox);
  static Box get activityEvents  => Hive.box(activityEventsBox);
  static Box get jobServices    => Hive.box(jobServicesBox);
  static Box get jobHardware    => Hive.box(jobHardwareBox);
  static Box get jobExpenses    => Hive.box(jobExpensesBox);
  static Box get jobTemplates       => Hive.box(jobTemplatesBox);
  static Box get inventoryItems          => Hive.box(inventoryItemsBox);
  static Box get inventoryStockAdjustments => Hive.box(inventoryStockAdjustmentsBox);
  static Box get inventoryRestocks        => Hive.box(inventoryRestocksBox);
  static Box get recurringSchedules       => Hive.box(recurringSchedulesBox);
  static Box get auth           => Hive.box(authBox);
  static Box get settings        => Hive.box(settingsBox);
  static Box get meta            => Hive.box(metaBox);
}
