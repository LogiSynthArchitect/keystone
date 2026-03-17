import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/whatsapp_constants.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';

class EditableFollowUpState {
  final TextEditingController controller;
  final bool isInitialized;

  EditableFollowUpState({
    required this.controller,
    this.isInitialized = false,
  });

  EditableFollowUpState copyWith({
    TextEditingController? controller,
    bool? isInitialized,
  }) => EditableFollowUpState(
    controller: controller ?? this.controller,
    isInitialized: isInitialized ?? this.isInitialized,
  );
}

class EditableFollowUpNotifier extends StateNotifier<EditableFollowUpState> {
  final Ref _ref;
  final JobEntity _job;

  EditableFollowUpNotifier(this._ref, this._job) 
      : super(EditableFollowUpState(controller: TextEditingController()));

  void initialize() {
    if (state.isInitialized) return;

    final customer = _ref.read(customerDetailProvider(_job.customerId)).valueOrNull;
    final profile = _ref.read(profileProvider).profile;

    if (customer != null && profile != null) {
      final message = WhatsAppConstants.buildFollowUpMessage(
        customerName: customer.fullName,
        technicianName: profile.displayName,
        serviceType: _job.serviceType.name,
        profileUrl: profile.profileUrl,
      );
      state.controller.text = message;
      state = state.copyWith(isInitialized: true);
    }
  }

  @override
  void dispose() {
    state.controller.dispose();
    super.dispose();
  }
}

final editableFollowUpProvider = StateNotifierProvider.family<EditableFollowUpNotifier, EditableFollowUpState, JobEntity>((ref, job) {
  return EditableFollowUpNotifier(ref, job);
});
