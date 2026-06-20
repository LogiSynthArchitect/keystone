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
  final DateTime? termsAcceptedAt;
  final int termsVersion;
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
    this.termsAcceptedAt,
    this.termsVersion = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;
  bool get hasBio => bio != null && bio!.isNotEmpty;
  bool get hasAcceptedTerms => termsAcceptedAt != null;

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
    DateTime? termsAcceptedAt,
    int? termsVersion,
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
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      termsVersion: termsVersion ?? this.termsVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
