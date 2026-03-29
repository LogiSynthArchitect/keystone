import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/job_entity.dart';

class JobModel {
  final String id;
  final String userId;
  final String customerId;
  final String serviceType;
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
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final double? quotedPrice;
  final String? hardwareBrand;
  final String? hardwareKeyway;
  final bool isDeleted;
  final DateTime? deletedAt;
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
    this.status = 'in_progress',
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.quotedPrice,
    this.hardwareBrand,
    this.hardwareKeyway,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) => JobModel(
    id: json['id'],
    userId: json['user_id'] ?? json['userId'],
    customerId: json['customer_id'] ?? json['customerId'],
    serviceType: json['service_type'] as String? ?? 'car_lock_programming',
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
    status: json['status'] as String? ?? 'in_progress',
    paymentStatus: json['payment_status'] as String? ?? 'unpaid',
    paymentMethod: json['payment_method'] as String?,
    quotedPrice: json['quoted_price'] != null ? (num.parse(json['quoted_price'].toString()) * 100).round().toDouble() : null,
    hardwareBrand: json['hardware_brand'] as String?,
    hardwareKeyway: json['hardware_keyway'] as String?,
    isDeleted: json['is_deleted'] as bool? ?? false,
    deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    createdAt: json['created_at'],
    updatedAt: json['updated_at'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'customer_id': customerId,
    'service_type': serviceType,
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
    'status': status,
    'payment_status': paymentStatus,
    'payment_method': paymentMethod,
    'quoted_price': quotedPrice != null ? quotedPrice! / 100.0 : null,
    'hardware_brand': hardwareBrand,
    'hardware_keyway': hardwareKeyway,
    'is_deleted': isDeleted,
    'deleted_at': deletedAt?.toIso8601String(),
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
    status: status,
    paymentStatus: paymentStatus,
    paymentMethod: paymentMethod,
    quotedPrice: quotedPrice,
    hardwareBrand: hardwareBrand,
    hardwareKeyway: hardwareKeyway,
    isDeleted: isDeleted,
    deletedAt: deletedAt,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
  );

  JobModel copyWith({
    String? id,
    String? userId,
    String? customerId,
    String? serviceType,
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
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    double? quotedPrice,
    String? hardwareBrand,
    String? hardwareKeyway,
    bool? isDeleted,
    DateTime? deletedAt,
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
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      quotedPrice: quotedPrice ?? this.quotedPrice,
      hardwareBrand: hardwareBrand ?? this.hardwareBrand,
      hardwareKeyway: hardwareKeyway ?? this.hardwareKeyway,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
