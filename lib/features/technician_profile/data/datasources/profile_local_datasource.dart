import '../../../../core/storage/hive_service.dart';
import '../models/profile_model.dart';

class ProfileLocalDatasource {
  Future<void> saveProfile(ProfileModel profile) async {
    final box = HiveService.profile;
    await box.put('current_profile', profile.toJson());
    await box.flush();
  }

  Future<ProfileModel?> getProfile() async {
    final box = HiveService.profile;
    final data = box.get('current_profile');
    if (data != null) {
      return ProfileModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<void> clearProfile() async {
    final box = HiveService.profile;
    await box.clear();
    await box.flush();
  }
}
