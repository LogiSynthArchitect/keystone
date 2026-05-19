import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'secure_vault_service.dart';

class AuthTokenManager {
  final SecureVaultService _vault;
  final supa.SupabaseClient _supabase;

  AuthTokenManager(this._vault, this._supabase);

  Future<void> storeSession(supa.Session session) async {
    if (session.refreshToken != null) {
      await _vault.storeRefreshToken(session.refreshToken!);
    }
  }

  Future<void> clearSession() async {
    await _vault.clearAll();
  }

  Future<bool> attemptRefresh() async {
    final token = await _vault.getRefreshToken();
    if (token == null) return false;
    try {
      final response = await _supabase.auth.refreshSession();
      if (response.session != null) {
        await storeSession(response.session!);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[KS:TOKEN] refresh failed: $e');
      return false;
    }
  }
}
