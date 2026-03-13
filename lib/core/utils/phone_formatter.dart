import '../errors/validation_exception.dart';

class PhoneFormatter {
  PhoneFormatter._();

  static String normalize(String input) {
    // Remove spaces, dashes, parentheses, and non-digits
    String cleaned = input.replaceAll(RegExp(r'\D'), '');

    // Already in E.164 format logic
    if (cleaned.startsWith('233') && (cleaned.length == 12)) {
      return '+$cleaned';
    }

    // 0XXXXXXXXX format (local) - Truncate the 0 and append +233
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return '+233${cleaned.substring(1)}';
    }

    // XXXXXXXXX format (no zero) - Append +233
    if (cleaned.length == 9) {
      return '+233$cleaned';
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
