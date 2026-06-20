import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/widgets/ks_step_drawer.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/whatsapp_launcher.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/constants/whatsapp_constants.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import 'package:arclock/features/job_logging/domain/entities/job_entity.dart';
import 'package:arclock/features/whatsapp_followup/presentation/providers/follow_up_provider.dart';
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
    final isSent = widget.job.followUpSent;
    final statusAsync = ref.watch(followUpStatusProvider(widget.job.id));
    final currentStatus = statusAsync.valueOrNull?.responseStatus ?? 'sent';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isSent ? context.ksc.primary700.withValues(alpha: 0.3) : context.ksc.accent500,
        border: isSent ? Border(top: BorderSide(color: context.ksc.primary700)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openFollowUpDrawer,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    isSent ? LineAwesomeIcons.check_circle_solid : LineAwesomeIcons.whatsapp,
                    color: isSent ? context.ksc.success500 : context.ksc.primary900,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSent ? 'FOLLOW-UP SENT' : 'SEND WHATSAPP FOLLOW-UP',
                      style: AppTextStyles.h2.copyWith(
                        color: isSent ? context.ksc.white : context.ksc.primary900,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  if (isSent && widget.job.followUpSentAt != null) ...[
                    Text(
                      DateFormatter.display(widget.job.followUpSentAt!),
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.neutral400,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _statusBadge(context, currentStatus),
                    const SizedBox(width: 10),
                  ],
                  Icon(
                    LineAwesomeIcons.chevron_up_solid,
                    color: isSent ? context.ksc.neutral400 : context.ksc.primary900,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String status) {
    Color color;
    switch (status) {
      case 'responded':
        color = context.ksc.success500;
        break;
      case 'no_response':
        color = context.ksc.error500;
        break;
      default:
        color = context.ksc.neutral400;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ─── Drawer ─────────────────────────────────────────────────

  void _openFollowUpDrawer() {
    final isSent = widget.job.followUpSent;
    ref.read(editableFollowUpProvider(widget.job).notifier).initialize();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetCtx) => SizedBox(
        height: MediaQuery.of(sheetCtx).size.height * 0.85,
        child: KsStepDrawer(
          title: 'FOLLOW-UP MESSAGE',
          showBackArrow: true,
          steps: [
            const KsStep(label: 'EDIT MESSAGE', icon: LineAwesomeIcons.edit_solid,
              imageAsset: 'assets/icons/3d/transparent/66b0f8-pencil.png'),
            const KsStep(label: 'PREVIEW & SEND', icon: LineAwesomeIcons.whatsapp,
              imageAsset: 'assets/icons/3d/transparent/e5d0c9-whatsapp.png'),
          ],
          nextLabel: 'NEXT',
          saveLabel: isSent ? 'RESEND' : 'SEND',
          onSave: () async {
            if (isSent) {
              await _resendFollowUp();
            } else {
              await _sendFollowUp();
            }
            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
          },
          canAdvance: (step, subStep) => true,
          onClose: () => Navigator.pop(sheetCtx),
          stepContent: (step, subStep, rebuild, advance) {
            return Consumer(
              builder: (ctx, ref, _) {
                final customerAsync =
                    ref.watch(customerDetailProvider(widget.job.customerId));
                final profileState = ref.watch(profileProvider);
                final editState =
                    ref.watch(editableFollowUpProvider(widget.job));

                if (!editState.isInitialized) {
                  ref
                      .read(editableFollowUpProvider(widget.job).notifier)
                      .initialize();
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                switch (step) {
                  case 0:
                    return _buildEditStep(ctx, editState);
                  case 1:
                    return _buildPreviewStep(
                        ctx, editState, customerAsync, profileState);
                  default:
                    return const SizedBox.shrink();
                }
              },
            );
          },
        ),
      ),
    );
  }

  // ─── Step 1: Edit Message ───────────────────────────────────

  Widget _buildEditStep(BuildContext ctx, editState) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final textColor = isDark ? ctx.ksc.neutral100 : ctx.ksc.neutral800;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write your follow-up message below.',
            style: AppTextStyles.body.copyWith(
              color: ctx.ksc.neutral500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // Editable TextField — bottom border only
          TextField(
            controller: editState.controller,
            maxLines: 8,
            minLines: 4,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.body.copyWith(
              color: textColor,
              height: 1.6,
              fontSize: 14,
            ),
            cursorColor: ctx.ksc.accent500,
            decoration: InputDecoration(
              filled: false,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: ctx.ksc.primary600),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ctx.ksc.primary600),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ctx.ksc.accent500, width: 2),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 8),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${editState.controller.text.length} characters',
              style: AppTextStyles.caption.copyWith(
                color: ctx.ksc.neutral500,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Preview & Send ─────────────────────────────────

  Widget _buildPreviewStep(
      BuildContext ctx, editState, AsyncValue? customerAsync, profileState) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final bubbleBg = isDark ? ctx.ksc.primary700 : ctx.ksc.primary700.withValues(alpha: 0.5);
    final textColor = isDark ? ctx.ksc.neutral100 : ctx.ksc.neutral800;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ctx.ksc.success500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LineAwesomeIcons.whatsapp,
                    color: ctx.ksc.success500, size: 14),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MESSAGE PREVIEW',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: ctx.ksc.neutral300,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'This is how your message will appear',
                    style: AppTextStyles.caption.copyWith(
                      color: ctx.ksc.neutral500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // WhatsApp-style bubble
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bubbleBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LineAwesomeIcons.whatsapp,
                        color: ctx.ksc.success500, size: 11),
                    const SizedBox(width: 6),
                    Text(
                      'FOLLOW-UP MESSAGE',
                      style: AppTextStyles.caption.copyWith(
                        color: ctx.ksc.success500,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  editState.controller.text,
                  style: AppTextStyles.body.copyWith(
                    color: textColor,
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _infoRow(ctx, LineAwesomeIcons.user_solid,
              'To: ${customerAsync?.valueOrNull?.fullName ?? 'Customer'}'),
          const SizedBox(height: 6),
          _infoRow(ctx, LineAwesomeIcons.phone_solid,
              'WhatsApp: ${customerAsync?.valueOrNull?.phoneNumber ?? '—'}'),
          if (widget.job.followUpSent) ...[
            const SizedBox(height: 28),
            const Divider(height: 1),
            const SizedBox(height: 20),
            Text(
              'UPDATE RESPONSE STATUS',
              style: AppTextStyles.caption.copyWith(
                color: ctx.ksc.neutral500,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusChips(ctx),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext ctx, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: ctx.ksc.neutral500),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: ctx.ksc.neutral400,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ─── Response Status Chips ──────────────────────────────────

  Widget _buildStatusChips(BuildContext ctx) {
    final statusAsync = ref.watch(followUpStatusProvider(widget.job.id));
    final currentStatus = statusAsync.valueOrNull?.responseStatus ?? 'sent';

    return Row(
      children: [
        _chip(ctx, 'SENT', currentStatus == 'sent', ctx.ksc.neutral500, () {
          ref
              .read(followUpProvider(widget.job.id).notifier)
              .updateStatus(widget.job.id, 'sent');
        }),
        const SizedBox(width: 8),
        _chip(
            ctx, 'RESPONDED', currentStatus == 'responded', ctx.ksc.success500,
            () {
          ref
              .read(followUpProvider(widget.job.id).notifier)
              .updateStatus(widget.job.id, 'responded');
        }),
        const SizedBox(width: 8),
        _chip(ctx, 'NO RESPONSE', currentStatus == 'no_response',
            ctx.ksc.error500, () {
          ref
              .read(followUpProvider(widget.job.id).notifier)
              .updateStatus(widget.job.id, 'no_response');
        }),
      ],
    );
  }

  Widget _chip(
      BuildContext ctx, String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.15)
              : ctx.ksc.primary700.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: active ? color : ctx.ksc.neutral400),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: active ? color : ctx.ksc.neutral500,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  // ─── Send / Resend ──────────────────────────────────────────

  Future<void> _sendFollowUp() async {
    HapticFeedback.lightImpact();
    final customer =
        ref.read(customerDetailProvider(widget.job.customerId)).valueOrNull;
    final profile = ref.read(profileProvider).profile;
    final editState = ref.read(editableFollowUpProvider(widget.job));

    if (customer != null && profile != null && editState.isInitialized) {
      final message = editState.controller.text.trim();
      await _openWhatsApp(customer.phoneNumber, message, customer.id,
          customer.fullName, profile);
    }
  }

  Future<void> _resendFollowUp() async {
    HapticFeedback.lightImpact();
    final customer =
        ref.read(customerDetailProvider(widget.job.customerId)).valueOrNull;
    final profile = ref.read(profileProvider).profile;
    final editState = ref.read(editableFollowUpProvider(widget.job));

    if (customer != null && profile != null && editState.isInitialized) {
      final message = editState.controller.text.trim();
      await _openWhatsApp(customer.phoneNumber, message, customer.id,
          customer.fullName, profile);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, String message,
      String customerId, String customerName, profile) async {
    try {
      await WhatsAppLauncher.openChat(
        phoneNumber: phoneNumber,
        message: message,
      );

      await ref.read(followUpProvider(widget.job.id).notifier).send(
            jobId: widget.job.id,
            customerId: customerId,
            messageText: message,
            customerName: customerName,
            technicianName: profile.displayName,
            serviceType: widget.job.serviceType,
            profileUrl: profile.profileUrl,
          );

      ref
          .read(jobListProvider.notifier)
          .toggleFollowUpSent(widget.job.id, true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Opening WhatsApp... Remember to hit the Send arrow!'),
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
