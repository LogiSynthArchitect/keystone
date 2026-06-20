import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_provider.dart';
import '../services/internal_auth/internal_auth_service.dart';
import '../services/internal_auth/models/auth_method.dart';

final internalAuthServiceProvider = Provider<InternalAuthService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return InternalAuthService(supabase);
});

final authMethodProvider = FutureProvider<AuthMethod>((ref) async {
  final service = ref.watch(internalAuthServiceProvider);
  return service.getEnrolledMethod();
});

final hasBiometricProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(internalAuthServiceProvider);
  return service.vault.getHasBiometric();
});
