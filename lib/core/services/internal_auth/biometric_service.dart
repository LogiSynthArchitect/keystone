import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thrown by [BiometricService] when device setup prevents biometric auth.
class BiometricAuthException implements Exception {
  final String code;
  final String userMessage;

  BiometricAuthException(this.code, this.userMessage);

  bool get isPasscodeNotSet => code == 'PasscodeNotSet';
  bool get isNotEnrolled => code == 'NotEnrolled';
}

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('[KS:BIOMETRIC] canCheckBiometrics error: $e');
      return false;
    }
  }

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('[KS:BIOMETRIC] isDeviceSupported error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('[KS:BIOMETRIC] getAvailableBiometrics error: $e');
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    final canBio = await canCheckBiometrics();
    if (!canBio) return false;
    return _callAuth(
      reason: 'Verify your identity to enable biometric unlock',
      biometricOnly: true,
    );
  }

  /// Authenticate using device credentials (PIN/pattern/password OR biometrics).
  /// Opens the Android system unlock screen — no custom PIN entry needed.
  Future<bool> authenticateWithDeviceCredentials({String reason = 'Verify your identity'}) async {
    return _callAuth(
      reason: reason,
      biometricOnly: false,
    );
  }

  Future<bool> _callAuth({
    required String reason,
    required bool biometricOnly,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == 'PasscodeNotSet') {
        throw BiometricAuthException(
          'PasscodeNotSet',
          'No device lock screen set. Please go to Settings > Security and '
              'set up a PIN, pattern, or password first.',
        );
      }
      if (e.code == 'NotEnrolled') {
        throw BiometricAuthException(
          'NotEnrolled',
          'No biometrics enrolled. Please go to Settings > Security and '
              'add a fingerprint or face unlock first.',
        );
      }
      if (e.code == 'no_fragment_activity') {
        throw BiometricAuthException(
          'no_fragment_activity',
          'Biometric authentication is not supported on this device configuration. '
              'Please use the App PIN option instead.',
        );
      }
      debugPrint('[KS:BIOMETRIC] authenticate error ($biometricOnly): $e');
      return false;
    } catch (e) {
      debugPrint('[KS:BIOMETRIC] authenticate error ($biometricOnly): $e');
      return false;
    }
  }
}
