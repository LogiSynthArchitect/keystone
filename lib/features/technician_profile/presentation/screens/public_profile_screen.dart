import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/public_profile_provider.dart';
import '../../../../core/constants/app_enums.dart';

class PublicProfileScreen extends ConsumerWidget {
  final String slug;
  const PublicProfileScreen({super.key, required this.slug});

  String _serviceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return 'Car Key Programming';
      case ServiceType.doorLockInstallation:  return 'Door Installation';
      case ServiceType.doorLockRepair:        return 'Door Lock Repair';
      case ServiceType.smartLockInstallation: return 'Smart Lock Setup';
    }
  }

  IconData _getServiceIcon(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return LineAwesomeIcons.car_solid;
      case ServiceType.doorLockInstallation:  return LineAwesomeIcons.door_open_solid;
      case ServiceType.doorLockRepair:        return LineAwesomeIcons.tools_solid;
      case ServiceType.smartLockInstallation: return LineAwesomeIcons.fingerprint_solid;
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
              Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 80, color: AppColors.error500),
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
                  Icon(LineAwesomeIcons.user_slash_solid, size: 80, color: AppColors.primary800),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- IDENTITY MODULE ---
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary800,
                            border: Border.all(color: AppColors.accent500, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent500.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ],
                            image: profile.hasPhoto 
                                ? DecorationImage(image: NetworkImage(profile.photoUrl!), fit: BoxFit.cover) 
                                : null,
                          ),
                          child: !profile.hasPhoto
                              ? Center(
                                  child: Text(profile.displayName[0].toUpperCase(),
                                    style: AppTextStyles.h1.copyWith(color: AppColors.accent500, fontSize: 56, fontWeight: FontWeight.w900)))
                              : null,
                        ),
                        const SizedBox(height: 24),
                        Text(profile.displayName.toUpperCase(), 
                          textAlign: TextAlign.center,
                          style: AppTextStyles.display.copyWith(fontSize: 28, letterSpacing: 2.0)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent500.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.accent500.withValues(alpha: 0.4)),
                          ),
                          child: Text("VERIFIED KEYSTONE OPERATOR", 
                            style: AppTextStyles.caption.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                        ),
                        if (profile.hasBio) ...[
                          const SizedBox(height: 24),
                          Text(profile.bio!,
                              style: AppTextStyles.body.copyWith(color: AppColors.neutral400, height: 1.6, fontSize: 15),
                              textAlign: TextAlign.center),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 56),
                  
                  // --- TECHNICAL CAPABILITIES GRID ---
                  Text('TECHNICAL CAPABILITIES', 
                    style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 2.0)),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: profile.services.length,
                    itemBuilder: (context, index) {
                      final service = profile.services[index];
                      final icon = _getServiceIcon(service);
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary800,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary700),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: AppColors.accent500, size: 32),
                            const SizedBox(height: 12),
                            Text(_serviceLabel(service).toUpperCase(),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 64),
                  
                  // --- CONTACT MODULE ---
                  ElevatedButton(
                    onPressed: () => _openWhatsApp(profile.whatsappNumber),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(64),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center, 
                      children: [
                        Icon(LineAwesomeIcons.whatsapp, size: 32),
                        SizedBox(width: 12),
                        Text('INITIATE SECURE CHAT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
                      ]
                    ),
                  ),

                  const SizedBox(height: 80),
                  Center(
                    child: Column(
                      children: [
                        Opacity(
                          opacity: 0.2,
                          child: Icon(LineAwesomeIcons.shield_alt_solid, color: AppColors.neutral500, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: 0.3,
                          child: Text('POWERED BY KEYSTONE TERMINAL v1.0',
                              style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
