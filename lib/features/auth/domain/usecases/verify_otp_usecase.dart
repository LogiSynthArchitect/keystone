import '../../../../core/errors/validation_exception.dart';
import '../../../../core/usecases/use_case.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpParams {
  final String phoneNumber;
  final String token;
  const VerifyOtpParams({required this.phoneNumber, required this.token});
}

class VerifyOtpUsecase implements UseCase<void, VerifyOtpParams> {
  final AuthRepository _repository;
  VerifyOtpUsecase(this._repository);

  @override
  Future<void> call(VerifyOtpParams params) async {
    if (params.token.trim().isEmpty) {
      throw const ValidationException(
        message: 'Please enter the OTP sent to your phone.',
        code: 'OTP_REQUIRED',
        field: 'otp',
      );
    }
    if (params.token.length != 6) {
      throw const ValidationException(
        message: 'OTP must be 6 digits.',
        code: 'OTP_INVALID_LENGTH',
        field: 'otp',
      );
    }

    // Normalize phone number to E.164 before repository call
    final normalizedPhone = PhoneFormatter.normalize(params.phoneNumber);

    await _repository.verifyOtp(
      phoneNumber: normalizedPhone,
      token: params.token,
    );
  }
}
