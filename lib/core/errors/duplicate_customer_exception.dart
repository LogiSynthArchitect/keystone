class DuplicateCustomerException implements Exception {
  final String message;
  final String existingCustomerId;
  final String existingCustomerName;
  const DuplicateCustomerException({
    required this.message,
    required this.existingCustomerId,
    required this.existingCustomerName,
  });
}
