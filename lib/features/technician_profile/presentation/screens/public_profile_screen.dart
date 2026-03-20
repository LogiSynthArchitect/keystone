import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/public_profile_provider.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/widgets/ks_logo_animated.dart';

class PublicProfileScreen extends ConsumerWidget {
  final String slug;
  const PublicProfileScreen({super.key, required this.slug});

  String _serviceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return 'Car Key\nProgramming';
      case ServiceType.doorLockInstallation:  return 'Door Lock\nInstallation';
      case ServiceType.doorLockRepair:        return 'Door Lock\nRepair';
      case ServiceType.smartLockInstallation: return 'Smart Lock\nSetup';
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

  Future<void> _callPhone(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent500),
        ),
        error: (e, _) => _centeredCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 64, color: AppColors.error500),
              const SizedBox(height: 24),
              Text("CONNECTION ERROR",
                  style: AppTextStyles.h2.copyWith(color: AppColors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text("Could not load this profile. Please try again.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.neutral500)),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return _centeredCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LineAwesomeIcons.user_slash_solid, size: 64, color: AppColors.primary700),
                  const SizedBox(height: 24),
                  Text("PROFILE NOT FOUND",
                      style: AppTextStyles.h2.copyWith(color: AppColors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text("This profile link is inactive or no longer exists.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(color: AppColors.neutral500)),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // --- TOP BRAND MARK ---
                      Center(
                        child: Column(
                          children: [
                            const KsLogoAnimated(size: 80, primaryColor: AppColors.white),
                            const SizedBox(height: 12),
                            Text('KEYSTONE',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.accent500,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4.0,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- AVATAR + IDENTITY ---
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary800,
                                border: Border.all(color: AppColors.accent500, width: 2.5),
                                image: profile.hasPhoto
                                    ? DecorationImage(image: NetworkImage(profile.photoUrl!), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: !profile.hasPhoto
                                  ? Center(
                                      child: Text(
                                        profile.displayName[0].toUpperCase(),
                                        style: AppTextStyles.h1.copyWith(
                                          color: AppColors.accent500,
                                          fontSize: 48,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              profile.displayName.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h1.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent500.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: AppColors.accent500.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'PROFESSIONAL LOCKSMITH · GHANA',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.accent500,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            if (profile.hasBio) ...[
                              const SizedBox(height: 20),
                              Text(
                                profile.bio!,
                                style: AppTextStyles.body.copyWith(color: AppColors.neutral400, height: 1.6),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // --- SERVICES ---
                      if (profile.services.isNotEmpty) ...[
                        _sectionLabel('SERVICES OFFERED'),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.6,
                          ),
                          itemCount: profile.services.length,
                          itemBuilder: (context, index) {
                            final service = profile.services[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary800,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.primary700),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_getServiceIcon(service), color: AppColors.accent500, size: 28),
                                  const SizedBox(height: 10),
                                  Text(
                                    _serviceLabel(service).toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9,
                                      letterSpacing: 0.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 48),
                      ],

                      // --- CONTACT SECTION ---
                      _sectionLabel('GET IN TOUCH'),
                      const SizedBox(height: 16),

                      // WhatsApp button (primary)
                      ElevatedButton(
                        onPressed: () => _openWhatsApp(profile.whatsappNumber),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LineAwesomeIcons.whatsapp, size: 26),
                            SizedBox(width: 10),
                            Text('CHAT ON WHATSAPP',
                                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 15)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Call button (secondary)
                      OutlinedButton(
                        onPressed: () => _callPhone(profile.whatsappNumber),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: const BorderSide(color: AppColors.primary700),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LineAwesomeIcons.phone_solid, size: 20, color: AppColors.neutral400),
                            const SizedBox(width: 10),
                            Text(
                              profile.whatsappNumber,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.neutral300,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 64),

                      // --- FOOTER ---
                      const Divider(color: AppColors.primary800, thickness: 1),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'POWERED BY KEYSTONE',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary700,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Professional Job Management for Locksmiths in Ghana',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary700,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.neutral500,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
        fontSize: 10,
      ),
    );
  }

  Widget _centeredCard({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: child,
        ),
      ),
    );
  }
}
