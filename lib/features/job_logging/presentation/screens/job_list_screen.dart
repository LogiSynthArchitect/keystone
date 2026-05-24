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
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/widgets/ks_filter_sheet.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/widgets/ks_search_bar.dart';
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
          KsSnackbar.show(context, message: next.errorMessage!, type: KsSnackbarType.error);
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: draft.dateRange != null
                          ? context.ksc.accent100
                          : context.ksc.primary700,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: draft.dateRange != null
                            ? context.ksc.accent500
                            : context.ksc.primary600,
                      ),
                    ),
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
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: _selectionMode ? "${_selectedIds.length} SELECTED" : "MY JOBS",
        actions: _selectionMode
            ? [
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
                    : NotificationListener<ScrollNotification>(
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
                                        child: Stack(
                                          children: [
                                            JobCard(
                                              job: job,
                                              onShareInvoice: () {
                                                final invoice = StringBuffer();
                                                invoice.writeln('KEYSTONE INVOICE');
                                                invoice.writeln('===============');
                                                invoice.writeln('Job: ${job.serviceType.replaceAll('_', ' ')}');
                                                invoice.writeln('Date: ${DateFormatter.display(job.jobDate)}');
                                                invoice.writeln('Status: ${job.status.toUpperCase()}');
                                                if (job.hasAmount) {
                                                  invoice.writeln('Amount: ${CurrencyFormatter.format(job.amountCharged!)}');
                                                }
                                                invoice.writeln('Payment: ${job.paymentStatus.toUpperCase()}');
                                                if (job.location != null && job.location!.isNotEmpty) {
                                                  invoice.writeln('Location: ${job.location}');
                                                }
                                                Share.share(invoice.toString(), subject: 'Invoice - ${job.serviceType.replaceAll('_', ' ')}');
                                              },
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
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? context.ksc.accent500 : context.ksc.primary700,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: isSelected ? context.ksc.accent500 : context.ksc.neutral500),
                                                  ),
                                                  child: isSelected
                                                      ? Icon(LineAwesomeIcons.check_solid, size: 14, color: context.ksc.primary900)
                                                      : null,
                                                ),
                                              ),
                                          ],
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
                      ),   // NotificationListener
          ),
        ],
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push(RouteNames.logJob),
              backgroundColor: context.ksc.accent500,
              foregroundColor: context.ksc.primary900,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              child: const Icon(LineAwesomeIcons.plus_solid, size: 28),
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
          KsSnackbar.show(context, message: "${ids.length} jobs archived", type: KsSnackbarType.success);
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
