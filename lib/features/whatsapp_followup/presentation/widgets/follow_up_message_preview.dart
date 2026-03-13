import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/whatsapp_constants.dart';
import '../../../job_logging/domain/entities/job_entity.dart';
import '../../../customer_history/presentation/providers/customer_providers.dart';
import '../../../technician_profile/presentation/providers/profile_provider.dart';

class FollowUpMessagePreview extends ConsumerWidget {
  final JobEntity job;
  const FollowUpMessagePreview({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(job.customerId));
    final profileState = ref.watch(profileProvider);

    return customerAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (customer) {
        if (profileState.profile == null) return const SizedBox.shrink();
        
        final message = WhatsAppConstants.buildFollowUpMessage(
          customerName: customer?.fullName ?? "Customer",
          technicianName: profileState.profile!.displayName,
          serviceType: job.serviceType.name,
          profileUrl: profileState.profile!.profileUrl,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: AppColors.accent500, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "MESSAGE PREVIEW", 
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w900)
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: AppTextStyles.body.copyWith(color: AppColors.neutral400, height: 1.5, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      },
    );
  }
}
