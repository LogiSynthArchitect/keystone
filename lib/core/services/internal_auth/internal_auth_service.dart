import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:hive_flutter/hive_flutter.dart';
import '../../storage/hive_service.dart';
import 'models/auth_method.dart';
import 'models/unlock_result.dart';
import 'secure_vault_service.dart';
import 'biometric_service.dart';
import 'pin_service.dart';
import 'auth_token_manager.dart';

class InternalAuthService {
  late final SecureVaultService vault;
  late final BiometricService biometric;
  late final PinService pinService;
  late final AuthTokenManager tokenManager;
  final supa.SupabaseClient _supabase;

  InternalAuthService(this._supabase) {
    vault = SecureVaultService();
    biometric = BiometricService();
    pinService = PinService(vault);
    tokenManager = AuthTokenManager(vault, _supabase);
  }

  static const Duration _staleThreshold = Duration(hours: 24);

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

  DateTime? _lastOnlineSync() {
    final authBox = Hive.box('auth');
    final epoch = authBox.get(HiveService.lastOnlineSyncKey) as int?;
    if (epoch == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(epoch);
  }

  Future<UnlockResult> tryAutoLogin() async {
    final method = await vault.getEnrolledMethod();
    if (method == AuthMethod.none) {
      return UnlockNeedsNetwork('No local credentials stored.');
    }

    if (method == AuthMethod.biometric) {
      final matched = await biometric.authenticateWithBiometrics();
      if (!matched) return UnlockLocked('Biometric verification failed.');
    }

    if (method == AuthMethod.biometric || method == AuthMethod.pin) {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        return UnlockNeedsNetwork('Session expired. Please sign in.');
      }

      final authBox = Hive.box('auth');
      final storedCounter = authBox.get('sync_counter') as int? ?? 0;
      final lastUnlockCounter = authBox.get('last_unlock_counter') as int? ?? 0;

      if (storedCounter < lastUnlockCounter) {
        return UnlockNeedsOnline(
          lastSync: null,
          reason: 'Security check failed. Please reconnect to server.',
        );
      }
      await authBox.put('last_unlock_counter', storedCounter);

      final storedTs = authBox.get(HiveService.lastOnlineSyncKey) as int?;
      if (storedTs != null && DateTime.now().millisecondsSinceEpoch < storedTs) {
        return UnlockNeedsOnline(
          lastSync: null,
          reason: 'Clock mismatch detected. Please reconnect to verify.',
        );
      }

      final lastSync = _lastOnlineSync();
      if (lastSync == null || DateTime.now().difference(lastSync) > _staleThreshold) {
        return UnlockNeedsOnline(
          lastSync: lastSync,
          reason: 'Last verified ${_formatAge(lastSync)} ago. Reconnect to confirm.',
        );
      }
      return UnlockSuccess();
    }

    return UnlockNeedsNetwork('Password required.');
  }

  String _formatAge(DateTime? dt) {
    if (dt == null) return 'unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
  }

  Future<bool> unlockWithPin(String pin) async {
    return await pinService.verifyPin(pin);
  }

  Future<bool> enrollBiometric() async {
    final supported = await biometric.isDeviceSupported();
    if (!supported) return false;
    final canBio = await biometric.canCheckBiometrics();
    if (!canBio) return false;
    final matched = await biometric.authenticateWithBiometrics();
    if (matched) {
      await vault.storeEnrolledMethod(AuthMethod.biometric);
      await vault.storeHasBiometric(true);
      return true;
    }
    return false;
  }

  Future<void> enrollPin(String pin) async {
    await pinService.storePin(pin);
    await vault.storeEnrolledMethod(AuthMethod.pin);
  }

  Future<bool> enrollPassword(String phone, String password) async {
    try {
      await _supabase.auth.signUp(phone: phone, password: password);
      return true;
    } catch (e) {
      debugPrint('[KS:AUTH] signUp error: $e');
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
        await vault.storePhoneHash(_sha256Hex(phone));
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

  Future<void> clearVault() => vault.clearAll();

  String _sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
