import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/data_export_service.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../reminders/presentation/providers/reminders_provider.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';
import '../../../technician_profile/presentation/providers/profile_provider.dart';

class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final remindersCount = ref.watch(remindersProvider).activeCount;

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "MORE",
        showBack: false,
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
                  top: 8, right: 8,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(color: context.ksc.error500, shape: BoxShape.circle),
                    child: Center(child: Text('$remindersCount', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: context.ksc.white))),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.sign_out_alt_solid, color: context.ksc.error500, size: 22),
            onPressed: () => KsConfirmDialog.show(
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
          const KsOfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(context, ref, profile),
            const SizedBox(height: 32),
            _sectionHeader(context, "TOOLS"),
            const SizedBox(height: 16),
            _buildActionTile(context, LineAwesomeIcons.lightbulb_solid, "KNOWLEDGE BASE", "Notes and references", () => context.push(RouteNames.notes)),
            _buildActionTile(context, LineAwesomeIcons.boxes_solid, "INVENTORY", "Track parts and hardware stock", () => context.push(RouteNames.inventory)),
            _buildActionTile(context, LineAwesomeIcons.coins_solid, "SERVICE PRICING", "Set default prices per service", () => context.push(RouteNames.pricing)),
            _buildActionTile(context, LineAwesomeIcons.copy_solid, "JOB TEMPLATES", "Save and load job templates", () => context.push(RouteNames.templates)),
            _buildActionTile(context, LineAwesomeIcons.clock_solid, "ACTIVITY TIMELINE", "Full audit trail of all events", () => context.push(RouteNames.timeline)),
            _buildActionTile(context, LineAwesomeIcons.chart_line_solid, "ANALYTICS", "Revenue, jobs, and trends", () => context.push(RouteNames.analytics)),
            const SizedBox(height: 32),
            _sectionHeader(context, "SETTINGS"),
            const SizedBox(height: 16),
            _buildThemeToggleTile(context, isDark, () => ref.read(themeModeProvider.notifier).toggle()),
            _buildActionTile(context, LineAwesomeIcons.bell_solid, "REMINDER SETTINGS", "Configure reminder thresholds", () => context.push(RouteNames.reminderSettings)),
            _buildActionTile(context, LineAwesomeIcons.calendar_alt_solid, "RECURRING JOBS", "Manage recurring schedules", () => context.push(RouteNames.recurringJobs)),
            _buildActionTile(context, LineAwesomeIcons.cogs_solid, "SERVICE TYPES", "Manage available service types", () => context.push(RouteNames.serviceTypes)),
            const SizedBox(height: 32),
            _sectionHeader(context, "DATA"),
            const SizedBox(height: 16),
            _buildActionTile(context, LineAwesomeIcons.file_csv_solid, "EXPORT JOBS CSV", "Download jobs as spreadsheet", () => DataExportService.exportAsCsv()),
            _buildActionTile(context, LineAwesomeIcons.file_invoice_solid, "EXPORT JOBS DETAILED CSV", "With parts, expenses, and profit", () => DataExportService.exportDetailedJobsCsv()),
            _buildActionTile(context, LineAwesomeIcons.users_solid, "EXPORT CUSTOMERS CSV", "Download customers as spreadsheet", () => DataExportService.exportCustomersAsCsv()),
            _buildActionTile(context, LineAwesomeIcons.boxes_solid, "EXPORT INVENTORY CSV", "Download inventory as spreadsheet", () => DataExportService.exportInventoryAsCsv()),
            _buildActionTile(context, LineAwesomeIcons.book_solid, "EXPORT NOTES CSV", "Download notes as spreadsheet", () => DataExportService.exportNotesAsCsv()),
            _buildActionTile(context, LineAwesomeIcons.file_code_solid, "EXPORT ALL JSON", "Full data export as JSON", () => DataExportService.exportAsJson()),
            if (isAdmin) ...[
              const SizedBox(height: 32),
              _sectionHeader(context, "ADMINISTRATION"),
              const SizedBox(height: 16),
              _buildActionTile(context, LineAwesomeIcons.clipboard_list_solid, "CORRECTION REQUESTS", "Approve or reject job corrections", () => context.push(RouteNames.adminRequests)),
              _buildActionTile(context, LineAwesomeIcons.lock_solid, "TECHNICIAN PERMISSIONS", "Manage role-based access", () => context.push(RouteNames.permissions)),
            ],
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () => context.push(RouteNames.setup),
                icon: Icon(LineAwesomeIcons.rocket_solid, size: 16, color: context.ksc.neutral500),
                label: Text("SETUP GUIDE", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
              ),
            ),
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

  Widget _buildProfileCard(BuildContext context, WidgetRef ref, ProfileEntity? profile) {
    final displayName = profile?.displayName;
    return GestureDetector(
      onTap: () => context.push(RouteNames.profile),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.ksc.primary900,
                shape: BoxShape.circle,
                border: Border.all(color: context.ksc.accent500, width: 2),
              ),
              child: (profile?.photoUrl != null)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(profile!.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(LineAwesomeIcons.user_circle_solid, color: context.ksc.accent500, size: 28)),
                    )
                  : Icon(LineAwesomeIcons.user_circle_solid, color: context.ksc.accent500, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName?.toUpperCase() ?? "MY PROFILE", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text("Tap to view full profile", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
                ],
              ),
            ),
            Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.neutral500),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String label, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.ksc.primary700),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.ksc.neutral400, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                    Text(subtitle, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
                  ],
                ),
              ),
              Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.neutral600, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggleTile(BuildContext context, bool isDark, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          children: [
            Icon(isDark ? LineAwesomeIcons.moon_solid : LineAwesomeIcons.sun_solid, color: context.ksc.neutral400, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("APPEARANCE", style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                  Text(isDark ? "Dark Mode" : "Light Mode", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
                ],
              ),
            ),
            Switch(
              value: isDark,
              onChanged: (_) => onToggle(),
              activeTrackColor: context.ksc.accent500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Text(title, style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.5));
}
