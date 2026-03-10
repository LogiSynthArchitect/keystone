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
    final supabase = ref.watch(supabaseClientProvider);

    // Listen to auth state changes — rebuild on any change
    final sub = supabase.auth.onAuthStateChange.listen((event) {
      ref.invalidateSelf();
    });
    ref.onDispose(() => sub.cancel());

    final session = supabase.auth.currentSession;

    // No session — unauthenticated
    if (session == null) {
      return const AuthState();
    }

    // Session exists — check if profile is complete
    try {
      final userId = session.user.id;
      final profile = await supabase
          .from('users')
          .select()
          .eq('auth_id', userId)
          .maybeSingle();

      return AuthState(
        session: session,
        hasProfile: profile != null,
      );
    } catch (_) {
      // If profile check fails, treat as no profile
      return AuthState(session: session, hasProfile: false);
    }
  }

  Future<void> signOut() async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.auth.signOut();
    ref.invalidateSelf();
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
