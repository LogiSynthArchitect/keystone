import '../../../../core/utils/phone_formatter.dart';
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
  final String? termsAcceptedAt;
  final int termsVersion;
  final String createdAt;
  final String updatedAt;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.photoUrl,
    required this.services,
    required String whatsappNumber,
    required this.isPublic,
    required this.profileUrl,
    this.termsAcceptedAt,
    this.termsVersion = 0,
    required this.createdAt,
    required this.updatedAt,
  }) : whatsappNumber = PhoneFormatter.normalize(whatsappNumber);

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final whatsapp = (json['whatsapp_number'] as String?) ?? '';
    return ProfileModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        displayName: (json['display_name'] as String?) ?? '',
        bio: json['bio'] as String?,
        photoUrl: json['photo_url'] as String?,
        services: List<String>.from(json['services'] as List? ?? []),
        whatsappNumber: whatsapp,
        isPublic: json['is_public'] as bool? ?? true,
        profileUrl: (json['profile_url'] as String?) ?? '',
        termsAcceptedAt: json['terms_accepted_at'] as String?,
        termsVersion: json['terms_version'] as int? ?? 0,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );
  }

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
        'terms_accepted_at': termsAcceptedAt,
        'terms_version': termsVersion,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  ProfileEntity toEntity() => ProfileEntity(
        id: id,
        userId: userId,
        displayName: displayName,
        bio: bio,
        photoUrl: photoUrl,
        services: services,
        whatsappNumber: whatsappNumber,
        isPublic: isPublic,
        profileUrl: profileUrl,
        termsAcceptedAt: termsAcceptedAt != null ? DateTime.parse(termsAcceptedAt!) : null,
        termsVersion: termsVersion,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
