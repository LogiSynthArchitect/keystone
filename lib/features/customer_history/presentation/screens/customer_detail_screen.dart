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
import '../../../key_codes/presentation/providers/key_code_provider.dart';
import '../../../key_codes/presentation/screens/edit_key_code_screen.dart';
import '../providers/customer_providers.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));
    final allJobsState = ref.watch(jobListProvider);
    final keyCodeState = ref.watch(keyCodeProvider(widget.customerId));

    final customerJobs = allJobsState.activeJobs
        .where((j) => j.customerId == widget.customerId)
        .toList()
      ..sort((a, b) => b.jobDate.compareTo(a.jobDate));

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "CUSTOMER DETAILS",
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(LineAwesomeIcons.edit, color: context.ksc.accent500, size: 22),
            onPressed: () => context.push(RouteNames.editCustomer(widget.customerId)),
          ),
        ],
      ),
      body: Column(
        children: [
          const KsOfflineBanner(),
          Expanded(
            child: customerAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: context.ksc.accent500)),
              error: (err, _) => Center(child: Text("Could not load customer.", style: AppTextStyles.caption.copyWith(color: context.ksc.error500))),
              data: (customer) {
                if (customer == null) {
                  return Center(child: Text("CUSTOMER NOT FOUND", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)));
                }

                return Column(
                  children: [
                    // Header info
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          _buildProfileModule(context, customer),
                          const SizedBox(height: 16),
                          _buildStatsRow(context, customer, customerJobs.length),
                        ],
                      ),
                    ),
                    // Tab bar
                    Container(
                      color: context.ksc.primary800,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: context.ksc.accent500,
                        labelColor: context.ksc.accent500,
                        unselectedLabelColor: context.ksc.neutral500,
                        labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.0),
                        tabs: const [
                          Tab(text: "KEY CODES"),
                          Tab(text: "SERVICE HISTORY"),
                        ],
                      ),
                    ),
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Key Codes tab
                          _KeyCodesTab(customerId: widget.customerId, keyCodeState: keyCodeState),
                          // Service History tab
                          _ServiceHistoryTab(customer: customer, jobs: customerJobs),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: context.ksc.primary800, border: Border(top: BorderSide(color: context.ksc.primary700))),
        padding: const EdgeInsets.all(24.0),
        child: SafeArea(
          top: false,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push(RouteNames.logJob, extra: widget.customerId),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LOG NEW JOB', style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 2.0)),
                  Icon(LineAwesomeIcons.plus_circle_solid, color: context.ksc.accent500, size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileModule(BuildContext context, CustomerEntity customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: context.ksc.primary900, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
            child: Center(child: Text(customer.fullName[0].toUpperCase(), style: AppTextStyles.h1.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(customer.fullName.toUpperCase(), style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 0.5))),
                    if (customer.propertyType != null)
                      _PropertyBadge(type: customer.propertyType!),
                  ],
                ),
                const SizedBox(height: 4),
                Text(customer.phoneNumber, style: AppTextStyles.body.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600)),
                if (customer.leadSource != null) ...[
                  const SizedBox(height: 2),
                  Text("Via: ${_leadSourceLabel(customer.leadSource!)}", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
                ],
                if (customer.location != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(LineAwesomeIcons.map_marker_solid, size: 12, color: context.ksc.accent500),
                      const SizedBox(width: 4),
                      Expanded(child: Text(customer.location!.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
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
      decoration: BoxDecoration(color: context.ksc.primary800.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stat(context, "TOTAL RECORDS", jobCount.toString().padLeft(2, '0')),
          Container(width: 1, height: 20, color: context.ksc.primary700),
          _stat(context, "STATUS", customer.isRepeatCustomer ? "REPEAT" : "NEW"),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.0)),
      const SizedBox(height: 2),
      Text(value, style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
    ],
  );

  String _leadSourceLabel(String key) {
    const map = {
      'word_of_mouth': 'Word of Mouth', 'google_maps': 'Google Maps',
      'referral': 'Referral', 'physical_card': 'Physical Card',
      'whatsapp': 'WhatsApp', 'other': 'Other',
    };
    return map[key] ?? key;
  }
}

class _PropertyBadge extends StatelessWidget {
  final String type;
  const _PropertyBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'residential' => ('RESIDENTIAL', context.ksc.success500),
      'commercial'  => ('COMMERCIAL',  context.ksc.warning500),
      _             => ('AUTOMOTIVE',  context.ksc.neutral500),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1.0)),
    );
  }
}

class _KeyCodesTab extends ConsumerWidget {
  final String customerId;
  final KeyCodeState keyCodeState;
  const _KeyCodesTab({required this.customerId, required this.keyCodeState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (keyCodeState.isLoading) {
      return Center(child: CircularProgressIndicator(color: context.ksc.accent500));
    }
    return Column(
      children: [
        Expanded(
          child: keyCodeState.entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LineAwesomeIcons.key_solid, size: 48, color: context.ksc.primary700),
                      const SizedBox(height: 12),
                      Text("NO KEY CODES YET", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, letterSpacing: 1.5)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: keyCodeState.entries.length,
                  itemBuilder: (context, i) {
                    final entry = keyCodeState.entries[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
                      child: Row(
                        children: [
                          Icon(LineAwesomeIcons.key_solid, size: 16, color: context.ksc.accent500),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.keyCode.toUpperCase(), style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                                if (entry.keyType != null)
                                  Text(entry.keyType!, style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontSize: 10)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(LineAwesomeIcons.edit, color: context.ksc.neutral500, size: 18),
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => EditKeyCodeScreen(customerId: customerId, existing: entry),
                            )),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EditKeyCodeScreen(customerId: customerId),
            )),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.ksc.accent500,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            icon: Icon(LineAwesomeIcons.plus_solid, color: context.ksc.primary900, size: 18),
            label: Text("ADD KEY CODE", style: AppTextStyles.label.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

class _ServiceHistoryTab extends StatelessWidget {
  final CustomerEntity customer;
  final List<JobEntity> jobs;
  const _ServiceHistoryTab({required this.customer, required this.jobs});

  @override
  Widget build(BuildContext context) {
    final totalAmount = jobs.fold<int>(0, (sum, j) => sum + (j.amountCharged ?? 0));

    return Column(
      children: [
        if (jobs.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: context.ksc.primary800.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("TOTAL VISITS", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10, fontWeight: FontWeight.w800)),
                  Text("${jobs.length}", style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text("TOTAL SPENT", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10, fontWeight: FontWeight.w800)),
                  Text(CurrencyFormatter.formatShort(totalAmount), style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
                ]),
              ],
            ),
          ),
        Expanded(
          child: jobs.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(LineAwesomeIcons.history_solid, size: 48, color: context.ksc.primary700),
                  const SizedBox(height: 12),
                  Text("NO SERVICE RECORDS", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, letterSpacing: 2.0)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length,
                  itemBuilder: (context, i) => _JobHistoryItem(job: jobs[i]),
                ),
        ),
      ],
    );
  }
}

class _JobHistoryItem extends StatelessWidget {
  final JobEntity job;
  const _JobHistoryItem({required this.job});

  @override
  Widget build(BuildContext context) {
    final paymentColor = switch (job.paymentStatus) {
      'paid'    => context.ksc.success500,
      'partial' => context.ksc.warning500,
      _         => context.ksc.error500,
    };

    return GestureDetector(
      onTap: () => context.push(RouteNames.jobDetail(job.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormatter.short(job.jobDate).toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                  const SizedBox(height: 4),
                  Text(job.serviceType.replaceAll('_', ' ').toUpperCase(), style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: paymentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2), border: Border.all(color: paymentColor.withValues(alpha: 0.3))),
                    child: Text(job.paymentStatus.toUpperCase(), style: AppTextStyles.caption.copyWith(color: paymentColor, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1.0)),
                  ),
                ],
              ),
            ),
            if (job.hasAmount)
              Text(CurrencyFormatter.formatShort(job.amountCharged!), style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, fontFeatures: [const FontFeature.tabularFigures()])),
            const SizedBox(width: 8),
            Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.primary700, size: 16),
          ],
        ),
      ),
    );
  }
}
