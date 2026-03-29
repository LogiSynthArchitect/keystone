import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/router/route_names.dart';
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

    final customerJobs = allJobsState.activeJobs.where((j) => j.customerId == customerId).toList()
      ..sort((a, b) => b.jobDate.compareTo(a.jobDate));

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: const KsAppBar(
        title: "CUSTOMER DETAILS",
        showBack: true,
      ),
      body: Column(
        children: [
          const KsOfflineBanner(),
          Expanded(
            child: customerAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: context.ksc.accent500)),
              error: (err, _) => Center(child: Text("Could not load customer. Please go back and try again.", style: AppTextStyles.caption.copyWith(color: context.ksc.error500))),
              data: (customer) {
                if (customer == null) return Center(child: Text("CUSTOMER NOT FOUND", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)));

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(context, "CUSTOMER INFO"),
                      _buildProfileModule(context, customer),
                      const SizedBox(height: 24),

                      _buildStatsRow(context, customer, customerJobs.length),
                      const SizedBox(height: 32),

                      _buildSectionHeader(context, "PAST JOBS"),
                      if (customerJobs.isEmpty)
                        _buildEmptyLedger(context)
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
      bottomNavigationBar: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          border: Border(top: BorderSide(color: context.ksc.primary700)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: SafeArea(
          top: false,
          child: Material(
            color: Colors.transparent,
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
                      color: context.ksc.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Icon(LineAwesomeIcons.plus_circle_solid, color: context.ksc.accent500, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.5)
      ),
    );
  }

  Widget _buildProfileModule(BuildContext context, CustomerEntity customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: context.ksc.primary900,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: context.ksc.primary700),
            ),
            child: Center(
              child: Text(
                customer.fullName[0].toUpperCase(),
                style: AppTextStyles.h1.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.fullName.toUpperCase(),
                  style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(customer.phoneNumber, style: AppTextStyles.body.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600)),
                if (customer.location != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(LineAwesomeIcons.map_marker_solid, size: 12, color: context.ksc.accent500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          customer.location!.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, CustomerEntity customer, int jobCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: context.ksc.primary800.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTacticalStat(context, "TOTAL RECORDS", jobCount.toString().padLeft(2, '0')),
          Container(width: 1, height: 20, color: context.ksc.primary700),
          _buildTacticalStat(context, "STATUS", customer.isRepeatCustomer ? "REPEAT" : "NEW"),
        ],
      ),
    );
  }

  Widget _buildTacticalStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.0)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _buildLedgerItem(BuildContext context, JobEntity job) {
    final serviceLabel = _getServiceLabel(job.serviceType);

    return GestureDetector(
      onTap: () => context.push(RouteNames.jobDetail(job.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormatter.short(job.jobDate).toUpperCase(),
                    style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    serviceLabel,
                    style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            if (job.hasAmount)
              Text(
                CurrencyFormatter.formatShort(job.amountCharged!),
                style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, fontFeatures: [const FontFeature.tabularFigures()]),
              ),
            const SizedBox(width: 16),
            Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.primary700, size: 16),
          ],
        ),
      ),
    );
  }

  String _getServiceLabel(String type) {
    return type.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildEmptyLedger(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: context.ksc.primary800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(LineAwesomeIcons.history_solid, color: context.ksc.primary700, size: 48),
          const SizedBox(height: 24),
          Text(
            "NO SERVICE RECORDS",
            style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, fontWeight: FontWeight.w900, letterSpacing: 2.0),
          ),
        ],
      ),
    );
  }
}
