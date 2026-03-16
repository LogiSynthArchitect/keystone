import '../../../../core/constants/app_enums.dart';

class JobEntity {
  final String id;
  final String userId;
  final String customerId;
  final ServiceType serviceType;
  final DateTime jobDate;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final double? amountCharged;
  final bool followUpSent;
  final DateTime? followUpSentAt;
  final SyncStatus syncStatus;
  final String? syncErrorMessage;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobEntity({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.serviceType,
    required this.jobDate,
    this.location,
    this.latitude,
    this.longitude,
    this.notes,
    this.amountCharged,
    required this.followUpSent,
    this.followUpSentAt,
    required this.syncStatus,
    this.syncErrorMessage,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSynced        => syncStatus == SyncStatus.synced;
  bool get isPending       => syncStatus == SyncStatus.pending;
  bool get hasAmount       => amountCharged != null && amountCharged! >= 0;
  bool get hasLocation     => location != null && location!.isNotEmpty;
  bool get hasCoordinates => latitude != null && longitude != null;
  bool get canSendFollowUp => !followUpSent && !isArchived;

  JobEntity copyWith({
    String? id,
    String? userId,
    String? customerId,
    ServiceType? serviceType,
    DateTime? jobDate,
    String? location,
    double? latitude,
    double? longitude,
    String? notes,
    double? amountCharged,
    bool? followUpSent,
    DateTime? followUpSentAt,
    SyncStatus? syncStatus,
    String? syncErrorMessage,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      serviceType: serviceType ?? this.serviceType,
      jobDate: jobDate ?? this.jobDate,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      amountCharged: amountCharged ?? this.amountCharged,
      followUpSent: followUpSent ?? this.followUpSent,
      followUpSentAt: followUpSentAt ?? this.followUpSentAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncErrorMessage: syncErrorMessage ?? this.syncErrorMessage,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
