import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/profile_entity.dart';
import '../../../../core/constants/app_enums.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import 'package:keystone/features/technician_profile/data/datasources/profile_local_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _remote;
  final ProfileLocalDatasource _local;
  final SupabaseClient _supabase;

  ProfileRepositoryImpl(this._remote, this._local, this._supabase);

  String get _authUserId => _supabase.auth.currentUser?.id ?? '';

  @override
  Future<ProfileEntity?> getProfile() async {
    try {
      final model = await _remote.getProfile(_authUserId);
      if (model != null) {
        await _local.saveProfile(model);
        return model.toEntity();
      }
    } catch (_) {}
    
    final local = await _local.getProfile();
    return local?.toEntity();
  }

  @override
  Future<ProfileEntity?> getProfileByPhone(String phone) async {
    final model = await _remote.getProfileByPhone(phone);
    return model?.toEntity();
  }

  @override
  Future<ProfileEntity> createProfile(ProfileEntity profile) async {
    debugPrint('[KS:PROFILE_REPO] createProfile — internalUserId: ${profile.userId}');
    final model = await _remote.createProfile({
      'user_id': profile.userId,
      'display_name': profile.displayName,
      'bio': profile.bio,
      'photo_url': profile.photoUrl,
      'services': profile.services.map((s) => _serviceTypeToString(s)).toList(),
      'whatsapp_number': profile.whatsappNumber,
      'is_public': profile.isPublic,
      'profile_url': profile.profileUrl.contains('keystone.app/p/') 
          ? profile.profileUrl 
          : 'keystone.app/p/${profile.profileUrl}',
    });
    await _local.saveProfile(model);
    return model.toEntity();
  }

  @override
  Future<ProfileEntity> updateProfile(ProfileEntity profile) async {
    debugPrint('[KS:PROFILE_REPO] updateProfile — profileId: ${profile.id}');
    final model = await _remote.updateProfile(profile.id, {
      'display_name': profile.displayName,
      'bio': profile.bio,
      'photo_url': profile.photoUrl,
      'services': profile.services.map((s) => _serviceTypeToString(s)).toList(),
      'whatsapp_number': profile.whatsappNumber,
      'is_public': profile.isPublic,
    });
    await _local.saveProfile(model);
    return model.toEntity();
  }

  @override
  Future<ProfileEntity?> getPublicProfile(String slug) async {
    final model = await _remote.getPublicProfile(slug);
    return model?.toEntity();
  }

  @override
  Future<String> uploadPhoto(String filePath) =>
      _remote.uploadPhoto(userId: _authUserId, filePath: filePath);

  static String _serviceTypeToString(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return 'car_lock_programming';
      case ServiceType.doorLockInstallation:  return 'door_lock_installation';
      case ServiceType.doorLockRepair:        return 'door_lock_repair';
      case ServiceType.smartLockInstallation: return 'smart_lock_installation';
    }
  }
}
