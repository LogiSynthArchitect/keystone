import '../../../../core/constants/app_enums.dart';

class ProfileEntity {
  final String id;
  final String userId;
  final String displayName;
  final String? bio;
  final String? photoUrl;
  final List<ServiceType> services;
  final String whatsappNumber;
  final bool isPublic;
  final String profileUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileEntity({
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

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;
  bool get hasBio => bio != null && bio!.isNotEmpty;
}
