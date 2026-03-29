class ProfileEntity {
  final String id;
  final String userId;
  final String displayName;
  final String? bio;
  final String? photoUrl;
  final List<String> services;
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

  ProfileEntity copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? bio,
    String? photoUrl,
    List<String>? services,
    String? whatsappNumber,
    bool? isPublic,
    String? profileUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      services: services ?? this.services,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      isPublic: isPublic ?? this.isPublic,
      profileUrl: profileUrl ?? this.profileUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
