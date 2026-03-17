import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.parseToPesewas', () {
    test('parses valid amount string to pesewas (int)', () {
      expect(CurrencyFormatter.parseToPesewas('150.00'), equals(15000));
    });

    test('strips commas before parsing', () {
      expect(CurrencyFormatter.parseToPesewas('1,500.00'), equals(150000));
    });

    test('returns null for empty string', () {
      expect(CurrencyFormatter.parseToPesewas(''), isNull);
    });

    test('returns null for non-numeric string', () {
      expect(CurrencyFormatter.parseToPesewas('abc'), isNull);
    });
  });

  group('CurrencyFormatter.format', () {
    test('formats pesewas with GHS prefix', () {
      expect(CurrencyFormatter.format(15000), startsWith('GHS'));
    });

    test('formats pesewas with two decimal places', () {
      expect(CurrencyFormatter.format(15000), equals('GHS 150.00'));
    });

    test('formats large amount with comma separator', () {
      expect(CurrencyFormatter.format(150000), equals('GHS 1,500.00'));
    });
  });

  group('CurrencyFormatter.formatShort', () {
    test('formats pesewas without decimal places', () {
      expect(CurrencyFormatter.formatShort(15000), equals('GHS 150'));
    });
  });
}
