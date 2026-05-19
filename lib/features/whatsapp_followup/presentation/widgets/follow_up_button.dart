import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/whatsapp_launcher.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/constants/whatsapp_constants.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/features/whatsapp_followup/presentation/providers/follow_up_provider.dart';
import '../providers/editable_followup_provider.dart';

class FollowUpButton extends ConsumerStatefulWidget {
  final JobEntity job;
  const FollowUpButton({super.key, required this.job});

  @override
  ConsumerState<FollowUpButton> createState() => _FollowUpButtonState();
}

class _FollowUpButtonState extends ConsumerState<FollowUpButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editableFollowUpProvider(widget.job).notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.job.followUpSent) {
      return _buildSentState();
    }

    return _buildUnsentState();
  }

  Widget _buildUnsentState() {
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
          onTap: () => _sendFollowUp(),
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

  Widget _buildSentState() {
    final editState = ref.watch(editableFollowUpProvider(widget.job));
    final statusAsync = ref.watch(followUpStatusProvider(widget.job.id));
    final currentStatus = statusAsync.valueOrNull?.responseStatus ?? 'sent';

    return Container(
      width: double.infinity,
      color: context.ksc.primary800,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(LineAwesomeIcons.check_circle_solid, color: context.ksc.success500, size: 16),
                const SizedBox(width: 8),
                Text(
                  'FOLLOW-UP SENT',
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.success500,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                if (widget.job.followUpSentAt != null)
                  Text(
                    DateFormatter.display(widget.job.followUpSentAt!),
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral500,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
            if (editState.isInitialized) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.ksc.primary700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: editState.controller,
                  maxLines: 3,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  style: AppTextStyles.body.copyWith(
                    color: context.ksc.neutral300,
                    height: 1.5,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  cursorColor: context.ksc.accent500,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _resendFollowUp(),
                child: Row(
                  children: [
                    Icon(LineAwesomeIcons.whatsapp, color: context.ksc.accent500, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'RESEND WHATSAPP',
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.accent500,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    Icon(LineAwesomeIcons.arrow_right_solid, color: context.ksc.accent500, size: 16),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'UPDATE RESPONSE STATUS:',
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusChip(
                  label: 'SENT',
                  active: currentStatus == 'sent',
                  color: context.ksc.neutral500,
                  onTap: () => ref.read(followUpProvider(widget.job.id).notifier).updateStatus(widget.job.id, 'sent'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'RESPONDED',
                  active: currentStatus == 'responded',
                  color: context.ksc.success500,
                  onTap: () => ref.read(followUpProvider(widget.job.id).notifier).updateStatus(widget.job.id, 'responded'),
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'NO RESPONSE',
                  active: currentStatus == 'no_response',
                  color: context.ksc.error500,
                  onTap: () => ref.read(followUpProvider(widget.job.id).notifier).updateStatus(widget.job.id, 'no_response'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFollowUp() async {
    HapticFeedback.lightImpact();
    final customer = ref.read(customerDetailProvider(widget.job.customerId)).valueOrNull;
    final profile = ref.read(profileProvider).profile;
    final editState = ref.read(editableFollowUpProvider(widget.job));

    if (customer != null && profile != null && editState.isInitialized) {
      final message = editState.controller.text.trim();
      await _openWhatsApp(customer.phoneNumber, message, customer.id, customer.fullName, profile);
    }
  }

  Future<void> _resendFollowUp() async {
    HapticFeedback.lightImpact();
    final customer = ref.read(customerDetailProvider(widget.job.customerId)).valueOrNull;
    final profile = ref.read(profileProvider).profile;
    final editState = ref.read(editableFollowUpProvider(widget.job));

    if (customer != null && profile != null && editState.isInitialized) {
      final message = editState.controller.text.trim();
      await _openWhatsApp(customer.phoneNumber, message, customer.id, customer.fullName, profile);
    }
  }

  Future<void> _openWhatsApp(
    String phoneNumber,
    String message,
    String customerId,
    String customerName,
    profile,
  ) async {
    try {
      await WhatsAppLauncher.openChat(
        phoneNumber: phoneNumber,
        message: message,
      );

      ref.read(followUpProvider(widget.job.id).notifier).send(
            jobId: widget.job.id,
            customerId: customerId,
            customerPhone: phoneNumber,
            customerName: customerName,
            technicianName: profile.displayName,
            serviceType: widget.job.serviceType,
            profileUrl: profile.profileUrl,
          );

      ref.read(jobListProvider.notifier).toggleFollowUpSent(widget.job.id, true);

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
