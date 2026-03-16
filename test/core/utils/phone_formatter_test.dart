import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/core/utils/phone_formatter.dart';
import 'package:keystone/core/errors/validation_exception.dart';

void main() {
  group('PhoneFormatter.normalize', () {
    test('normalizes 0244123456 to +233244123456', () {
      // TODO
    });

    test('normalizes +233244123456 to +233244123456', () {
      // TODO
    });

    test('normalizes 233244123456 to +233244123456', () {
      // TODO
    });

    test('normalizes number with spaces to E164', () {
      // TODO
    });

    test('normalizes number with dashes to E164', () {
      // TODO
    });

    test('throws ValidationException for number too short', () {
      // TODO
    });

    test('throws ValidationException for empty string', () {
      // TODO
    });
  });

  group('PhoneFormatter.isValid', () {
    test('returns true for valid Ghana number', () {
      // TODO
    });

    test('returns false for invalid number', () {
      // TODO
    });
  });

  group('PhoneFormatter.display', () {
    test('formats E164 number for display', () {
      // TODO
    });
  });
}
