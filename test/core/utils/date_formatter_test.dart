import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    test('display formats date as d MMM yyyy', () {
      final date = DateTime(2026, 1, 15);
      expect(DateFormatter.display(date), equals('15 Jan 2026'));
    });

    test('short formats date as d MMM', () {
      final date = DateTime(2026, 1, 15);
      expect(DateFormatter.short(date), equals('15 Jan'));
    });

    test('relative returns Today for today', () {
      final today = DateTime.now();
      expect(DateFormatter.relative(today), equals('Today'));
    });

    test('relative returns Yesterday for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateFormatter.relative(yesterday), equals('Yesterday'));
    });

    test('relative returns N days ago for recent dates', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      expect(DateFormatter.relative(threeDaysAgo), equals('3 days ago'));
    });

    test('toDb formats date as yyyy-MM-dd', () {
      final date = DateTime(2026, 1, 15);
      expect(DateFormatter.toDb(date), equals('2026-01-15'));
    });
  });
}
