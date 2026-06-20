import 'app_exception.dart';

class DuplicateCustomerException extends AppException {
  final String existingCustomerId;
  final String existingCustomerName;
  const DuplicateCustomerException({
    required String message,
    required this.existingCustomerId,
    required this.existingCustomerName,
  }) : super(
    message: message,
    code: 'DUPLICATE_CUSTOMER',
  );
}
