import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../providers/job_providers.dart';
import '../widgets/job_card.dart';

class JobListScreen extends ConsumerStatefulWidget {
  const JobListScreen({super.key});
  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(jobListProvider).searchQuery);
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(jobListProvider, (prev, next) {
        if (next.errorMessage != null && mounted) {
          KsSnackbar.show(context, message: next.errorMessage!, type: KsSnackbarType.error);
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
      backgroundColor: AppColors.primary900,
      appBar: KsAppBar(
        title: "MY JOBS",
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary800,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _isSearchFocused ? AppColors.accent500 : AppColors.primary700,
                  width: _isSearchFocused ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (val) => ref.read(jobListProvider.notifier).setSearchQuery(val),
                style: AppTextStyles.body.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                cursorColor: AppColors.accent500,
                decoration: InputDecoration(
                  hintText: "SEARCH DATABASE...",
                  hintStyle: AppTextStyles.caption.copyWith(color: AppColors.neutral600, letterSpacing: 1.0),
                  prefixIcon: Icon(LineAwesomeIcons.search_solid, color: _isSearchFocused ? AppColors.accent500 : AppColors.neutral500, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const KsOfflineBanner(),
          Expanded(
            child: state.isLoading
                ? _buildLoadingState()
                : state.filteredJobs.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => ref.read(jobListProvider.notifier).refresh(),
                        color: AppColors.accent500,
                        backgroundColor: AppColors.primary800,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _SummaryStrip(
                                totalJobs: state.totalJobs,
                                monthEarnings: state.thisMonthEarnings
                              ).animate().fadeIn().slideY(begin: 0.1, end: 0)
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final job = state.filteredJobs[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: JobCard(
                                        job: job,
                                        onTap: () => context.push(RouteNames.jobDetail(job.id))
                                      ),
                                    );
                                  },
                                  childCount: state.filteredJobs.length,
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 100)),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.logJob),
        backgroundColor: AppColors.accent500,
        foregroundColor: AppColors.primary900,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: const Icon(LineAwesomeIcons.plus_solid, size: 28),
      ),
      bottomNavigationBar: KsBottomNav(currentIndex: 0, onTabTapped: _onTabTapped),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(24.0),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.primary700),
        ),
      ).animate(onPlay: (controller) => controller.repeat())
       .shimmer(duration: 1200.ms, color: AppColors.primary700.withValues(alpha: 0.5)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LineAwesomeIcons.database_solid, size: 80, color: AppColors.primary800),
            const SizedBox(height: 24),
            Text(
              "NO RECORDS FOUND",
              style: AppTextStyles.h2.copyWith(color: AppColors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)
            ),
            const SizedBox(height: 12),
            Text(
              "System database is currently empty.\nInitialize your first job log.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral400, height: 1.5)
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final int totalJobs;
  final int monthEarnings;

  const _SummaryStrip({required this.totalJobs, required this.monthEarnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: AppColors.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary700, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(value: "$totalJobs", label: "TOTAL LOGS"),
          Container(width: 1, height: 40, color: AppColors.primary700),
          _Stat(value: monthEarnings > 0 ? CurrencyFormatter.formatShort(monthEarnings) : "—", label: "THIS MONTH"),
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
    return Column(
      children: [
        Text(value, style: AppTextStyles.h1.copyWith(color: AppColors.white, fontWeight: FontWeight.w900, letterSpacing: 0)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      ]
    );
  }
}
