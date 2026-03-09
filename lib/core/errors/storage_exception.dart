import 'app_exception.dart';

class StorageException extends AppException {
  const StorageException({
    required super.message,
    required super.code,
    super.cause,
  });
}
