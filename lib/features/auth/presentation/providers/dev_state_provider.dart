import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/config/dev_mode.dart';

/// Dev-mode overrides for auth state, step completion, and UI state injection.
///
/// Enables bypassing real authentication steps during development.
/// All overrides are guarded by [kDevMode] — tree-shaken in release builds.
class DevAuthOverride {
  /// Master switch — when false, no overrides take effect
  final bool enabled;

  /// Inject a fake authenticated session (bypasses real Supabase auth)
  final bool simulateAuthenticated;

  /// Phone number to use for the fake session
  final String phone;

  /// User ID to use for the fake session
  final String userId;

  /// Whether the user has a completed profile
  final bool hasProfile;

  /// Whether the user needs password upgrade
  final bool needsPasswordUpgrade;

  /// Whether the user has a password set (affects router: OTP vs password entry)
  final bool hasPassword;

  /// Whether the user is locally unlocked (no PIN/biometric needed)
  final bool isLocallyUnlocked;

  // ── Flow step completion flags ──

  /// OTP verification marked as done
  final bool otpVerified;

  /// Password creation marked as done
  final bool passwordCreated;

  /// PIN enrollment marked as done
  final bool pinCreated;

  /// Biometric enrollment marked as done
  final bool biometricEnrolled;

  /// Initial sync marked as done
  final bool initialSyncDone;

  /// Onboarding marked as completed
  final bool onboardingDone;

  /// Terms accepted
  final bool termsAccepted;

  const DevAuthOverride({
    this.enabled = false,
    this.simulateAuthenticated = false,
    this.phone = '233530823904',
    this.userId = 'dev-user-00000000-0000-0000-0000-000000000001',
    this.hasProfile = false,
    this.needsPasswordUpgrade = false,
    this.hasPassword = false,
    this.isLocallyUnlocked = true,
    this.otpVerified = false,
    this.passwordCreated = false,
    this.pinCreated = false,
    this.biometricEnrolled = false,
    this.initialSyncDone = false,
    this.onboardingDone = false,
    this.termsAccepted = false,
  });

  DevAuthOverride copyWith({
    bool? enabled,
    bool? simulateAuthenticated,
    String? phone,
    String? userId,
    bool? hasProfile,
    bool? needsPasswordUpgrade,
    bool? hasPassword,
    bool? isLocallyUnlocked,
    bool? otpVerified,
    bool? passwordCreated,
    bool? pinCreated,
    bool? biometricEnrolled,
    bool? initialSyncDone,
    bool? onboardingDone,
    bool? termsAccepted,
  }) {
    return DevAuthOverride(
      enabled: enabled ?? this.enabled,
      simulateAuthenticated: simulateAuthenticated ?? this.simulateAuthenticated,
      phone: phone ?? this.phone,
      userId: userId ?? this.userId,
      hasProfile: hasProfile ?? this.hasProfile,
      needsPasswordUpgrade: needsPasswordUpgrade ?? this.needsPasswordUpgrade,
      hasPassword: hasPassword ?? this.hasPassword,
      isLocallyUnlocked: isLocallyUnlocked ?? this.isLocallyUnlocked,
      otpVerified: otpVerified ?? this.otpVerified,
      passwordCreated: passwordCreated ?? this.passwordCreated,
      pinCreated: pinCreated ?? this.pinCreated,
      biometricEnrolled: biometricEnrolled ?? this.biometricEnrolled,
      initialSyncDone: initialSyncDone ?? this.initialSyncDone,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      termsAccepted: termsAccepted ?? this.termsAccepted,
    );
  }

  /// Pre-built "Fully Authenticated + Onboarded" shortcut
  static const authenticatedFull = DevAuthOverride(
    enabled: true,
    simulateAuthenticated: true,
    hasProfile: true,
    needsPasswordUpgrade: false,
    isLocallyUnlocked: true,
    hasPassword: true,
    otpVerified: true,
    passwordCreated: true,
    pinCreated: true,
    biometricEnrolled: false,
    initialSyncDone: true,
    onboardingDone: true,
    termsAccepted: true,
  );

  /// Pre-built "Phone entered, OTP verified, but no profile yet"
  static const otpDone = DevAuthOverride(
    enabled: true,
    simulateAuthenticated: true,
    hasProfile: false,
    needsPasswordUpgrade: false,
    isLocallyUnlocked: true,
    otpVerified: true,
    passwordCreated: false,
  );

  /// Pre-built "Profile exists, needs password upgrade"
  static const needsPasswordUpgradeState = DevAuthOverride(
    enabled: true,
    simulateAuthenticated: true,
    hasProfile: true,
    needsPasswordUpgrade: true,
    isLocallyUnlocked: true,
    otpVerified: true,
    passwordCreated: false,
  );
}

/// Builds a fake Supabase Session for dev-mode state injection.
supa.Session _buildFakeSession(String userId, String phone) {
  final now = DateTime.now().toUtc().toIso8601String();
  final user = supa.User(
    id: userId,
    aud: 'authenticated',
    role: 'authenticated',
    email: null,
    phone: phone,
    appMetadata: const {'provider': 'phone'},
    userMetadata: {},
    identities: [
      supa.UserIdentity(
        id: userId,
        userId: userId,
        identityId: userId,
        identityData: {},
        provider: 'phone',
        createdAt: now,
        lastSignInAt: now,
      ),
    ],
    createdAt: now,
    updatedAt: now,
  );

  return supa.Session(
    accessToken: 'dev_access_token',
    tokenType: 'bearer',
    refreshToken: 'dev_refresh_token',
    user: user,
    expiresIn: 86400,
    providerToken: null,
    providerRefreshToken: null,
  );
}

/// Merges real [authStateProvider] with dev overrides.
///
/// When [DevAuthOverride.enabled] is true and [simulateAuthenticated] is set,
/// returns a constructed [AuthState] with fake session + overridden flags.
/// Otherwise passes through the real auth state unchanged.
final mergedAuthStateProvider = Provider<AsyncValue<AuthState>>((ref) {
  final realAsync = ref.watch(authStateProvider);
  final devState = ref.watch(devAuthOverrideProvider);

  if (!kDevMode || !devState.enabled) return realAsync;

  // Build overridden state from dev flags
  final session = devState.simulateAuthenticated
      ? _buildFakeSession(devState.userId, devState.phone)
      : realAsync.valueOrNull?.session;

  return AsyncData(
    AuthState(
      session: session,
      hasProfile: devState.hasProfile,
      needsPasswordUpgrade: devState.needsPasswordUpgrade,
      isLocallyUnlocked: devState.isLocallyUnlocked,
    ),
  );
});

/// Dev-mode auth override state provider — toggle flags from DevAuthPanel.
final devAuthOverrideProvider =
    StateNotifierProvider<DevAuthOverrideNotifier, DevAuthOverride>((ref) {
  return DevAuthOverrideNotifier();
});

class DevAuthOverrideNotifier extends StateNotifier<DevAuthOverride> {
  DevAuthOverrideNotifier() : super(const DevAuthOverride());

  void toggleEnabled() => state = state.copyWith(enabled: !state.enabled);

  void setEnabled(bool v) => state = state.copyWith(enabled: v);

  void setSimulateAuthenticated(bool v) =>
      state = state.copyWith(simulateAuthenticated: v);

  void setHasProfile(bool v) => state = state.copyWith(hasProfile: v);

  void setNeedsPasswordUpgrade(bool v) =>
      state = state.copyWith(needsPasswordUpgrade: v);

  void setHasPassword(bool v) =>
      state = state.copyWith(hasPassword: v);

  void setIsLocallyUnlocked(bool v) =>
      state = state.copyWith(isLocallyUnlocked: v);

  // ── Flow step markers ──

  void markOtpVerified() => state = state.copyWith(
        enabled: true,
        otpVerified: true,
        simulateAuthenticated: true,
      );

  void markPasswordCreated() => state = state.copyWith(passwordCreated: true);

  void markPinCreated() => state = state.copyWith(pinCreated: true);

  void markBiometricEnrolled() =>
      state = state.copyWith(biometricEnrolled: true);

  void markInitialSyncDone() => state = state.copyWith(initialSyncDone: true);

  void markOnboardingDone() => state = state.copyWith(
        onboardingDone: true,
        hasProfile: true,
      );

  void markTermsAccepted() => state = state.copyWith(termsAccepted: true);

  // ── Presets ──

  void applyPreset(DevAuthOverride preset) => state = preset;

  void reset() => state = const DevAuthOverride();
}
