import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/network_exception.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../models/profile_model.dart';

class ProfileRemoteDatasource {
  final SupabaseClient _supabase;
  final CloudinaryService _cloudinary;
  ProfileRemoteDatasource(this._supabase) : _cloudinary = CloudinaryService();

  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final data = await _supabase.from('profiles').select().eq('user_id', userId).maybeSingle();
      return data != null ? ProfileModel.fromJson(data) : null;
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not load profile.', code: 'PROFILE_FETCH_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<ProfileModel?> getProfileByPhone(String phone) async {
    try {
      final data = await _supabase.from('profiles').select().eq('whatsapp_number', phone).maybeSingle();
      return data != null ? ProfileModel.fromJson(data) : null;
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Profile lookup failed.', code: 'PROFILE_PHONE_FETCH_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'Connection lost.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<ProfileModel> createProfile(Map<String, dynamic> json) async {
    debugPrint('[KS:PROFILE] createProfile — userId: ${json['user_id']}');
    try {
      final data = await _supabase.from('profiles').insert(json).select().single();
      debugPrint('[KS:PROFILE] createProfile SUCCESS');
      return ProfileModel.fromJson(data);
    } on PostgrestException catch (e) {
      debugPrint('[KS:PROFILE] createProfile PostgrestException — ${e.message} (code: ${e.code})');
      throw NetworkException(message: 'Could not create profile.', code: 'PROFILE_CREATE_FAILED', cause: e);
    } catch (e) {
      debugPrint('[KS:PROFILE] createProfile unknown error — $e');
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
      final data = await _supabase.from('profiles').select().ilike('profile_url', '%$slug').eq('is_public', true).maybeSingle();
      return data != null ? ProfileModel.fromJson(data) : null;
    } on PostgrestException catch (e) {
      throw NetworkException(message: 'Could not load profile.', code: 'PROFILE_FETCH_FAILED', cause: e);
    } catch (e) {
      throw NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION', cause: e);
    }
  }

  Future<String> uploadPhoto({required String userId, required String filePath}) async {
    try {
      if (kIsWeb) {
        throw const NetworkException(message: 'Photo upload not supported on web.', code: 'WEB_UPLOAD_UNSUPPORTED');
      }

      final file = File(filePath);
      final cloudUrl = await _cloudinary.uploadMedia(
        file: file,
        publicId: 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (cloudUrl != null) return cloudUrl;

      final ext = filePath.split('.').last.toLowerCase();
      final path = '$userId/profile.$ext';
      await _supabase.storage.from(SupabaseConstants.profilePhotosBucket).upload(path, file, fileOptions: const FileOptions(upsert: true));
      final rawUrl = _supabase.storage.from(SupabaseConstants.profilePhotosBucket).getPublicUrl(path);
      return '$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException(message: 'Could not upload photo.', code: 'PHOTO_UPLOAD_FAILED', cause: e);
    }
  }
}
