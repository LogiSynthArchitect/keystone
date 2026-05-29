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
  final String? leadSource;
  final double? quotedPrice;
  final String? hardwareBrand;
  final String? hardwareKeyway;
  final String? quotedAt;
  final String? inProgressAt;
  final String? completedAt;
  final String? invoicedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? coverImageUrl;
  final String createdAt;
  final String updatedAt;
  final bool subEntitiesSaved;
  final String? generatedFromScheduleId;
  final String? generationBatchId;

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
    this.leadSource,
    this.quotedPrice,
    this.hardwareBrand,
    this.hardwareKeyway,
    this.quotedAt,
    this.inProgressAt,
    this.completedAt,
    this.invoicedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.coverImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.subEntitiesSaved = true,
    this.generatedFromScheduleId,
    this.generationBatchId,
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
    leadSource: json['lead_source'] as String?,
    quotedPrice: json['quoted_price'] != null ? (num.parse(json['quoted_price'].toString()) * 100).round().toDouble() : null,
    hardwareBrand: json['hardware_brand'] as String?,
    hardwareKeyway: json['hardware_keyway'] as String?,
    quotedAt: json['quoted_at'] as String?,
    inProgressAt: json['in_progress_at'] as String?,
    completedAt: json['completed_at'] as String?,
    invoicedAt: json['invoiced_at'] as String?,
    isDeleted: json['is_deleted'] as bool? ?? false,
    deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    coverImageUrl: json['cover_image_url'] as String?,
    subEntitiesSaved: json['sub_entities_saved'] as bool? ?? true,
    generatedFromScheduleId: json['generated_from_schedule_id'] as String?,
    generationBatchId: json['generation_batch_id'] as String?,
    createdAt: json['created_at'],
    updatedAt: json['updated_at'],
  );

  factory JobModel.fromEntity(JobEntity entity) => JobModel(
    id: entity.id,
    userId: entity.userId,
    customerId: entity.customerId,
    serviceType: entity.serviceType,
    jobDate: entity.jobDate,
    location: entity.location,
    latitude: entity.latitude,
    longitude: entity.longitude,
    notes: entity.notes,
    amountCharged: entity.amountCharged,
    followUpSent: entity.followUpSent,
    followUpSentAt: entity.followUpSentAt,
    syncStatus: entity.syncStatus.name,
    syncErrorMessage: entity.syncErrorMessage,
    isArchived: entity.isArchived,
    status: entity.status,
    paymentStatus: entity.paymentStatus,
    paymentMethod: entity.paymentMethod,
    leadSource: entity.leadSource,
    quotedPrice: entity.quotedPrice,
    hardwareBrand: entity.hardwareBrand,
    hardwareKeyway: entity.hardwareKeyway,
    quotedAt: entity.quotedAt?.toIso8601String(),
    inProgressAt: entity.inProgressAt?.toIso8601String(),
    completedAt: entity.completedAt?.toIso8601String(),
    invoicedAt: entity.invoicedAt?.toIso8601String(),
    isDeleted: entity.isDeleted,
    deletedAt: entity.deletedAt,
    coverImageUrl: entity.coverImageUrl,
    subEntitiesSaved: entity.subEntitiesSaved,
    generatedFromScheduleId: entity.generatedFromScheduleId,
    generationBatchId: entity.generationBatchId,
    createdAt: entity.createdAt.toIso8601String(),
    updatedAt: entity.updatedAt.toIso8601String(),
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
    'lead_source': leadSource,
    'quoted_price': quotedPrice != null ? quotedPrice! / 100.0 : null,
    'hardware_brand': hardwareBrand,
    'hardware_keyway': hardwareKeyway,
    'quoted_at': quotedAt,
    'in_progress_at': inProgressAt,
    'completed_at': completedAt,
    'invoiced_at': invoicedAt,
    'is_deleted': isDeleted,
    'deleted_at': deletedAt?.toIso8601String(),
    'cover_image_url': coverImageUrl,
    'sub_entities_saved': subEntitiesSaved,
    'generated_from_schedule_id': generatedFromScheduleId,
    'generation_batch_id': generationBatchId,
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
    leadSource: leadSource,
    quotedPrice: quotedPrice,
    hardwareBrand: hardwareBrand,
    hardwareKeyway: hardwareKeyway,
    quotedAt: quotedAt != null ? DateTime.parse(quotedAt!) : null,
    inProgressAt: inProgressAt != null ? DateTime.parse(inProgressAt!) : null,
    completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
    invoicedAt: invoicedAt != null ? DateTime.parse(invoicedAt!) : null,
    isDeleted: isDeleted,
    deletedAt: deletedAt,
    coverImageUrl: coverImageUrl,
    subEntitiesSaved: subEntitiesSaved,
    generatedFromScheduleId: generatedFromScheduleId,
    generationBatchId: generationBatchId,
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
    String? leadSource,
    double? quotedPrice,
    String? hardwareBrand,
    String? hardwareKeyway,
    String? quotedAt,
    String? inProgressAt,
    String? completedAt,
    String? invoicedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    String? coverImageUrl,
    bool? subEntitiesSaved,
    String? generatedFromScheduleId,
    String? generationBatchId,
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
      leadSource: leadSource ?? this.leadSource,
      quotedPrice: quotedPrice ?? this.quotedPrice,
      hardwareBrand: hardwareBrand ?? this.hardwareBrand,
      hardwareKeyway: hardwareKeyway ?? this.hardwareKeyway,
      quotedAt: quotedAt ?? this.quotedAt,
      inProgressAt: inProgressAt ?? this.inProgressAt,
      completedAt: completedAt ?? this.completedAt,
      invoicedAt: invoicedAt ?? this.invoicedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      subEntitiesSaved: subEntitiesSaved ?? this.subEntitiesSaved,
      generatedFromScheduleId: generatedFromScheduleId ?? this.generatedFromScheduleId,
      generationBatchId: generationBatchId ?? this.generationBatchId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
