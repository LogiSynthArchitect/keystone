import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/widgets/ks_badge.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_button.dart';
import 'package:keystone/core/widgets/ks_sliding_notification.dart';
import '../../../../core/providers/connectivity_provider.dart';
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
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../job_logging/domain/entities/job_entity.dart';
import '../../../job_logging/presentation/providers/job_providers.dart';
import '../../../job_logging/presentation/screens/log_job_screen.dart';
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
import '../../../service_types/presentation/providers/service_type_provider.dart';
import '../../../job_templates/presentation/providers/job_template_provider.dart';
import '../../../technician_profile/presentation/providers/profile_provider.dart';
import '../../../reminders/domain/models/reminder_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _tapCount = 0;
  DateTime? _firstTap;

  void _handleTitleTap() {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final remindersState = ref.watch(remindersProvider);
    final reminders = remindersState.active;
    final jobListState = ref.watch(jobListProvider);
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;
    final connectivityAsync = ref.watch(connectivityStreamProvider);

    final allJobs = jobListState.activeJobs;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todayJobs = allJobs
        .where((j) => j.jobDate.isAfter(todayStart))
        .toList()
      ..sort((a, b) => a.jobDate.compareTo(b.jobDate));
    final monthStart = DateTime(now.year, now.month, 1);
    final monthJobs = allJobs.where((j) => j.jobDate.isAfter(monthStart)).toList();
    final todayRevenue = todayJobs.fold<int>(0, (s, j) => s + (j.amountCharged ?? 0));
    final monthRevenue = monthJobs.fold<int>(0, (s, j) => s + (j.amountCharged ?? 0));
    final unpaidCount = reminders.where((r) => r.type == ReminderType.unpaidJob).length;
    final stuckCount = reminders.where((r) => r.type == ReminderType.stuckInProgress).length;
    final followUpCount = reminders.where((r) =>
      r.type == ReminderType.followUpPending || r.type == ReminderType.followUpNoResponse
    ).length;
    final recurringOverdueCount = reminders.where((r) => r.type == ReminderType.recurringJobOverdue).length;

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "DASHBOARD",
        titleWidget: GestureDetector(
          onTap: _handleTitleTap,
          behavior: HitTestBehavior.opaque,
          child: Text("DASHBOARD", style: AppTextStyles.h3.copyWith(
            color: context.ksc.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          )),
        ),
        showBack: false,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(LineAwesomeIcons.bell_solid, color: followUpCount > 0 ? context.ksc.accent500 : context.ksc.neutral400, size: 22),
                onPressed: () => context.push(RouteNames.reminders),
              ),
              if (followUpCount > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(color: context.ksc.error500, shape: BoxShape.circle),
                    child: Center(child: Text('$followUpCount', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: context.ksc.white))),
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.profile),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: connectivityAsync.value == true
                          ? context.ksc.success500.withValues(alpha: 0.15)
                          : context.ksc.error500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(
                          color: connectivityAsync.value == true
                              ? context.ksc.success500
                              : context.ksc.error500,
                          shape: BoxShape.circle,
                        )),
                        const SizedBox(width: 4),
                        Text(
                          connectivityAsync.value == true ? 'ONLINE' : 'OFFLINE',
                          style: AppTextStyles.caption.copyWith(
                            color: connectivityAsync.value == true
                                ? context.ksc.success500
                                : context.ksc.error500,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(LineAwesomeIcons.user_circle_solid, color: context.ksc.neutral400, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroRevenue(context, todayRevenue, todayJobs.length, monthRevenue, monthJobs.length),
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
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBottomActions(context),
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
      ),
    );
  }

  Widget _buildHeroRevenue(BuildContext context, int todayRevenue, int todayCount, int monthRevenue, int monthJobsCount) {
    final monthlyTarget = 500000; // GHS 5,000 in pesewas
    final progress = monthRevenue / monthlyTarget;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final pct = (clampedProgress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.ksc.primary800,
            context.ksc.primary800.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TODAY", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(CurrencyFormatter.format(todayRevenue), style: AppTextStyles.display.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, fontSize: 40, height: 1.0)),
                    const SizedBox(height: 8),
                    Text("$todayCount job${todayCount != 1 ? 's' : ''} today", style: AppTextStyles.body.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.ksc.success500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: context.ksc.success500.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("MONTH", style: AppTextStyles.caption.copyWith(color: context.ksc.success500, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 9)),
                    const SizedBox(height: 4),
                    Text(CurrencyFormatter.formatShort(monthRevenue), style: AppTextStyles.h2.copyWith(color: context.ksc.success500, fontWeight: FontWeight.w900)),
                    Text("$monthJobsCount jobs", style: AppTextStyles.caption.copyWith(color: context.ksc.success500, fontWeight: FontWeight.w600, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: clampedProgress,
                    backgroundColor: context.ksc.primary700,
                    color: context.ksc.accent500,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text("$pct%", style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          Text("of monthly target ${CurrencyFormatter.format(monthlyTarget)}", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        ],
      ),
    );
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

    Color statusColor;
    switch (job.status) {
      case 'completed': statusColor = context.ksc.success500;
      case 'in_progress': statusColor = context.ksc.primary500;
      case 'invoiced': statusColor = context.ksc.warning500;
      default: statusColor = context.ksc.neutral500;
    }

    return GestureDetector(
      onTap: () => context.push(RouteNames.jobDetail(job.id)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(timeStr, style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10)),
              ),
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
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LineAwesomeIcons.bell_solid, size: 16, color: context.ksc.neutral400),
                const SizedBox(width: 8),
                Text("FOLLOW-UPS", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                const Spacer(),
                Text("VIEW ALL", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 12),
            if (unpaidCount > 0)
              _buildFollowUpRow(context, LineAwesomeIcons.wallet_solid, "$unpaidCount unpaid invoice${unpaidCount != 1 ? 's' : ''}", context.ksc.error500),
            if (stuckCount > 0)
              _buildFollowUpRow(context, LineAwesomeIcons.clock_solid, "$stuckCount job${stuckCount != 1 ? 's' : ''} still in progress", context.ksc.warning500),
            if (followUpCount > 0)
              _buildFollowUpRow(context, LineAwesomeIcons.whatsapp, "$followUpCount customer${followUpCount != 1 ? 's' : ''} awaiting follow-up", context.ksc.primary500),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpRow(BuildContext context, IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Text(text, style: AppTextStyles.body.copyWith(color: context.ksc.neutral300, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildQuickTools(BuildContext context) {
    final tools = [
      (LineAwesomeIcons.chart_line_solid, "ANALYTICS", context.ksc.accent500, () => context.push(RouteNames.analytics)),
      (LineAwesomeIcons.boxes_solid, "INVENTORY", context.ksc.primary500, () => context.push(RouteNames.inventory)),
      (LineAwesomeIcons.lightbulb_solid, "KNOWLEDGE", context.ksc.warning500, () => context.push(RouteNames.notes)),
      (LineAwesomeIcons.clock_solid, "ACTIVITY", context.ksc.neutral400, () => context.push(RouteNames.timeline)),
      (LineAwesomeIcons.coins_solid, "PRICING", context.ksc.success500, () => context.push(RouteNames.pricing)),
      (LineAwesomeIcons.copy_solid, "TEMPLATES", context.ksc.neutral400, () => context.push(RouteNames.templates)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tools.map((t) {
          final (icon, label, color, onTap) = t;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 88,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: context.ksc.primary800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(icon, size: 24, color: color),
                    const SizedBox(height: 8),
                    Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w700, fontSize: 9)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        border: Border(top: BorderSide(color: context.ksc.primary700)),
      ),
      child: Row(
        children: [
          Expanded(
            child: KsButton(
              label: "NEW JOB",
              variant: KsButtonVariant.primary,
              size: KsButtonSize.small,
              leadingIcon: LineAwesomeIcons.plus_solid,
              onPressed: () => LogJobScreen.show(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: KsButton(
              label: "NEW CUSTOMER",
              variant: KsButtonVariant.secondary,
              size: KsButtonSize.small,
              leadingIcon: LineAwesomeIcons.user_plus_solid,
              onPressed: () => context.push(RouteNames.addCustomer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Text(
    title, style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.5),
  );
}
