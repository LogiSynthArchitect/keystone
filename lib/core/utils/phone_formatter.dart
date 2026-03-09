import '../errors/validation_exception.dart';

class PhoneFormatter {
  PhoneFormatter._();

  static String normalize(String input) {
    // Remove spaces, dashes, parentheses
    String cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Already in E.164 format
    if (cleaned.startsWith('+233') && cleaned.length == 13) {
      return cleaned;
    }

    // 233XXXXXXXXX format (no +)
    if (cleaned.startsWith('233') && cleaned.length == 12) {
      return '+$cleaned';
    }

    // 0XXXXXXXXX format (local)
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return '+233${cleaned.substring(1)}';
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

  // Format for display: +233244123456 → 0244 123 456
  static String display(String normalized) {
    if (normalized.startsWith('+233') && normalized.length == 13) {
      final local = '0${normalized.substring(4)}';
      return '${local.substring(0, 4)} ${local.substring(4, 7)} ${local.substring(7)}';
    }
    return normalized;
  }
}
