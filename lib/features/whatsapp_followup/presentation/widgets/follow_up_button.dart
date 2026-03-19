import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/whatsapp_launcher.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/features/whatsapp_followup/presentation/providers/follow_up_provider.dart';
import '../providers/editable_followup_provider.dart';

class FollowUpButton extends ConsumerWidget {
  final JobEntity job;
  const FollowUpButton({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (job.followUpSent) {
      return GestureDetector(
        onLongPress: () {
          // Allow the user to manually mark as unsent if they backed out of WhatsApp
          ref.read(jobListProvider.notifier).toggleFollowUpSent(job.id, false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Follow-up marked as unsent.')),
          );
        },
        child: Container(
          width: double.infinity,
          color: AppColors.success600.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LineAwesomeIcons.check_circle, color: AppColors.success500),
              const SizedBox(width: 8),
              Text(
                "WHATSAPP OPENED", 
                style: AppTextStyles.h2.copyWith(color: AppColors.success500, fontWeight: FontWeight.w900)
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.accent500,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            final customer = ref.read(customerDetailProvider(job.customerId)).valueOrNull;
            final profile = ref.read(profileProvider).profile;
            final editState = ref.read(editableFollowUpProvider(job));
            
            if (customer != null && profile != null && editState.isInitialized) {
              final message = editState.controller.text.trim();

              try {
                await WhatsAppLauncher.openChat(
                  phoneNumber: customer.phoneNumber,
                  message: message,
                );
                
                // Track follow-up in the analytics/system
                ref.read(followUpProvider(job.id).notifier).send(
                  jobId: job.id,
                  customerId: customer.id,
                  customerPhone: customer.phoneNumber,
                  customerName: customer.fullName,
                  technicianName: profile.displayName,
                  serviceType: job.serviceType.name,
                  profileUrl: profile.profileUrl,
                );

                // Update the job locally to show 'SENT' immediately
                ref.read(jobListProvider.notifier).toggleFollowUpSent(job.id, true);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening WhatsApp... Remember to hit the Send arrow!'),
                      backgroundColor: AppColors.success600,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SEND WHATSAPP FOLLOW-UP',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.primary900,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const Icon(LineAwesomeIcons.whatsapp, color: AppColors.primary900, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
