import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/widgets/ks_bottom_sheet_scaffold.dart';
import '../../../../core/widgets/ks_badge.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_icon_well.dart';
import '../../../../core/widgets/ks_loading_indicator.dart';

import 'package:keystone/core/widgets/ks_sliding_notification.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/demo_data_seeder.dart';
import '../../../inventory/data/datasources/inventory_local_datasource.dart';
import '../../../inventory/data/datasources/inventory_restocks_local_datasource.dart';
import '../../../inventory/data/datasources/inventory_stock_adjustments_local_datasource.dart';
import '../../../knowledge_base/data/datasources/knowledge_note_local_datasource.dart';
import '../../../note_links/data/datasources/note_link_local_datasource.dart';
import '../../../whatsapp_followup/data/datasources/follow_up_local_datasource.dart';
import '../../../key_codes/data/datasources/key_code_local_datasource.dart';
import '../../../recurring_jobs/data/datasources/recurring_schedule_local_datasource.dart';
import '../../../job_templates/data/datasources/job_template_local_datasource.dart';
import '../../../service_types/data/datasources/service_type_local_datasource.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../job_logging/domain/entities/job_entity.dart';
import '../../../job_logging/presentation/providers/job_providers.dart';
import '../../../job_logging/presentation/screens/log_job_screen.dart';
import '../../../customer_history/presentation/screens/add_customer_screen.dart';
import '../../../job_logging/data/datasources/job_local_datasource.dart';
import '../../../job_logging/data/datasources/job_services_local_datasource.dart';
import '../../../job_logging/data/datasources/job_hardware_local_datasource.dart';
import '../../../job_logging/data/datasources/job_parts_local_datasource.dart';
import '../../../job_logging/data/datasources/job_expenses_local_datasource.dart';
import '../../../job_logging/data/datasources/job_audit_local_datasource.dart';
import '../../../job_logging/data/datasources/job_photos_local_datasource.dart';
import '../../../customer_history/data/datasources/customer_local_datasource.dart';
import '../../../customer_history/presentation/providers/customer_providers.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../knowledge_base/presentation/providers/notes_providers.dart';
import '../../../reminders/presentation/providers/reminders_provider.dart';
import '../../../recurring_jobs/presentation/providers/recurring_schedule_provider.dart';
import '../../../job_templates/presentation/providers/job_template_provider.dart';
import '../../../service_types/presentation/providers/service_type_provider.dart';
import '../../../reminders/domain/models/reminder_model.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _tapCount = 0;
  DateTime? _firstTap;
  bool _isSeeding = false;

  void _handleTitleTap() {
    if (_isSeeding) return; // lock — prevents race during active seed
    final now = DateTime.now();
    if (_firstTap == null || now.difference(_firstTap!) > const Duration(seconds: 3)) {
      _tapCount = 1;
      _firstTap = now;
      return;
    }
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      _firstTap = null;
      _toggleDemoData();
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(jobListProvider);
    ref.invalidate(remindersProvider);
    ref.invalidate(customerListProvider);
  }

  Future<void> _toggleDemoData() async {
    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) {
      if (mounted) KsSlidingNotification.show(context, message: 'Please log in first', type: KsNotificationType.error);
      return;
    }

    final service = DemoDataSeeder(
      customerLocal: CustomerLocalDatasource(),
      jobLocal: JobLocalDatasource(),
      servicesLocal: JobServicesLocalDatasource(),
      hardwareLocal: JobHardwareLocalDatasource(),
      partsLocal: JobPartsLocalDatasource(),
      expensesLocal: JobExpensesLocalDatasource(),
      photosLocal: JobPhotosLocalDatasource(),
      auditLocal: JobAuditLocalDatasource(),
      inventoryLocal: InventoryLocalDatasource(),
      restocksLocal: InventoryRestocksLocalDatasource(),
      stockAdjustmentsLocal: InventoryStockAdjustmentsLocalDatasource(),
      notesLocal: KnowledgeNoteLocalDatasource(),
      noteLinkLocal: NoteLinkLocalDatasource(),
      followUpLocal: FollowUpLocalDatasource(),
      keyCodeLocal: KeyCodeLocalDatasource(),
      recurringScheduleLocal: RecurringScheduleLocalDatasource(),
      jobTemplateLocal: JobTemplateLocalDatasource(),
      serviceTypeLocal: ServiceTypeLocalDatasource(),
      userId: userId,
    );

    setState(() => _isSeeding = true);
    try {
      final exists = await service.hasDemoData();
      if (exists) {
        await service.remove();
      } else {
        await service.seed();
      }
      if (mounted) {
        // Invalidate ALL providers to refresh UI from Hive
        ref.invalidate(jobListProvider);
        ref.invalidate(customerListProvider);
        ref.invalidate(inventoryProvider);
        ref.invalidate(notesListProvider);
        ref.invalidate(remindersProvider);
        ref.invalidate(recurringScheduleProvider);
        ref.invalidate(jobTemplateProvider);
        ref.invalidate(serviceTypeProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(analyticsProvider);
        });
        KsSlidingNotification.show(
          context,
          message: exists ? 'Demo data removed' : 'Demo data seeded — 8 customers, 12 jobs, inventory, notes, & more',
          type: KsNotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        KsSlidingNotification.show(context, message: 'Demo data error: $e', type: KsNotificationType.error);
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remindersState = ref.watch(remindersProvider);
    final reminders = remindersState.active;
    final jobListState = ref.watch(jobListProvider);
    // ── Loading state ──
    if (jobListState.isLoading) {
      return Scaffold(
        backgroundColor: context.ksc.primary900,
        appBar: _buildAppBar(context, followUpCount: 0),
        body: const KsLoadingIndicator(fullScreen: true),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }

    // ── Error state ──
    if (jobListState.errorMessage != null) {
      return Scaffold(
        backgroundColor: context.ksc.primary900,
        appBar: _buildAppBar(context, followUpCount: 0),
        body: Center(
          child: KsEmptyState(
            icon: LineAwesomeIcons.exclamation_triangle_solid,
            title: 'LOAD FAILED',
            subtitle: jobListState.errorMessage!,
            actionLabel: 'RETRY',
            onAction: _onRefresh,
          ),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }

    final allJobs = jobListState.activeJobs;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todayJobs = allJobs
        .where((j) =>
            j.jobDate.year == todayStart.year &&
            j.jobDate.month == todayStart.month &&
            j.jobDate.day == todayStart.day)
        .toList()
      ..sort((a, b) => a.jobDate.compareTo(b.jobDate));
    final monthStart = DateTime(now.year, now.month, 1);
    final monthJobs = allJobs.where((j) =>
      j.jobDate.year == monthStart.year &&
      j.jobDate.month == monthStart.month
    ).toList();
    final todayRevenue = todayJobs.fold<int>(0, (s, j) => s + (j.amountCharged ?? 0));
    final monthRevenue = monthJobs.fold<int>(0, (s, j) => s + (j.amountCharged ?? 0));
    final unpaidCount = reminders.where((r) => r.type == ReminderType.unpaidJob).length;
    final stuckCount = reminders.where((r) => r.type == ReminderType.stuckInProgress).length;
    final followUpCount = reminders.where((r) =>
      r.type == ReminderType.followUpPending || r.type == ReminderType.followUpNoResponse
    ).length;
    final recurringOverdueCount = reminders.where((r) => r.type == ReminderType.recurringJobOverdue).length;
    final totalActiveReminders = reminders.length;

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: _buildAppBar(context, followUpCount: totalActiveReminders),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: context.ksc.accent500,
              backgroundColor: context.ksc.primary800,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Metric cards (TODAY / MONTH) ──
                    Row(children: [
                      _buildMetricCard('TODAY', CurrencyFormatter.format(todayRevenue),
                          '${todayJobs.length} job${todayJobs.length != 1 ? 's' : ''} today', 'f32794-calendar.png'),
                      const SizedBox(width: 8),
                      _buildMetricCard('MONTH', CurrencyFormatter.formatShort(monthRevenue),
                          '${monthJobs.length} jobs this month', '36f0c6-money-bag.png'),
                    ]),
                    const SizedBox(height: 8),
                    // ── Monthly target progress ──
                    GestureDetector(
                      onTap: _showTargetEditDrawer,
                      child: _buildMonthlyProgress(context, monthRevenue),
                    ),
                    const SizedBox(height: 16),
                    // Reminder breakdown chips
                    if (reminders.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            if (unpaidCount > 0)
                              _reminderChip("$unpaidCount unpaid", context.ksc.error500),
                            if (stuckCount > 0)
                              _reminderChip("$stuckCount stuck", context.ksc.warning500),
                            if (followUpCount > 0)
                              _reminderChip("$followUpCount follow-up", context.ksc.primary400),
                            if (recurringOverdueCount > 0)
                              _reminderChip("$recurringOverdueCount recurring", context.ksc.accent500),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (todayJobs.isNotEmpty) ...[
                      _sectionHeader(context, "TODAY'S JOBS"),
                      const SizedBox(height: 12),
                      ...todayJobs.map((job) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildTodayJobCard(context, job),
                      )),
                      const SizedBox(height: 24),
                    ] else ...[
                      _buildEmptyDayCard(context),
                      const SizedBox(height: 24),
                    ],
                    if (reminders.isNotEmpty) ...[
                      _buildFollowUpSection(context, unpaidCount, stuckCount, followUpCount),
                      const SizedBox(height: 24),
                    ],
                    _sectionHeader(context, "TOOLS"),
                    const SizedBox(height: 12),
                    _buildQuickTools(context),
                    const SizedBox(height: 24),
                    // ── New Job / New Customer — clean cards ──
                    _sectionHeader(context, "QUICK ACTIONS"),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: LineAwesomeIcons.plus_circle_solid,
                      label: "NEW JOB",
                      subtitle: "Log a new service job",
                      onTap: () => LogJobScreen.show(context),
                    ),
                    const SizedBox(height: 8),
                    _buildActionCard(
                      icon: LineAwesomeIcons.user_plus_solid,
                      label: "NEW CUSTOMER",
                      subtitle: "Add a customer record",
                      onTap: () => AddCustomerScreen.show(context),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  KsAppBar _buildAppBar(BuildContext context, {required int followUpCount}) {
    return KsAppBar(
      title: "DASHBOARD",
      titleWidget: GestureDetector(
        onTap: _isSeeding ? null : _handleTitleTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("DASHBOARD", style: AppTextStyles.h3.copyWith(
              color: _isSeeding ? context.ksc.neutral500 : context.ksc.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            )),
            if (_isSeeding) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.ksc.accent500,
                ),
              ),
            ],
          ],
        ),
      ),
      showBack: false,
      actions: [
        KsIconWell(
          icon: LineAwesomeIcons.bell_solid,
          isActive: followUpCount > 0,
          badgeCount: followUpCount,
          onTap: () => context.push(RouteNames.reminders),
        ),
        KsIconWell(
          icon: LineAwesomeIcons.user_circle_solid,
          onTap: () => context.push(RouteNames.profile),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KsBottomNav(
          currentIndex: 0,
          onTabTapped: (i) {
            switch (i) {
              case 0: context.go(RouteNames.dashboard);
              case 1: context.go(RouteNames.jobs);
              case 2: context.go(RouteNames.customers);
              case 3: context.go(RouteNames.hub);
            }
          },
        ),
      ],
    );
  }

  Widget _buildMonthlyProgress(BuildContext context, int monthRevenue) {
    final monthlyTarget = ref.watch(monthlyTargetProvider);
    final pct = ((monthRevenue / monthlyTarget).clamp(0.0, 1.0) * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.ksc.primary800, context.ksc.primary800.withValues(alpha: 0.6)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LineAwesomeIcons.chart_line_solid, size: 20, color: context.ksc.neutral500),
              const SizedBox(width: 8),
              Text("MONTHLY TARGET",
                  style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const Spacer(),
              Text("$pct%",
                  style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (monthRevenue / monthlyTarget).clamp(0.0, 1.0),
              backgroundColor: context.ksc.primary700,
              color: context.ksc.accent500,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text("of ${CurrencyFormatter.format(monthlyTarget)} target",
              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        ],
      ),
    );
  }

  Future<void> _showTargetEditDrawer() async {
    final current = ref.read(monthlyTargetProvider);
    final ghs = current ~/ 100;
    final controller = TextEditingController(text: ghs > 0 ? ghs.toString() : '');
    String? successMessage;

    await KsBottomSheetScaffold.show<void>(
      context,
      title: 'MONTHLY TARGET',
      subtitle: 'Set your monthly revenue goal in GHS',
      bottomLabel: 'SAVE',
      onDone: () {
        final parsed = CurrencyFormatter.parseToPesewas(controller.text.trim());
        if (parsed == null || parsed <= 0) {
          KsSlidingNotification.show(context,
              message: 'Enter a valid amount', type: KsNotificationType.error);
          return;
        }
        HiveService.settings.put('monthlyTarget', parsed);
        ref.read(monthlyTargetProvider.notifier).state = parsed;
        successMessage = 'Monthly target updated to ${CurrencyFormatter.format(parsed)}';
      },
      contentBuilder: (ctx, setSheetState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter your monthly revenue target in GHS.',
              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            decoration: InputDecoration(
              hintText: 'e.g. 1500',
              hintStyle: AppTextStyles.bodyLarge.copyWith(
                color: context.ksc.neutral600,
                fontWeight: FontWeight.bold,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 4),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.ksc.primary700, width: 1),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.ksc.accent500, width: 1.5),
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: context.ksc.primary700),
              ),
              prefixText: 'GHS ',
              prefixStyle: AppTextStyles.body.copyWith(color: context.ksc.neutral500),
            ),
            style: AppTextStyles.body.copyWith(color: context.ksc.white),
            autofocus: true,
          ),
          const SizedBox(height: 24),
          if (current > 0) ...[
            Row(
              children: [
                Icon(LineAwesomeIcons.info_circle_solid, size: 14, color: context.ksc.neutral600),
                const SizedBox(width: 6),
                Text('Current: ${CurrencyFormatter.formatShort(current)}',
                    style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
              ],
            ),
          ],
        ],
      ),
    );

    // Show notification after sheet is fully closed to avoid overlay conflicts
    if (context.mounted && successMessage != null) {
      KsSlidingNotification.show(context,
          message: successMessage!, type: KsNotificationType.success);
    }
  }

  Widget _reminderChip(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: AppTextStyles.caption.copyWith(
          color: color, fontWeight: FontWeight.w800, fontSize: 10,
        )),
      ),
    );
  }

  Widget _buildTodayJobCard(BuildContext context, JobEntity job) {
    final timeStr = DateFormatter.shortTime(job.jobDate);

    return GestureDetector(
      onTap: () => context.push(RouteNames.jobDetail(job.id)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: context.ksc.primary700.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(LineAwesomeIcons.wrench_solid, size: 20, color: context.ksc.neutral400),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.serviceType.replaceAll('_', ' ').toUpperCase(),
                          style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      KsBadge(
                        label: job.status.toUpperCase().replaceAll('_', ' '),
                        variant: job.status == 'completed' ? KsBadgeVariant.success
                            : job.status == 'in_progress' ? KsBadgeVariant.neutral
                            : job.status == 'invoiced' ? KsBadgeVariant.warning
                            : KsBadgeVariant.neutral,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (job.location != null && job.location!.isNotEmpty) ...[
                        Icon(LineAwesomeIcons.map_marker_alt_solid, size: 10, color: context.ksc.neutral500),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(job.location!, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10), overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(timeStr, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
                      const SizedBox(width: 12),
                      if (job.amountCharged != null)
                        Text(CurrencyFormatter.formatShort(job.amountCharged!), style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LineAwesomeIcons.angle_right_solid, size: 16, color: context.ksc.neutral500),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDayCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: const KsEmptyState(
        icon: LineAwesomeIcons.calendar_day_solid,
        title: 'NO JOBS TODAY',
        subtitle: 'Tap + to log your first job today.',
      ),
    );
  }

  Widget _buildFollowUpSection(BuildContext context, int unpaidCount, int stuckCount, int followUpCount) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.reminders),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LineAwesomeIcons.clock_solid, size: 18, color: context.ksc.neutral500),
                const SizedBox(width: 10),
                Text("FOLLOW-UPS",
                    style: AppTextStyles.caption.copyWith(
                        color: context.ksc.neutral400,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5)),
                const Spacer(),
                Icon(LineAwesomeIcons.angle_right_solid,
                    size: 14, color: context.ksc.neutral500),
              ],
            ),
            const SizedBox(height: 16),
            if (unpaidCount > 0)
              _buildFollowUpRow(LineAwesomeIcons.file_invoice_dollar_solid,
                  "$unpaidCount unpaid invoice${unpaidCount != 1 ? 's' : ''}",
                  context.ksc.error500),
            if (stuckCount > 0)
              _buildFollowUpRow(LineAwesomeIcons.bolt_solid,
                  "$stuckCount job${stuckCount != 1 ? 's' : ''} still in progress",
                  context.ksc.warning500),
            if (followUpCount > 0)
              _buildFollowUpRow(LineAwesomeIcons.comment_solid,
                  "$followUpCount customer${followUpCount != 1 ? 's' : ''} awaiting follow-up",
                  context.ksc.primary500),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpRow(IconData icon, String text, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: context.ksc.primary700.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: context.ksc.neutral400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: AppTextStyles.body.copyWith(
                    color: context.ksc.neutral400,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTools(BuildContext context) {
    final tools = [
      ('4a4275-chart.png', "ANALYTICS", () => context.push(RouteNames.analytics)),
      ('176980-folder.png', "INVENTORY", () => context.push(RouteNames.inventory)),
      ('628100-notebook.png', "KNOWLEDGE", () => context.push(RouteNames.notes)),
      ('637858-flash.png', "ACTIVITY", () => context.push(RouteNames.timeline)),
      ('49b6f4-target.png', "PRICING", () => context.push(RouteNames.pricing)),
      ('d3d0c8-copy.png', "TEMPLATES", () => context.push(RouteNames.templates)),
    ];

    // 3-column grid — 3D icons kept here as the single premium zone
    return Column(
      children: [
        for (var row = 0; row < 2; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (row * 3 + col < tools.length)
                    Expanded(
                      child: _buildToolCard(tools[row * 3 + col]),
                    ),
                  if (col < 2) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildToolCard((String, String, VoidCallback) tool) {
    final (icon3d, label, onTap) = tool;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            _3dIcon(icon3d, size: 32),
            const SizedBox(height: 10),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: context.ksc.neutral400,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: context.ksc.primary700.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 18, color: context.ksc.neutral400),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.body.copyWith(
                          color: context.ksc.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption.copyWith(
                          color: context.ksc.neutral500, fontSize: 11)),
                ],
              ),
            ),
            Icon(LineAwesomeIcons.angle_right_solid,
                size: 16, color: context.ksc.neutral500),
          ],
        ),
      ),
    );
  }

  /// 3D icon — tools grid only (premium zone).
  Widget _3dIcon(String asset, {double size = 36}) => Image.asset(
    'assets/icons/3d/transparent/$asset',
    width: size, height: size,
    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
  );

  Widget _buildMetricCard(String label, String value, String sub, String icon3d) {
    final c = context;
    return Expanded(
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.ksc.primary800, c.ksc.primary800.withValues(alpha: 0.6)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.ksc.primary700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: c.ksc.primary700.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Image.asset('assets/icons/3d/transparent/$icon3d', width: 24, height: 24,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: c.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.display.copyWith(color: c.ksc.white, fontWeight: FontWeight.w900, fontSize: 32, height: 1)),
          const SizedBox(height: 2),
          Text(sub,
              style: AppTextStyles.body.copyWith(color: c.ksc.neutral400, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Text(
    title, style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.5),
  );
}
