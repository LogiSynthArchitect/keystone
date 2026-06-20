import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_icon_well.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/data_export_service.dart';
import '../../../reminders/presentation/providers/reminders_provider.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';
import '../../../technician_profile/presentation/providers/profile_provider.dart';
import '../../../job_logging/presentation/providers/job_providers.dart';
import '../../../knowledge_base/presentation/providers/notes_providers.dart';
import '../../../service_types/presentation/providers/service_type_provider.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../job_templates/presentation/providers/job_template_provider.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';

class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;
    final profileLoading = profileState.isLoading;
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final remindersCount = ref.watch(remindersProvider).activeCount;
    final jobState = ref.watch(jobListProvider);
    final monthlyTarget = ref.watch(monthlyTargetProvider);
    final notesState = ref.watch(notesListProvider);
    final notesCount = notesState.notes.length;
    final servicesAsync = ref.watch(serviceTypeProvider);
    final servicesCount = servicesAsync.valueOrNull?.length ?? 0;
    final invAsync = ref.watch(inventoryProvider);
    final invItems = invAsync.valueOrNull ?? [];
    final lowStockCount = invItems.where((i) => i.isLowStock).length;
    final templatesAsync = ref.watch(jobTemplateProvider);
    final templatesCount = templatesAsync.valueOrNull?.length ?? 0;
    final analyticsState = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "MORE",
        showBack: false,
        actions: [
          KsIconWell(
            icon: LineAwesomeIcons.bell_solid,
            isActive: remindersCount > 0,
            badgeCount: remindersCount,
            onTap: () => context.push(RouteNames.reminders),
          ),
          KsIconWell(
            icon: LineAwesomeIcons.sign_out_alt_solid,
            iconColor: context.ksc.error500,
            onTap: () => KsConfirmDialog.show(
              context,
              title: 'SIGN OUT',
              message: 'Are you sure you want to sign out? All local data will be cleared.',
              confirmLabel: 'SIGN OUT',
              cancelLabel: 'CANCEL',
              isDanger: true,
              onConfirm: () => ref.read(authStateProvider.notifier).signOut(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: profileLoading && profile == null
                  ? _buildLoadingSkeleton(context)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHero(context, ref, profile, jobState, monthlyTarget),
                        const SizedBox(height: 28),
                        _sectionHeader(context, "TOOLS"),
                        const SizedBox(height: 16),
                        _buildToolsBento(context, ref,
                          notesCount: notesCount,
                          lowStockCount: lowStockCount,
                          servicesCount: servicesCount,
                          templatesCount: templatesCount,
                          profitMargin: analyticsState.profitMargin,
                          jobCount: jobState.allJobs.length),
                        const SizedBox(height: 28),
                        _sectionHeader(context, "ACCOUNT"),
                        const SizedBox(height: 16),
                        _buildAccountGrid(context, ref),
                        const SizedBox(height: 28),
                        _sectionHeader(context, "SETTINGS"),
                        const SizedBox(height: 16),
                        _buildSettingsGrid(context, ref, isDark),
                        const SizedBox(height: 28),
                        _sectionHeader(context, "DATA"),
                        const SizedBox(height: 16),
                        _buildDataGrid(context, ref),
                        if (isAdmin) ...[
                          const SizedBox(height: 28),
                          _buildAdminBanner(context, ref),
                        ],
                        const SizedBox(height: 16),
                        _buildSetupLink(context),
                        const SizedBox(height: 48),
                      ],
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: KsBottomNav(
        currentIndex: 3,
        onTabTapped: (i) {
          switch (i) {
            case 0: context.go(RouteNames.dashboard);
            case 1: context.go(RouteNames.jobs);
            case 2: context.go(RouteNames.customers);
            case 3: context.go(RouteNames.hub);
          }
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  HERO
  // ═══════════════════════════════════════════════

  Widget _buildProfileHero(BuildContext context, WidgetRef ref,
      ProfileEntity? profile, JobListState jobState, int monthlyTarget) {
    final displayName = profile?.displayName;
    final monthEarnings = jobState.thisMonthEarnings;
    final pendingCount = jobState.pendingCount;
    final monthTargetFraction = monthlyTarget > 0
        ? (monthEarnings / monthlyTarget).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => context.push(RouteNames.profile),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Avatar + Name row — no container, floats on screen ───
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.ksc.primary800,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.ksc.accent500, width: 2),
                  ),
                  child: (profile?.photoUrl != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.network(
                            profile!.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Padding(
                              padding: EdgeInsets.all(9),
                              child: Image(
                                image: AssetImage(
                                    'assets/icons/3d/transparent/634b4b-crown.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        )
                      : const Padding(
                          padding: EdgeInsets.all(9),
                          child: Image(
                            image: AssetImage(
                                'assets/icons/3d/transparent/634b4b-crown.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName?.toUpperCase() ?? "MY PROFILE",
                        style: AppTextStyles.h3.copyWith(
                          color: context.ksc.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pendingCount > 0
                            ? '$pendingCount pending'
                            : 'All caught up',
                        style: AppTextStyles.body.copyWith(
                          color: pendingCount > 0
                              ? context.ksc.accent500
                              : context.ksc.neutral500,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(LineAwesomeIcons.angle_right_solid,
                    color: context.ksc.neutral600, size: 18),
              ],
            ),
            const SizedBox(height: 24),
            // ─── Monthly Target — no card, just icon + label + progress ───
            if (monthlyTarget > 0) ...[
              Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: Image(
                      image: AssetImage(
                          'assets/icons/3d/transparent/49b6f4-target.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("MONTHLY TARGET",
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(monthTargetFraction * 100).toInt()}%',
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.accent500,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: context.ksc.primary800,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: monthTargetFraction,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: context.ksc.accent500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TOOLS – BENTO GRID
  // ═══════════════════════════════════════════════

  Widget _buildToolsBento(BuildContext context, WidgetRef ref,
      {required int notesCount, required int lowStockCount, required int servicesCount,
      required int templatesCount, required double profitMargin, required int jobCount}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Knowledge Base – spans 2 cols
            Expanded(
              child: _bentoCard(
                context,
                icon: LineAwesomeIcons.sticky_note_solid,
                label: "KNOWLEDGE BASE",
                subtitle: "Notes and references",
                onTap: () => context.push(RouteNames.notes),
                child: _inlineTags(context, ["$notesCount notes"]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _bentoCard(
                context,
                icon: LineAwesomeIcons.boxes_solid,
                label: "INVENTORY",
                subtitle: "Track parts and hardware",
                onTap: () => context.push(RouteNames.inventory),
                child: _liveMetric(context, "$lowStockCount", "low stock"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bentoCard(
                context,
                icon: LineAwesomeIcons.coins_solid,
                label: "PRICING",
                subtitle: "Default service prices",
                onTap: () => context.push(RouteNames.pricing),
                child: _liveMetric(context, "$servicesCount", "service types"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _bentoCard(
                context,
                icon: LineAwesomeIcons.copy_solid,
                label: "TEMPLATES",
                subtitle: "Save and load job templates",
                onTap: () => context.push(RouteNames.templates),
                child: _inlineTags(context, ["$templatesCount saved"]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bentoCard(
                context,
                icon: LineAwesomeIcons.chart_line_solid,
                label: "ANALYTICS",
                subtitle: "Revenue and trends",
                onTap: () => context.push(RouteNames.analytics),
                child: _progressBar(context, profitMargin.clamp(0.0, 1.0),
                    "${(profitMargin * 100).toInt()}%"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _bentoCard(
                context,
                icon: LineAwesomeIcons.clock_solid,
                label: "TIMELINE",
                subtitle: "Full audit trail",
                onTap: () => context.push(RouteNames.timeline),
                child: _liveMetric(context, "$jobCount", "jobs"),
              ),
            ),
            const SizedBox(width: 12),
            // Empty cell to maintain balance – could be a future feature slot
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _bentoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    Widget? child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: context.ksc.accent500),
            const SizedBox(height: 8),
            Text(label,
              style: AppTextStyles.body.copyWith(
                color: context.ksc.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitle,
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500,
                fontSize: 10,
              ),
            ),
            if (child != null) ...[
              const SizedBox(height: 10),
              child,
            ],
          ],
        ),
      ),
    );
  }

  Widget _inlineTags(BuildContext context, List<String> tags) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags.map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: context.ksc.accent500.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(t,
          style: AppTextStyles.caption.copyWith(
            color: context.ksc.accent500,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      )).toList(),
    );
  }

  Widget _liveMetric(BuildContext context, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
          style: AppTextStyles.h3.copyWith(
            color: context.ksc.accent500,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        Text(label,
          style: AppTextStyles.caption.copyWith(
            color: context.ksc.neutral500,
            fontSize: 8,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _progressBar(BuildContext context, double fraction, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: context.ksc.primary900,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: context.ksc.accent500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
          style: AppTextStyles.caption.copyWith(
            color: context.ksc.neutral500,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  SETTINGS + DATA – COMPACT GRID
  // ═══════════════════════════════════════════════

  Widget _buildAccountGrid(BuildContext context, WidgetRef ref) {
    return _compactGrid(context, [
      _compactTile(context, icon: LineAwesomeIcons.shield_alt_solid,
          label: "Security & Account",
          onTap: () => context.push('/profile/security')),
      _compactTile(context, icon: LineAwesomeIcons.sign_out_alt_solid,
          label: "Sign Out", onTap: () => KsConfirmDialog.show(
            context,
            title: 'SIGN OUT',
            message: 'Are you sure you want to sign out? All local data will be cleared.',
            confirmLabel: 'SIGN OUT',
            cancelLabel: 'CANCEL',
            isDanger: true,
            onConfirm: () => ref.read(authStateProvider.notifier).signOut(),
          )),
    ]);
  }

  Widget _buildSettingsGrid(BuildContext context, WidgetRef ref, bool isDark) {
    return _compactGrid(context, [
      _compactTile(context, icon: isDark ? LineAwesomeIcons.moon_solid : LineAwesomeIcons.sun_solid,
          label: "Appearance", onTap: () => ref.read(themeModeProvider.notifier).toggle()),
      _compactTile(context, icon: LineAwesomeIcons.bell_solid,
          label: "Reminders", onTap: () => context.push(RouteNames.reminderSettings)),
      _compactTile(context, icon: LineAwesomeIcons.calendar_alt_solid,
          label: "Recurring", onTap: () => context.push(RouteNames.recurringJobs)),
      _compactTile(context, icon: LineAwesomeIcons.cogs_solid,
          label: "Service Types", onTap: () => context.push(RouteNames.serviceTypes)),
    ]);
  }

  Widget _buildDataGrid(BuildContext context, WidgetRef ref) {
    return _compactGrid(context, [
      _compactTile(context, icon: LineAwesomeIcons.file_csv_solid,
          label: "Jobs CSV", onTap: () => DataExportService.exportAsCsv()),
      _compactTile(context, icon: LineAwesomeIcons.file_invoice_solid,
          label: "Detailed CSV", onTap: () => DataExportService.exportDetailedJobsCsv()),
      _compactTile(context, icon: LineAwesomeIcons.users_solid,
          label: "Customers", onTap: () => DataExportService.exportCustomersAsCsv()),
      _compactTile(context, icon: LineAwesomeIcons.boxes_solid,
          label: "Inventory", onTap: () => DataExportService.exportInventoryAsCsv()),
      _compactTileWide(context, icon: LineAwesomeIcons.file_code_solid,
          label: "Full JSON Export", onTap: () => DataExportService.exportAsJson()),
    ]);
  }

  Widget _compactGrid(BuildContext context, List<Widget> tiles) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tiles,
    );
  }

  Widget _compactTile(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 24 * 2 - 8) / 2,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: context.ksc.neutral400),
            const SizedBox(width: 10),
            Flexible(
              child: Text(label,
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactTileWide(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 24 * 2 - 8) / 2,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: context.ksc.neutral400),
            const SizedBox(width: 10),
            Flexible(
              child: Text(label,
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  ADMIN
  // ═══════════════════════════════════════════════

  Widget _buildAdminBanner(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.adminRequests),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.ksc.primary800,
              context.ksc.primary900,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.ksc.error500.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(LineAwesomeIcons.shield_alt_solid,
                color: context.ksc.error500, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ADMINISTRATION",
                    style: AppTextStyles.body.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text("Corrections, permissions",
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LineAwesomeIcons.angle_right_solid,
                color: context.ksc.neutral600, size: 18),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  SETUP LINK
  // ═══════════════════════════════════════════════

  Widget _buildSetupLink(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => context.push(RouteNames.setup),
        icon: Icon(LineAwesomeIcons.rocket_solid, size: 16,
            color: context.ksc.neutral500),
        label: Text("SETUP GUIDE",
          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  SECTION HEADER
  // ═══════════════════════════════════════════════

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(title,
      style: AppTextStyles.caption.copyWith(
        color: context.ksc.accent500,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  LOADING SKELETON
  // ═══════════════════════════════════════════════

  Widget _buildLoadingSkeleton(BuildContext context) {
    // Using subtle animated shimmer containers
    final shimmer = context.ksc.primary800;
    final shimmerLight = context.ksc.primary700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skeleton hero
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: shimmer,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 28),
        // Section header skeleton
        Container(
          width: 80, height: 14,
          decoration: BoxDecoration(
            color: shimmer, borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 16),
        // Bento skeleton – row 1
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: shimmer,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  color: shimmerLight, borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  color: shimmerLight, borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
