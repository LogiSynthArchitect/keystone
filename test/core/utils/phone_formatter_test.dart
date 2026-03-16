import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/core/utils/phone_formatter.dart';
import 'package:keystone/core/errors/validation_exception.dart';

void main() {
  group('PhoneFormatter.normalize', () {
    test('normalizes 0244123456 to +233244123456', () {
      expect(PhoneFormatter.normalize('0244123456'), equals('+233244123456'));
    });

    test('normalizes +233244123456 to +233244123456', () {
      expect(PhoneFormatter.normalize('+233244123456'), equals('+233244123456'));
    });

    test('normalizes 233244123456 to +233244123456', () {
      expect(PhoneFormatter.normalize('233244123456'), equals('+233244123456'));
    });

    test('normalizes number with spaces to E164', () {
      expect(PhoneFormatter.normalize('0244 123 456'), equals('+233244123456'));
    });

    test('normalizes number with dashes to E164', () {
      expect(PhoneFormatter.normalize('0244-123-456'), equals('+233244123456'));
    });

    test('throws ValidationException for number too short', () {
      expect(
        () => PhoneFormatter.normalize('0244'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws ValidationException for empty string', () {
      expect(
        () => PhoneFormatter.normalize(''),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('PhoneFormatter.isValid', () {
    test('returns true for valid Ghana number', () {
      expect(PhoneFormatter.isValid('0244123456'), isTrue);
    });

    test('returns false for invalid number', () {
      expect(PhoneFormatter.isValid('0244'), isFalse);
    });
  });

  group('PhoneFormatter.display', () {
    test('formats E164 number for display', () {
      expect(
        PhoneFormatter.display('+233244123456'),
        equals('0244 123 456'),
      );
    });
  });
}
