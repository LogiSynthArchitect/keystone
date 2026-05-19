class UserPermissions {
  final bool canEditFinalPrice;
  final bool canDeleteJobs;
  final bool canViewKeyCodes;
  final bool requireAfterPhoto;

  const UserPermissions({
    this.canEditFinalPrice = true,
    this.canDeleteJobs = true,
    this.canViewKeyCodes = true,
    this.requireAfterPhoto = false,
  });

  static const defaults = UserPermissions();

  UserPermissions copyWith({
    bool? canEditFinalPrice,
    bool? canDeleteJobs,
    bool? canViewKeyCodes,
    bool? requireAfterPhoto,
  }) => UserPermissions(
    canEditFinalPrice: canEditFinalPrice ?? this.canEditFinalPrice,
    canDeleteJobs: canDeleteJobs ?? this.canDeleteJobs,
    canViewKeyCodes: canViewKeyCodes ?? this.canViewKeyCodes,
    requireAfterPhoto: requireAfterPhoto ?? this.requireAfterPhoto,
  );

  factory UserPermissions.fromJson(Map<String, dynamic> json) => UserPermissions(
    canEditFinalPrice: json['can_edit_final_price'] as bool? ?? true,
    canDeleteJobs: json['can_delete_jobs'] as bool? ?? true,
    canViewKeyCodes: json['can_view_key_codes'] as bool? ?? true,
    requireAfterPhoto: json['require_after_photo'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'can_edit_final_price': canEditFinalPrice,
    'can_delete_jobs': canDeleteJobs,
    'can_view_key_codes': canViewKeyCodes,
    'require_after_photo': requireAfterPhoto,
  };
}
