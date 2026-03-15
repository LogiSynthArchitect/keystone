import '../../domain/entities/customer_entity.dart';

class CustomerModel {
  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String? location;
  final String? notes;
  final int totalJobs;
  final String? lastJobAt;
  final String syncStatus;
  final String createdAt;
  final String updatedAt;

  const CustomerModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    this.location,
    this.notes,
    required this.totalJobs,
    this.lastJobAt,
    this.syncStatus = 'synced',
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String,
        phoneNumber: json['phone_number'] as String,
        location: json['location'] as String?,
        notes: json['notes'] as String?,
        totalJobs: (json['total_jobs'] as num).toInt(),
        lastJobAt: json['last_job_at'] as String?,
        syncStatus: json['sync_status'] as String? ?? 'synced',
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'location': location,
        'notes': notes,
        'total_jobs': totalJobs,
        'last_job_at': lastJobAt,
        'sync_status': syncStatus,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  CustomerEntity toEntity() => CustomerEntity(
        id: id,
        userId: userId,
        fullName: fullName,
        phoneNumber: phoneNumber,
        location: location,
        notes: notes,
        totalJobs: totalJobs,
        lastJobAt: lastJobAt != null ? DateTime.parse(lastJobAt!) : null,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
