import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/auth_method.dart';

class SecureVaultService {
  final FlutterSecureStorage _storage;

  SecureVaultService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  static const _keyPinHash = 'vault_pin_hash';
  static const _keyPinSalt = 'vault_pin_salt';
  static const _keyRefreshToken = 'vault_refresh_token';
  static const _keyEnrolledMethod = 'vault_enrolled_method';
  static const _keyPhoneHash = 'vault_phone_hash';
  static const _keyHasBiometric = 'vault_has_biometric';

  Future<void> storePinHash(String hash) =>
      _storage.write(key: _keyPinHash, value: hash);

  Future<String?> getPinHash() =>
      _storage.read(key: _keyPinHash);

  Future<void> storePinSalt(String salt) =>
      _storage.write(key: _keyPinSalt, value: salt);

  Future<String?> getPinSalt() =>
      _storage.read(key: _keyPinSalt);

  Future<void> storeRefreshToken(String token) =>
      _storage.write(key: _keyRefreshToken, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _keyRefreshToken);

  Future<void> storeEnrolledMethod(AuthMethod method) =>
      _storage.write(key: _keyEnrolledMethod, value: method.name);

  Future<AuthMethod> getEnrolledMethod() async {
    final raw = await _storage.read(key: _keyEnrolledMethod);
    if (raw == null) return AuthMethod.none;
    return AuthMethod.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => AuthMethod.none,
    );
  }

  Future<void> storePhoneHash(String hash) =>
      _storage.write(key: _keyPhoneHash, value: hash);

  Future<String?> getPhoneHash() =>
      _storage.read(key: _keyPhoneHash);

  Future<void> storeHasBiometric(bool value) =>
      _storage.write(key: _keyHasBiometric, value: value.toString());

  Future<bool> getHasBiometric() async {
    final raw = await _storage.read(key: _keyHasBiometric);
    return raw == 'true';
  }

  Future<bool> hasAnyCredentials() async {
    final method = await getEnrolledMethod();
    return method != AuthMethod.none;
  }

  Future<void> clearAll() => _storage.deleteAll();
}
