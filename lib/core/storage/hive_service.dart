import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    try {
      await _openBoxes();
    } on HiveError catch (e) {
      debugPrint('[KS:HIVE] HiveError on open — wiping corrupt boxes and retrying: $e');
      await Hive.deleteBoxFromDisk(jobsBox);
      await Hive.deleteBoxFromDisk(customersBox);
      await Hive.deleteBoxFromDisk(notesBox);
      await Hive.deleteBoxFromDisk(followUpsBox);
      await Hive.deleteBoxFromDisk(profileBox);
      await Hive.deleteBoxFromDisk(settingsBox);
      await Hive.deleteBoxFromDisk(serviceTypesBox);
      await Hive.deleteBoxFromDisk(jobPartsBox);
      await Hive.deleteBoxFromDisk(jobPhotosBox);
      await Hive.deleteBoxFromDisk(jobAuditLogBox);
      await Hive.deleteBoxFromDisk(keyCodeHistoryBox);
      await Hive.deleteBoxFromDisk(noteJobLinksBox);
      await Hive.deleteBoxFromDisk(remindersBox);
      await Hive.deleteBoxFromDisk(activityEventsBox);
      await _openBoxes();
    }
  }

  static Future<void> _openBoxes() async {
    final jobs = await Hive.openBox<Map>(jobsBox);
    final customers = await Hive.openBox<Map>(customersBox);
    await Hive.openBox<Map>(notesBox);
    await Hive.openBox<Map>(followUpsBox);
    await Hive.openBox<Map>(profileBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox<Map>(serviceTypesBox);
    await Hive.openBox<Map>(jobPartsBox);
    await Hive.openBox<Map>(jobPhotosBox);
    await Hive.openBox<Map>(jobAuditLogBox);
    await Hive.openBox<Map>(keyCodeHistoryBox);
    await Hive.openBox<Map>(noteJobLinksBox);
    await Hive.openBox<Map>(remindersBox);
    await Hive.openBox<Map>(activityEventsBox);

    await jobs.compact();
    await customers.compact();
  }

  static Future<void> clearAll() async {
    await jobs.clear();
    await customers.clear();
    await notes.clear();
    await followUps.clear();
    await profile.clear();
    await serviceTypes.clear();
    await jobParts.clear();
    await jobPhotos.clear();
    await jobAuditLog.clear();
    await keyCodeHistory.clear();
    await noteJobLinks.clear();
    await reminders.clear();
    await activityEvents.clear();
  }

  static Box<Map> get jobs            => Hive.box<Map>(jobsBox);
  static Box<Map> get customers       => Hive.box<Map>(customersBox);
  static Box<Map> get notes           => Hive.box<Map>(notesBox);
  static Box<Map> get followUps       => Hive.box<Map>(followUpsBox);
  static Box<Map> get profile         => Hive.box<Map>(profileBox);
  static Box<Map> get serviceTypes    => Hive.box<Map>(serviceTypesBox);
  static Box<Map> get jobParts        => Hive.box<Map>(jobPartsBox);
  static Box<Map> get jobPhotos       => Hive.box<Map>(jobPhotosBox);
  static Box<Map> get jobAuditLog     => Hive.box<Map>(jobAuditLogBox);
  static Box<Map> get keyCodeHistory  => Hive.box<Map>(keyCodeHistoryBox);
  static Box<Map> get noteJobLinks    => Hive.box<Map>(noteJobLinksBox);
  static Box<Map> get reminders       => Hive.box<Map>(remindersBox);
  static Box<Map> get activityEvents  => Hive.box<Map>(activityEventsBox);
  static Box      get settings        => Hive.box(settingsBox);
}
