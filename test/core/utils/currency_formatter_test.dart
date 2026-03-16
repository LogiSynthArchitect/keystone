import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.parse', () {
    test('parses valid amount string to double', () {
      expect(CurrencyFormatter.parse('150.00'), equals(150.00));
    });

    test('strips commas before parsing', () {
      expect(CurrencyFormatter.parse('1,500.00'), equals(1500.00));
    });

    test('returns null for empty string', () {
      expect(CurrencyFormatter.parse(''), isNull);
    });

    test('returns null for non-numeric string', () {
      expect(CurrencyFormatter.parse('abc'), isNull);
    });
  });

  group('CurrencyFormatter.format', () {
    test('formats amount with GHS prefix', () {
      expect(CurrencyFormatter.format(150.00), startsWith('GHS'));
    });

    test('formats amount with two decimal places', () {
      expect(CurrencyFormatter.format(150.00), equals('GHS 150.00'));
    });

    test('formats large amount with comma separator', () {
      expect(CurrencyFormatter.format(1500.00), equals('GHS 1,500.00'));
    });
  });

  group('CurrencyFormatter.formatShort', () {
    test('formats amount without decimal places', () {
      expect(CurrencyFormatter.formatShort(150.00), equals('GHS 150'));
    });
  });
}
