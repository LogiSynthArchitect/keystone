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
