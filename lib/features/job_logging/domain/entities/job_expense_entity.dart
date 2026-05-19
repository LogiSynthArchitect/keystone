class JobExpenseEntity {
  final String id;
  final String jobId;
  final String category;
  final String description;
  final int amount;
  final DateTime createdAt;

  const JobExpenseEntity({
    required this.id,
    required this.jobId,
    required this.category,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  String get categoryLabel {
    switch (category) {
      case 'transport':     return 'Transport';
      case 'parking':       return 'Parking';
      case 'subcontractor': return 'Subcontractor';
      case 'supplies':      return 'Supplies';
      case 'other':         return 'Other';
      default:              return category;
    }
  }

  JobExpenseEntity copyWith({
    String? id,
    String? jobId,
    String? category,
    String? description,
    int? amount,
    DateTime? createdAt,
  }) {
    return JobExpenseEntity(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
