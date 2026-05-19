import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/profile_provider.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "MY PROFILE",
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(LineAwesomeIcons.edit, color: context.ksc.accent500, size: 22),
            onPressed: () => context.push(RouteNames.editProfile),
          ),
        ],
      ),
      body: profileState.isLoading
          ? Center(child: CircularProgressIndicator(color: context.ksc.accent500))
          : profileState.errorMessage != null && profile == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 64, color: context.ksc.error500),
                        const SizedBox(height: 24),
                        Text("FAILED TO LOAD", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Text("Could not load profile.", textAlign: TextAlign.center, style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400)),
                        const SizedBox(height: 24),
                        KsButton(
                          label: "TAP TO RETRY",
                          variant: KsButtonVariant.primary,
                          size: KsButtonSize.small,
                          fullWidth: false,
                          onPressed: () => ref.read(profileProvider.notifier).load(),
                        ),
                      ],
                    ),
                  ),
                )
              : profile == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LineAwesomeIcons.user_circle_solid, size: 64, color: context.ksc.neutral500),
                            const SizedBox(height: 24),
                            Text("NO PROFILE YET", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 12),
                            Text("Set up your profile to get started.", textAlign: TextAlign.center, style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400)),
                            const SizedBox(height: 24),
                            KsButton(
                              label: "SET UP PROFILE",
                              variant: KsButtonVariant.primary,
                              size: KsButtonSize.small,
                              fullWidth: false,
                              onPressed: () => context.push(RouteNames.editProfile),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileCard(context, profile, isAdmin),
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, "CONTACT"),
                      const SizedBox(height: 8),
                      _buildInfoRow(context, LineAwesomeIcons.phone_solid, profile.whatsappNumber.isNotEmpty ? profile.whatsappNumber : "No phone number added", isHighlighted: true),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, LineAwesomeIcons.calendar_alt_solid, "Joined ${DateFormat('MMMM yyyy').format(profile.createdAt)}"),
                      if (profile.bio != null && profile.bio!.isNotEmpty) const SizedBox(height: 20),
                      if (profile.bio != null && profile.bio!.isNotEmpty)
                        _buildSectionHeader(context, "ABOUT"),
                      if (profile.bio != null && profile.bio!.isNotEmpty) const SizedBox(height: 8),
                      if (profile.bio != null && profile.bio!.isNotEmpty)
                        _buildInfoRow(context, LineAwesomeIcons.info_circle_solid, profile.bio!, isDescriptive: true),
                      if (profile.bio != null && profile.bio!.isNotEmpty) const SizedBox(height: 12),
                      if (profile.services.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildServicesSection(context, profile.services),
                      ],
                      if (profile.profileUrl.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildShareSection(context, ref, profile),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(RouteNames.editProfile),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.ksc.accent500,
                            side: BorderSide(color: context.ksc.accent500.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          icon: Icon(LineAwesomeIcons.edit, size: 18),
                          label: Text("EDIT PROFILE", style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileCard(BuildContext context, ProfileEntity? profile, bool isAdmin) {
    return Container(
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
            alignment: Alignment.center,
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
                      errorBuilder: (context, error, stackTrace) => Text(profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : "?", style: TextStyle(color: context.ksc.accent500, fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                  )
                : Text(profile?.displayName.isNotEmpty == true ? profile!.displayName[0].toUpperCase() : "?", style: TextStyle(color: context.ksc.accent500, fontSize: 32, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile?.displayName.toUpperCase() ?? "SET UP YOUR PROFILE", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildBadge(context, "PILOT USER", context.ksc.accent500),
                    _buildBadge(
                      context,
                      isAdmin ? "ADMIN" : "TECHNICIAN",
                      isAdmin ? context.ksc.error500 : context.ksc.success500,
                    ),
                    if (profile?.isPublic == true)
                      _buildBadge(context, "PUBLIC PROFILE ON", context.ksc.success500),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
    );
  }

  Widget _buildServicesSection(BuildContext context, List<String> services) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LineAwesomeIcons.tools_solid, color: context.ksc.accent500, size: 16),
              const SizedBox(width: 8),
              Text("SERVICES", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services.map((s) => GestureDetector(
              onTap: () => context.push(RouteNames.pricing),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.ksc.primary900,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: context.ksc.primary700),
                ),
                child: Text(
                  s.replaceAll('_', ' ').toUpperCase(),
                  style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w700, fontSize: 10),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildShareSection(BuildContext context, WidgetRef ref, ProfileEntity profile) {
    final url = "${AppConstants.profileBaseUrl}/${profile.profileUrl}";
    return Container(
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
            child: Text(url, style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.share_square_solid, color: context.ksc.accent500, size: 20),
            onPressed: () => ref.read(profileProvider.notifier).shareProfile(),
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.eye_solid, color: context.ksc.neutral400, size: 20),
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, {bool isHighlighted = false, bool isDescriptive = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDescriptive ? 20 : 16),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isHighlighted ? context.ksc.accent500.withValues(alpha: 0.3) : context.ksc.primary700),
      ),
      child: Row(
        children: [
          if (isHighlighted)
            Container(width: 3, height: 24, color: context.ksc.accent500, margin: const EdgeInsets.only(right: 12)),
          if (!isHighlighted) Icon(icon, color: context.ksc.neutral400, size: 20),
          if (!isHighlighted) const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: context.ksc.white,
                fontStyle: isDescriptive ? FontStyle.italic : FontStyle.normal,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
