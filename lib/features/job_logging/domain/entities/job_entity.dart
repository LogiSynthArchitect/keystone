import '../../../technician_profile/domain/entities/profile_entity.dart';

enum SyncStatus { pending, synced, failed }

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
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSynced       => syncStatus == SyncStatus.synced;
  bool get isPending      => syncStatus == SyncStatus.pending;
  bool get hasAmount      => amountCharged != null && amountCharged! > 0;
  bool get hasLocation    => location != null && location!.isNotEmpty;
  bool get hasCoordinates => latitude != null && longitude != null;
  bool get canSendFollowUp => !followUpSent && !isArchived;
}
