import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/features/job_logging/presentation/providers/job_providers.dart';
import 'package:keystone/features/job_logging/domain/usecases/request_correction_usecase.dart';
import 'package:keystone/core/widgets/ks_snackbar.dart';
import 'package:keystone/core/providers/supabase_provider.dart';
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
        title: "JOB RECORD",
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(LineAwesomeIcons.archive_solid, color: AppColors.neutral400, size: 22),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.primary800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  title: Text("ARCHIVE RECORD?", style: AppTextStyles.h2.copyWith(color: Colors.white)),
                  content: Text("This job will be moved to history. It cannot be permanently deleted.", style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("CANCEL", style: AppTextStyles.label.copyWith(color: AppColors.neutral400))),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("ARCHIVE", style: AppTextStyles.label.copyWith(color: AppColors.error500))),
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
              error: (err, _) => Center(child: Text("ERROR LOADING JOB DOSSIER", style: AppTextStyles.caption.copyWith(color: AppColors.error500))),
              data: (job) {
                if (job == null) return Center(child: Text("JOB RECORD NOT FOUND", style: AppTextStyles.caption.copyWith(color: AppColors.neutral500)));

                final bool isLocked = DateTime.now().difference(job.createdAt).inHours >= 24;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("SYSTEM ANALYSIS"),
                      _buildServiceModule(context, ref, job, isLocked),
                      const SizedBox(height: 32),

                      _buildSectionHeader("CUSTOMER ENTITY"),
                      _buildCustomerModule(ref, job.customerId),
                      const SizedBox(height: 32),

                      if (job.notes != null && job.notes!.isNotEmpty) ...[
                        _buildSectionHeader("TECHNICAL LOG"),
                        _buildNotesModule(job.notes!),
                        const SizedBox(height: 32),
                      ],

                      _buildSectionHeader("COMMUNICATION STATUS"),
                      FollowUpMessagePreview(job: job),
                      const SizedBox(height: 120),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: jobAsync.when(
        data: (job) => job != null ? FollowUpButton(job: job) : const SizedBox.shrink(),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  void _showCorrectionDialog(BuildContext context, WidgetRef ref, String jobId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primary800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text("REQUEST CORRECTION", style: AppTextStyles.h2.copyWith(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Explain what needs to be changed and why. An admin will review your request.", 
              style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              style: AppTextStyles.body.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g. Changed service type to Smart Lock Installation...",
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                filled: true,
                fillColor: AppColors.primary900,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: AppTextStyles.label.copyWith(color: AppColors.neutral400))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent500),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final reason = controller.text.trim();
              Navigator.pop(ctx);
              
              try {
                final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
                if (userId == null) {
                  if (context.mounted) KsSnackbar.show(context, message: "Session expired. Please log in again.", type: KsSnackbarType.error);
                  return;
                }
                await ref.read(requestCorrectionUsecaseProvider).call(
                  RequestCorrectionParams(jobId: jobId, userId: userId, reason: reason)
                );
                if (context.mounted) {
                  KsSnackbar.show(context, message: "Correction request submitted.", type: KsSnackbarType.success);
                }
              } catch (e) {
                if (context.mounted) {
                  KsSnackbar.show(context, message: "Failed to submit request.", type: KsSnackbarType.error);
                }
              }
            }, 
            child: Text("SUBMIT", style: AppTextStyles.label.copyWith(color: AppColors.primary900, fontWeight: FontWeight.w900))
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.5)
      ),
    );
  }

  Widget _buildServiceModule(BuildContext context, WidgetRef ref, JobEntity job, bool isLocked) {
    final serviceLabel = _getServiceLabel(job.serviceType);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  serviceLabel,
                  style: AppTextStyles.h2.copyWith(color: AppColors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormatter.short(job.jobDate).toUpperCase(),
                    style: AppTextStyles.caption.copyWith(color: isLocked ? AppColors.neutral500 : AppColors.accent500, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  if (isLocked) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LineAwesomeIcons.lock_solid, size: 10, color: AppColors.neutral500),
                        const SizedBox(width: 4),
                        Text("SYSTEM LOCKED", style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showCorrectionDialog(context, ref, job.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.accent500.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "REQUEST CORRECTION",
                          style: AppTextStyles.caption.copyWith(color: AppColors.accent500, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (job.hasAmount) ...[
            const SizedBox(height: 20),
            const Divider(color: AppColors.primary700, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TOTAL CHARGED", style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                Text(
                  CurrencyFormatter.formatShort(job.amountCharged!),
                  style: AppTextStyles.h1.copyWith(color: AppColors.white, fontWeight: FontWeight.w900, fontFeatures: [const FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getServiceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return "CAR KEY PROGRAMMING";
      case ServiceType.doorLockInstallation:  return "DOOR LOCK INSTALLATION";
      case ServiceType.doorLockRepair:        return "DOOR LOCK REPAIR";
      case ServiceType.smartLockInstallation: return "SMART LOCK INSTALLATION";
    }
  }

  Widget _buildCustomerModule(WidgetRef ref, String customerId) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    return customerAsync.when(
      loading: () => Container(height: 80, color: AppColors.primary800).animate().shimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (customer) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.primary700),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary900,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primary700),
              ),
              child: Center(
                child: Text(
                  customer?.fullName[0].toUpperCase() ?? "?", 
                  style: AppTextStyles.h2.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w900)
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer?.fullName.toUpperCase() ?? "UNKNOWN ENTITY", style: AppTextStyles.body.copyWith(color: AppColors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(customer?.phoneNumber ?? "NO CONTACT", style: AppTextStyles.caption.copyWith(color: AppColors.neutral400, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(LineAwesomeIcons.angle_right_solid, color: AppColors.primary700, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesModule(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LineAwesomeIcons.terminal_solid, size: 14, color: AppColors.accent500),
              const SizedBox(width: 8),
              Text("LOG ENTRY", style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notes,
            style: AppTextStyles.body.copyWith(color: AppColors.neutral200, height: 1.6, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
