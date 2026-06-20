import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_provider.dart';
import '../network/connectivity_service.dart';
import '../storage/hive_service.dart';
import '../services/internal_auth/internal_auth_service.dart';
import '../services/internal_auth/secure_vault_service.dart';

import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/domain/entities/user_entity.dart';

class AuthState {
  final Session? session;
  final bool hasProfile;
  final bool isLoading;
  final bool needsPasswordUpgrade;
  final bool isLocallyUnlocked;
  final bool isSessionStale;
  final bool setupComplete;
  const AuthState({
    this.session,
    this.hasProfile = false,
    this.isLoading = false,
    this.needsPasswordUpgrade = false,
    this.isLocallyUnlocked = false,
    this.isSessionStale = false,
    this.setupComplete = false,
  });
  bool get isAuthenticated => session != null;
  AuthState copyWith({
    Session? session,
    bool? hasProfile,
    bool? isLoading,
    bool? needsPasswordUpgrade,
    bool? isLocallyUnlocked,
    bool? isSessionStale,
    bool? setupComplete,
  }) {
    return AuthState(
      session: session ?? this.session,
      hasProfile: hasProfile ?? this.hasProfile,
      isLoading: isLoading ?? this.isLoading,
      needsPasswordUpgrade: needsPasswordUpgrade ?? this.needsPasswordUpgrade,
      isLocallyUnlocked: isLocallyUnlocked ?? this.isLocallyUnlocked,
      isSessionStale: isSessionStale ?? this.isSessionStale,
      setupComplete: setupComplete ?? this.setupComplete,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final supabase = ref.read(supabaseClientProvider);
    final session = supabase.auth.currentSession;
    if (session == null) {
      debugPrint('[KS:AUTH_STATE] no session — unauthenticated');
      return const AuthState();
    }
    debugPrint('[KS:AUTH_STATE] session found — userId: ${session.user.id}');

    // ── Session recovery guard (HI-006) ──
    // GoTrueClient.recoverSession() runs fire-and-forget during initialization.
    // The persisted session in currentSession may be expired/stale. Subscribe
    // briefly to catch a late signedOut event from a failed recovery.
    // If no signedOut within 5s, proceed with the cached session (offline-safe).
    // If signedOut fires and we have network, the session is truly dead.
    //
    // OPTIMIZATION: If currentSession already exists locally, skip the 5s wait.
    // The session was persisted from a previous app life — no need to poll for
    // a late signedOut that already would have fired during initialization.
    // This reduces cold start latency from ~5.5s to ~50ms for returning users.
    bool signedOut = false;
    final currentSession = supabase.auth.currentSession;
    if (currentSession == null) {
      final signedOutReceived = Completer<void>();
      StreamSubscription? authSub;
      try {
        authSub = supabase.auth.onAuthStateChange.listen((event) {
          if (event.event == AuthChangeEvent.signedOut) {
            debugPrint('[KS:AUTH_STATE] session recovery failed (signedOut)');
            signedOut = true;
            signedOutReceived.complete();
          }
        });
        await signedOutReceived.future.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        // No signedOut within 5s → session recovery succeeded or offline
        debugPrint('[KS:AUTH_STATE] no signedOut within 5s — session is usable');
      } finally {
        await authSub?.cancel();
      }
    } else {
      debugPrint('[KS:AUTH_STATE] local session found — skipping 5s recovery wait');
    }

    // ── Persistent auth listener ──
    // Catches late signedOut events (token refresh failure, server-side
    // revocation, password change) after the initial 5s recovery window.
    final persistentSub = supabase.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedOut) {
        debugPrint('[KS:AUTH_STATE] persistent listener — signedOut received');
        ref.invalidateSelf();
      }
    });
    ref.onDispose(() => persistentSub.cancel());

    if (signedOut) {
      final connectivity = ConnectivityService();
      final isOnline = await connectivity.isConnected;
      if (isOnline) {
        debugPrint('[KS:AUTH_STATE] online + signedOut → session truly dead');
        return const AuthState();
      }
      // Offline: accept cached session but mark as stale
      debugPrint('[KS:AUTH_STATE] offline + signedOut → marking session as stale');
      return AuthState(session: session, isSessionStale: true);
    }

    // Detect if user needs password upgrade (signed up via phone-only OTP)
    bool needsUpgrade = await _needsPasswordUpgrade(session);
    debugPrint('[KS:AUTH_STATE] needsPasswordUpgrade: $needsUpgrade');

    // ── Auto-ensure public.users row exists + fetch profile in parallel ──
    // These two DB operations are independent (different tables) so running
    // them concurrently cuts one network round trip from the auth flow.
    Future<void> _ensureUser() async {
      try {
        await supabase.from('users').upsert({
          'auth_id': session.user.id,
          'full_name': session.user.userMetadata?['name'] ?? 'User',
          'profile_slug': session.user.id.replaceAll('-', '').substring(0, 20),
        }, onConflict: 'auth_id');
      } catch (_) {
        // Non-critical — if it fails, onboarding will create the row
        debugPrint('[KS:AUTH_STATE] ensureUser upsert failed (non-critical)');
      }
    }

    Future<Map<String, dynamic>?> _fetchProfile() async {
      try {
        return await supabase
            .from('profiles')
            .select()
            .eq('user_id', session.user.id)
            .maybeSingle();
      } catch (e) {
        debugPrint('[KS:AUTH_STATE] profile fetch ERROR — $e');
        final cachedProfile = HiveService.profile.get('current_profile');
        if (cachedProfile != null) {
          debugPrint('[KS:AUTH_STATE] profile found in cache');
          return cachedProfile as Map<String, dynamic>?;
        }
        return null;
      }
    }

    final results = await Future.wait([
      _ensureUser(),
      _fetchProfile(),
    ]);
    final profile = results[1] as Map<String, dynamic>?;
    debugPrint('[KS:AUTH_STATE] hasProfile: ${profile != null}');

    // Cross-check identities with profile:
    // If user has only phone identities but profile says password exists,
    // trust the profile — Supabase never creates a password identity
    // when setting a password on a phone-only account.
    final profilePasswordCreated = profile != null && profile['password_created'] == true;
    if (needsUpgrade && profilePasswordCreated) {
      needsUpgrade = false;
      debugPrint('[KS:AUTH_STATE] cross-check: profile says password_created=true → no upgrade needed');
    }
    debugPrint('[KS:AUTH_STATE] profile password_created: $profilePasswordCreated → needsUpgrade: $needsUpgrade');
    final effectiveNeedsUpgrade = needsUpgrade;

    await InternalAuthService.markSync();
    // Self-heal any corrupted vault states before reading
    final vault = SecureVaultService();
    await vault.healVaultState();
    // Auto-unlock if user has no local credentials enrolled
    final hasCredentials = await vault.hasAnyCredentials();
    final locallyUnlocked = !hasCredentials;
    debugPrint('[KS:AUTH_STATE] vault hasCredentials: $hasCredentials → locallyUnlocked: $locallyUnlocked');

    // Derive setup_complete from profile (primary) or local cache (fallback)
    final hiveSetupDone = HiveService.auth.get('setup_complete') as bool? ?? false;
    final setupComplete = (profile != null && profile['setup_complete'] == true) || hiveSetupDone;

    return AuthState(
      session: session,
      hasProfile: profile != null,
      needsPasswordUpgrade: effectiveNeedsUpgrade,
      isLocallyUnlocked: locallyUnlocked,
      setupComplete: setupComplete,
    );
  }

  Future<bool> _needsPasswordUpgrade(Session session) async {
    final identities = session.user.identities;
    if (identities == null) return false;
    
    // If user has any non-phone identity, they definitely have a password
    final hasNonPhoneIdentity = identities.any((id) => id.provider != 'phone');
    if (hasNonPhoneIdentity) return false;
    
    // All identities are phone — query database for password_created
    try {
      final supabase = ref.read(supabaseClientProvider);
      final profile = await supabase
          .from('profiles')
          .select('password_created')
          .eq('user_id', session.user.id)
          .maybeSingle();
      
      if (profile != null && profile['password_created'] == true) {
        debugPrint('[KS:AUTH_STATE] _needsPasswordUpgrade: phone-only identity but DB says password_created=true → no upgrade needed');
        return false;
      }
    } catch (e) {
      debugPrint('[KS:AUTH_STATE] _needsPasswordUpgrade: DB query failed — $e');
    }
    
    // Default: phone-only identities need password upgrade
    return true;
  }

  void setLocallyUnlocked(bool value) {
    debugPrint('[KS:AUTH_STATE] setLocallyUnlocked: $value');
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(isLocallyUnlocked: value));
  }

  Future<void> refresh() async {
    debugPrint('[KS:AUTH_STATE] refresh called');
    ref.invalidateSelf();
  }

  Future<void> signOut() async {
    debugPrint('[KS:AUTH_STATE] signOut called');
    await HiveService.clearAll();
    final internalAuth = InternalAuthService(ref.read(supabaseClientProvider));
    await internalAuth.clearVault();
    final supabase = ref.read(supabaseClientProvider);
    await supabase.auth.signOut();
    debugPrint('[KS:AUTH_STATE] signOut complete');
    ref.invalidateSelf();
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final authStateAsync = ref.watch(authStateProvider);
  final session = authStateAsync.valueOrNull?.session;
  if (session == null) return null;
  
  final entity = await ref.watch(authRepositoryProvider).getCurrentUser();
  if (entity == null) return null;

  // Use authId as the primary identifier — all FK references in other tables
  // (jobs, inventory, recurring_schedules, etc.) store auth_id, not internal users.id.
  return UserEntity(
    id: entity.authId ?? entity.id,
    authId: entity.authId,
    fullName: entity.fullName,
    phoneNumber: entity.phoneNumber,
    email: entity.email,
    role: entity.role,
    status: entity.status,
    profileSlug: entity.profileSlug,
    lastSeenAt: entity.lastSeenAt,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );
});
