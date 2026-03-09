import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_skeleton_loader.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../providers/job_providers.dart';
import '../widgets/job_card.dart';

class JobListScreen extends ConsumerStatefulWidget {
  const JobListScreen({super.key});
  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(jobListProvider, (prev, next) {
        if (next.errorMessage != null && mounted) {
          KsSnackbar.show(context, message: next.errorMessage!, type: KsSnackbarType.error);
        }
      });
    });
  }

  void _onTabTapped(int index) {
    switch (index) {
      case 0: context.go(RouteNames.jobs); break;
      case 1: context.go(RouteNames.customers); break;
      case 2: context.go(RouteNames.notes); break;
      case 3: context.go(RouteNames.profile); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobListProvider);
    return Scaffold(
      backgroundColor: AppColors.neutral050,
      appBar: const KsAppBar(title: "Jobs"),
      body: Column(
        children: [
          const KsOfflineBanner(),
          Expanded(
            child: state.isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.pagePadding),
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, __) => const KsSkeletonLoader(height: 80),
                  )
                : state.jobs.isEmpty
                    ? KsEmptyState(
                        icon: Icons.work_outline,
                        title: "No jobs yet",
                        subtitle: "Tap the + button to log your first job.",
                        actionLabel: "Log a job",
                        onAction: () => context.push(RouteNames.logJob),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(jobListProvider.notifier).refresh(),
                        color: AppColors.primary700,
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(child: _SummaryStrip(totalJobs: state.totalJobs, monthEarnings: state.thisMonthEarnings)),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding, vertical: AppSpacing.sm),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final job = state.jobs[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                      child: JobCard(job: job, onTap: () => context.push(RouteNames.jobDetail(job.id))),
                                    );
                                  },
                                  childCount: state.jobs.length,
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.fabOffset)),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.logJob),
        backgroundColor: AppColors.primary700,
        elevation: 4,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      bottomNavigationBar: KsBottomNav(currentIndex: 0, onTabTapped: _onTabTapped),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final int totalJobs;
  final double monthEarnings;
  const _SummaryStrip({required this.totalJobs, required this.monthEarnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.lg, AppSpacing.pagePadding, AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.primary700, borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(value: "$totalJobs", label: "Total jobs"),
          Container(width: 1, height: 32, color: AppColors.primary400),
          _Stat(value: monthEarnings > 0 ? CurrencyFormatter.formatShort(monthEarnings) : "—", label: "This month"),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: AppTextStyles.h2.copyWith(color: AppColors.white)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.primary100)),
    ]);
  }
}
