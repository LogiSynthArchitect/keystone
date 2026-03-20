import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../providers/public_profile_provider.dart';
import '../../../../core/constants/app_enums.dart';

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
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callPhone(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(publicProfileProvider(slug));

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: state.when(
              loading: () => Center(child: CircularProgressIndicator(color: context.ksc.accent500)),
              error: (_, __) => _centeredMessage(
                context: context,
                icon: LineAwesomeIcons.exclamation_triangle_solid,
                iconColor: context.ksc.error500,
                title: 'Something went wrong',
                subtitle: 'We could not load this profile. Please try again.',
              ),
              data: (profile) {
                if (profile == null) {
                  return _centeredMessage(
                    context: context,
                    icon: LineAwesomeIcons.user_slash_solid,
                    iconColor: context.ksc.neutral300,
                    title: 'Profile Not Found',
                    subtitle: 'This link is no longer active.',
                  );
                }

                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildIdentityCard(context, profile),
                            const SizedBox(height: 20),
                            if (profile.services.isNotEmpty) ...[
                              _buildServicesSection(context, profile),
                              const SizedBox(height: 20),
                            ],
                            _buildContactSection(context, profile),
                            const SizedBox(height: 48),
                            _buildFooter(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      width: double.infinity,
      color: context.ksc.primary800,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        border: Border(bottom: BorderSide(color: context.ksc.primary700)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: context.ksc.accent500,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: SvgPicture.asset(
                    'assets/logo/keystone_logo.svg',
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'KEYSTONE',
                style: AppTextStyles.body.copyWith(
                  color: context.ksc.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.0,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                'Built for Locksmiths',
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral400,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityCard(BuildContext context, dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.ksc.primary700),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1628).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.ksc.primary900,
              border: Border.all(color: context.ksc.accent500, width: 3),
              image: profile.hasPhoto
                  ? DecorationImage(image: NetworkImage(profile.photoUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: !profile.hasPhoto
                ? Center(
                    child: Text(
                      profile.displayName[0].toUpperCase(),
                      style: TextStyle(
                        color: context.ksc.accent500,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'BarlowSemiCondensed',
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            profile.displayName,
            textAlign: TextAlign.center,
            style: AppTextStyles.h1.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.ksc.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: context.ksc.accent500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Locksmith · Ghana',
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.accent500,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (profile.hasBio) ...[
            const SizedBox(height: 20),
            Divider(color: context.ksc.primary700, height: 1),
            const SizedBox(height: 20),
            Text(
              profile.bio!,
              style: AppTextStyles.body.copyWith(
                color: context.ksc.neutral500,
                height: 1.7,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context, dynamic profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, 'What I Do'),
        const SizedBox(height: 12),
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
                color: context.ksc.primary800,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.ksc.primary700),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A1628).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getServiceIcon(service), color: context.ksc.accent500, size: 26),
                  const SizedBox(height: 8),
                  Text(
                    _serviceLabel(service),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral500,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context, dynamic profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, 'Get in Touch'),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _openWhatsApp(profile.whatsappNumber),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LineAwesomeIcons.whatsapp, size: 24),
              SizedBox(width: 10),
              Text('Chat on WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => _callPhone(profile.whatsappNumber),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.ksc.neutral500,
            side: BorderSide(color: context.ksc.primary700, width: 1.5),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LineAwesomeIcons.phone_solid, size: 18, color: context.ksc.neutral400),
              const SizedBox(width: 10),
              Text(
                profile.whatsappNumber,
                style: AppTextStyles.body.copyWith(
                  color: context.ksc.neutral500,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Divider(color: context.ksc.primary700, height: 1),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/logo/keystone_logo.svg',
              colorFilter: ColorFilter.mode(context.ksc.neutral300, BlendMode.srcIn),
              width: 12,
              height: 12,
            ),
            const SizedBox(width: 6),
            Text(
              'Made with Keystone',
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral300,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        color: context.ksc.white,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }

  Widget _centeredMessage({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: iconColor),
              const SizedBox(height: 20),
              Text(title,
                  style: AppTextStyles.h2.copyWith(
                      color: context.ksc.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
            ],
          ),
        ),
      ),
    );
  }
}
