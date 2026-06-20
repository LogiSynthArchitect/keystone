import '../../domain/entities/job_expense_entity.dart';

class JobExpenseModel {
  final String id;
  final String jobId;
  final String category;
  final String description;
  final int amount;
  final String createdAt;

  const JobExpenseModel({
    required this.id,
    required this.jobId,
    required this.category,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  factory JobExpenseModel.fromJson(Map<String, dynamic> json) => JobExpenseModel(
    id: json['id'] as String,
    jobId: json['job_id'] as String,
    category: (json['category'] as String?) ?? '',
    description: (json['description'] as String?) ?? '',
    amount: (json['amount'] as int?) ?? 0,
    createdAt: json['created_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'job_id': jobId,
    'category': category,
    'description': description,
    'amount': amount,
    'created_at': createdAt,
  };

  JobExpenseEntity toEntity() => JobExpenseEntity(
    id: id,
    jobId: jobId,
    category: category,
    description: description,
    amount: amount,
    createdAt: DateTime.parse(createdAt),
  );

  factory JobExpenseModel.fromEntity(JobExpenseEntity entity) => JobExpenseModel(
    id: entity.id,
    jobId: entity.jobId,
    category: entity.category,
    description: entity.description,
    amount: entity.amount,
    createdAt: entity.createdAt.toIso8601String(),
  );
}
