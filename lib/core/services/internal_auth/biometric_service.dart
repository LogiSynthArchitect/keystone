import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

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

  Future<bool> authenticate({
    required String reason,
    bool stickyAuth = true,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint('[KS:BIOMETRIC] authenticate error: $e');
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    final canBio = await canCheckBiometrics();
    if (!canBio) return false;
    return authenticate(reason: 'Verify your identity to unlock Keystone');
  }
}
