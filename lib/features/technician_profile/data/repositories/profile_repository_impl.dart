import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _remote;
  final SupabaseClient _supabase;

  ProfileRepositoryImpl(this._remote, this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  @override
  Future<ProfileEntity?> getProfile() async {
    final model = await _remote.getProfile(_userId);
    return model?.toEntity();
  }

  @override
  Future<ProfileEntity> createProfile(ProfileEntity profile) async {
    final model = await _remote.createProfile({
      'user_id': _userId,
      'display_name': profile.displayName,
      'bio': profile.bio,
      'photo_url': profile.photoUrl,
      'services': profile.services.map((s) => _serviceTypeToString(s)).toList(),
      'whatsapp_number': profile.whatsappNumber,
      'is_public': profile.isPublic,
      'profile_url': profile.profileUrl,
    });
    return model.toEntity();
  }

  @override
  Future<ProfileEntity> updateProfile(ProfileEntity profile) async {
    final model = await _remote.updateProfile(profile.id, {
      'display_name': profile.displayName,
      'bio': profile.bio,
      'photo_url': profile.photoUrl,
      'services': profile.services.map((s) => _serviceTypeToString(s)).toList(),
      'whatsapp_number': profile.whatsappNumber,
      'is_public': profile.isPublic,
    });
    return model.toEntity();
  }

  @override
  Future<ProfileEntity?> getPublicProfile(String slug) async {
    final model = await _remote.getPublicProfile(slug);
    return model?.toEntity();
  }

  @override
  Future<String> uploadPhoto(String filePath) =>
      _remote.uploadPhoto(userId: _userId, filePath: filePath);

  static String _serviceTypeToString(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return 'car_lock_programming';
      case ServiceType.doorLockInstallation:  return 'door_lock_installation';
      case ServiceType.doorLockRepair:        return 'door_lock_repair';
      case ServiceType.smartLockInstallation: return 'smart_lock_installation';
    }
  }
}
