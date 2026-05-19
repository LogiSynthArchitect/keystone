import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'secure_vault_service.dart';

class PinService {
  final SecureVaultService _vault;

  PinService(this._vault);

  bool isValidPin(String pin) {
    return pin.length == 6 && RegExp(r'^\d{6}$').hasMatch(pin);
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final key = utf8.encode(salt);
    final value = utf8.encode(pin);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(value);
    return base64Url.encode(digest.bytes);
  }

  Future<void> storePin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _vault.storePinSalt(salt);
    await _vault.storePinHash(hash);
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _vault.getPinHash();
    final storedSalt = await _vault.getPinSalt();
    if (storedHash == null || storedSalt == null) return false;
    final computedHash = _hashPin(pin, storedSalt);
    return computedHash == storedHash;
  }

  Future<bool> hasPinStored() async {
    final hash = await _vault.getPinHash();
    return hash != null;
  }
}
