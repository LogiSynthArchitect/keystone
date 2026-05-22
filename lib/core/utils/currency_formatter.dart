import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  /// Parses a string into pesewas (int).
  /// Multiplies the value by 100 to convert to int storage.
  static int? parseToPesewas(String input) {
    if (input.isEmpty) return null;
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    if (cleaned.isEmpty) return null;
    final val = double.tryParse(cleaned);
    if (val == null) return null;
    return (val * 100).round();
  }

  /// Formats pesewas (int) into GHS string with 2 decimals.
  static String format(int pesewas) {
    final amount = pesewas / 100.0;
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'GHS $intPart.${parts[1]}';
  }

  /// Formats pesewas (int) into GHS string without decimals (truncates, does not round).
  static String formatShort(int pesewas) {
    final intPart = (pesewas ~/ 100).toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'GHS $intPart';
  }
}

/// Formats pricing input as user types.
/// - Allows only digits and one decimal point
/// - Limits decimal places to 2
class CurrencyInputFormatter extends TextInputFormatter {
  /// Max integer digits to prevent overflow (GHS 999,999).
  static const int _maxIntegerDigits = 6;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow empty
    if (text.isEmpty) return newValue;

    // Only digits and at most one '.'
    final filtered = StringBuffer();
    bool hasDot = false;
    int decimalDigits = 0;
    bool afterDot = false;
    int integerDigits = 0;
    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == '.') {
        if (hasDot) continue;
        hasDot = true;
        afterDot = true;
        decimalDigits = 0;
        filtered.write(ch);
      } else if (ch == '0' || (ch.codeUnitAt(0) >= 49 && ch.codeUnitAt(0) <= 57)) {
        if (afterDot) {
          if (decimalDigits < 2) {
            decimalDigits++;
            filtered.write(ch);
          }
        } else {
          if (integerDigits < _maxIntegerDigits) {
            integerDigits++;
            filtered.write(ch);
          }
        }
      }
    }

    final result = filtered.toString();
    if (result == oldValue.text) return oldValue;
    return newValue.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

/// Returns a [FocusNode] with a listener that formats the controller's
/// text to 2 decimal places on focus loss.
FocusNode currencyFocusNode(TextEditingController controller) {
  final node = FocusNode();
  node.addListener(() {
    if (!node.hasFocus && controller.text.isNotEmpty) {
      final val = double.tryParse(controller.text);
      if (val != null) {
        controller.text = val.toStringAsFixed(2);
      }
    }
  });
  return node;
}
