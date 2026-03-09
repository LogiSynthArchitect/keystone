enum UserRole { technician, foundingTechnician, admin }
enum UserStatus { pending, active, suspended }

class UserEntity {
  final String id;
  final String? authId;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final UserRole role;
  final UserStatus status;
  final String profileSlug;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    this.authId,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.role,
    required this.status,
    required this.profileSlug,
    this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == UserStatus.active;
  bool get isFoundingTechnician => role == UserRole.foundingTechnician;
  bool get isAdmin => role == UserRole.admin;
}
