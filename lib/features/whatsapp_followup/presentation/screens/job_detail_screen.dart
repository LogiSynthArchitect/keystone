import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../job_logging/presentation/providers/job_providers.dart';
import '../../../customer_history/presentation/providers/customer_providers.dart';
import '../widgets/follow_up_button.dart';
import '../widgets/follow_up_message_preview.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));

    return Scaffold(
      backgroundColor: AppColors.primary900,
      appBar: KsAppBar(
        title: "JOB DETAILS",
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(LineAwesomeIcons.trash_solid, color: AppColors.error500),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.primary800,
                  title: Text("ARCHIVE JOB?", style: AppTextStyles.h3.copyWith(color: Colors.white)),
                  content: Text("This will remove the job from your dashboard.", style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("ARCHIVE", style: TextStyle(color: AppColors.error500))),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(jobListProvider.notifier).archive(jobId);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const KsOfflineBanner(),
          Expanded(
            child: jobAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent500)),
              error: (err, _) => Center(child: Text("Error loading job details", style: AppTextStyles.body.copyWith(color: Colors.white))),
              data: (job) {
                if (job == null) return const Center(child: Text("Job not found", style: TextStyle(color: Colors.white)));

                // Task 3: 24-Hour UI Lock Calculation
                final bool isLocked = DateTime.now().difference(job.createdAt).inHours >= 24;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("SERVICE"),
                      _buildServiceModule(job, isLocked),
                      const SizedBox(height: 24),

                      _buildSectionHeader("CUSTOMER"),
                      _buildCustomerModule(ref, job.customerId),
                      const SizedBox(height: 24),

                      if (job.notes != null && job.notes!.isNotEmpty) ...[
                        _buildSectionHeader("TECHNICAL NOTES"),
                        _buildNotesModule(job.notes!),
                        const SizedBox(height: 24),
                      ],

                      _buildSectionHeader("FOLLOW-UP STATUS"),
                      FollowUpMessagePreview(job: job),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: jobAsync.when(
        data: (job) => job != null ? FollowUpButton(job: job) : const SizedBox.shrink(),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.5)
      ),
    );
  }

  Widget _buildServiceModule(job, bool isLocked) {
    final serviceName = job.serviceType.toString().split('.').last;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  serviceName.replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'), (Match m) => ' ${m.group(0)}').toUpperCase(),
                  style: AppTextStyles.h3.copyWith(color: AppColors.white, fontWeight: FontWeight.w900),
                ),
              ),
              Row(
                children: [
                  if (isLocked) const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(LineAwesomeIcons.lock_solid, size: 14, color: AppColors.neutral500),
                  ),
                  Text(
                    DateFormatter.short(job.jobDate).toUpperCase(),
                    style: AppTextStyles.caption.copyWith(color: isLocked ? AppColors.neutral500 : AppColors.accent500, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
          if (job.hasAmount) ...[
            const SizedBox(height: 12),
            Text(
              "GHS ${job.amountCharged?.toStringAsFixed(2)}",
              style: AppTextStyles.h2.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w900),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerModule(WidgetRef ref, String customerId) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    return customerAsync.when(
      loading: () => const LinearProgressIndicator(color: AppColors.accent500),
      error: (_, __) => const SizedBox.shrink(),
      data: (customer) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary900,
              child: Text(customer?.fullName[0].toUpperCase() ?? "?", style: const TextStyle(color: AppColors.accent500, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer?.fullName ?? "Unknown", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w800)),
                  Text(customer?.phoneNumber ?? "", style: AppTextStyles.caption.copyWith(color: AppColors.neutral400)),
                ],
              ),
            ),
            const Icon(LineAwesomeIcons.angle_right_solid, color: AppColors.neutral500, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesModule(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        notes,
        style: AppTextStyles.body.copyWith(color: AppColors.neutral400, height: 1.5),
      ),
    );
  }
}
