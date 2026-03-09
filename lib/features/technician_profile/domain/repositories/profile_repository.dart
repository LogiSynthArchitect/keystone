import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<ProfileEntity?> getProfile();
  Future<ProfileEntity> createProfile(ProfileEntity profile);
  Future<ProfileEntity> updateProfile(ProfileEntity profile);
  Future<ProfileEntity?> getPublicProfile(String slug);
  Future<String> uploadPhoto(String filePath);
}
