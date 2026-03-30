import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/core/models/user_permissions.dart';

void main() {
  group('UserPermissions Model Tests', () {

    test('1. UserPermissions.defaults should have all permissions set to true', () {
      // Arrange & Act
      const defaults = UserPermissions.defaults;

      // Assert
      expect(defaults.canEditFinalPrice, isTrue);
      expect(defaults.canDeleteJobs, isTrue);
      expect(defaults.canViewKeyCodes, isTrue);
    });

    test('2. UserPermissions.fromJson should parse correctly when all fields are present', () {
      // Arrange
      final json = {
        'can_edit_final_price': false,
        'can_delete_jobs': false,
        'can_view_key_codes': false,
      };

      // Act
      final permissions = UserPermissions.fromJson(json);

      // Assert
      expect(permissions.canEditFinalPrice, isFalse);
      expect(permissions.canDeleteJobs, isFalse);
      expect(permissions.canViewKeyCodes, isFalse);
    });

    test('3. UserPermissions.fromJson should fall back to true defaults for missing fields', () {
      // Arrange
      final json = {'can_edit_final_price': false};

      // Act
      final permissions = UserPermissions.fromJson(json);

      // Assert
      expect(permissions.canEditFinalPrice, isFalse);
      expect(permissions.canDeleteJobs, isTrue);
      expect(permissions.canViewKeyCodes, isTrue);
    });

    test('4. UserPermissions.toJson should serialize all three fields', () {
      // Arrange
      const permissions = UserPermissions(
        canEditFinalPrice: true,
        canDeleteJobs: false,
        canViewKeyCodes: true,
      );

      // Act
      final json = permissions.toJson();

      // Assert
      expect(json, {
        'can_edit_final_price': true,
        'can_delete_jobs': false,
        'can_view_key_codes': true,
      });
    });

    test('5. UserPermissions.copyWith should only change the target field', () {
      // Arrange
      const original = UserPermissions(
        canEditFinalPrice: true,
        canDeleteJobs: true,
        canViewKeyCodes: true,
      );

      // Act
      final updated = original.copyWith(canEditFinalPrice: false);

      // Assert
      expect(updated.canEditFinalPrice, isFalse);
      expect(updated.canDeleteJobs, isTrue);
      expect(updated.canViewKeyCodes, isTrue);
    });
  });
}
