import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_loading_indicator.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../providers/profile_provider.dart';
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
      backgroundColor: AppColors.primary900,
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent500)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 80, color: AppColors.error500),
              const SizedBox(height: 24),
              Text("SUPABASE ERROR", style: AppTextStyles.h2.copyWith(color: AppColors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(e.toString(), 
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.error500, fontSize: 10, fontFamily: 'monospace')),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LineAwesomeIcons.user_slash_solid, size: 80, color: AppColors.primary800),
                  const SizedBox(height: 24),
                  Text("PROFILE NOT FOUND", style: AppTextStyles.h2.copyWith(color: AppColors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text("This operator profile does not exist or is no longer public.", 
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.neutral500)),
                ],
              ),
            );
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  Center(
                    child: Column(children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary800,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primary700, width: 2),
                          image: profile.hasPhoto ? DecorationImage(image: NetworkImage(profile.photoUrl!), fit: BoxFit.cover) : null,
                        ),
                        child: !profile.hasPhoto
                            ? Center(
                                child: Text(profile.displayName[0].toUpperCase(),
                                  style: AppTextStyles.h1.copyWith(color: AppColors.accent500, fontSize: 48, fontWeight: FontWeight.w900)))
                            : null,
                      ),
                      const SizedBox(height: 24),
                      Text(profile.displayName.toUpperCase(), style: AppTextStyles.h1.copyWith(letterSpacing: 1.0)),
                      if (profile.hasBio) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(profile.bio!,
                              style: AppTextStyles.body.copyWith(color: AppColors.neutral400, height: 1.5),
                              textAlign: TextAlign.center),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 48),
                  Text('TECHNICAL CAPABILITIES', style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.services.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary800,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.primary700),
                      ),
                      child: Text(_serviceLabel(s).toUpperCase(),
                          style: AppTextStyles.caption.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    )).toList(),
                  ),
                  const SizedBox(height: 64),
                  ElevatedButton(
                    onPressed: () => _openWhatsApp(profile.whatsappNumber),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(LineAwesomeIcons.whatsapp, size: 24),
                      SizedBox(width: 12),
                      Text('CHAT ON WHATSAPP', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    ]),
                  ),
                  const SizedBox(height: 64),
                  Center(
                    child: Opacity(
                      opacity: 0.3,
                      child: Text('POWERED BY KEYSTONE TERMINAL',
                          style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
