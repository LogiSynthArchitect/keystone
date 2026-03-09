import '../../../../core/usecases/use_case.dart';
import '../../../../core/constants/whatsapp_constants.dart';

class BuildFollowupMessageParams {
  final String customerName;
  final String technicianName;
  final String serviceType;
  final String profileUrl;

  const BuildFollowupMessageParams({
    required this.customerName,
    required this.technicianName,
    required this.serviceType,
    required this.profileUrl,
  });
}

class BuildFollowupMessageUsecase
    implements UseCase<String, BuildFollowupMessageParams> {
  @override
  Future<String> call(BuildFollowupMessageParams params) async {
    return WhatsAppConstants.buildFollowUpMessage(
      customerName: params.customerName,
      technicianName: params.technicianName,
      serviceType: params.serviceType,
      profileUrl: params.profileUrl,
    );
  }
}
