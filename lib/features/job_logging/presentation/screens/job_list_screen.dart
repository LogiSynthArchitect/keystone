import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/widgets/ks_filter_sheet.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import 'package:keystone/core/widgets/ks_sliding_notification.dart';
import '../../../../core/widgets/ks_search_bar.dart';
import 'log_job_screen.dart';
import '../providers/job_providers.dart';
import '../widgets/job_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/data_export_service.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../service_types/presentation/providers/service_type_provider.dart';
import '../../../reminders/presentation/providers/reminders_provider.dart';

class JobListScreen extends ConsumerStatefulWidget {
  const JobListScreen({super.key});
  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen> {
  late final TextEditingController _searchController;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(jobListProvider).searchQuery);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(jobListProvider, (prev, next) {
        if (next.errorMessage != null && mounted) {
          KsSlidingNotification.show(context, message: next.errorMessage!, type: KsNotificationType.error);
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final currentFilters = ref.read(jobListProvider).filters;
    final serviceTypes = ref.read(serviceTypeProvider)
        .valueOrNull?.map((s) => s.name).toList() ?? const <String>[];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
      ),
      builder: (ctx) {
        JobListFilters draft = currentFilters;
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return KsFilterSheet(
              title: 'FILTER JOBS',
              onApply: () {
                ref.read(jobListProvider.notifier).setFilters(draft);
              },
              onClear: () {
                draft = const JobListFilters();
                setLocalState(() {});
              },
              children: [
                KsFilterChipGroup(
                  label: 'STATUS',
                  options: const [
                    KsFilterOption(value: 'quoted', display: 'Quoted', icon: '📋'),
                    KsFilterOption(value: 'in_progress', display: 'In Progress', icon: '⏳'),
                    KsFilterOption(value: 'completed', display: 'Completed', icon: '✅'),
                    KsFilterOption(value: 'invoiced', display: 'Invoiced', icon: '💰'),
                  ],
                  selected: draft.status,
                  onSelect: (v) => setLocalState(() => draft = draft.copyWith(status: v)),
                ),
                KsFilterChipGroup(
                  label: 'PAYMENT',
                  options: const [
                    KsFilterOption(value: 'unpaid', display: 'Unpaid', icon: '❌'),
                    KsFilterOption(value: 'partial', display: 'Partial', icon: '💳'),
                    KsFilterOption(value: 'paid', display: 'Paid', icon: '✅'),
                  ],
                  selected: draft.paymentStatus,
                  onSelect: (v) => setLocalState(() => draft = draft.copyWith(paymentStatus: v)),
                ),
                if (serviceTypes.isNotEmpty)
                  KsFilterChipGroup(
                    label: 'SERVICE TYPE',
                    options: serviceTypes.map(
                      (name) => KsFilterOption(value: name, display: name),
                    ).toList(),
                    selected: draft.serviceType,
                    onSelect: (v) => setLocalState(() => draft = draft.copyWith(serviceType: v)),
                  ),
                // Date range section
                Row(
                  children: [
                    Text('DATE RANGE',
                        style: AppTextStyles.captionMedium
                            .copyWith(color: context.ksc.neutral500, letterSpacing: 1.5)),
                    const Spacer(),
                    if (draft.dateRange != null)
                      TextButton(
                        onPressed: () => setLocalState(() => draft = draft.copyWith(dateRange: null)),
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
                      initialDateRange: draft.dateRange,
                      builder: (innerCtx, child) => Theme(
                        data: Theme.of(innerCtx).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: innerCtx.ksc.accent500,
                            onPrimary: innerCtx.ksc.primary900,
                            surface: innerCtx.ksc.primary800,
                            onSurface: innerCtx.ksc.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setLocalState(() => draft = draft.copyWith(dateRange: picked));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF2A3A4A), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            draft.dateRange == null
                                ? 'Select date range...'
                                : '${draft.dateRange!.start.day}/${draft.dateRange!.start.month}/${draft.dateRange!.start.year} → ${draft.dateRange!.end.day}/${draft.dateRange!.end.month}/${draft.dateRange!.end.year}',
                            style: AppTextStyles.body.copyWith(
                              color: draft.dateRange != null
                                  ? context.ksc.accent500
                                  : context.ksc.neutral500,
                            ),
                          ),
                        ),
                        Icon(LineAwesomeIcons.calendar_solid,
                            color: context.ksc.neutral500, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onTabTapped(int index) {
    switch (index) {
      case 0: context.go(RouteNames.dashboard); break;
      case 1: context.go(RouteNames.jobs); break;
      case 2: context.go(RouteNames.customers); break;
      case 3: context.go(RouteNames.hub); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobListProvider);
    final remindersCount = ref.watch(remindersProvider).activeCount;
    return Scaffold(
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => LogJobScreen.show(context),
              backgroundColor: context.ksc.accent500,
              foregroundColor: context.ksc.primary900,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              child: const Icon(LineAwesomeIcons.plus_solid, size: 28),
            ),
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: _selectionMode ? "${_selectedIds.length} SELECTED" : "MY JOBS",
        actions: _selectionMode
            ? [
                TextButton(
                  onPressed: _selectedIds.length < state.filteredJobs.length
                      ? () => setState(() {
                          _selectedIds.addAll(state.filteredJobs.map((j) => j.id));
                        })
                      : null,
                  child: Text(
                    "SELECT ALL",
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.accent500,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral400, size: 22),
                  onPressed: () => setState(() { _selectionMode = false; _selectedIds.clear(); }),
                ),
              ]
            : [
                if (state.activeJobs.isNotEmpty)
                  IconButton(
                    icon: Icon(LineAwesomeIcons.check_square_solid, color: context.ksc.neutral400, size: 22),
                    onPressed: () => setState(() => _selectionMode = true),
                  ),
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
              ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: KsSearchBar(
              hint: "Search your jobs...",
              controller: _searchController,
              onChanged: (val) => ref.read(jobListProvider.notifier).setSearchQuery(val),
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
                : state.errorMessage != null && state.filteredJobs.isEmpty
                    ? _buildErrorState(context, ref)
                    : state.filteredJobs.isEmpty
                        ? _buildEmptyState()
                    : Column(
                        children: [
                          _SummaryStrip(
                            filteredEarnings: state.filteredEarnings,
                            filteredJobCount: state.filteredJobCount,
                            summaryLabel: state.summaryLabel,
                            monthEarnings: state.thisMonthEarnings,
                            pendingCount: state.pendingCount,
                            isSyncing: state.isSyncing,
                            hasActiveFilters: state.filters.hasActive,
                            monthlyTarget: ref.watch(monthlyTargetProvider),
                          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                          Expanded(
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (n) {
                                if (n is ScrollEndNotification && n.metrics.extentAfter < 200) {
                                  ref.read(jobListProvider.notifier).loadMore();
                                }
                                return false;
                              },
                              child: RefreshIndicator(
                                onRefresh: () => ref.read(jobListProvider.notifier).refresh(),
                                color: context.ksc.accent500,
                                backgroundColor: context.ksc.primary800,
                                child: CustomScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  slivers: [
                                    SliverPadding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                                      sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final jobs = state.pagedJobs;
                                    if (index == jobs.length) {
                                      return state.hasMore
                                          ? Padding(
                                              padding: const EdgeInsets.only(bottom: 16.0),
                                              child: Center(
                                                child: CircularProgressIndicator(strokeWidth: 2, color: context.ksc.accent500),
                                              ),
                                            )
                                          : const SizedBox.shrink();
                                    }
                                    final job = jobs[index];
                                    final isSelected = _selectedIds.contains(job.id);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: GestureDetector(
                                        onLongPress: _selectionMode ? null : () {
                                          HapticFeedback.mediumImpact();
                                          setState(() {
                                            _selectionMode = true;
                                            _selectedIds.add(job.id);
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: _selectionMode && isSelected
                                                ? Border.all(color: context.ksc.accent500, width: 2)
                                                : null,
                                          ),
                                          child: Stack(
                                            children: [
                                              JobCard(
                                                job: job,
                                                onTap: () {
                                                  if (_selectionMode) {
                                                    setState(() {
                                                      if (isSelected) {
                                                        _selectedIds.remove(job.id);
                                                        if (_selectedIds.isEmpty) _selectionMode = false;
                                                      } else {
                                                        _selectedIds.add(job.id);
                                                      }
                                                    });
                                                  } else {
                                                    context.push(RouteNames.jobDetail(job.id));
                                                  }
                                                },
                                              ),
                                              if (_selectionMode)
                                                Positioned(
                                                  top: 8,
                                                  left: 8,
                                                  child: Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isSelected ? context.ksc.accent500 : Colors.transparent,
                                                      border: Border.all(
                                                        color: isSelected ? context.ksc.accent500 : context.ksc.neutral500,
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: state.pagedJobs.length + (state.hasMore ? 1 : 0),
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 100)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      bottomNavigationBar: _selectionMode
          ? _buildBulkActionBar()
          : KsBottomNav(currentIndex: 1, onTabTapped: _onTabTapped),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 64, color: context.ksc.error500),
            const SizedBox(height: 24),
            Text(
              "FAILED TO LOAD",
              style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Text(
              "Could not load jobs. Check your connection and try again.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400, height: 1.5),
            ),
            const SizedBox(height: 24),
            KsButton(
              label: "TAP TO RETRY",
              variant: KsButtonVariant.primary,
              size: KsButtonSize.small,
              fullWidth: false,
              onPressed: () => ref.read(jobListProvider.notifier).load(),
            ),
          ],
        ),
      ),
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
    return KsEmptyState(
      icon: LineAwesomeIcons.database_solid,
      title: "NO JOBS YET",
      subtitle: "You haven't logged any jobs yet.\nTap + below to log your first job.",
      actionLabel: "SETUP GUIDE",
      onAction: () => context.push(RouteNames.setup),
    );
  }

  Widget _buildBulkActionBar() {
    return Container(
      color: context.ksc.primary800,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _selectedIds.isEmpty ? null : () => _bulkArchive(),
                icon: Icon(LineAwesomeIcons.archive_solid, size: 18, color: _selectedIds.isEmpty ? context.ksc.neutral600 : context.ksc.error500),
                label: Text("ARCHIVE", style: AppTextStyles.label.copyWith(
                  color: _selectedIds.isEmpty ? context.ksc.neutral600 : context.ksc.error500,
                  fontWeight: FontWeight.w800,
                )),
              ),
            ),
            Container(width: 1, height: 32, color: context.ksc.primary700),
            Expanded(
              child: TextButton.icon(
                onPressed: _selectedIds.isEmpty ? null : () => _bulkExport(),
                icon: Icon(LineAwesomeIcons.file_csv_solid, size: 18, color: _selectedIds.isEmpty ? context.ksc.neutral600 : context.ksc.accent500),
                label: Text("EXPORT CSV", style: AppTextStyles.label.copyWith(
                  color: _selectedIds.isEmpty ? context.ksc.neutral600 : context.ksc.accent500,
                  fontWeight: FontWeight.w800,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bulkArchive() {
    final ids = Set<String>.from(_selectedIds);
    KsConfirmDialog.show(
      context,
      title: "ARCHIVE ${ids.length} JOBS",
      message: "These jobs will be moved to history. They cannot be permanently deleted.",
      confirmLabel: "ARCHIVE",
      cancelLabel: "CANCEL",
      isDanger: true,
      onConfirm: () async {
        for (final id in ids) {
          await ref.read(archiveJobUsecaseProvider).call(id);
        }
        if (mounted) {
          setState(() { _selectionMode = false; _selectedIds.clear(); });
          ref.read(jobListProvider.notifier).refresh();
          KsSlidingNotification.show(context, message: "${ids.length} jobs archived", type: KsNotificationType.success);
        }
      },
    );
  }

  void _bulkExport() async {
    final jobState = ref.read(jobListProvider);
    final selected = jobState.pagedJobs.where((j) => _selectedIds.contains(j.id)).toList();
    await DataExportService.exportJobsAsCsv(selected);
    setState(() { _selectionMode = false; _selectedIds.clear(); });
  }
}

class _SummaryStrip extends StatelessWidget {
  final int filteredEarnings;
  final int filteredJobCount;
  final String summaryLabel;
  final int monthEarnings;
  final int pendingCount;
  final bool isSyncing;
  final bool hasActiveFilters;
  final int monthlyTarget;

  const _SummaryStrip({
    required this.filteredEarnings,
    required this.filteredJobCount,
    required this.summaryLabel,
    required this.monthEarnings,
    required this.pendingCount,
    required this.isSyncing,
    required this.hasActiveFilters,
    required this.monthlyTarget,
  });

  @override
  Widget build(BuildContext context) {
    final displayEarnings = hasActiveFilters ? filteredEarnings : monthEarnings;
    final progress = monthEarnings > 0 ? (monthEarnings / monthlyTarget).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main earnings number
          Text(
            CurrencyFormatter.formatShort(displayEarnings),
            style: AppTextStyles.h1.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, fontSize: 28),
          ),
          const SizedBox(height: 2),
          Text(
            hasActiveFilters ? "$summaryLabel EARNINGS" : "${summaryLabel}'S EARNINGS",
            style: AppTextStyles.caption.copyWith(
              color: context.ksc.neutral500, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0),
          ),
          // Progress bar — only for unfiltered this-month view
          if (!hasActiveFilters && monthEarnings > 0) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${(progress * 100).toStringAsFixed(0)}% of ${CurrencyFormatter.formatShort(monthlyTarget)} target",
                  style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 9, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Container(
                height: 4,
                decoration: BoxDecoration(color: context.ksc.primary700, borderRadius: BorderRadius.circular(2)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.ksc.success500,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(height: 1, color: context.ksc.primary700),
          const SizedBox(height: 12),
          // Secondary stats row
          Row(
            children: [
              Icon(LineAwesomeIcons.box_solid, size: 12, color: context.ksc.neutral500),
              const SizedBox(width: 4),
              Text("$filteredJobCount jobs", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontSize: 10, fontWeight: FontWeight.w700)),
              if (pendingCount > 0) ...[
                const SizedBox(width: 14),
                Icon(LineAwesomeIcons.sync_solid, size: 12, color: context.ksc.accent500),
                const SizedBox(width: 4),
                Text(
                  '$pendingCount uploading${isSyncing ? "…" : ""}',
                  style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontSize: 10, fontWeight: FontWeight.w700),
                ),
                if (isSyncing) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 10, height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: context.ksc.accent500),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }
}
