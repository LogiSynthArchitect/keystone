import '../../../../core/usecases/use_case.dart';
import '../entities/follow_up_entity.dart';
import '../repositories/follow_up_repository.dart';

class SendFollowupParams {
  final String userId;
  final String jobId;
  final String customerId;
  final String messageText;

  const SendFollowupParams({
    required this.userId,
    required this.jobId,
    required this.customerId,
    required this.messageText,
  });
}

class SendFollowupUsecase implements UseCase<FollowUpEntity, SendFollowupParams> {
  final FollowUpRepository _repository;
  SendFollowupUsecase(this._repository);

  @override
  Future<FollowUpEntity> call(SendFollowupParams params) async {
    // Check not already sent
    final existing = await _repository.getFollowUpByJobId(params.jobId);
    if (existing != null) {
      return existing;
    }

    // Record the follow-up — only persist if jobId is a valid UUID
    final now = DateTime.now();
    final followUp = FollowUpEntity(
      id: '',
      jobId: params.jobId,
      userId: params.userId,
      customerId: params.customerId,
      messageText: params.messageText,
      sentAt: now,
      deliveryConfirmed: false,
      createdAt: now,
    );

    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    if (!uuidRegex.hasMatch(params.jobId)) return followUp;

    return _repository.createFollowUp(followUp);
  }
}


