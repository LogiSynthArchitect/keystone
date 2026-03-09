import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../job_logging/presentation/providers/job_providers.dart';
import '../../../job_logging/domain/entities/job_entity.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';
import '../../presentation/providers/follow_up_provider.dart';
import '../../presentation/widgets/follow_up_button.dart';
import '../../presentation/widgets/follow_up_message_preview.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  // V1: customer name stored in customerId field until Phase 7
  // Phone number input required for follow-up
  final _phoneController = TextEditingController();
  final _customerNameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  JobEntity? _findJob() {
    final jobs = ref.read(jobListProvider).jobs;
    try { return jobs.firstWhere((j) => j.id == widget.jobId); }
    catch (_) { return null; }
  }

  String _serviceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return "Car Key Programming";
      case ServiceType.doorLockInstallation:  return "Door Lock Installation";
      case ServiceType.doorLockRepair:        return "Door Lock Repair";
      case ServiceType.smartLockInstallation: return "Smart Lock Installation";
    }
  }

  IconData _serviceIcon(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return Icons.car_repair;
      case ServiceType.doorLockInstallation:  return Icons.door_front_door_outlined;
      case ServiceType.doorLockRepair:        return Icons.lock_outlined;
      case ServiceType.smartLockInstallation: return Icons.lock_outlined;
    }
  }

  Future<void> _onSendFollowUp(JobEntity job) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
    KsSnackbar.show(context, message: "Enter customer WhatsApp number first.", type: KsSnackbarType.error);
      return;
    }
    // Normalize phone to E.164
    String normalized = phone.replaceAll(RegExp(r"\s"), "");
    if (normalized.startsWith("0")) normalized = "+233${normalized.substring(1)}";
    if (!normalized.startsWith("+")) normalized = "+$normalized";

    final notifier = ref.read(followUpProvider(widget.jobId).notifier);
    final customerName = _customerNameController.text.trim().isEmpty
        ? job.customerId // V1 fallback
        : _customerNameController.text.trim();

    final ok = await notifier.send(
      jobId: widget.jobId,
      customerId: job.customerId,
      customerPhone: normalized,
      customerName: customerName,
      technicianName: "Your technician", // replaced in Phase 8 with real profile
      serviceType: job.serviceType.name,
      profileUrl: "https://keystone.app/p/me", // replaced in Phase 8 with real profile slug
    );

    if (!mounted) return;
    if (ok) {
      KsSnackbar.show(context, message: "WhatsApp opened. Tap Send in WhatsApp to deliver.", type: KsSnackbarType.success);
    } else {
      final err = ref.read(followUpProvider(widget.jobId)).errorMessage;
      KsSnackbar.show(context, message: err ?? "Could not open WhatsApp.", type: KsSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _findJob();
    final followUpState = ref.watch(followUpProvider(widget.jobId));

    if (job == null) {
      return const Scaffold(
        appBar: KsAppBar(title: "Job Detail", showBack: true),
        body: Center(child: Text("Job not found.")),
      );
    }

    // Build preview message whenever screen loads
    if (followUpState.previewMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(followUpProvider(widget.jobId).notifier).buildPreview(
          customerName: _customerNameController.text.trim().isEmpty ? job.customerId : _customerNameController.text.trim(),
          technicianName: "Your technician",
          serviceType: job.serviceType.name,
          profileUrl: "https://keystone.app/p/me",
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.neutral050,
      appBar: const KsAppBar(title: "Job Detail", showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(_serviceIcon(job.serviceType), size: 22, color: AppColors.primary500),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(_serviceLabel(job.serviceType), style: AppTextStyles.h3)),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  _DetailRow(icon: Icons.calendar_today_outlined, label: DateFormatter.display(job.jobDate)),
                  if (job.hasLocation) _DetailRow(icon: Icons.location_on_outlined, label: job.location!),
                  if (job.hasAmount) _DetailRow(icon: Icons.payments_outlined, label: CurrencyFormatter.format(job.amountCharged!)),
                  if (job.notes != null && job.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text("Notes", style: AppTextStyles.captionMedium.copyWith(color: AppColors.neutral500)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(job.notes!, style: AppTextStyles.body.copyWith(color: AppColors.neutral700)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Follow-up section
            Text("WhatsApp Follow-up", style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.xs),
            Text("Send a thank-you message to your customer after the job.",
                style: AppTextStyles.body.copyWith(color: AppColors.neutral600)),

            const SizedBox(height: AppSpacing.lg),

            if (!followUpState.isSent && !job.followUpSent) ...[
              // Customer name field
              _InputField(
                label: "Customer name",
                hint: job.customerId,
                controller: _customerNameController,
                onChanged: (_) {
                  ref.read(followUpProvider(widget.jobId).notifier).buildPreview(
                    customerName: _customerNameController.text.trim().isEmpty ? job.customerId : _customerNameController.text.trim(),
                    technicianName: "Your technician",
                    serviceType: job.serviceType.name,
                    profileUrl: "https://keystone.app/p/me",
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              // Phone field
              _InputField(
                label: "Customer WhatsApp number",
                hint: "0201234567",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Message preview
            if (followUpState.previewMessage != null) ...[
              FollowUpMessagePreview(message: followUpState.previewMessage!),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Send button
            FollowUpButton(
              isSent: followUpState.isSent || job.followUpSent,
              isLoading: followUpState.isLoading,
              onTap: () => _onSendFollowUp(job),
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.neutral400),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.neutral700))),
      ]),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  const _InputField({required this.label, required this.hint, required this.controller, this.keyboardType, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.captionMedium.copyWith(color: AppColors.neutral700)),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.neutral400),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.neutral300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.neutral300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.primary600, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
