import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/auth/domain/usecases/request_otp_usecase.dart';
import 'package:keystone/core/errors/validation_exception.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late RequestOtpUsecase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = RequestOtpUsecase(mockRepository);
  });

  group('RequestOtpUsecase', () {
    test('sends OTP for valid Ghana phone number', () async {
      // TODO
    });

    test('throws ValidationException for empty phone number', () async {
      // TODO
    });

    test('throws ValidationException for invalid phone number', () async {
      // TODO
    });

    test('normalizes phone number before sending OTP', () async {
      // TODO
    });
  });
}
