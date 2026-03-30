import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../providers/job_providers.dart';
import '../widgets/job_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../service_types/presentation/providers/service_type_provider.dart';
import '../../../reminders/presentation/providers/reminders_provider.dart';

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

  Future<void> _showFilterSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
      ),
      builder: (ctx) => _JobFilterSheet(
        current: ref.read(jobListProvider).filters,
        onApply: (f) => ref.read(jobListProvider.notifier).setFilters(f),
        onClear: () => ref.read(jobListProvider.notifier).clearFilters(),
      ),
    );
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
    final remindersCount = ref.watch(remindersProvider).activeCount;
    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "MY JOBS",
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(LineAwesomeIcons.bell_solid, color: remindersCount > 0 ? context.ksc.accent500 : context.ksc.neutral400, size: 22),
                onPressed: () => context.push(RouteNames.reminders),
              ),
              if (remindersCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: context.ksc.error500, shape: BoxShape.circle),
                    child: Center(child: Text('$remindersCount', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: context.ksc.white))),
                  ),
                ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(LineAwesomeIcons.filter_solid, color: state.filters.hasActive ? context.ksc.accent500 : context.ksc.neutral400, size: 22),
                onPressed: () => _showFilterSheet(context),
              ),
              if (state.filters.activeCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: context.ksc.accent500, shape: BoxShape.circle),
                    child: Center(child: Text('${state.filters.activeCount}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: context.ksc.primary900))),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.search_solid, color: context.ksc.neutral400, size: 22),
            onPressed: () => context.push(RouteNames.search),
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.chart_line_solid, color: context.ksc.neutral400, size: 22),
            onPressed: () => context.push(RouteNames.analytics),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: context.ksc.primary800,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _isSearchFocused ? context.ksc.accent500 : context.ksc.primary700,
                  width: _isSearchFocused ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (val) => ref.read(jobListProvider.notifier).setSearchQuery(val),
                style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
                cursorColor: context.ksc.accent500,
                decoration: InputDecoration(
                  hintText: "Search your jobs...",
                  hintStyle: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, letterSpacing: 1.0),
                  prefixIcon: Icon(LineAwesomeIcons.search_solid, color: _isSearchFocused ? context.ksc.accent500 : context.ksc.neutral500, size: 20),
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
                        color: context.ksc.accent500,
                        backgroundColor: context.ksc.primary800,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _SummaryStrip(
                                totalJobs: state.totalJobs,
                                monthEarnings: state.thisMonthEarnings,
                                pendingCount: state.pendingCount,
                                isSyncing: state.isSyncing,
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
        backgroundColor: context.ksc.accent500,
        foregroundColor: context.ksc.primary900,
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
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.ksc.primary700),
        ),
      ).animate(onPlay: (controller) => controller.repeat()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineAwesomeIcons.database_solid, size: 80, color: context.ksc.primary800),
            const SizedBox(height: 24),
            Text(
              "NO JOBS YET",
              style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)
            ),
            const SizedBox(height: 12),
            Text(
              "You haven't logged any jobs yet.\nTap + below to log your first job.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400, height: 1.5)
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
  final int pendingCount;
  final bool isSyncing;

  const _SummaryStrip({required this.totalJobs, required this.monthEarnings, required this.pendingCount, required this.isSyncing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(value: "$totalJobs", label: "TOTAL LOGS"),
              Container(width: 1, height: 40, color: context.ksc.primary700),
              _Stat(value: CurrencyFormatter.formatShort(monthEarnings), label: "THIS MONTH"),
            ],
          ),
          if (pendingCount > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sync, size: 14, color: context.ksc.accent500),
                const SizedBox(width: 4),
                Text(
                  '$pendingCount uploading...',
                  style: AppTextStyles.label.copyWith(color: context.ksc.accent500),
                ),
                if (isSyncing) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.ksc.accent500)
                  ),
                ],
              ],
            ),
          ]
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
        Text(value, style: AppTextStyles.h1.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, letterSpacing: 0)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      ]
    );
  }
}

// ── Filter bottom sheet ──────────────────────────────────────────────────────

class _JobFilterSheet extends ConsumerStatefulWidget {
  final JobListFilters current;
  final ValueChanged<JobListFilters> onApply;
  final VoidCallback onClear;

  const _JobFilterSheet({
    required this.current,
    required this.onApply,
    required this.onClear,
  });

  @override
  ConsumerState<_JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends ConsumerState<_JobFilterSheet> {
  late JobListFilters _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
  }

  void _apply() {
    widget.onApply(_draft);
    Navigator.of(context).pop();
  }

  void _clear() {
    widget.onClear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final serviceTypes = ref.watch(serviceTypeProvider)
        .valueOrNull?.map((s) => s.name).toList() ?? const <String>[];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('FILTER JOBS',
                      style: AppTextStyles.h3
                          .copyWith(color: context.ksc.white, letterSpacing: 1.5)),
                  TextButton(
                    onPressed: _clear,
                    child: Text('CLEAR ALL',
                        style: AppTextStyles.captionMedium
                            .copyWith(color: context.ksc.error500)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Status
              _FilterSection(
                label: 'STATUS',
                options: const [
                  ('quoted', 'Quoted'),
                  ('in_progress', 'In Progress'),
                  ('completed', 'Completed'),
                  ('invoiced', 'Invoiced'),
                ],
                selected: _draft.status,
                onSelect: (v) => setState(() => _draft = _draft.copyWith(status: v)),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Payment status
              _FilterSection(
                label: 'PAYMENT',
                options: const [
                  ('unpaid', 'Unpaid'),
                  ('partial', 'Partial'),
                  ('paid', 'Paid'),
                ],
                selected: _draft.paymentStatus,
                onSelect: (v) =>
                    setState(() => _draft = _draft.copyWith(paymentStatus: v)),
              ),

              if (serviceTypes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _FilterSectionDynamic(
                  label: 'SERVICE TYPE',
                  options: serviceTypes,
                  selected: _draft.serviceType,
                  onSelect: (v) =>
                      setState(() => _draft = _draft.copyWith(serviceType: v)),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Date range
              Row(
                children: [
                  Text('DATE RANGE',
                      style: AppTextStyles.captionMedium
                          .copyWith(color: context.ksc.neutral500, letterSpacing: 1.5)),
                  const Spacer(),
                  if (_draft.dateRange != null)
                    TextButton(
                      onPressed: () =>
                          setState(() => _draft = _draft.copyWith(dateRange: null)),
                      child: Text('CLEAR',
                          style: AppTextStyles.captionMedium
                              .copyWith(color: context.ksc.error500)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _draft.dateRange,
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: ctx.ksc.accent500,
                          onPrimary: ctx.ksc.primary900,
                          surface: ctx.ksc.primary800,
                          onSurface: ctx.ksc.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => _draft = _draft.copyWith(dateRange: picked));
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _draft.dateRange != null
                        ? context.ksc.accent100
                        : context.ksc.primary700,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: _draft.dateRange != null
                          ? context.ksc.accent500
                          : context.ksc.primary600,
                    ),
                  ),
                  child: Text(
                    _draft.dateRange == null
                        ? 'Select date range...'
                        : '${_formatDate(_draft.dateRange!.start)} → ${_formatDate(_draft.dateRange!.end)}',
                    style: AppTextStyles.body.copyWith(
                      color: _draft.dateRange != null
                          ? context.ksc.accent500
                          : context.ksc.neutral500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.ksc.accent500,
                    foregroundColor: context.ksc.primary900,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                  ),
                  child: Text('APPLY FILTERS',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: context.ksc.primary900,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _FilterSection extends StatelessWidget {
  final String label;
  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _FilterSection({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.captionMedium
                .copyWith(color: context.ksc.neutral500, letterSpacing: 1.5)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: options.map(((String val, String display) pair) {
            final isSelected = selected == pair.$1;
            return GestureDetector(
              onTap: () => onSelect(isSelected ? null : pair.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isSelected ? context.ksc.accent500 : context.ksc.primary700,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: isSelected ? context.ksc.accent500 : context.ksc.primary600,
                  ),
                ),
                child: Text(
                  pair.$2.toUpperCase(),
                  style: AppTextStyles.captionMedium.copyWith(
                    color: isSelected ? context.ksc.primary900 : context.ksc.neutral400,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FilterSectionDynamic extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _FilterSectionDynamic({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.captionMedium
                .copyWith(color: context.ksc.neutral500, letterSpacing: 1.5)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: options.map((name) {
            final isSelected = selected == name;
            return GestureDetector(
              onTap: () => onSelect(isSelected ? null : name),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isSelected ? context.ksc.accent500 : context.ksc.primary700,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: isSelected ? context.ksc.accent500 : context.ksc.primary600,
                  ),
                ),
                child: Text(
                  name.toUpperCase(),
                  style: AppTextStyles.captionMedium.copyWith(
                    color: isSelected ? context.ksc.primary900 : context.ksc.neutral400,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
