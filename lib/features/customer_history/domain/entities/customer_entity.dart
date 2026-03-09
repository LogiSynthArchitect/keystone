class CustomerEntity {
  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String? location;
  final String? notes;
  final int totalJobs;
  final DateTime? lastJobAt;
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
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRepeatCustomer => totalJobs > 1;
  bool get hasNotes => notes != null && notes!.isNotEmpty;
}
