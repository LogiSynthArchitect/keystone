import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final userAsync = ref.watch(currentUserProvider);
    final profile = profileState.profile;
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.primary900,
      appBar: KsAppBar(
        title: "OPERATOR PROFILE",
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(LineAwesomeIcons.sign_out_alt_solid, color: AppColors.error500, size: 22),
            onPressed: () => ref.read(authStateProvider.notifier).signOut(),
          ),
        ],
      ),
      body: profileState.isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent500))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header - INDUSTRIAL IDENTITY MODULE
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary800,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.primary700),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary900,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.primary700, width: 2),
                            image: (profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty) 
                                ? DecorationImage(image: NetworkImage(profile.photoUrl!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: (profile?.photoUrl == null || profile!.photoUrl!.isEmpty)
                              ? Center(child: Text(profile?.displayName[0].toUpperCase() ?? "?", style: AppTextStyles.h1.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w900)))
                              : null,
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile?.displayName.toUpperCase() ?? "UNKNOWN OPERATOR", style: AppTextStyles.h2.copyWith(color: AppColors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent500.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(color: AppColors.accent500.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      "V1 PILOT OPERATOR", 
                                      style: AppTextStyles.caption.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1.0)
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(profile?.whatsappNumber ?? "NO REGISTERED CONTACT", style: AppTextStyles.body.copyWith(color: AppColors.neutral400, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionLabel("SYSTEM ACCESS LINK"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary800,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.accent500.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LineAwesomeIcons.link_solid, color: AppColors.accent500, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "keystone.app/p/${profile?.profileUrl ?? ''}",
                            style: AppTextStyles.body.copyWith(color: AppColors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LineAwesomeIcons.share_square_solid, color: AppColors.accent500, size: 20),
                          onPressed: () => ref.read(profileProvider.notifier).shareProfile(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionLabel("TERMINAL SETTINGS"),
                  _buildSettingsTile(LineAwesomeIcons.map_marker_solid, "REGION", "ACCRA, GHANA"),
                  _buildSettingsTile(LineAwesomeIcons.language_solid, "LANGUAGE", "ENGLISH (UK)"),
                  
                  if (isAdmin) ...[
                    const SizedBox(height: 32),
                    _buildSectionLabel("ADMINISTRATION"),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary800,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.accent500.withValues(alpha: 0.5)),
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
                                  style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                                ),
                                const Icon(LineAwesomeIcons.clipboard_list_solid, color: AppColors.accent500, size: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),
                  
                  // EDIT PROFILE ACTION
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary800,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.primary700),
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
                                "CONFIGURE PROFILE",
                                style: AppTextStyles.h2.copyWith(color: AppColors.white, fontWeight: FontWeight.w800, letterSpacing: 2.0),
                              ),
                              const Icon(LineAwesomeIcons.cog_solid, color: AppColors.accent500, size: 24),
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
          case 3: break; // Already here
        }
      }),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
    );
  }

  Widget _buildSettingsTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary700),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neutral500, size: 20),
          const SizedBox(width: 16),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          const Spacer(),
          Text(value, style: AppTextStyles.body.copyWith(color: AppColors.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
