import '../../../../core/errors/validation_exception.dart';
import '../../../../core/usecases/use_case.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../repositories/auth_repository.dart';

class RequestOtpParams {
  final String phoneNumber;
  const RequestOtpParams({required this.phoneNumber});
}

class RequestOtpUsecase implements UseCase<void, RequestOtpParams> {
  final AuthRepository _repository;
  RequestOtpUsecase(this._repository);

  @override
  Future<void> call(RequestOtpParams params) async {
    if (params.phoneNumber.trim().isEmpty) {
      throw const ValidationException(
        message: 'Please enter your phone number.',
        code: 'PHONE_REQUIRED',
        field: 'phone_number',
      );
    }
    if (!PhoneFormatter.isValid(params.phoneNumber)) {
      throw const ValidationException(
        message: 'Please enter a valid Ghana phone number.',
        code: 'PHONE_INVALID',
        field: 'phone_number',
      );
    }
    final normalized = PhoneFormatter.normalize(params.phoneNumber);
    await _repository.requestOtp(normalized);
  }
}
