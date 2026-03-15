import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_loading_indicator.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../providers/profile_provider.dart';
import '../../domain/entities/profile_entity.dart';
import '../../../../core/constants/app_enums.dart';

class PublicProfileScreen extends ConsumerWidget {
  final String slug;
  const PublicProfileScreen({super.key, required this.slug});

  String _serviceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return 'Car Key Programming';
      case ServiceType.doorLockInstallation:  return 'Door Lock Installation';
      case ServiceType.doorLockRepair:        return 'Door Lock Repair';
      case ServiceType.smartLockInstallation: return 'Smart Lock Installation';
    }
  }

  Future<void> _openWhatsApp(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(publicProfileProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.neutral050,
      body: state.when(
        loading: () => const KsLoadingIndicator(fullScreen: true),
        error: (e, _) => const KsEmptyState(
          icon: Icons.person_off_outlined,
          title: 'Profile not found',
          subtitle: 'This profile does not exist or is no longer public.',
        ),
        data: (profile) {
          if (profile == null) {
            return const KsEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Profile not found',
              subtitle: 'This profile does not exist or is no longer public.',
            );
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Column(children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary100,
                        backgroundImage: profile.hasPhoto ? NetworkImage(profile.photoUrl!) : null,
                        child: !profile.hasPhoto
                            ? Text(profile.displayName[0].toUpperCase(),
                                style: AppTextStyles.h1.copyWith(color: AppColors.primary700))
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(profile.displayName, style: AppTextStyles.h2),
                      if (profile.hasBio) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(profile.bio!,
                            style: AppTextStyles.body.copyWith(color: AppColors.neutral600),
                            textAlign: TextAlign.center),
                      ],
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Services', style: AppTextStyles.captionMedium.copyWith(color: AppColors.neutral500)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: profile.services.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primary050,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(color: AppColors.primary100),
                      ),
                      child: Text(_serviceLabel(s),
                          style: AppTextStyles.caption.copyWith(color: AppColors.primary700)),
                    )).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  GestureDetector(
                    onTap: () => _openWhatsApp(profile.whatsappNumber),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.chat, size: 18, color: AppColors.white),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Chat on WhatsApp',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Center(
                    child: Text('Powered by Keystone',
                        style: AppTextStyles.caption.copyWith(color: AppColors.neutral400)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
