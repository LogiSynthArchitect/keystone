class UserPermissions {
  final bool canEditFinalPrice;
  final bool canDeleteJobs;
  final bool canViewKeyCodes;

  const UserPermissions({
    this.canEditFinalPrice = true,
    this.canDeleteJobs = true,
    this.canViewKeyCodes = true,
  });

  static const defaults = UserPermissions();

  UserPermissions copyWith({
    bool? canEditFinalPrice,
    bool? canDeleteJobs,
    bool? canViewKeyCodes,
  }) => UserPermissions(
    canEditFinalPrice: canEditFinalPrice ?? this.canEditFinalPrice,
    canDeleteJobs: canDeleteJobs ?? this.canDeleteJobs,
    canViewKeyCodes: canViewKeyCodes ?? this.canViewKeyCodes,
  );

  factory UserPermissions.fromJson(Map<String, dynamic> json) => UserPermissions(
    canEditFinalPrice: json['can_edit_final_price'] as bool? ?? true,
    canDeleteJobs: json['can_delete_jobs'] as bool? ?? true,
    canViewKeyCodes: json['can_view_key_codes'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'can_edit_final_price': canEditFinalPrice,
    'can_delete_jobs': canDeleteJobs,
    'can_view_key_codes': canViewKeyCodes,
  };
}
