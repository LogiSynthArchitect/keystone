import '../../../../core/constants/app_enums.dart';
import '../../../../core/utils/phone_formatter.dart';
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
  final SyncStatus syncStatus;
  final String? syncErrorMessage;
  final String? propertyType;
  final String? leadSource;
  final String? coverImageUrl;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final int syncVersion;

  CustomerModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required String phoneNumber,
    this.location,
    this.notes,
    required this.totalJobs,
    this.lastJobAt,
    this.syncStatus = SyncStatus.synced,
    this.syncErrorMessage,
    this.propertyType,
    this.leadSource,
    this.coverImageUrl,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.syncVersion = 1,
  }) : phoneNumber = PhoneFormatter.normalize(phoneNumber);

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        fullName: (json['full_name'] as String?) ?? '',
        phoneNumber: json['phone_number'] as String,
        location: json['location'] as String?,
        notes: json['notes'] as String?,
        totalJobs: ((json['total_jobs'] as num?)?.toInt() ?? 0),
        lastJobAt: json['last_job_at'] as String?,
        syncStatus: _parseSyncStatus(json['sync_status'] as String? ?? 'synced'),
        syncErrorMessage: json['sync_error_message'] as String?,
        propertyType: json['property_type'] as String?,
        leadSource: json['lead_source'] as String?,
        coverImageUrl: json['cover_image_url'] as String?,
        deletedAt: json['deleted_at'] as String?,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
        syncVersion: ((json['sync_version'] as num?)?.toInt() ?? 1),
      );

  static SyncStatus _parseSyncStatus(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncStatus.synced,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'location': location,
        'notes': notes,
        'total_jobs': totalJobs,
        'last_job_at': lastJobAt,
        'sync_status': syncStatus.name,
        'sync_error_message': syncErrorMessage,
        'property_type': propertyType,
        'lead_source': leadSource,
        'cover_image_url': coverImageUrl,
        if (deletedAt != null) 'deleted_at': deletedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'sync_version': syncVersion,
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
        syncStatus: syncStatus,
        syncErrorMessage: syncErrorMessage,
        propertyType: propertyType,
        leadSource: leadSource,
        coverImageUrl: coverImageUrl,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        syncVersion: syncVersion,
      );

  CustomerModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? location,
    String? notes,
    int? totalJobs,
    String? lastJobAt,
    SyncStatus? syncStatus,
    String? syncErrorMessage,
    String? propertyType,
    String? leadSource,
    String? coverImageUrl,
    Object? deletedAt = _sentinel,
    String? createdAt,
    String? updatedAt,
    int? syncVersion,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      totalJobs: totalJobs ?? this.totalJobs,
      lastJobAt: lastJobAt ?? this.lastJobAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncErrorMessage: syncErrorMessage ?? this.syncErrorMessage,
      propertyType: propertyType ?? this.propertyType,
      leadSource: leadSource ?? this.leadSource,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      deletedAt: deletedAt == _sentinel ? this.deletedAt : deletedAt as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncVersion: syncVersion ?? this.syncVersion,
    );
  }

  static const _sentinel = Object();
}
