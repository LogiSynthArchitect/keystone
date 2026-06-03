import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import '../../../../core/config/dev_mode.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import 'package:arclock/features/technician_profile/domain/entities/profile_entity.dart';
import 'package:arclock/features/technician_profile/domain/repositories/profile_repository.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/request_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'dev_state_provider.dart';
import '../../../../core/router/route_names.dart';

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
  bool _isVerifying = false;

  AuthNotifier(this._requestOtp, this._verifyOtp, this._profileRepo, this._authRepo, this._ref) : super(AuthUiState());

  /// Maps exception messages to user-friendly strings.
  String _mapOtpError(Object e) {
    final msg = e.toString();
    if (msg.contains('Token expired') || msg.contains('token_expired')) {
      return 'Code expired. Request a new one.';
    }
    if (msg.contains('Invalid token') || msg.contains('token_invalid') || msg.contains('Verification failed')) {
      return 'Wrong code. Try again or request a new one.';
    }
    if (msg.contains('no network') || msg.contains('NO_CONNECTION') || msg.contains('TimeoutException')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (msg.contains('OTP_SEND_FAILED')) {
      return 'Could not send code. Please try again.';
    }
    return msg.replaceFirst(RegExp(r"AppException\(\d+\):\s*"), "").trim();
  }

  void reset() => state = AuthUiState();

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  /// Checks if a phone number has a password set, then routes accordingly.
  /// Returns the route name to navigate to, or null on error.
  Future<String?> checkAuthState(String phone) async {
    final normalized = PhoneFormatter.isValid(phone) ? PhoneFormatter.normalize(phone) : phone;
    state = state.copyWith(isLoading: true, phoneNumber: normalized, clearError: true);

    // DEV_MODE bypass — use dev override state to decide routing
    if (kDevMode) {
      debugPrint('[KS:AUTH:DEV] checkAuthState bypass — phone: $normalized');
      final devOverride = _ref.read(devAuthOverrideProvider);
      if (devOverride.hasPassword) {
        state = state.copyWith(isLoading: false);
        return RouteNames.passwordEntry;
      } else {
        final otpOk = await requestOtp(normalized);
        return otpOk ? RouteNames.otpVerify : null;
      }
    }

    try {
      final result = await _authRepo.checkAuthState(normalized);
      if (result.exists && result.hasPassword) {
        debugPrint('[KS:AUTH] checkAuthState — returning user with password');
        state = state.copyWith(isLoading: false);
        return RouteNames.passwordEntry;
      } else {
        debugPrint('[KS:AUTH] checkAuthState — new user or no password, sending OTP');
        final otpOk = await requestOtp(normalized);
        return otpOk ? RouteNames.otpVerify : null;
      }
    } catch (e) {
      debugPrint('[KS:AUTH] checkAuthState error — $e');
      state = state.copyWith(isLoading: false, errorMessage: 'Could not verify account. Please try again.');
      return null;
    }
  }

  Future<bool> requestOtp(String phone) async {
    final normalized = PhoneFormatter.isValid(phone) ? PhoneFormatter.normalize(phone) : phone;
    state = state.copyWith(isLoading: true, phoneNumber: normalized, clearError: true);

    // DEV_MODE bypass — mark OTP as sent without calling the edge function
    if (kDevMode) {
      debugPrint('[KS:AUTH:DEV] requestOtp bypass — pretending OTP sent to $normalized');
      state = state.copyWith(isLoading: false, isOtpSent: true);
      return true;
    }

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
    // Double-submit guard — prevents concurrent verification calls
    if (_isVerifying) {
      debugPrint('[KS:AUTH] verifyOtp — already verifying, ignoring duplicate call');
      return false;
    }

    final phone = state.phoneNumber;
    if (phone == null) return false;

    _isVerifying = true;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // DEV_MODE bypass — skip real OTP verification, mark it done
      if (kDevMode) {
        debugPrint('[KS:AUTH:DEV] verifyOtp bypass — pretending OTP $token is valid');
        _ref.read(devAuthOverrideProvider.notifier).markOtpVerified();
        state = state.copyWith(isLoading: false);
        return true;
      }

      // Step 1: Verify the OTP with Supabase
      await _verifyOtp(VerifyOtpParams(phoneNumber: phone, token: token));

      // Step 2: OTP is valid — now best-effort post-auth refresh.
      // A refresh failure MUST NOT roll back a successful OTP verification
      // because it falsely tells the user "verification failed" when the OTP
      // was already accepted by Supabase.
      if (kDevMode) {
        _ref.read(devAuthOverrideProvider.notifier).markOtpVerified();
      }
      try {
        await _ref.read(authStateProvider.notifier).refresh();
        final refreshedAuth = _ref.read(authStateProvider).valueOrNull;
        if (refreshedAuth?.hasProfile == true) {
          _ref.invalidate(profileProvider);
          _ref.invalidate(jobListProvider);
          _ref.invalidate(customerListProvider);
          _ref.invalidate(notesListProvider);
        }
      } catch (refreshError) {
        debugPrint('[KS:AUTH] verifyOtp — post-OTP refresh failed (non-fatal): $refreshError');
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final cleanError = _mapOtpError(e);
      state = state.copyWith(isLoading: false, errorMessage: cleanError);
      return false;
    } finally {
      _isVerifying = false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    debugPrint('[KS:AUTH] changePassword');
    state = state.copyWith(isLoading: true);
    try {
      final supabase = _ref.read(supabaseClientProvider);
      // Re-auth with current password first
      await supabase.auth.signInWithPassword(
        password: currentPassword,
        phone: state.phoneNumber,
      );
      // Then update to new password
      await supabase.auth.updateUser(supa.UserAttributes(password: newPassword));
      debugPrint('[KS:AUTH] changePassword SUCCESS');
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      debugPrint('[KS:AUTH] changePassword error: $e');
      state = state.copyWith(isLoading: false, errorMessage: '$e');
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    debugPrint('[KS:AUTH] deleteAccount');
    state = state.copyWith(isLoading: true);
    try {
      final supabase = _ref.read(supabaseClientProvider);
      await supabase.functions.invoke('delete-account', body: {
        'user_id': supabase.auth.currentUser?.id,
      });
      await logout();
      debugPrint('[KS:AUTH] deleteAccount SUCCESS');
      return true;
    } catch (e) {
      debugPrint('[KS:AUTH] deleteAccount error: $e');
      state = state.copyWith(isLoading: false, errorMessage: '$e');
      return false;
    }
  }

  Future<bool> changePhone(String newPhone) async {
    debugPrint('[KS:AUTH] changePhone: $newPhone');
    state = state.copyWith(isLoading: true);
    try {
      final supabase = _ref.read(supabaseClientProvider);
      await supabase.auth.updateUser(supa.UserAttributes(phone: newPhone));
      debugPrint('[KS:AUTH] changePhone SUCCESS');
      return true;
    } catch (e) {
      debugPrint('[KS:AUTH] changePhone error: $e');
      state = state.copyWith(isLoading: false, errorMessage: '$e');
      return false;
    }
  }

  Future<bool> completeOnboarding({required String name, required List<String> services, DateTime? termsAcceptedAt, int termsVersion = 0}) async {
    debugPrint('[KS:ONBOARD] completeOnboarding — name: $name, services: $services, termsVersion: $termsVersion');
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
        termsAcceptedAt: termsAcceptedAt,
        termsVersion: termsVersion > 0 ? termsVersion : 1,
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

  Future<void> updateTermsAcceptance({required DateTime termsAcceptedAt, required int termsVersion}) async {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('profiles').update({
        'terms_accepted_at': termsAcceptedAt.toIso8601String(),
        'terms_version': termsVersion,
      }).eq('user_id', userId);

      // Update local cache
      final profile = await _profileRepo.getProfile();
      if (profile != null) {
        final updated = profile.copyWith(
          termsAcceptedAt: termsAcceptedAt,
          termsVersion: termsVersion,
        );
        await _profileRepo.updateProfile(updated);
      }
    } catch (e) {
      debugPrint('[KS:AUTH] updateTermsAcceptance error: $e');
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
      final internalAuth = InternalAuthService(supabase);
      // Wipe local data first — never depends on network
      await HiveService.clearAll();
      await internalAuth.clearVault();
      _ref.invalidate(authStateProvider);
      // Then invalidate server session — best-effort
      await supabase.auth.signOut();
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
