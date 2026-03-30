import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_permissions.dart';
import '../storage/hive_service.dart';
import 'auth_provider.dart';

/// Returns effective permissions for the current user.
/// Admin users always get full permissions, regardless of saved settings.
/// Technician users get whatever is stored in settings (defaults if nothing saved).
final permissionsProvider = Provider<UserPermissions>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;

  // Admin always has full access.
  if (user?.isAdmin == true) return UserPermissions.defaults;

  final raw = HiveService.settings.get('technician_permissions');
  if (raw == null) return UserPermissions.defaults;
  try {
    return UserPermissions.fromJson(Map<String, dynamic>.from(raw as Map));
  } catch (_) {
    return UserPermissions.defaults;
  }
});
