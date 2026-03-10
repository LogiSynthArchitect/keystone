import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_provider.dart';

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
          .from('users')
          .select()
          .eq('auth_id', session.user.id)
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
