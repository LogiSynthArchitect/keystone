import '../../../../core/usecases/use_case.dart';
import '../../../../core/utils/whatsapp_launcher.dart';
import '../entities/follow_up_entity.dart';
import '../repositories/follow_up_repository.dart';

class SendFollowupParams {
  final String jobId;
  final String customerId;
  final String customerPhone;
  final String messageText;

  const SendFollowupParams({
    required this.jobId,
    required this.customerId,
    required this.customerPhone,
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

    // Open WhatsApp
    await WhatsAppLauncher.openChat(
      phoneNumber: params.customerPhone,
      message: params.messageText,
    );

    // Record the follow-up
    final now = DateTime.now();
    final followUp = FollowUpEntity(
      id: '',
      jobId: params.jobId,
      userId: '',
      customerId: params.customerId,
      messageText: params.messageText,
      sentAt: now,
      deliveryConfirmed: false,
      createdAt: now,
    );

    return _repository.createFollowUp(followUp);
  }
}
