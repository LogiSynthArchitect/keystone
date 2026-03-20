import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/constants/whatsapp_constants.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import '../providers/editable_followup_provider.dart';

class FollowUpMessagePreview extends ConsumerStatefulWidget {
  final JobEntity job;
  const FollowUpMessagePreview({super.key, required this.job});

  @override
  ConsumerState<FollowUpMessagePreview> createState() => _FollowUpMessagePreviewState();
}

class _FollowUpMessagePreviewState extends ConsumerState<FollowUpMessagePreview> {
  @override
  void initState() {
    super.initState();
    // Initialize the editable message state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editableFollowUpProvider(widget.job).notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerDetailProvider(widget.job.customerId));
    final profileState = ref.watch(profileProvider);
    final editState = ref.watch(editableFollowUpProvider(widget.job));

    return customerAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (customer) {
        // Retry initialization whenever customer data is available but not yet initialized
        if (!editState.isInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) ref.read(editableFollowUpProvider(widget.job).notifier).initialize();
          });
        }
        if (profileState.profile == null || !editState.isInitialized) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.ksc.primary700),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LineAwesomeIcons.whatsapp, color: context.ksc.accent500, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "MESSAGE PREVIEW",
                        style: AppTextStyles.labelSmall.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                  Tooltip(
                    message: "Restore original message",
                    child: GestureDetector(
                      onTap: () {
                        final message = WhatsAppConstants.buildFollowUpMessage(
                          customerName: customer?.fullName ?? "Customer",
                          technicianName: profileState.profile!.displayName,
                          serviceType: widget.job.serviceType.name,
                          profileUrl: profileState.profile!.profileUrl,
                        );
                        editState.controller.text = message;
                      },
                      child: Icon(LineAwesomeIcons.undo_solid, color: context.ksc.neutral500, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: editState.controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: AppTextStyles.body.copyWith(color: context.ksc.white, height: 1.6, fontStyle: FontStyle.italic),
                cursorColor: context.ksc.accent500,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Type your custom message...",
                  hintStyle: TextStyle(color: context.ksc.neutral600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
