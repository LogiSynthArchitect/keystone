class FollowUpEntity {
  final String id;
  final String jobId;
  final String userId;
  final String customerId;
  final String messageText;
  final DateTime sentAt;
  final bool deliveryConfirmed;
  final DateTime createdAt;

  const FollowUpEntity({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.customerId,
    required this.messageText,
    required this.sentAt,
    required this.deliveryConfirmed,
    required this.createdAt,
  });
}
