import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../services/internal_auth/secure_vault_service.dart';
import '../services/internal_auth/models/auth_method.dart';

/// Manages the lock overlay visibility state.
///
/// - [show]: Triggers the lock overlay if the user has an enrolled local
///   credential (PIN or biometric). Users with no local credentials are
///   never locked — there is nothing to unlock with.
/// - [hide]: Dismisses the lock overlay after successful unlock.
final lockProvider = NotifierProvider<LockNotifier, bool>(LockNotifier.new);

class LockNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Show the lock overlay. Only locks if the user has an enrolled credential.
  Future<void> show() async {
    final vault = SecureVaultService();
    final method = await vault.getEnrolledMethod();
    if (method == AuthMethod.none) {
      debugPrint('[KS:LOCK] no enrolled credential — skipping lock');
      return;
    }
    debugPrint('[KS:LOCK] locking — method: ${method.label}');
    ref.read(authStateProvider.notifier).setLocallyUnlocked(false);
    state = true;
  }

  /// Dismiss the lock overlay after successful unlock.
  void hide({required bool isUnlocked}) {
    debugPrint('[KS:LOCK] hiding — isUnlocked: $isUnlocked');
    if (isUnlocked) {
      ref.read(authStateProvider.notifier).setLocallyUnlocked(true);
    }
    state = false;
  }
}
