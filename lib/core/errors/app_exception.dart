abstract class AppException implements Exception {
  final String message;
  final String code;
  final String? field;
  final Object? cause;

  const AppException({
    required this.message,
    required this.code,
    this.field,
    this.cause,
  });

  @override
  String toString() => 'AppException($code): $message';
}
