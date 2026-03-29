class FollowUpEntity {
  final String id;
  final String jobId;
  final String userId;
  final String customerId;
  final String messageText;
  final DateTime sentAt;
  final bool deliveryConfirmed;
  final String responseStatus;       // 'sent' | 'responded' | 'no_response'
  final DateTime? responseUpdatedAt;
  final DateTime createdAt;

  const FollowUpEntity({
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

  FollowUpEntity copyWith({
    String? id,
    String? jobId,
    String? userId,
    String? customerId,
    String? messageText,
    DateTime? sentAt,
    bool? deliveryConfirmed,
    String? responseStatus,
    DateTime? responseUpdatedAt,
    DateTime? createdAt,
  }) {
    return FollowUpEntity(
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
