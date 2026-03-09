import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  HiveService._();

  static const String jobsBox      = 'jobs';
  static const String customersBox = 'customers';
  static const String notesBox     = 'notes';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(jobsBox);
    await Hive.openBox<Map>(customersBox);
    await Hive.openBox<Map>(notesBox);
  }

  static Box<Map> get jobs      => Hive.box<Map>(jobsBox);
  static Box<Map> get customers => Hive.box<Map>(customersBox);
  static Box<Map> get notes     => Hive.box<Map>(notesBox);
}
