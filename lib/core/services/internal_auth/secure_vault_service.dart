import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/auth_method.dart';

class SecureVaultService {
  final FlutterSecureStorage _storage;

  SecureVaultService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  static const _keyRefreshToken = 'vault_refresh_token';
  static const _keyEnrolledMethod = 'vault_enrolled_method';
  static const _keyHasBiometric = 'vault_has_biometric';
  static const _keyPinHash = 'vault_pin_hash';
  static const _keyPinSalt = 'vault_pin_salt';
  static const _keyPinFailedAttempts = 'vault_pin_failed_attempts';

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

  Future<void> storeHasBiometric(bool value) =>
      _storage.write(key: _keyHasBiometric, value: value.toString());

  Future<bool> getHasBiometric() async {
    final raw = await _storage.read(key: _keyHasBiometric);
    return raw == 'true';
  }

  // ── PIN ──────────────────────────────────────────────────────────────

  Future<void> storePinHash(String hash) =>
      _storage.write(key: _keyPinHash, value: hash);

  Future<String?> getPinHash() =>
      _storage.read(key: _keyPinHash);

  Future<void> storePinSalt(String salt) =>
      _storage.write(key: _keyPinSalt, value: salt);

  Future<String?> getPinSalt() =>
      _storage.read(key: _keyPinSalt);

  Future<void> storePinFailedAttempts(int count) =>
      _storage.write(key: _keyPinFailedAttempts, value: count.toString());

  Future<int> getPinFailedAttempts() async {
    final raw = await _storage.read(key: _keyPinFailedAttempts);
    if (raw == null) return 0;
    return int.tryParse(raw) ?? 0;
  }

  /// Remove all PIN-related storage keys (used on wipe).
  Future<void> clearPinData() async {
    await _storage.delete(key: _keyPinHash);
    await _storage.delete(key: _keyPinSalt);
    await _storage.delete(key: _keyPinFailedAttempts);
  }

  Future<bool> hasAnyCredentials() async {
    final pinHash = await getPinHash();
    final hasBio = await getHasBiometric();
    return pinHash != null || hasBio;
  }

  /// Self-healing: detect and fix corrupted vault states where
  /// enrolled_method was overwritten by biometric enrollment
  /// but PIN hash still exists (or vice versa).
  Future<void> healVaultState() async {
    final pinHash = await getPinHash();
    final hasBio = await getHasBiometric();
    final method = await getEnrolledMethod();

    // Case 1: PIN exists, biometric doesn't, but method says biometric
    // → Fix: restore method to pin
    if (pinHash != null && !hasBio && method == AuthMethod.biometric) {
      await storeEnrolledMethod(AuthMethod.pin);
    }

    // Case 2: Biometric exists, PIN doesn't, but method says pin
    // → Fix: restore method to biometric
    if (hasBio && pinHash == null && method == AuthMethod.pin) {
      await storeEnrolledMethod(AuthMethod.biometric);
    }

    // Case 3: Both exist → prefer biometric (tried first)
    if (pinHash != null && hasBio) {
      await storeEnrolledMethod(AuthMethod.biometric);
    }
  }

  Future<void> clearAll() => _storage.deleteAll();
}
