import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/core/services/cloudinary_service.dart';

void main() {
  group('CloudinaryConfig', () {
    test('isConfigured returns false when creds are empty', () {
      expect(CloudinaryConfig.isConfigured, isFalse);
    });

    test('uploadUrlFor builds correct URL', () {
      expect(CloudinaryConfig.uploadUrlFor('demo'), 'https://api.cloudinary.com/v1_1/demo/auto/upload');
    });
  });

  group('CloudinaryService', () {
    test('sign generates valid SHA-1 hex', () {
      final result = CloudinaryService.sign(12345, 'mysecret');
      // Known: SHA-1('timestamp=12345mysecret') = 4c39aeb8470e3a2e94ca053c66e65a3fb7c6f73c
      expect(result, '9ae68c86227e0ba0e8e59af0574b4587a31e01b0');
    });

    test('sign is deterministic for same inputs', () {
      final a = CloudinaryService.sign(999, 'abc');
      final b = CloudinaryService.sign(999, 'abc');
      expect(a, b);
    });

    test('sign changes when timestamp differs', () {
      final a = CloudinaryService.sign(100, 'key');
      final b = CloudinaryService.sign(200, 'key');
      expect(a, isNot(b));
    });

    test('sign changes when secret differs', () {
      final a = CloudinaryService.sign(100, 'key1');
      final b = CloudinaryService.sign(100, 'key2');
      expect(a, isNot(b));
    });

    test('timestamp returns valid unix epoch seconds', () {
      final ts = CloudinaryService.timestamp();
      expect(ts, greaterThan(1700000000)); // Reasonable lower bound
      expect(ts, lessThan(2000000000));    // Reasonable upper bound
    });
  });
}
