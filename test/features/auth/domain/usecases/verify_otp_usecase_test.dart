import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:keystone/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:keystone/core/errors/validation_exception.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late VerifyOtpUsecase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = VerifyOtpUsecase(mockRepository);
  });

  group('VerifyOtpUsecase', () {
    test('verifies valid 6 digit OTP successfully', () async {
      // TODO
    });

    test('throws ValidationException for empty OTP', () async {
      // TODO
    });

    test('throws ValidationException for OTP less than 6 digits', () async {
      // TODO
    });

    test('normalizes phone number before verification', () async {
      // TODO
    });
  });
}
