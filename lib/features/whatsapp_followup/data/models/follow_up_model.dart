import '../../domain/entities/follow_up_entity.dart';

class FollowUpModel {
  final String id;
  final String jobId;
  final String userId;
  final String customerId;
  final String messageText;
  final String sentAt;
  final bool deliveryConfirmed;
  final String createdAt;

  const FollowUpModel({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.customerId,
    required this.messageText,
    required this.sentAt,
    required this.deliveryConfirmed,
    required this.createdAt,
  });

  factory FollowUpModel.fromJson(Map<String, dynamic> json) => FollowUpModel(
        id: json['id'] as String,
        jobId: json['job_id'] as String,
        userId: json['user_id'] as String,
        customerId: json['customer_id'] as String,
        messageText: json['message_text'] as String,
        sentAt: json['sent_at'] as String,
        deliveryConfirmed: json['delivery_confirmed'] as bool,
        createdAt: json['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_id': jobId,
        'user_id': userId,
        'customer_id': customerId,
        'message_text': messageText,
        'sent_at': sentAt,
        'delivery_confirmed': deliveryConfirmed,
        'created_at': createdAt,
      };

  FollowUpEntity toEntity() => FollowUpEntity(
        id: id,
        jobId: jobId,
        userId: userId,
        customerId: customerId,
        messageText: messageText,
        sentAt: DateTime.parse(sentAt),
        deliveryConfirmed: deliveryConfirmed,
        createdAt: DateTime.parse(createdAt),
      );
}
