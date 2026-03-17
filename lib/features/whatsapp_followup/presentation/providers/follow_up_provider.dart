import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/constants/whatsapp_constants.dart';
import '../../data/datasources/follow_up_remote_datasource.dart';
import '../../data/datasources/follow_up_local_datasource.dart';
import '../../data/repositories/follow_up_repository_impl.dart';
import '../../domain/entities/follow_up_entity.dart';
import '../../domain/repositories/follow_up_repository.dart';
import '../../domain/usecases/send_followup_usecase.dart';
import '../../domain/usecases/build_followup_message_usecase.dart';

final followUpRemoteDatasourceProvider = Provider<FollowUpRemoteDatasource>(
  (ref) => FollowUpRemoteDatasource(ref.watch(supabaseClientProvider)));

final followUpLocalDatasourceProvider = Provider<FollowUpLocalDatasource>(
  (ref) => FollowUpLocalDatasource());

final followUpRepositoryProvider = Provider<FollowUpRepository>(
  (ref) => FollowUpRepositoryImpl(
    ref.watch(followUpRemoteDatasourceProvider), 
    ref.watch(supabaseClientProvider),
    ref.watch(followUpLocalDatasourceProvider),
  ));

final sendFollowupUsecaseProvider = Provider<SendFollowupUsecase>(
  (ref) => SendFollowupUsecase(ref.watch(followUpRepositoryProvider)));

final buildFollowupMessageUsecaseProvider = Provider<BuildFollowupMessageUsecase>(
  (ref) => BuildFollowupMessageUsecase());

class FollowUpState {
  final bool isLoading;
  final bool isSent;
  final String? errorMessage;
  final String? previewMessage;
  final FollowUpEntity? followUp;

  const FollowUpState({
    this.isLoading = false,
    this.isSent = false,
    this.errorMessage,
    this.previewMessage,
    this.followUp,
  });

  FollowUpState copyWith({
    bool? isLoading,
    bool? isSent,
    String? errorMessage,
    String? previewMessage,
    FollowUpEntity? followUp,
    bool clearError = false,
  }) => FollowUpState(
    isLoading: isLoading ?? this.isLoading,
    isSent: isSent ?? this.isSent,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    previewMessage: previewMessage ?? this.previewMessage,
    followUp: followUp ?? this.followUp,
  );
}

class FollowUpNotifier extends StateNotifier<FollowUpState> {
  final SendFollowupUsecase _sendFollowup;
  final String _userId;
  FollowUpNotifier(this._sendFollowup, this._userId) : super(const FollowUpState());

  void buildPreview({
    required String customerName,
    required String technicianName,
    required String serviceType,
    required String profileUrl,
  }) {
    final message = WhatsAppConstants.buildFollowUpMessage(
      customerName: customerName,
      technicianName: technicianName,
      serviceType: serviceType,
      profileUrl: profileUrl,
    );
    state = state.copyWith(previewMessage: message);
  }

  Future<bool> send({
    required String jobId,
    required String customerId,
    required String customerPhone,
    required String customerName,
    required String technicianName,
    required String serviceType,
    required String profileUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final message = WhatsAppConstants.buildFollowUpMessage(
        customerName: customerName,
        technicianName: technicianName,
        serviceType: serviceType,
        profileUrl: profileUrl,
      );
      final followUp = await _sendFollowup(SendFollowupParams(
        userId: _userId,
        jobId: jobId,
        customerId: customerId,
        customerPhone: customerPhone,
        messageText: message,
      ));
      state = state.copyWith(isLoading: false, isSent: true, followUp: followUp, previewMessage: message);
      return true;
    } catch (e) {
state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void reset() => state = const FollowUpState();
}

final followUpProvider = StateNotifierProvider.family<FollowUpNotifier, FollowUpState, String>(
  (ref, jobId) => FollowUpNotifier(
    ref.watch(sendFollowupUsecaseProvider),
    ref.watch(supabaseClientProvider).auth.currentUser?.id ?? '',
  ),
);
