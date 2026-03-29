class JobPartEntity {
  final String id;
  final String jobId;
  final String partName;
  final int? quantity;
  final int? unitPrice; // In pesewas
  final DateTime createdAt;

  const JobPartEntity({
    required this.id,
    required this.jobId,
    required this.partName,
    this.quantity,
    this.unitPrice,
    required this.createdAt,
  });

  int get totalCost => (quantity ?? 0) * (unitPrice ?? 0);
}
