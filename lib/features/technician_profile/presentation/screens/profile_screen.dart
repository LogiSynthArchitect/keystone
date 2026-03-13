import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;

    return Scaffold(
      backgroundColor: AppColors.primary900,
      appBar: KsAppBar(
        title: "MY PROFILE",
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(LineAwesomeIcons.sign_out_alt_solid, color: AppColors.error500),
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
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary800,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary900,
                          backgroundImage: (profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty) 
                              ? NetworkImage(profile.photoUrl!) 
                              : null,
                          child: (profile?.photoUrl == null || profile!.photoUrl!.isEmpty)
                              ? Text(profile?.displayName[0].toUpperCase() ?? "?", style: AppTextStyles.h1.copyWith(color: AppColors.accent500))
                              : null,
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile?.displayName.toUpperCase() ?? "UNKNOWN", style: AppTextStyles.h3.copyWith(color: AppColors.white, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(profile?.whatsappNumber ?? "", style: AppTextStyles.body.copyWith(color: AppColors.neutral400)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionLabel("BUSINESS LINK"),
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
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LineAwesomeIcons.share_square, color: AppColors.accent500),
                          onPressed: () => ref.read(profileProvider.notifier).shareProfile(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionLabel("SETTINGS"),
                  _buildSettingsTile(LineAwesomeIcons.map_marker_solid, "REGION", "ACCRA, GHANA"),
                  _buildSettingsTile(LineAwesomeIcons.language_solid, "LANGUAGE", "ENGLISH (UK)"),
                  
                  const SizedBox(height: 48),
                  
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary800,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        side: const BorderSide(color: AppColors.accent500),
                      ),
                      onPressed: () => context.push(RouteNames.editProfile),
                      child: Text("EDIT PROFILE", style: AppTextStyles.label.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neutral500, size: 20),
          const SizedBox(width: 16),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.neutral500)),
          const Spacer(),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
