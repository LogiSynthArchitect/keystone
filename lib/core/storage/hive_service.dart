import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  HiveService._();

  static const String jobsBox       = 'jobs';
  static const String customersBox  = 'customers';
  static const String notesBox      = 'notes';
  static const String followUpsBox  = 'follow_ups';
  static const String profileBox    = 'profile';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    try {
      await _openBoxes();
    } catch (e) {
      // Task 3: Corruption Recovery - Wipe all boxes from disk and retry
      // This prevents a hard crash on startup if Hive box files are corrupted.
      await Hive.deleteBoxFromDisk(jobsBox);
      await Hive.deleteBoxFromDisk(customersBox);
      await Hive.deleteBoxFromDisk(notesBox);
      await Hive.deleteBoxFromDisk(followUpsBox);
      await Hive.deleteBoxFromDisk(profileBox);
      
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
}
