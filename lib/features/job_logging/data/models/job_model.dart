import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/job_entity.dart';

// Helper extension for snake_case conversion to match Supabase enums
extension on String {
  String toSnakeCase() {
    return replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}');
  }
}

class JobModel {
  final String id;
  final String userId;
  final String customerId;
  final ServiceType serviceType;
  final DateTime jobDate;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final int? amountCharged;
  final bool followUpSent;
  final DateTime? followUpSentAt;
  final String syncStatus;
  final String? syncErrorMessage;
  final bool isArchived;
  final String createdAt;
  final String updatedAt;

  JobModel({
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

  factory JobModel.fromJson(Map<String, dynamic> json) => JobModel(
    id: json['id'],
    userId: json['userId'] ?? json['user_id'],
    customerId: json['customerId'] ?? json['customer_id'],
    // FIX [JOB-001]: Compare against snake_case to match DB
    serviceType: ServiceType.values.firstWhere(
      (e) => e.name.toSnakeCase() == json['service_type'],
      orElse: () => ServiceType.values.first,
    ),
    jobDate: DateTime.parse(json['job_date']),
    location: json['location'],
    latitude: json['latitude']?.toDouble(),
    longitude: json['longitude']?.toDouble(),
    notes: json['notes'],
    amountCharged: json['amount_charged'] != null ? (num.parse(json['amount_charged'].toString()) * 100).round() : null,
    followUpSent: json['follow_up_sent'] ?? false,
    followUpSentAt: json['follow_up_sent_at'] != null ? DateTime.parse(json['follow_up_sent_at']) : null,
    syncStatus: json['sync_status'] ?? 'pending',
    syncErrorMessage: json['sync_error_message'],
    isArchived: json['is_archived'] ?? false,
    createdAt: json['created_at'],
    updatedAt: json['updated_at'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'customer_id': customerId,
    // FIX [JOB-001]: Convert to snake_case for Supabase compatibility
    'service_type': serviceType.name.toSnakeCase(),
    'job_date': jobDate.toIso8601String().split('T').first,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'notes': notes,
    'amount_charged': amountCharged != null ? amountCharged! / 100.0 : null,
    'follow_up_sent': followUpSent,
    'follow_up_sent_at': followUpSentAt?.toIso8601String(),
    'sync_status': syncStatus,
    'sync_error_message': syncErrorMessage,
    'is_archived': isArchived,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  JobEntity toEntity() => JobEntity(
    id: id,
    userId: userId,
    customerId: customerId,
    serviceType: serviceType,
    jobDate: jobDate,
    location: location,
    latitude: latitude,
    longitude: longitude,
    notes: notes,
    amountCharged: amountCharged,
    followUpSent: followUpSent,
    followUpSentAt: followUpSentAt,
    syncStatus: SyncStatus.values.firstWhere((e) => e.name == syncStatus),
    syncErrorMessage: syncErrorMessage,
    isArchived: isArchived,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );

  JobModel copyWith({
    String? id,
    String? userId,
    String? customerId,
    ServiceType? serviceType,
    DateTime? jobDate,
    String? location,
    double? latitude,
    double? longitude,
    String? notes,
    int? amountCharged,
    bool? followUpSent,
    DateTime? followUpSentAt,
    String? syncStatus,
    String? syncErrorMessage,
    bool? isArchived,
    String? createdAt,
    String? updatedAt,
  }) {
    return JobModel(
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
