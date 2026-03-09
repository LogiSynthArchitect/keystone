import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/request_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

// ── Datasource & Repository providers ────────────────────────────────────────
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDatasourceProvider));
});

// ── Use case providers ────────────────────────────────────────────────────────
final requestOtpUsecaseProvider = Provider<RequestOtpUsecase>((ref) {
  return RequestOtpUsecase(ref.watch(authRepositoryProvider));
});

final verifyOtpUsecaseProvider = Provider<VerifyOtpUsecase>((ref) {
  return VerifyOtpUsecase(ref.watch(authRepositoryProvider));
});

final logoutUsecaseProvider = Provider<LogoutUsecase>((ref) {
  return LogoutUsecase(ref.watch(authRepositoryProvider));
});

// ── Auth UI state ─────────────────────────────────────────────────────────────
class AuthUiState {
  final bool isLoading;
  final String? errorMessage;
  final String? phoneNumber;
  final bool otpSent;

  const AuthUiState({
    this.isLoading = false,
    this.errorMessage,
    this.phoneNumber,
    this.otpSent = false,
  });

  AuthUiState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? phoneNumber,
    bool? otpSent,
    bool clearError = false,
  }) {
    return AuthUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otpSent: otpSent ?? this.otpSent,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthUiState> {
  final RequestOtpUsecase _requestOtp;
  final VerifyOtpUsecase _verifyOtp;
  final LogoutUsecase _logout;

  AuthNotifier(this._requestOtp, this._verifyOtp, this._logout)
      : super(const AuthUiState());

  Future<bool> requestOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _requestOtp(RequestOtpParams(phoneNumber: phoneNumber));
      state = state.copyWith(
        isLoading: false,
        phoneNumber: PhoneFormatter.normalize(phoneNumber),
        otpSent: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String token) async {
    if (state.phoneNumber == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _verifyOtp(VerifyOtpParams(
        phoneNumber: state.phoneNumber!,
        token: token,
      ));
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _logout();
    state = const AuthUiState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthUiState>((ref) {
  return AuthNotifier(
    ref.watch(requestOtpUsecaseProvider),
    ref.watch(verifyOtpUsecaseProvider),
    ref.watch(logoutUsecaseProvider),
  );
});

// ── Connectivity provider for auth screens ────────────────────────────────────
final connectivityProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});
