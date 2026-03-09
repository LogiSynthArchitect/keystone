import '../../domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String? authId;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String role;
  final String status;
  final String profileSlug;
  final String? lastSeenAt;
  final String createdAt;
  final String updatedAt;

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        authId: json['auth_id'] as String?,
        fullName: json['full_name'] as String,
        phoneNumber: json['phone_number'] as String,
        email: json['email'] as String?,
        role: json['role'] as String,
        status: json['status'] as String,
        profileSlug: json['profile_slug'] as String,
        lastSeenAt: json['last_seen_at'] as String?,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'auth_id': authId,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'email': email,
        'role': role,
        'status': status,
        'profile_slug': profileSlug,
        'last_seen_at': lastSeenAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  UserEntity toEntity() => UserEntity(
        id: id,
        authId: authId,
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
        role: _parseRole(role),
        status: _parseStatus(status),
        profileSlug: profileSlug,
        lastSeenAt: lastSeenAt != null ? DateTime.parse(lastSeenAt!) : null,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  static UserRole _parseRole(String value) {
    switch (value) {
      case 'founding_technician': return UserRole.foundingTechnician;
      case 'admin':               return UserRole.admin;
      default:                    return UserRole.technician;
    }
  }

  static UserStatus _parseStatus(String value) {
    switch (value) {
      case 'active':    return UserStatus.active;
      case 'suspended': return UserStatus.suspended;
      default:          return UserStatus.pending;
    }
  }
}
