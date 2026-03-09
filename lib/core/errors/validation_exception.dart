import 'app_exception.dart';

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    required super.code,
    super.field,
  });
}
