import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/data_export_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final userAsync = ref.watch(currentUserProvider);
    final profile = profileState.profile;
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "MY PROFILE",
        showBack: false,
        actions: [
          IconButton(
            icon: Icon(LineAwesomeIcons.sign_out_alt_solid, color: context.ksc.error500, size: 22),
            onPressed: () => ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: profileState.isLoading
          ? Center(child: CircularProgressIndicator(color: context.ksc.accent500))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.ksc.primary800,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: context.ksc.primary700),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: context.ksc.primary900,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.ksc.accent500, width: 2),
                          ),
                          child: (profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.network(
                                    profile.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildInitialsPlaceholder(context, profile.displayName),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: context.ksc.accent500,
                                        strokeWidth: 2,
                                      ));
                                    },
                                  ),
                                )
                              : _buildInitialsPlaceholder(context, profile?.displayName ?? "?"),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile?.displayName.toUpperCase() ?? "SET UP YOUR PROFILE", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: context.ksc.accent500.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      "PILOT USER",
                                      style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1.0),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(profile?.whatsappNumber ?? "No phone number added", style: AppTextStyles.body.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionLabel(context, "YOUR PROFILE LINK"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.ksc.primary800,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(LineAwesomeIcons.link_solid, color: context.ksc.accent500, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "${AppConstants.profileBaseUrl}/${profile?.profileUrl ?? ''}",
                            style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          ),
                        ),
                        IconButton(
                          icon: Icon(LineAwesomeIcons.share_square_solid, color: context.ksc.accent500, size: 20),
                          onPressed: () => ref.read(profileProvider.notifier).shareProfile(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionLabel(context, "APP SETTINGS"),
                  _buildSettingsTile(context, LineAwesomeIcons.map_marker_solid, "REGION", "ACCRA, GHANA"),
                  _buildSettingsTile(context, LineAwesomeIcons.language_solid, "LANGUAGE", "ENGLISH (UK)"),
                  _buildThemeToggleTile(context, isDark, () => ref.read(themeModeProvider.notifier).toggle()),

                  if (isAdmin) ...[
                    const SizedBox(height: 32),
                    _buildSectionLabel(context, "ADMINISTRATION"),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.ksc.primary800,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.5)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.push(RouteNames.adminRequests),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "CORRECTION REQUESTS",
                                  style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                                ),
                                Icon(LineAwesomeIcons.clipboard_list_solid, color: context.ksc.accent500, size: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  _buildSectionLabel(context, "GETTING STARTED"),
                  _buildActionTile(
                    context,
                    LineAwesomeIcons.rocket_solid,
                    "SETUP GUIDE",
                    () => context.push(RouteNames.setup),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionLabel(context, "DATA"),
                  _buildActionTile(
                    context,
                    LineAwesomeIcons.file_code_solid,
                    "EXPORT AS JSON",
                    () => DataExportService.exportAsJson(),
                  ),
                  _buildActionTile(
                    context,
                    LineAwesomeIcons.file_csv_solid,
                    "EXPORT JOBS AS CSV",
                    () => DataExportService.exportAsCsv(),
                  ),

                  const SizedBox(height: 48),

                  // EDIT PROFILE ACTION
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.ksc.primary800,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: context.ksc.primary700),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push(RouteNames.editProfile),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "EDIT MY PROFILE",
                                style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 2.0),
                              ),
                              Icon(LineAwesomeIcons.cog_solid, color: context.ksc.accent500, size: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomNavigationBar: KsBottomNav(currentIndex: 3, onTabTapped: (index) {
        switch (index) {
          case 0: context.go(RouteNames.jobs); break;
          case 1: context.go(RouteNames.customers); break;
          case 2: context.go(RouteNames.notes); break;
          case 3: break;
        }
      }),
    );
  }

  Widget _buildInitialsPlaceholder(BuildContext context, String name) {
    return Center(
      child: Text(
        name.isEmpty ? "?" : name[0].toUpperCase(),
        style: AppTextStyles.h1.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildThemeToggleTile(BuildContext context, bool isDark, VoidCallback onToggle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Row(
        children: [
          Icon(isDark ? LineAwesomeIcons.moon : LineAwesomeIcons.sun, color: context.ksc.neutral500, size: 20),
          const SizedBox(width: 16),
          Text("APPEARANCE", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          const Spacer(),
          Text(isDark ? "DARK" : "LIGHT", style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(width: 12),
          Switch(value: isDark, onChanged: (_) => onToggle()),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: context.ksc.accent500, size: 20),
                const SizedBox(width: 16),
                Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                const Spacer(),
                Icon(LineAwesomeIcons.download_solid, color: context.ksc.neutral500, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.ksc.neutral500, size: 20),
          const SizedBox(width: 16),
          Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          const Spacer(),
          Text(value, style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
