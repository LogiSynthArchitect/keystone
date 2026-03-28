import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/auth_exception.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  AuthRepositoryImpl(this._remote);

  // Cache the user profile so offline sessions can still resolve the current user.
  UserEntity? _cachedUser;

  @override
  Future<void> requestOtp(String phoneNumber) =>
      _remote.requestOtp(phoneNumber);

  @override
  Future<supa.Session> verifyOtp({
    required String phoneNumber,
    required String token,
  }) => _remote.verifyOtp(phoneNumber, token);

  @override
  Future<void> signOut() async {
    _cachedUser = null;
    await _remote.logout();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final authUser = supa.Supabase.instance.client.auth.currentUser;
    if (authUser == null) return null;
    // Validate cache belongs to the current session before returning it.
    // authId is nullable — if null or mismatched, treat cache as stale.
    if (_cachedUser != null) {
      final cachedAuthId = _cachedUser!.authId;
      if (cachedAuthId == null || cachedAuthId != authUser.id) {
        _cachedUser = null;
      }
    }
    if (_cachedUser != null) return _cachedUser;
    final model = await _remote.getCurrentUser(authUser.id);
    if (model != null) _cachedUser = model.toEntity();
    return _cachedUser;
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
