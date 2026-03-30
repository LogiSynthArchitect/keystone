import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
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
      return Consumer(builder: (context, ref, _) {
        final statusAsync = ref.watch(followUpStatusProvider(job.id));
        final currentStatus = statusAsync.valueOrNull?.responseStatus ?? 'sent';

        return Container(
          width: double.infinity,
          color: context.ksc.primary800,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FOLLOW-UP SENT',
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.success500,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'UPDATE RESPONSE STATUS:',
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral500,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _StatusChip(
                    label: 'SENT',
                    active: currentStatus == 'sent',
                    color: context.ksc.neutral500,
                    onTap: () => ref.read(followUpProvider(job.id).notifier).updateStatus(job.id, 'sent'),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: 'RESPONDED',
                    active: currentStatus == 'responded',
                    color: context.ksc.success500,
                    onTap: () => ref.read(followUpProvider(job.id).notifier).updateStatus(job.id, 'responded'),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: 'NO RESPONSE',
                    active: currentStatus == 'no_response',
                    color: context.ksc.error500,
                    onTap: () => ref.read(followUpProvider(job.id).notifier).updateStatus(job.id, 'no_response'),
                  ),
                ],
              ),
            ],
          ),
        );
      });
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.ksc.accent500,
        border: Border(top: BorderSide(color: context.ksc.primary700)),
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
                      serviceType: job.serviceType,
                      profileUrl: profile.profileUrl,
                    );

                // Update the job locally to show 'SENT' immediately
                ref.read(jobListProvider.notifier).toggleFollowUpSent(job.id, true);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Opening WhatsApp... Remember to hit the Send arrow!'),
                      backgroundColor: context.ksc.success600,
                      duration: const Duration(seconds: 4),
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
              Expanded(
                child: Text(
                  'SEND WHATSAPP FOLLOW-UP',
                  style: AppTextStyles.h2.copyWith(
                    color: context.ksc.primary900,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Icon(LineAwesomeIcons.whatsapp, color: context.ksc.primary900, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _StatusChip({required this.label, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: active ? color : context.ksc.primary700),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: active ? color : context.ksc.neutral500,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
