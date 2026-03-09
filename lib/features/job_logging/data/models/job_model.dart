import '../../domain/entities/job_entity.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';

class JobModel {
  final String id;
  final String userId;
  final String customerId;
  final String serviceType;
  final String jobDate;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final double? amountCharged;
  final bool followUpSent;
  final String? followUpSentAt;
  final String syncStatus;
  final bool isArchived;
  final String createdAt;
  final String updatedAt;

  const JobModel({
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

  factory JobModel.fromJson(Map<String, dynamic> json) => JobModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        customerId: json['customer_id'] as String,
        serviceType: json['service_type'] as String,
        jobDate: json['job_date'] as String,
        location: json['location'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        amountCharged: (json['amount_charged'] as num?)?.toDouble(),
        followUpSent: json['follow_up_sent'] as bool,
        followUpSentAt: json['follow_up_sent_at'] as String?,
        syncStatus: json['sync_status'] as String,
        isArchived: json['is_archived'] as bool,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'customer_id': customerId,
        'service_type': serviceType,
        'job_date': jobDate,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'amount_charged': amountCharged,
        'follow_up_sent': followUpSent,
        'follow_up_sent_at': followUpSentAt,
        'sync_status': syncStatus,
        'is_archived': isArchived,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  JobEntity toEntity() => JobEntity(
        id: id,
        userId: userId,
        customerId: customerId,
        serviceType: _parseServiceType(serviceType),
        jobDate: DateTime.parse(jobDate),
        location: location,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
        amountCharged: amountCharged,
        followUpSent: followUpSent,
        followUpSentAt: followUpSentAt != null ? DateTime.parse(followUpSentAt!) : null,
        syncStatus: _parseSyncStatus(syncStatus),
        isArchived: isArchived,
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

  static SyncStatus _parseSyncStatus(String value) {
    switch (value) {
      case 'synced': return SyncStatus.synced;
      case 'failed': return SyncStatus.failed;
      default:       return SyncStatus.pending;
    }
  }
}
