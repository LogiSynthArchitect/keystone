import '../../../../core/constants/app_enums.dart';

class CustomerEntity {
  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String? location;
  final String? notes;
  final int totalJobs;
  final DateTime? lastJobAt;
  final SyncStatus syncStatus;
  final String? syncErrorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerEntity({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    this.location,
    this.notes,
    required this.totalJobs,
    this.lastJobAt,
    this.syncStatus = SyncStatus.synced,
    this.syncErrorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRepeatCustomer => totalJobs > 1;
  bool get hasNotes => notes != null && notes!.isNotEmpty;
  bool get isSynced => syncStatus == SyncStatus.synced;
  bool get isFailed => syncStatus == SyncStatus.failed;

  CustomerEntity copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? location,
    String? notes,
    int? totalJobs,
    DateTime? lastJobAt,
    SyncStatus? syncStatus,
    String? syncErrorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerEntity(
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
