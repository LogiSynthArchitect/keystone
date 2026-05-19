import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import 'package:keystone/features/technician_profile/domain/entities/profile_entity.dart';
import 'package:keystone/features/technician_profile/domain/repositories/profile_repository.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/request_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

class AuthUiState {
  final bool isLoading;
  final String? errorMessage;
  final String? phoneNumber;
  final bool isOtpSent;
  final bool? hasProfile;
  final bool isPasswordCreated;

  AuthUiState({
    this.isLoading = false,
    this.errorMessage,
    this.phoneNumber,
    this.isOtpSent = false,
    this.hasProfile,
    this.isPasswordCreated = false,
  });

  AuthUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? phoneNumber,
    bool? isOtpSent,
    bool? hasProfile,
    bool? isPasswordCreated,
    bool clearError = false,
  }) => AuthUiState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    phoneNumber: phoneNumber ?? this.phoneNumber,
    isOtpSent: isOtpSent ?? this.isOtpSent,
    hasProfile: hasProfile ?? this.hasProfile,
    isPasswordCreated: isPasswordCreated ?? this.isPasswordCreated,
  );
}

class AuthNotifier extends StateNotifier<AuthUiState> {
  final RequestOtpUsecase _requestOtp;
  final VerifyOtpUsecase _verifyOtp;
  final ProfileRepository _profileRepo;
  final AuthRepository _authRepo;
  final Ref _ref;

  AuthNotifier(this._requestOtp, this._verifyOtp, this._profileRepo, this._authRepo, this._ref) : super(AuthUiState());

  void reset() => state = AuthUiState();

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<bool> requestOtp(String phone) async {
    final normalized = PhoneFormatter.isValid(phone) ? PhoneFormatter.normalize(phone) : phone;
    state = state.copyWith(isLoading: true, phoneNumber: normalized, clearError: true);

    try {
      await _requestOtp(RequestOtpParams(phoneNumber: normalized));
      state = state.copyWith(isLoading: false, isOtpSent: true);
      return true;
    } catch (e) {
      String cleanError = e.toString();
      debugPrint('[KS:AUTH] requestOtp RAW ERROR: $e');
      if (cleanError.contains('20003') || cleanError.contains('invalid username')) {
        cleanError = "SMS Gateway Fault: Check Twilio Credentials.";
      } else {
        cleanError = cleanError.replaceFirst(RegExp(r"AppException\(\d+\):\s*"), "").trim();
      }
      state = state.copyWith(isLoading: false, errorMessage: cleanError);
      return false;
    }
  }

  Future<bool> verifyOtp(String token) async {
    final phone = state.phoneNumber;
    if (phone == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _verifyOtp(VerifyOtpParams(phoneNumber: phone, token: token));
      // Force refresh the router's auth state to check for existing profile
      await _ref.read(authStateProvider.notifier).refresh();
      // Invalidate data providers only for returning users (hasProfile = true).
      // New users have no data yet — invalidating triggers failed fetches before
      // the router redirects them to onboarding.
      final refreshedAuth = _ref.read(authStateProvider).valueOrNull;
      if (refreshedAuth?.hasProfile == true) {
        _ref.invalidate(profileProvider);
        _ref.invalidate(jobListProvider);
        _ref.invalidate(customerListProvider);
        _ref.invalidate(notesListProvider);
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      String cleanError = e.toString().replaceFirst(RegExp(r"AppException\(\d+\):\s*"), "").trim();
      state = state.copyWith(isLoading: false, errorMessage: cleanError);
      return false;
    }
  }

  Future<bool> bypassOtp(String phone) async {
    state = state.copyWith(isLoading: true, phoneNumber: phone, clearError: true);
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase.functions.invoke(
        'dev-bypass',
        body: {
          'phone': phone,
          'bypass_secret': 'dev-bypass-2026',
        },
      );

      if (response.data == null || response.data['access_token'] == null) {
        throw Exception('No session returned');
      }

      await supabase.auth.setSession(
        response.data['refresh_token'] as String,
      );

      final passwordExists = response.data['password_exists'] as bool? ?? false;
      if (passwordExists) {
        Hive.box('auth').put('password_exists', true);
      }

      await _ref.read(authStateProvider.notifier).refresh();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      debugPrint('[KS:AUTH] bypassOtp error: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'Dev bypass failed: $e');
      return false;
    }
  }

  Future<bool> completeOnboarding({required String name, required List<String> services}) async {
    debugPrint('[KS:ONBOARD] completeOnboarding — name: $name, services: $services');
    String? phone = state.phoneNumber;
    debugPrint('[KS:ONBOARD] phone from state: $phone');
    if (phone == null) {
      final supabase = _ref.read(supabaseClientProvider);
      phone = supabase.auth.currentUser?.phone;
      debugPrint('[KS:ONBOARD] phone from currentUser: $phone');
      if (phone == null) {
        debugPrint('[KS:ONBOARD] phone is null — cannot continue');
        return false;
      }
      state = state.copyWith(phoneNumber: phone);
    }
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Create/Update user record (Idempotent)
      debugPrint('[KS:ONBOARD] calling createUser...');
      final user = await _authRepo.createUser(fullName: name, phoneNumber: phone);
      debugPrint('[KS:ONBOARD] createUser success — user: ${user.authId}, slug: ${user.profileSlug}');
      
      // 2. Create profile record
      debugPrint('[KS:ONBOARD] calling createProfile...');
      final profile = ProfileEntity(
        id: '',
        userId: user.authId ?? '',
        displayName: name,
        bio: '',
        photoUrl: '',
        services: services,
        whatsappNumber: user.phoneNumber,
        isPublic: true,
        profileUrl: user.profileSlug,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _profileRepo.createProfile(profile);
      debugPrint('[KS:ONBOARD] createProfile success');

      // If this user was created via dev-bypass (already has password), mark it
      final authBox = Hive.box('auth');
      if (authBox.get('password_exists', defaultValue: false) as bool) {
        final supabase = _ref.read(supabaseClientProvider);
        try {
          await supabase.from('profiles').update({
            'password_created': true,
          }).eq('user_id', user.authId!);
          debugPrint('[KS:ONBOARD] password_created set to true (dev-bypass)');
        } catch (_) {}
        await authBox.delete('password_exists');
      }
      
      // 3. Force refresh router and profile state
      await _ref.read(authStateProvider.notifier).refresh();
      _ref.invalidate(profileProvider);
      
      state = state.copyWith(isLoading: false, hasProfile: true);
      debugPrint('[KS:ONBOARD] complete — success');
      return true;
    } catch (e, s) {
      debugPrint('[KS:ONBOARD] ERROR — $e');
      debugPrint('[KS:ONBOARD] stack — $s');
      String cleanError = e.toString().replaceFirst(RegExp(r"AppException\(\d+\):\s*"), "").trim();
      state = state.copyWith(isLoading: false, errorMessage: cleanError);
      return false;
    }
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  void setPhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone);
  }

  Future<void> setPasswordCreated() async {
    state = state.copyWith(isPasswordCreated: true);
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final supabase = _ref.read(supabaseClientProvider);
      await supabase.auth.signOut();
      await HiveService.clearAll();
      _ref.invalidate(authStateProvider);
    } catch (e) {
      debugPrint('[KS:AUTH] Logout error (proceeding anyway): $e');
    }
    state = state.copyWith(isLoading: false);
  }
}

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDatasourceProvider));
});

final requestOtpProvider = Provider<RequestOtpUsecase>((ref) {
  return RequestOtpUsecase(ref.watch(authRepositoryProvider));
});

final verifyOtpProvider = Provider<VerifyOtpUsecase>((ref) {
  return VerifyOtpUsecase(ref.watch(authRepositoryProvider));
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthUiState>((ref) {
  final requestOtp = ref.watch(requestOtpProvider);
  final verifyOtp = ref.watch(verifyOtpProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthNotifier(requestOtp, verifyOtp, profileRepo, authRepo, ref); 
});
