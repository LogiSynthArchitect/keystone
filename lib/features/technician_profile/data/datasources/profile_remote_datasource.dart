import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/network_exception.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../models/profile_model.dart';

class ProfileRemoteDatasource {
  final SupabaseClient _supabase;
  ProfileRemoteDatasource(this._supabase);

  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return data != null ? ProfileModel.fromJson(data) : null;
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not load profile.', code: 'PROFILE_FETCH_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<ProfileModel> createProfile(Map<String, dynamic> json) async {
    try {
      final data = await _supabase.from('profiles').insert(json).select().single();
      return ProfileModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not create profile.', code: 'PROFILE_CREATE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<ProfileModel> updateProfile(String id, Map<String, dynamic> json) async {
    try {
      final data = await _supabase.from('profiles').update(json).eq('id', id).select().single();
      return ProfileModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not update profile.', code: 'PROFILE_UPDATE_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<ProfileModel?> getPublicProfile(String slug) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('profile_url', 'keystone.app/$slug')
          .eq('is_public', true)
          .maybeSingle();
      return data != null ? ProfileModel.fromJson(data) : null;
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not load profile.', code: 'PROFILE_FETCH_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<String> uploadPhoto({required String userId, required String filePath}) async {
    try {
      final file = File(filePath);
      final ext = filePath.split('.').last;
      final path = '$userId/profile.$ext';
      await _supabase.storage
          .from(SupabaseConstants.profilePhotosBucket)
          .upload(path, file, fileOptions: const FileOptions(upsert: true));
      return _supabase.storage
          .from(SupabaseConstants.profilePhotosBucket)
          .getPublicUrl(path);
    } catch (e) {
      throw NetworkException(message: 'Could not upload photo.', code: 'PHOTO_UPLOAD_FAILED', cause: e);
    }
  }
}
