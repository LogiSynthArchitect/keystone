import '../../../../core/constants/app_enums.dart';

class JobEntity {
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
  final SyncStatus syncStatus;
  final String? syncErrorMessage;
  final bool isArchived;
  final String status;           // 'quoted' | 'in_progress' | 'completed' | 'invoiced'
  final String paymentStatus;    // 'unpaid' | 'partial' | 'paid'
  final String? paymentMethod;   // 'cash' | 'mobile_money' | 'bank_transfer' | 'other'
  final String? leadSource;
  final double? quotedPrice;
  final String? hardwareBrand;
  final String? hardwareKeyway;
  final DateTime? quotedAt;
  final DateTime? inProgressAt;
  final DateTime? completedAt;
  final DateTime? invoicedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? coverImageUrl;
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
  });

  bool get isSynced        => syncStatus == SyncStatus.synced;
  bool get isPending       => syncStatus == SyncStatus.pending;
  bool get hasAmount       => amountCharged != null && amountCharged! >= 0;
  bool get hasLocation     => location != null && location!.isNotEmpty;
  bool get hasCoordinates => latitude != null && longitude != null;
  bool get canSendFollowUp => !followUpSent && !isArchived;
  bool get isCompleted    => status == 'completed';
  bool get isInvoiced     => status == 'invoiced';
  bool get isPaid         => paymentStatus == 'paid';
  bool get isPartial      => paymentStatus == 'partial';
  bool get isDeleted_     => isDeleted;

  DateTime? get currentStatusTimestamp {
    switch (status) {
      case 'quoted':      return quotedAt;
      case 'in_progress': return inProgressAt;
      case 'completed':   return completedAt;
      case 'invoiced':    return invoicedAt;
      default:            return null;
    }
  }

  static const validStatuses = ['quoted', 'in_progress', 'completed', 'invoiced'];
  static const validPaymentStatuses = ['unpaid', 'partial', 'paid'];

  static const _statusOrder = ['quoted', 'in_progress', 'completed', 'invoiced'];

  static String? validateStatusTransition(String? from, String to) {
    if (!validStatuses.contains(to)) return 'Invalid status "$to".';
    if (from == null || from == to) return null;
    if (!validStatuses.contains(from)) return null;
    final fromIdx = _statusOrder.indexOf(from);
    final toIdx = _statusOrder.indexOf(to);
    if (toIdx < fromIdx) return 'Cannot move status backward from "$from" to "$to".';
    if (toIdx > fromIdx + 1) return 'Cannot skip status from "$from" to "$to". Must go through ${_statusOrder[fromIdx + 1]}.';
    return null;
  }

  static String? validatePaymentTransition(String status, String? from, String to) {
    if (!validPaymentStatuses.contains(to)) return 'Invalid payment status "$to".';
    if (from == to) return null;
    if (from == 'paid') return 'Cannot revert payment status from "paid".';
    if (from == 'partial' && to == 'unpaid') return 'Cannot revert from partial to unpaid. Use correction request.';
    if (to == 'paid' && status != 'invoiced') return 'Cannot mark as paid until job is invoiced.';
    if (to == 'partial' && status == 'quoted') return 'Cannot mark partial payment on a quoted job.';
    return null;
  }

  JobEntity copyWith({
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
    SyncStatus? syncStatus,
    String? syncErrorMessage,
    bool? isArchived,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    String? leadSource,
    double? quotedPrice,
    String? hardwareBrand,
    String? hardwareKeyway,
    DateTime? quotedAt,
    DateTime? inProgressAt,
    DateTime? completedAt,
    DateTime? invoicedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    String? coverImageUrl,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String? get hasCoverImage => coverImageUrl != null && coverImageUrl!.isNotEmpty ? coverImageUrl : null;
}
