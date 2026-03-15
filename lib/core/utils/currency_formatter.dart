class CurrencyFormatter {
  CurrencyFormatter._();

  static double? parse(String input) {
    if (input.isEmpty) return null;
    // Task 3: Harden Regex to strip all but digits and dots
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static String format(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'GHS $intPart.${parts[1]}';
  }

  static String formatShort(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final intPart = formatted.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'GHS $intPart';
  }
}
