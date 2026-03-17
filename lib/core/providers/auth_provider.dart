import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_provider.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/domain/entities/user_entity.dart';

class AuthState {
  final Session? session;
  final bool hasProfile;
  final bool isLoading;
  const AuthState({
    this.session,
    this.hasProfile = false,
    this.isLoading = false,
  });
  bool get isAuthenticated => session != null;
  AuthState copyWith({
    Session? session,
    bool? hasProfile,
    bool? isLoading,
  }) {
    return AuthState(
      session: session ?? this.session,
      hasProfile: hasProfile ?? this.hasProfile,
      isLoading: isLoading ?? this.isLoading,
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
    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('user_id', session.user.id)
          .maybeSingle();
      debugPrint('[KS:AUTH_STATE] hasProfile: ${profile != null}');
      return AuthState(session: session, hasProfile: profile != null);
    } catch (e) {
      debugPrint('[KS:AUTH_STATE] profile check ERROR — $e');
      return AuthState(session: session, hasProfile: false);
    }
  }

  Future<void> refresh() async {
    debugPrint('[KS:AUTH_STATE] refresh called');
    ref.invalidateSelf();
  }

  Future<void> signOut() async {
    debugPrint('[KS:AUTH_STATE] signOut called');
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
