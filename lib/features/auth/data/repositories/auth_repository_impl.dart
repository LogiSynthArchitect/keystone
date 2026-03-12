import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/auth_exception.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  AuthRepositoryImpl(this._remote);

  @override
  Future<void> requestOtp(String phoneNumber) =>
      _remote.requestOtp(phoneNumber);

  @override
  Future<supa.Session> verifyOtp({
    required String phoneNumber,
    required String token,
  }) => _remote.verifyOtp(phoneNumber, token);

  @override
  Future<void> signOut() => _remote.logout();

  @override
  Future<UserEntity?> getCurrentUser() async {
    final authUser = supa.Supabase.instance.client.auth.currentUser;
    if (authUser == null) return null;
    final model = await _remote.getCurrentUser(authUser.id);
    return model?.toEntity();
  }

  @override
  Future<UserEntity> createUser({
    required String fullName,
    required String phoneNumber,
  }) async {
    final authUser = supa.Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      throw const AuthException(
        message: 'No authenticated session.',
        code: 'NO_SESSION',
      );
    }
    final model = await _remote.createUser(
      authId: authUser.id,
      name: fullName,
      phone: phoneNumber,
    );
    return model.toEntity();
  }
}
