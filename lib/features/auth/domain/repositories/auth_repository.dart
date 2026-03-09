import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<void> requestOtp(String phoneNumber);
  Future<Session> verifyOtp({required String phoneNumber, required String token});
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> createUser({
    required String fullName,
    required String phoneNumber,
  });
}
