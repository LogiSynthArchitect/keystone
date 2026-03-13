import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';
import '../../../technician_profile/domain/repositories/profile_repository.dart';
import '../../../technician_profile/presentation/providers/profile_provider.dart';
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

  AuthUiState({
    this.isLoading = false,
    this.errorMessage,
    this.phoneNumber,
    this.isOtpSent = false,
    this.hasProfile,
  });

  AuthUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? phoneNumber,
    bool? isOtpSent,
    bool? hasProfile,
    bool clearError = false,
  }) => AuthUiState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    phoneNumber: phoneNumber ?? this.phoneNumber,
    isOtpSent: isOtpSent ?? this.isOtpSent,
    hasProfile: hasProfile ?? this.hasProfile,
  );
}

class AuthNotifier extends StateNotifier<AuthUiState> {
  final RequestOtpUsecase _requestOtp;
  final VerifyOtpUsecase _verifyOtp;
  final ProfileRepository _profileRepo;
  final AuthRepository _authRepo;

  AuthNotifier(this._requestOtp, this._verifyOtp, this._profileRepo, this._authRepo) : super(AuthUiState());

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<bool> requestOtp(String phone) async {
    debugPrint('[KS:FLOW] AuthNotifier.requestOtp — phone: $phone');

    final normalized = PhoneFormatter.isValid(phone)
        ? PhoneFormatter.normalize(phone)
        : phone;

    state = state.copyWith(isLoading: true, phoneNumber: normalized, clearError: true);
    
    try {
      await _requestOtp(RequestOtpParams(phoneNumber: normalized));
      debugPrint('[KS:FLOW] AuthNotifier.requestOtp SUCCESS');
      state = state.copyWith(isLoading: false, isOtpSent: true);
      return true;
    } catch (e) {
      debugPrint('[KS:FLOW] AuthNotifier.requestOtp ERROR: $e');
      
      String cleanError = e.toString();
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
    debugPrint('[KS:FLOW] AuthNotifier.verifyOtp — token: $token');
    final phone = state.phoneNumber;
    if (phone == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await _verifyOtp(VerifyOtpParams(phoneNumber: phone, token: token));

      debugPrint('[KS:FLOW] Interrogating profile for phone: $phone');
      final profile = await _profileRepo.getProfileByPhone(phone);
      final exists = profile != null;

      debugPrint('[KS:FLOW] Identity Check: ${exists ? "VETERAN" : "RECRUIT"}');
      state = state.copyWith(isLoading: false, hasProfile: exists);
      return true;
    } catch (e) {
      debugPrint('[KS:FLOW] AuthNotifier.verifyOtp ERROR: $e');
      String cleanError = e.toString().replaceFirst(RegExp(r"AppException\(\d+\):\s*"), "").trim();
      state = state.copyWith(isLoading: false, errorMessage: cleanError);
      return false;
    }
  }

  Future<bool> completeOnboarding({required String name, required List<ServiceType> services}) async {
    debugPrint('[KS:FLOW] AuthNotifier.completeOnboarding — name: $name, services: $services');
    final phone = state.phoneNumber;
    if (phone == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      debugPrint('[KS:FLOW] Calling authRepo.createUser...');
      final user = await _authRepo.createUser(
        fullName: name,
        phoneNumber: phone,
      );

      debugPrint('[KS:FLOW] Calling profileRepo.createProfile...');
      final profile = ProfileEntity(
        id: '',
        userId: user.authId ?? '',
        displayName: name,
        bio: '',
        photoUrl: '',
        services: services,
        whatsappNumber: user.phoneNumber,
        isPublic: true,
        profileUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _profileRepo.createProfile(profile);
      state = state.copyWith(isLoading: false, hasProfile: true);
      return true;
    } catch (e) {
      debugPrint('[KS:FLOW] AuthNotifier.completeOnboarding ERROR: $e');
      String cleanError = e.toString().replaceFirst(RegExp(r"AppException\(\d+\):\s*"), "").trim();
      state = state.copyWith(isLoading: false, errorMessage: cleanError);
      return false;
    }
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
  return AuthNotifier(requestOtp, verifyOtp, profileRepo, authRepo);
});
