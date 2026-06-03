import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/dev_mode.dart';

/// Dev-override phone number to auto-fill on phone entry screen.
///
/// In DEV_MODE, if this is non-null, the phone entry screen pre-fills the
/// input and auto-submits after a short delay.
final devAutoFillPhoneProvider = StateProvider<String?>((ref) {
  if (!kDevMode) return null;
  return null;
});

/// Dev-mode flag to skip OTP verification (auto-confirm with hardcoded token).
final devSkipOtpProvider = StateProvider<bool>((ref) {
  if (!kDevMode) return false;
  return false;
});

/// Dev-mode flag to skip password creation (treat user as having password).
final devSkipPasswordCreationProvider = StateProvider<bool>((ref) {
  if (!kDevMode) return false;
  return false;
});
