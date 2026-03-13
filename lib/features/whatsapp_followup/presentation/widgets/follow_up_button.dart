import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/whatsapp_launcher.dart';
import '../../../../core/constants/whatsapp_constants.dart';
import '../../../job_logging/domain/entities/job_entity.dart';
import '../../../customer_history/presentation/providers/customer_providers.dart';
import '../../../technician_profile/presentation/providers/profile_provider.dart';

class FollowUpButton extends ConsumerWidget {
  final JobEntity job;
  const FollowUpButton({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (job.followUpSent) {
      return Container(
        width: double.infinity,
        color: AppColors.success600.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LineAwesomeIcons.check_circle, color: AppColors.success500),
            const SizedBox(width: 8),
            Text(
              "FOLLOW-UP SENT", 
              style: AppTextStyles.h2.copyWith(color: AppColors.success500, fontWeight: FontWeight.w900)
            ),
          ],
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
            final customer = ref.read(customerDetailProvider(job.customerId)).value;
            final profile = ref.read(profileProvider).profile;
            
            if (customer != null && profile != null) {
              final message = WhatsAppConstants.buildFollowUpMessage(
                customerName: customer.fullName,
                technicianName: profile.displayName,
                serviceType: job.serviceType.name,
                profileUrl: profile.profileUrl,
              );

              await WhatsAppLauncher.openChat(
                phoneNumber: customer.phoneNumber,
                message: message,
              );
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
