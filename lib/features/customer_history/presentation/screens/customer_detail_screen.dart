import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/router/route_names.dart';
// Fixed relative paths:
import '../../../job_logging/presentation/providers/job_providers.dart';
import '../../../job_logging/domain/entities/job_entity.dart';
import '../providers/customer_providers.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final allJobsState = ref.watch(jobListProvider);
    
    final customerJobs = allJobsState.jobs.where((j) => j.customerId == customerId).toList()
      ..sort((a, b) => b.jobDate.compareTo(a.jobDate));

    return Scaffold(
      backgroundColor: AppColors.primary900,
      appBar: KsAppBar(
        title: "CUSTOMER DOSSIER", 
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(LineAwesomeIcons.edit, color: AppColors.accent500),
            onPressed: () {
              // Edit functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const KsOfflineBanner(),
          Expanded(
            child: customerAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent500)),
              error: (err, _) => Center(child: Text("Error loading dossier", style: AppTextStyles.body.copyWith(color: Colors.white))),
              data: (customer) {
                if (customer == null) return const Center(child: Text("Customer not found", style: TextStyle(color: Colors.white)));
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("PROFILE SUMMARY"),
                      _buildProfileModule(customer),
                      const SizedBox(height: 24),
                      
                      _buildStatsRow(customer, customerJobs.length),
                      const SizedBox(height: 24),
                      
                      _buildSectionHeader("SERVICE LEDGER"),
                      if (customerJobs.isEmpty)
                        _buildEmptyLedger()
                      else
                        ...customerJobs.map((job) => _buildLedgerItem(context, job)),
                      
                      const SizedBox(height: 100), 
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary700,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        padding: const EdgeInsets.all(24.0),
        child: SafeArea(
          top: false,
          child: InkWell(
            onTap: () {
              context.push(RouteNames.logJob, extra: customerId);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LOG NEW JOB',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const Icon(LineAwesomeIcons.plus_circle_solid, color: AppColors.accent500, size: 28),
              ],
            ),
          ),
        ),
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

  Widget _buildProfileModule(CustomerEntity customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary900,
            child: Text(
              customer.fullName[0].toUpperCase(), 
              style: AppTextStyles.h1.copyWith(color: AppColors.accent500)
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.fullName.toUpperCase(),
                  style: AppTextStyles.h3.copyWith(color: AppColors.white, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(customer.phoneNumber, style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
                if (customer.location != null) ...[
                  const SizedBox(height: 4),
                  Text(customer.location!.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(CustomerEntity customer, int jobCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary800.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTacticalStat("TOTAL JOBS", jobCount.toString().padLeft(2, '0')),
          Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.1)),
          _buildTacticalStat("STATUS", customer.isRepeatCustomer ? "REPEAT" : "NEW"),
        ],
      ),
    );
  }

  Widget _buildTacticalStat(String label, String value) {
    return Row(
      children: [
        Text("$label: ", style: AppTextStyles.labelSmall.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800)),
        Text(value, style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildLedgerItem(BuildContext context, JobEntity job) {
    final serviceName = job.serviceType.toString().split('.').last
        .replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'), (Match m) => ' ${m.group(0)}');

    return GestureDetector(
      onTap: () => context.push(RouteNames.jobDetail(job.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormatter.short(job.jobDate).toUpperCase(),
                    style: AppTextStyles.caption.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    serviceName.toUpperCase(),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            if (job.hasAmount)
              Text(
                "GHS ${job.amountCharged?.toInt()}",
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.w900),
              ),
            const SizedBox(width: 12),
            const Icon(LineAwesomeIcons.angle_right_solid, color: AppColors.neutral600, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLedger() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primary800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(LineAwesomeIcons.history_solid, color: Colors.white.withValues(alpha: 0.1), size: 48),
          const SizedBox(height: 16),
          Text(
            "NO SERVICE HISTORY",
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.neutral600, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
