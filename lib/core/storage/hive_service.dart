import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  HiveService._();

  static const String jobsBox       = 'jobs';
  static const String customersBox  = 'customers';
  static const String notesBox      = 'notes';
  static const String followUpsBox  = 'follow_ups';
  static const String profileBox    = 'profile';
  static const String settingsBox   = 'settings';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    try {
      await _openBoxes();
    } on HiveError catch (e) {
      // Corruption Recovery: only wipe on confirmed Hive-level errors (not transient IO issues)
      // to prevent data loss from non-corruption failures.
      debugPrint('[KS:HIVE] HiveError on open — wiping corrupt boxes and retrying: $e');
      await Hive.deleteBoxFromDisk(jobsBox);
      await Hive.deleteBoxFromDisk(customersBox);
      await Hive.deleteBoxFromDisk(notesBox);
      await Hive.deleteBoxFromDisk(followUpsBox);
      await Hive.deleteBoxFromDisk(profileBox);
      await Hive.deleteBoxFromDisk(settingsBox);
      await _openBoxes();
    }
  }

  static Future<void> _openBoxes() async {
    // Open boxes and store references to trigger compaction
    final jobs = await Hive.openBox<Map>(jobsBox);
    final customers = await Hive.openBox<Map>(customersBox);
    await Hive.openBox<Map>(notesBox);
    await Hive.openBox<Map>(followUpsBox);
    await Hive.openBox<Map>(profileBox);
    await Hive.openBox(settingsBox);

    // Compaction - physically deletes stale data rows on startup
    await jobs.compact();
    await customers.compact();
  }

  // Task 2 fix: Method to clear all local technician data
  static Future<void> clearAll() async {
    await jobs.clear();
    await customers.clear();
    await notes.clear();
    await followUps.clear();
    await profile.clear();
  }

  static Box<Map> get jobs      => Hive.box<Map>(jobsBox);
  static Box<Map> get customers => Hive.box<Map>(customersBox);
  static Box<Map> get notes      => Hive.box<Map>(notesBox);
  static Box<Map> get followUps => Hive.box<Map>(followUpsBox);
  static Box<Map> get profile   => Hive.box<Map>(profileBox);
  static Box      get settings  => Hive.box(settingsBox);
}
