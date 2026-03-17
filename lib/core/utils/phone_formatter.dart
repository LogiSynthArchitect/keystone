import '../errors/validation_exception.dart';

class PhoneFormatter {
  PhoneFormatter._();

  static String normalize(String input) {
    // 1. First, strip all non-numeric characters EXCEPT '+'
    String cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');

    // 2. If it starts with '+', it's already in international format; verify length
    if (cleaned.startsWith('+')) {
      if (cleaned.length >= 10 && cleaned.length <= 15) return cleaned;
      throw const ValidationException(message: 'Invalid international format.', code: 'INVALID_E164');
    }

    // 3. Handle local Ghana format (024, 055, etc.) -> Convert to +233
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return '+233${cleaned.substring(1)}';
    }

    // 4. Handle Ghana format without zero (24, 55, etc.) -> Convert to +233
    if (cleaned.length == 9) {
      return '+233$cleaned';
    }

    // 5. Handle Ghana format with 233 but no plus
    if (cleaned.startsWith('233') && cleaned.length == 12) {
      return '+$cleaned';
    }

    throw const ValidationException(
      message: 'Please enter a valid Ghana phone number.',
      code: 'PHONE_INVALID',
      field: 'phone_number',
    );
  }

  static bool isValid(String input) {
    try {
      normalize(input);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String display(String normalized) {
    if (normalized.startsWith('+233') && normalized.length == 13) {
      final local = '0${normalized.substring(4)}';
      return '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
    }
    return normalized;
  }
}
