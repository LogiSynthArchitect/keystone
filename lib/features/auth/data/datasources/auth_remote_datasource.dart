import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../../../core/errors/network_exception.dart';
import '../../../../core/errors/auth_exception.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final SupabaseClient _supabase;
  AuthRemoteDatasource(this._supabase);

  Future<void> requestOtp(String phoneNumber) async {
    debugPrint('[KS:AUTH] requestOtp — phone: $phoneNumber');
    try {
      await _supabase.auth.signInWithOtp(phone: phoneNumber);
      debugPrint('[KS:AUTH] requestOtp SUCCESS');
    } on AuthException catch (e) {
      debugPrint('[KS:AUTH] requestOtp AuthException — ${e.message}');
      throw AuthException(
        message: e.message,
        code: 'OTP_SEND_FAILED',
        cause: e,
      );
    } catch (e) {
      debugPrint('[KS:AUTH] requestOtp unknown error — $e');
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
    debugPrint('[KS:AUTH] verifyOtp — phone: $phoneNumber token: $token');
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );
      debugPrint('[KS:AUTH] verifyOTP response — session: ${response.session?.user.id}');
      if (response.session == null) {
        debugPrint('[KS:AUTH] verifyOtp FAILED — session is null');
        throw const AuthException(
          message: 'Invalid or expired OTP.',
          code: 'OTP_INVALID',
        );
      }
      debugPrint('[KS:AUTH] verifyOtp SUCCESS');
      return response.session!;
    } on AuthException catch (e) {
      debugPrint('[KS:AUTH] verifyOtp AuthException — ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[KS:AUTH] verifyOtp unknown error — $e');
      throw NetworkException(
        message: 'Could not verify OTP.',
        code: 'OTP_VERIFY_FAILED',
        cause: e,
      );
    }
  }

  Future<UserModel?> getCurrentUser(String authId) async {
    debugPrint('[KS:AUTH] getCurrentUser — authId: $authId');
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('auth_id', authId)
          .maybeSingle();
      debugPrint('[KS:AUTH] getCurrentUser — found: ${data != null}');
      return data != null ? UserModel.fromJson(data) : null;
    } on PostgrestException catch (e) {
      debugPrint('[KS:AUTH] getCurrentUser PostgrestException — $e');
      throw NetworkException(
        message: 'Could not load user.',
        code: 'USER_FETCH_FAILED',
        cause: e,
      );
    } catch (e) {
      debugPrint('[KS:AUTH] getCurrentUser unknown error — $e');
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
    debugPrint('[KS:AUTH] createUser — authId: $authId name: $fullName');
    try {
      final data = await _supabase.from('users').insert({
        'auth_id': authId,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'role': 'technician',
        'status': 'active',
      }).select().single();
      debugPrint('[KS:AUTH] createUser SUCCESS');
      return UserModel.fromJson(data);
    } on PostgrestException catch (e) {
      debugPrint('[KS:AUTH] createUser PostgrestException — $e');
      throw NetworkException(
        message: 'Could not create account.',
        code: 'USER_CREATE_FAILED',
        cause: e,
      );
    } catch (e) {
      debugPrint('[KS:AUTH] createUser unknown error — $e');
      throw NetworkException(
        message: 'Something went wrong.',
        code: 'UNKNOWN',
        cause: e,
      );
    }
  }

  Future<void> signOut() async {
    debugPrint('[KS:AUTH] signOut called');
    await _supabase.auth.signOut();
    debugPrint('[KS:AUTH] signOut complete');
  }
}
