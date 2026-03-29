import '../../domain/entities/follow_up_entity.dart';

class FollowUpModel {
  final String id;
  final String jobId;
  final String userId;
  final String customerId;
  final String messageText;
  final String sentAt;
  final bool deliveryConfirmed;
  final String responseStatus;
  final String? responseUpdatedAt;
  final String createdAt;

  const FollowUpModel({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.customerId,
    required this.messageText,
    required this.sentAt,
    required this.deliveryConfirmed,
    this.responseStatus = 'sent',
    this.responseUpdatedAt,
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
        responseStatus: json['response_status'] as String? ?? 'sent',
        responseUpdatedAt: json['response_updated_at'] as String?,
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
        'response_status': responseStatus,
        'response_updated_at': responseUpdatedAt,
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
        responseStatus: responseStatus,
        responseUpdatedAt: responseUpdatedAt != null ? DateTime.parse(responseUpdatedAt!) : null,
        createdAt: DateTime.parse(createdAt),
      );

  FollowUpModel copyWith({
    String? id,
    String? jobId,
    String? userId,
    String? customerId,
    String? messageText,
    String? sentAt,
    bool? deliveryConfirmed,
    String? responseStatus,
    String? responseUpdatedAt,
    String? createdAt,
  }) {
    return FollowUpModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      messageText: messageText ?? this.messageText,
      sentAt: sentAt ?? this.sentAt,
      deliveryConfirmed: deliveryConfirmed ?? this.deliveryConfirmed,
      responseStatus: responseStatus ?? this.responseStatus,
      responseUpdatedAt: responseUpdatedAt ?? this.responseUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
