import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_skeleton_loader.dart';
import '../providers/profile_provider.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0: context.go(RouteNames.jobs); break;
      case 1: context.go(RouteNames.customers); break;
      case 2: context.go(RouteNames.notes); break;
      case 3: context.go(RouteNames.profile); break;
    }
  }

  String _serviceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return 'Car Key Programming';
      case ServiceType.doorLockInstallation:  return 'Door Lock Installation';
      case ServiceType.doorLockRepair:        return 'Door Lock Repair';
      case ServiceType.smartLockInstallation: return 'Smart Lock Installation';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral050,
      appBar: KsAppBar(
        title: 'Profile',
        actions: [
          if (state.hasProfile)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.neutral600),
              onPressed: () => context.push(RouteNames.editProfile),
            ),
        ],
      ),
      body: Column(
        children: [
          const KsOfflineBanner(),
          Expanded(
            child: state.isLoading
                ? _buildSkeleton()
                : !state.hasProfile
                    ? _buildNoProfile(context)
                    : _buildProfile(context, ref, state.profile!),
          ),
        ],
      ),
      bottomNavigationBar: KsBottomNav(currentIndex: 3, onTabTapped: (i) => _onTabTapped(context, i)),
    );
  }

  Widget _buildSkeleton() {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(children: [
        SizedBox(height: AppSpacing.xl),
        Center(child: KsSkeletonLoader(width: 80, height: 80, borderRadius: 40)),
        SizedBox(height: AppSpacing.lg),
        KsSkeletonLoader(height: 24, width: 160),
        SizedBox(height: AppSpacing.sm),
        KsSkeletonLoader(height: 16, width: 200),
      ]),
    );
  }

  Widget _buildNoProfile(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.person_outline, size: 64, color: AppColors.neutral300),
          const SizedBox(height: AppSpacing.lg),
          Text('No profile yet', style: AppTextStyles.h3.copyWith(color: AppColors.neutral600)),
          const SizedBox(height: AppSpacing.sm),
          Text('Your profile is created automatically when you complete onboarding.', style: AppTextStyles.body.copyWith(color: AppColors.neutral500), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, ProfileEntity profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(children: [
              const SizedBox(height: AppSpacing.lg),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary100,
                backgroundImage: profile.hasPhoto ? NetworkImage(profile.photoUrl!) : null,
                child: !profile.hasPhoto
                    ? Text(profile.displayName[0].toUpperCase(), style: AppTextStyles.h1.copyWith(color: AppColors.primary700))
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(profile.displayName, style: AppTextStyles.h2),
              if (profile.hasBio) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(profile.bio!, style: AppTextStyles.body.copyWith(color: AppColors.neutral600), textAlign: TextAlign.center),
              ],
              const SizedBox(height: AppSpacing.xl),
            ]),
          ),

          // Services
          Text('Services', style: AppTextStyles.captionMedium.copyWith(color: AppColors.neutral500)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: profile.services.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(color: AppColors.primary050, borderRadius: BorderRadius.circular(AppSpacing.radiusFull), border: Border.all(color: AppColors.primary100)),
              child: Text(_serviceLabel(s), style: AppTextStyles.caption.copyWith(color: AppColors.primary700)),
            )).toList(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Share profile button
          GestureDetector(
            onTap: () => ref.read(profileProvider.notifier).shareProfile(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.primary700, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.share_outlined, size: 18, color: AppColors.white),
                const SizedBox(width: AppSpacing.sm),
                Text('Share my profile', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white)),
              ]),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Profile URL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.neutral200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your profile link', style: AppTextStyles.captionMedium.copyWith(color: AppColors.neutral500)),
              const SizedBox(height: AppSpacing.xs),
              Text('https://${profile.profileUrl}', style: AppTextStyles.body.copyWith(color: AppColors.primary600)),
            ]),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Sign out
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text('You will need to log in again.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out', style: TextStyle(color: AppColors.error600))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(authStateProvider.notifier).signOut();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.neutral200)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.logout, size: 18, color: AppColors.error600),
                const SizedBox(width: AppSpacing.sm),
                Text('Sign out', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error600)),
              ]),
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}
