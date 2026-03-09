import '../../domain/entities/profile_entity.dart';

class ProfileModel {
  final String id;
  final String userId;
  final String displayName;
  final String? bio;
  final String? photoUrl;
  final List<String> services;
  final String whatsappNumber;
  final bool isPublic;
  final String profileUrl;
  final String createdAt;
  final String updatedAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.photoUrl,
    required this.services,
    required this.whatsappNumber,
    required this.isPublic,
    required this.profileUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        bio: json['bio'] as String?,
        photoUrl: json['photo_url'] as String?,
        services: List<String>.from(json['services'] as List),
        whatsappNumber: json['whatsapp_number'] as String,
        isPublic: json['is_public'] as bool,
        profileUrl: json['profile_url'] as String,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'display_name': displayName,
        'bio': bio,
        'photo_url': photoUrl,
        'services': services,
        'whatsapp_number': whatsappNumber,
        'is_public': isPublic,
        'profile_url': profileUrl,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  ProfileEntity toEntity() => ProfileEntity(
        id: id,
        userId: userId,
        displayName: displayName,
        bio: bio,
        photoUrl: photoUrl,
        services: services.map(_parseServiceType).toList(),
        whatsappNumber: whatsappNumber,
        isPublic: isPublic,
        profileUrl: profileUrl,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );

  static ServiceType _parseServiceType(String value) {
    switch (value) {
      case 'car_lock_programming':    return ServiceType.carLockProgramming;
      case 'door_lock_installation':  return ServiceType.doorLockInstallation;
      case 'door_lock_repair':        return ServiceType.doorLockRepair;
      case 'smart_lock_installation': return ServiceType.smartLockInstallation;
      default:                        return ServiceType.doorLockRepair;
    }
  }
}
