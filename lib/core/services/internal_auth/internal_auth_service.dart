import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:hive_flutter/hive_flutter.dart';
import '../../config/dev_mode.dart';
import '../../storage/hive_service.dart';

import 'models/auth_method.dart';
import 'models/unlock_result.dart';
import 'secure_vault_service.dart';
import 'pin_service.dart';
import 'biometric_service.dart';
import 'auth_token_manager.dart';

/// Re-export so UI callers only need one import.
export 'biometric_service.dart' show BiometricAuthException;

class InternalAuthService {
  static bool _isAuthenticating = false;

  late final SecureVaultService vault;
  late final BiometricService biometric;
  late final AuthTokenManager tokenManager;
  late final PinService pin;
  final supa.SupabaseClient _supabase;

  InternalAuthService(this._supabase) {
    vault = SecureVaultService();
    biometric = BiometricService();
    tokenManager = AuthTokenManager(vault, _supabase);
    pin = PinService(vault);
  }

  Future<AuthMethod> getEnrolledMethod() => vault.getEnrolledMethod();

  Future<bool> hasAnyCredentials() => vault.hasAnyCredentials();

  static Future<void> markSync() async {
    final authBox = Hive.box('auth');
    final counter = (authBox.get('sync_counter') as int? ?? 0) + 1;
    await authBox.putAll({
      HiveService.lastOnlineSyncKey: DateTime.now().millisecondsSinceEpoch,
      'sync_counter': counter,
    });
  }

  Future<UnlockResult> tryAutoLogin() async {
    final hasBio = await vault.getHasBiometric();
    final pinHash = await vault.getPinHash();

    if (!hasBio && pinHash == null) {
      return UnlockNeedsNetwork('No local credentials stored.');
    }

    // Always show LockedScreen so user can CHOOSE their unlock method.
    // Auto-trying biometric traps users on devices where fingerprint fails
    // or is unavailable — the system dialog has no PIN/password fallback.
    return UnlockLocked('Unlock required.');
  }

  /// Unlock using biometric (system). PIN unlock uses [unlockWithPin].
  Future<bool> unlockWithDeviceAuth() async {
    try {
      final method = await vault.getEnrolledMethod();
      final hasBiometric = await vault.getHasBiometric();
      // Check both the enrolled method AND the persistent biometric flag —
      // PIN enrollment overwrites the method to AuthMethod.pin but the
      // biometric flag persists, so the fingerprint dialog still works.
      if (method == AuthMethod.biometric || hasBiometric) {
        // Guard against stale flag: if device no longer has biometrics,
        // clear flag and fall back to device credentials
        if (await biometric.canCheckBiometrics() && await biometric.isDeviceSupported()) {
          return biometric.authenticateWithBiometrics();
        }
        // Stale flag — clear it and fall through to device credentials
        debugPrint('[KS:AUTH] biometric flag stale — no biometrics available on device');
        await vault.storeHasBiometric(false);
        if (method == AuthMethod.biometric) {
          await vault.storeEnrolledMethod(AuthMethod.none);
        }
      }
      // Fallback: system credential auth
      return biometric.authenticateWithDeviceCredentials();
    } on BiometricAuthException {
      rethrow;
    } catch (e) {
      debugPrint('[KS:AUTH] unlockWithDeviceAuth error: $e');
      return false;
    }
  }

  /// Unlock using app-internal custom PIN via [PinService].
  Future<UnlockResult> unlockWithPin(String code) async {
    try {
      final ok = await pin.verifyPin(code);
      if (ok) return UnlockSuccess();
      final remaining = await pin.getRemainingAttempts();
      if (remaining <= 0) {
        return UnlockNeedsOnline(
          lastSync: null,
          reason: 'PIN wiped after too many attempts. Sign in with password.',
        );
      }
      return UnlockLocked('Wrong PIN. $remaining attempt(s) remaining.');
    } on PinWipedException {
      return UnlockNeedsOnline(
        lastSync: null,
        reason: 'PIN wiped after too many attempts. Sign in with password.',
      );
    }
  }

  Future<bool> enrollBiometric() async {
    try {
      final supported = await biometric.isDeviceSupported();
      if (!supported) return false;
      final canBio = await biometric.canCheckBiometrics();
      if (!canBio) return false;
      final matched = await biometric
          .authenticateWithBiometrics()
          .timeout(const Duration(seconds: 30))
          .catchError((e) {
        if (e is TimeoutException) {
          debugPrint('[KS:AUTH] biometric auth timeout — falling back');
          return false;
        }
        throw e;
      });
      if (matched) {
        // If PIN already exists, keep it. Only set method to biometric
        // as the preferred method (tried first). The PIN hash stays.
        final pinHash = await vault.getPinHash();
        if (pinHash == null) {
          await vault.storeEnrolledMethod(AuthMethod.biometric);
        } else {
          // Both exist: biometric is preferred, PIN stays as fallback
          await vault.storeEnrolledMethod(AuthMethod.biometric);
        }
        await vault.storeHasBiometric(true);
        return true;
      }
      return false;
    } on BiometricAuthException {
      rethrow;
    } catch (e) {
      debugPrint('[KS:AUTH] enrollBiometric error: $e');
      return false;
    }
  }

  /// Enroll a custom app PIN — hashes via [PinService] and stores method.
  Future<bool> enrollPin(String code) async {
    final ok = await pin.enrollPin(code);
    if (ok) {
      await vault.storeEnrolledMethod(AuthMethod.pin);
      // Do NOT touch has_biometric flag — fingerprint stays enrolled if it was set.
    }
    return ok;
  }

  Future<bool> enrollPassword(String phone, String password) async {
    try {
      if (kDevMode) {
        debugPrint('[KS:AUTH:DEV] enrollPassword bypass — no-op');
        return true;
      }
      await _supabase.auth.updateUser(
        supa.UserAttributes(password: password),
      );
      return true;
    } catch (e) {
      debugPrint('[KS:AUTH] enrollPassword error: $e');
      return false;
    }
  }

  Future<supa.Session?> verifyPassword(String phone, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        phone: phone,
        password: password,
      );
      if (response.session != null) {
        await tokenManager.storeSession(response.session!);
        await markSync();
      }
      return response.session;
    } catch (e) {
      debugPrint('[KS:AUTH] signInWithPassword error: $e');
      return null;
    }
  }

  Future<bool> upgradeAccount(String password) async {
    try {
      await _supabase.auth.updateUser(
        supa.UserAttributes(password: password),
      );
      await markSync();
      return true;
    } on supa.AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[KS:AUTH] upgradeAccount error: $e');
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        supa.UserAttributes(password: newPassword),
      );
      await markSync();
      return true;
    } catch (e) {
      debugPrint('[KS:AUTH] resetPassword error: $e');
      return false;
    }
  }

  /// Clear only biometric enrollment, preserving PIN if it exists.
  /// Used when user toggles biometric OFF in Security Settings.
  Future<void> clearBiometricOnly() async {
    await vault.storeHasBiometric(false);
    final pinHash = await vault.getPinHash();
    if (pinHash != null) {
      await vault.storeEnrolledMethod(AuthMethod.pin);
    } else {
      await vault.storeEnrolledMethod(AuthMethod.none);
    }
  }

  Future<void> clearVault() => vault.clearAll();

  /// Decode a JWT access token and check whether the `exp` claim has passed.
  static bool _isJwtExpired(String accessToken) {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return true;
      // Base64Url payload may need padding
      var payload = parts[1];
      final padding = 4 - payload.length % 4;
      if (padding != 4) payload += '=' * padding;
      final decoded = utf8.decode(base64Url.decode(payload));
      final data = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = data['exp'] as int?;
      if (exp == null) return false;
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp;
    } catch (e) {
      debugPrint('[KS:AUTH] _isJwtExpired error: $e');
      return true;
    }
  }

  /// Generate a random 16-byte salt.
  static String _generateSalt() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Hash input with PBKDF2-HMAC-SHA256 (100K iterations, salted).
  /// Reuses [pbkdf2HmacSha256] from pin_service for consistency.
  static String _hashWithKdf(String input, String salt) {
    final key = pbkdf2HmacSha256(
      hash: sha256,
      iterations: 100000,
      passphrase: utf8.encode(input),
      salt: utf8.encode(salt),
    );
    return base64Url.encode(key);
  }
}
