import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'secure_vault_service.dart';

/// PIN management service — PBKDF2 HMAC SHA256 hashing + 5-try limit.
///
/// Design decisions:
/// - **5 tries then wipe**: No exponential backoff. Wiping the PIN forces
///   password re-entry, which is better UX for field workers and avoids
///   client-side time manipulation attacks.
/// - **Trivial PIN rejection**: Repeating (111111) and sequential (123456)
///   patterns are blocked at setup time.
/// - **PBKDF2**: 100K iterations balances security vs. mobile CPU. Salt is
///   16 random bytes per user, stored alongside the hash in secure storage.
class PinService {
  final SecureVaultService vault;

  PinService(this.vault);

  // ── Constants ─────────────────────────────────────────────────────────

  static const int pinLength = 6;
  static const int maxAttempts = 5;
  static const int pbkdf2Iterations = 100000;

  // ── PIN Validation ────────────────────────────────────────────────────

  /// Returns null if the PIN is acceptable, or an error message if trivial.
  static String? validatePin(String pin) {
    if (pin.length != pinLength) return 'PIN must be $pinLength digits.';
    if (!RegExp(r'^\d+$').hasMatch(pin)) return 'PIN must be digits only.';

    // Repeating digits: 000000, 111111, ..., 999999
    if (RegExp(r'^(\d)\1{5}$').hasMatch(pin)) {
      return 'Please choose a more secure PIN.';
    }

    // Sequential ascending: 123456, 234567, ..., 456789
    if (pin == '123456' || pin == '234567' || pin == '345678' || pin == '456789') {
      return 'Please choose a more secure PIN.';
    }

    // Sequential descending: 654321, 543210
    if (pin == '654321' || pin == '543210') {
      return 'Please choose a more secure PIN.';
    }

    return null;
  }

  // ── Hashing ───────────────────────────────────────────────────────────

  /// Generate a 16-byte hex salt.
  static String generateSalt() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return base64Url.encode(bytes);
  }

  /// PBKDF2-HMAC-SHA256 with [pbkdf2Iterations] iterations.
  static String hashPin(String pin, String salt) {
    final key = pbkdf2HmacSha256(
      hash: sha256,
      iterations: pbkdf2Iterations,
      passphrase: utf8.encode(pin),
      salt: utf8.encode(salt),
    );
    return base64Url.encode(key);
  }

  // ── Attempt Tracking ──────────────────────────────────────────────────

  Future<int> getRemainingAttempts() async {
    final attempts = await vault.getPinFailedAttempts();
    return maxAttempts - attempts;
  }

  Future<int> recordFailedAttempt() async {
    final attempts = await vault.getPinFailedAttempts();
    final next = (attempts + 1).clamp(0, maxAttempts);
    await vault.storePinFailedAttempts(next);
    return maxAttempts - next; // remaining
  }

  Future<void> recordSuccessfulAttempt() async {
    await vault.storePinFailedAttempts(0);
  }

  Future<bool> isWiped() async {
    final attempts = await vault.getPinFailedAttempts();
    return attempts >= maxAttempts;
  }

  /// Wipes PIN data from the vault.
  Future<void> wipePin() async {
    await vault.clearPinData();
  }

  // ── Enrollment ────────────────────────────────────────────────────────

  /// Hash the PIN and store hash+salt in secure storage.
  Future<bool> enrollPin(String pin) async {
    final salt = generateSalt();
    final hash = await _computeHash(pin, salt);
    await vault.storePinHash(hash);
    await vault.storePinSalt(salt);
    await vault.storePinFailedAttempts(0);
    return true;
  }

  /// Compute PBKDF2 hash off the main thread via isolate.
  Future<String> _computeHash(String pin, String salt) async {
    return Isolate.run(() => _pbkdf2Hash(pin, salt));
  }

  // ── Verification ──────────────────────────────────────────────────────

  /// Returns `true` if the PIN matches the stored hash and attempts remain.
  /// Returns `false` if the PIN is wrong. Throws [PinWipedException] if
  /// attempts are exhausted — caller must redirect to password entry.
  Future<bool> verifyPin(String pin) async {
    if (await isWiped()) {
      throw PinWipedException();
    }

    final storedHash = await vault.getPinHash();
    final storedSalt = await vault.getPinSalt();
    if (storedHash == null || storedSalt == null) return false;

    final computed = await _computeHash(pin, storedSalt);
    if (computed != storedHash) {
      await recordFailedAttempt();
      return false;
    }

    await recordSuccessfulAttempt();
    return true;
  }
}

/// Top-level function for Isolate.run: PBKDF2 hash with 100K iterations.
String _pbkdf2Hash(String pin, String salt) {
  final key = pbkdf2HmacSha256(
    hash: sha256,
    iterations: 100000,
    passphrase: utf8.encode(pin),
    salt: utf8.encode(salt),
  );
  return base64Url.encode(key);
}

/// Thrown when the PIN has been wiped due to too many failed attempts.
class PinWipedException implements Exception {
  final String message;
  PinWipedException([this.message = 'PIN wiped after too many attempts.']);

  @override
  String toString() => message;
}

// ── PBKDF2 implementation (dart:crypto has no built-in PBKDF2) ─────────────

/// PBKDF2-HMAC-SHA256 using [Hmac] from dart:crypto.
/// Standard implementation per RFC 2898.
List<int> pbkdf2HmacSha256({
  required Hash hash,
  required int iterations,
  required List<int> passphrase,
  required List<int> salt,
  int keyLength = 32, // 256 bits
}) {
  final hmac = Hmac(hash, passphrase);
  final derived = List<int>.filled(keyLength, 0);

  // Compute hash output length from a test digest
  final hashLength = hmac.convert([0]).bytes.length;
  final blockCount = (keyLength / hashLength).ceil();

  for (int block = 1; block <= blockCount; block++) {
    final blockData = ByteData(4)..setInt32(0, block, Endian.big);
    final blockBytes = blockData.buffer.asUint8List();
    final u = <int>[...salt, ...blockBytes];

    final u1 = hmac.convert(u).bytes;
    var t = List<int>.from(u1);

    var uPrev = u1;
    for (int j = 1; j < iterations; j++) {
      uPrev = hmac.convert(uPrev).bytes;
      for (int k = 0; k < uPrev.length; k++) {
        t[k] ^= uPrev[k];
      }
    }

    final destStart = (block - 1) * hashLength;
    final remaining = keyLength - destStart;
    final copyLen = remaining < hashLength ? remaining : hashLength;
    for (int i = 0; i < copyLen; i++) {
      derived[destStart + i] = t[i];
    }
  }

  return derived;
}