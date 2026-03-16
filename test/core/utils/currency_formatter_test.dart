import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.parse', () {
    test('parses valid amount string to double', () {
      // TODO
    });

    test('strips commas before parsing', () {
      // TODO
    });

    test('returns null for empty string', () {
      // TODO
    });

    test('returns null for non-numeric string', () {
      // TODO
    });
  });

  group('CurrencyFormatter.format', () {
    test('formats amount with GHS prefix', () {
      // TODO
    });

    test('formats amount with two decimal places', () {
      // TODO
    });

    test('formats large amount with comma separator', () {
      // TODO
    });
  });

  group('CurrencyFormatter.formatShort', () {
    test('formats amount without decimal places', () {
      // TODO
    });
  });
}
