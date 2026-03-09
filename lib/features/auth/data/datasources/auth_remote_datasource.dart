import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../../../core/errors/network_exception.dart';
import '../../../../core/errors/auth_exception.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final SupabaseClient _supabase;
  AuthRemoteDatasource(this._supabase);

  Future<void> requestOtp(String phoneNumber) async {
    try {
      await _supabase.auth.signInWithOtp(phone: phoneNumber);
    } on AuthException catch (e) {
      throw AuthException(
        message: e.message,
        code: 'OTP_SEND_FAILED',
        cause: e,
      );
    } catch (e) {
      throw NetworkException(
        message: 'Could not send OTP. Check your connection.',
        code: 'NO_CONNECTION',
        cause: e,
      );
    }
  }

  Future<Session> verifyOtp({
    required String phoneNumber,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );
      if (response.session == null) {
        throw const AuthException(
          message: 'Invalid or expired OTP.',
          code: 'OTP_INVALID',
        );
      }
      return response.session!;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Could not verify OTP.',
        code: 'OTP_VERIFY_FAILED',
        cause: e,
      );
    }
  }

  Future<UserModel?> getCurrentUser(String authId) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('auth_id', authId)
          .maybeSingle();
      return data != null ? UserModel.fromJson(data) : null;
    } on PostgrestException catch (e) {
      throw NetworkException(
        message: 'Could not load user.',
        code: 'USER_FETCH_FAILED',
        cause: e,
      );
    } catch (e) {
      throw NetworkException(
        message: 'Something went wrong.',
        code: 'UNKNOWN',
        cause: e,
      );
    }
  }

  Future<UserModel> createUser({
    required String authId,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final data = await _supabase.from('users').insert({
        'auth_id': authId,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'role': 'technician',
        'status': 'active',
      }).select().single();
      return UserModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw NetworkException(
        message: 'Could not create account.',
        code: 'USER_CREATE_FAILED',
        cause: e,
      );
    } catch (e) {
      throw NetworkException(
        message: 'Something went wrong.',
        code: 'UNKNOWN',
        cause: e,
      );
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
