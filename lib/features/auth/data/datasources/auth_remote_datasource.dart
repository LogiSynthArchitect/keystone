import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/auth_exception.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final supa.SupabaseClient _supabase;
  AuthRemoteDatasource(this._supabase);

  Future<void> requestOtp(String phone) async {
    debugPrint('[KS:AUTH] requestOtp — phone: $phone');
    try {
      // Send OTP via edge function (triggers SMS + sets test OTP via Mgmt API).
      // We must await this — if it fails, the user never receives a code.
      await _supabase.functions.invoke(
        'send-login-otp',
        body: {'phone': phone},
      );

      // Notify Supabase Auth of the OTP attempt so verifyOTP is tracked.
      // This is best-effort; the test OTP was already set by the edge function.
      try {
        await _supabase.auth.signInWithOtp(phone: phone);
      } catch (e) {
        debugPrint('[KS:AUTH] signInWithOtp failed (non-fatal): $e');
      }
      debugPrint('[KS:AUTH] requestOtp SUCCESS');
    } catch (e) {
      final msg = e.toString();
      debugPrint('[KS:AUTH] requestOtp error — $msg');
      // Edge function failure (FunctionsException from functions_client)
      if (msg.contains('FunctionsException') || msg.contains('functions error')) {
        throw const NetworkException(
          message: 'Could not send verification code. Please try again.',
          code: 'OTP_SEND_FAILED',
        );
      }
      throw const NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION');
    }
  }

  Future<Map<String, dynamic>> checkAuthState(String phone) async {
    debugPrint('[KS:AUTH] checkAuthState — phone: $phone');
    try {
      final result = await _supabase.rpc('check_auth_state', params: {'p_phone': phone});
      debugPrint('[KS:AUTH] checkAuthState — result: $result');
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      debugPrint('[KS:AUTH] checkAuthState error — $e');
      // Fail safe — assume new user, let OTP flow handle it
      return {'exists': false, 'has_password': false};
    }
  }

  Future<supa.Session> verifyOtp(String phone, String token) async {
    debugPrint('[KS:AUTH] verifyOtp — phone: $phone, token: $token');
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: supa.OtpType.sms,
      ).timeout(const Duration(seconds: 30));
      
      if (response.session == null) {
        throw const AuthException(message: 'Verification failed.', code: 'VERIFICATION_FAILED');
      }

      debugPrint('[KS:AUTH] verifyOtp SUCCESS');
      return response.session!;
    } on supa.AuthException catch (e) {
      debugPrint('[KS:AUTH] verifyOtp AuthException — ${e.message}');
      throw AuthException(message: e.message, code: '${e.statusCode}');
    } catch (e) {
      debugPrint('[KS:AUTH] verifyOtp unknown error — $e');
      throw const NetworkException(message: 'No internet connection.', code: 'NO_CONNECTION');
    }
  }

  Future<UserModel> createUser({required String authId, required String name, required String phone}) async {
    debugPrint('[KS:AUTH] createUser — authId: $authId, name: $name');
    final baseSlug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .substring(0, name.length.clamp(1, 40));
    final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final slug = '$baseSlug-${suffix.substring(suffix.length - 4)}';
    debugPrint('[KS:AUTH] createUser — phone: $phone, slug: $slug');
    try {
      debugPrint('[KS:AUTH] createUser — attempting upsert...');
      final data = await _supabase.from('users').upsert({
        'auth_id': authId,
        'full_name': name,
        'phone_number': phone,
        'profile_slug': slug,
      }, onConflict: 'auth_id').select().single();
      debugPrint('[KS:AUTH] createUser SUCCESS — data: $data');
      return UserModel.fromJson(data);
    } on supa.PostgrestException catch (e) {
      debugPrint('[KS:AUTH] createUser PostgrestException — msg: "${e.message}" code: ${e.code} details: ${e.details} hint: ${e.hint}');
      debugPrint('[KS:AUTH] createUser PostgrestException — full: $e');
      throw NetworkException(message: 'Could not create user record: ${e.message}', code: 'USER_CREATE_FAILED', cause: e);
    } catch (e, s) {
      debugPrint('[KS:AUTH] createUser unknown error — $e');
      debugPrint('[KS:AUTH] createUser stack — $s');
      throw NetworkException(message: 'Could not create user record: $e', code: 'USER_CREATE_FAILED');
    }
  }

  Future<UserModel?> getCurrentUser(String authId) async {
    debugPrint('[KS:AUTH] getCurrentUser — authId: $authId');
    try {
      final data = await _supabase.from('users').select().eq('auth_id', authId).maybeSingle();
      debugPrint('[KS:AUTH] getCurrentUser — found: ${data != null}');
      return data != null ? UserModel.fromJson(data) : null;
    } catch (e) {
      debugPrint('[KS:AUTH] getCurrentUser error — $e');
      return null;
    }
  }

  Future<void> logout() async => await _supabase.auth.signOut();
}
