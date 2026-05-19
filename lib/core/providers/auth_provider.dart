import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_provider.dart';
import '../storage/hive_service.dart';
import '../services/internal_auth/internal_auth_service.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/domain/entities/user_entity.dart';

class AuthState {
  final Session? session;
  final bool hasProfile;
  final bool isLoading;
  final bool needsPasswordUpgrade;
  const AuthState({
    this.session,
    this.hasProfile = false,
    this.isLoading = false,
    this.needsPasswordUpgrade = false,
  });
  bool get isAuthenticated => session != null;
  AuthState copyWith({
    Session? session,
    bool? hasProfile,
    bool? isLoading,
    bool? needsPasswordUpgrade,
  }) {
    return AuthState(
      session: session ?? this.session,
      hasProfile: hasProfile ?? this.hasProfile,
      isLoading: isLoading ?? this.isLoading,
      needsPasswordUpgrade: needsPasswordUpgrade ?? this.needsPasswordUpgrade,
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

    // Detect if user needs password upgrade (signed up via phone-only OTP)
    final needsUpgrade = _needsPasswordUpgrade(session);
    debugPrint('[KS:AUTH_STATE] needsPasswordUpgrade: $needsUpgrade');

    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('user_id', session.user.id)
          .maybeSingle();
      debugPrint('[KS:AUTH_STATE] hasProfile: ${profile != null}');

      // Override needsUpgrade if profile shows password was already created
      // (handles dev-bypass accounts where password is set via edge function)
      final passwordCreated = profile != null && profile['password_created'] == true;
      final effectiveNeedsUpgrade = passwordCreated ? false : needsUpgrade;
      debugPrint('[KS:AUTH_STATE] password_created: $passwordCreated → needsUpgrade: $effectiveNeedsUpgrade');

      await InternalAuthService.markSync();
      return AuthState(
        session: session,
        hasProfile: profile != null,
        needsPasswordUpgrade: effectiveNeedsUpgrade,
      );
    } catch (e) {
      debugPrint('[KS:AUTH_STATE] profile check ERROR — $e');
      final cachedProfile = HiveService.profile.get('current_profile');
      if (cachedProfile != null) {
        debugPrint('[KS:AUTH_STATE] profile found in cache — returning hasProfile: true');
        return AuthState(
          session: session,
          hasProfile: true,
          needsPasswordUpgrade: needsUpgrade,
        );
      }
      return AuthState(
        session: session,
        hasProfile: false,
        needsPasswordUpgrade: needsUpgrade,
      );
    }
  }

  bool _needsPasswordUpgrade(Session session) {
    // Check if any identity uses the 'phone' provider (passwordless)
    final identities = session.user.identities;
    if (identities == null) return false;
    return identities.every((id) => id.provider == 'phone');
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
  
  return await ref.watch(authRepositoryProvider).getCurrentUser();
});
