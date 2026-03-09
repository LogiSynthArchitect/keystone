import 'app_exception.dart';

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    required super.code,
    super.cause,
  });
}
