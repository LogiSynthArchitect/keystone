import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/lock_provider.dart';
import '../providers/auth_provider.dart';
import '../router/route_names.dart';
import '../services/internal_auth/secure_vault_service.dart';


/// Foreground inactivity timeout in minutes.
const _kForegroundTimeout = Duration(minutes: 5);

/// Background grace period in minutes.
/// If the app is restored from background within this window, no lock is
/// triggered. Beyond this window, the lock overlay appears on resume.
const _kBackgroundGrace = Duration(minutes: 2);

/// Wraps the app content to monitor pointer events and app lifecycle for
/// inactivity-based auto-lock.
///
/// Behaviour:
/// - Resets a 5-minute timer on every pointer down event.
/// - On app resume from background: if elapsed > 2 min, triggers lock.
/// - When the lock overlay appears, the inactivity timer is stopped.
/// - When the lock overlay is dismissed, the timer restarts.
class InactivityLockWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const InactivityLockWrapper({super.key, required this.child});

  @override
  ConsumerState<InactivityLockWrapper> createState() =>
      _InactivityLockWrapperState();
}

class _InactivityLockWrapperState extends ConsumerState<InactivityLockWrapper>
    with WidgetsBindingObserver {
  Timer? _inactivityTimer;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  // ── Lifecycle Observer ───────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _backgroundedAt = DateTime.now();
        _inactivityTimer?.cancel();
      case AppLifecycleState.resumed:
        _onResume();
      default:
        break;
    }
  }

  void _onResume() {
    final bgd = _backgroundedAt;
    _backgroundedAt = null;

    if (bgd != null) {
      final elapsed = DateTime.now().difference(bgd);
      if (elapsed > _kBackgroundGrace) {
        _lockNow();
        return; // _lockNow handles timer restart on dismiss
      }
    }

    // Within grace period — restart inactivity timer
    _startInactivityTimer();
  }

  // ── Timer Management ─────────────────────────────────────────────────

  void _recordInteraction() {
    // Don't restart the timer if the lock overlay is already showing
    final isLocked = ref.read(lockProvider);
    if (isLocked) return;
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_kForegroundTimeout, _onInactivityTimeout);
  }

  void _onInactivityTimeout() {
    debugPrint('[KS:LOCK] foreground inactivity timer expired — locking');
    _lockNow();
  }

  Future<void> _lockNow() async {
    _inactivityTimer?.cancel();
    // Only lock if user has an enrolled local credential
    final vault = SecureVaultService();
    await vault.healVaultState();
    final hasCredentials = await vault.hasAnyCredentials();
    if (!hasCredentials) {
      debugPrint('[KS:LOCK] no enrolled credential — skipping lock');
      return;
    }
    ref.read(authStateProvider.notifier).setLocallyUnlocked(false);
    if (mounted) context.go(RouteNames.locked);
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Restart inactivity timer when user unlocks (isLocallyUnlocked flips
    // from false to true).
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (prev, next) {
      final wasLocked = prev?.valueOrNull?.isLocallyUnlocked == false;
      final nowUnlocked = next.valueOrNull?.isLocallyUnlocked == true;
      if (wasLocked && nowUnlocked && mounted) {
        _startInactivityTimer();
      }
    });

    return Listener(
      onPointerDown: (_) => _recordInteraction(),
      child: widget.child,
    );
  }
}
