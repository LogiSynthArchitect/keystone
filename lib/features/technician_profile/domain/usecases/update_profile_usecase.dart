import '../../../../core/errors/validation_exception.dart';
import '../../../../core/usecases/use_case.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUsecase implements UseCase<ProfileEntity, ProfileEntity> {
  final ProfileRepository _repository;
  UpdateProfileUsecase(this._repository);

  @override
  Future<ProfileEntity> call(ProfileEntity profile) async {
    if (profile.displayName.trim().length < 2) {
      throw const ValidationException(
        message: 'Display name must be at least 2 characters.',
        code: 'NAME_TOO_SHORT',
        field: 'display_name',
      );
    }
    
    if (profile.services.isEmpty) {
      throw const ValidationException(
        message: 'Please select at least one service.',
        code: 'SERVICES_REQUIRED',
        field: 'services',
      );
    }

    if (!PhoneFormatter.isValid(profile.whatsappNumber)) {
      throw const ValidationException(
        message: 'Please enter a valid WhatsApp phone number.',
        code: 'WHATSAPP_INVALID',
        field: 'whatsapp_number',
      );
    }

    final normalizedProfile = profile.copyWith(
      whatsappNumber: PhoneFormatter.normalize(profile.whatsappNumber),
      updatedAt: DateTime.now(),
    );

    return _repository.updateProfile(normalizedProfile);
  }
}
