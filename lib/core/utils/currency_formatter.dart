class CurrencyFormatter {
  CurrencyFormatter._();

  // Parse user input to double: "GHS 1,500" → 1500.00
  static double? parse(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'[GHSghs\s]'), '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned);
  }

  // Format for display: 1500.0 → GHS 1,500.00
  static String format(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'GHS $intPart.${parts[1]}';
  }

  // Short format for lists: 1500.0 → GHS 1,500
  static String formatShort(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final intPart = formatted.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'GHS $intPart';
  }
}
