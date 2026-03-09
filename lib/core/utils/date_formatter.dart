import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _display   = DateFormat('d MMM yyyy');
  static final _short     = DateFormat('d MMM');
  static final _dayOfWeek = DateFormat('EEEE');
  static final _db        = DateFormat('yyyy-MM-dd');

  // 15 Jan 2026
  static String display(DateTime date) => _display.format(date);

  // 15 Jan
  static String short(DateTime date) => _short.format(date);

  // Monday
  static String dayOfWeek(DateTime date) => _dayOfWeek.format(date);

  // 2026-01-15 (for database)
  static String toDb(DateTime date) => _db.format(date);

  // Relative: Today, Yesterday, 3 days ago, 15 Jan 2026
  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return display(date);
  }
}
