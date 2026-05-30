import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/utils/service_icon_map.dart';
import '../providers/profile_provider.dart';
import '../widgets/edit_profile_drawer.dart';
import '../../domain/entities/profile_entity.dart';
import '../../../service_types/presentation/providers/service_type_provider.dart';
import '../../../service_types/domain/entities/service_type_entity.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // 3D icon asset paths
  static const _crownIcon = 'assets/icons/3d/transparent/634b4b-crown.png';
  static const _phoneIcon = 'assets/icons/3d/transparent/1b19dc-call-only.png';
  static const _calendarIcon =
      'assets/icons/3d/transparent/0ef25b-calender.png';

  /// Format phone to +233 XX XXX XXXX
  static String _formatPhone(String raw) {
    try {
      final normalized = PhoneFormatter.normalize(raw);
      if (normalized.startsWith('+233') && normalized.length == 13) {
        final code = '+233';
        final p1 = normalized.substring(4, 6);
        final p2 = normalized.substring(6, 9);
        final p3 = normalized.substring(9);
        return '$code $p1 $p2 $p3';
      }
      return normalized;
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;

    // Resolve service type IDs to entities for the services section
    final svcAsync = ref.watch(serviceTypeProvider);
    final svcMap = <String, ServiceTypeEntity>{};
    if (svcAsync.valueOrNull != null) {
      for (final s in svcAsync.valueOrNull!) {
        svcMap[s.id] = s;
      }
    }

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "MY PROFILE",
        showBack: true,
      ),
      body: profileState.isLoading
          ? Center(
              child: CircularProgressIndicator(color: context.ksc.accent500))
          : profileState.errorMessage != null && profile == null
              ? _errorView(context, ref)
              : profile == null
                  ? _emptyView(context)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // ─── IDENTITY ───
                          _identitySection(context, profile, isAdmin),
                          const SizedBox(height: 28),

                          // ─── CONTACT ───
                          _sectionLabel(context, "Contact"),
                          const SizedBox(height: 12),
                          if (profile.whatsappNumber.isNotEmpty)
                            _infoRow(
                              context,
                              _phoneIcon,
                              _formatPhone(profile.whatsappNumber),
                              isHighlighted: true,
                            ),
                          _infoRow(
                            context,
                            _calendarIcon,
                            "Joined ${DateFormat('MMMM yyyy').format(profile.createdAt)}",
                            isLast: true,
                          ),
                          const SizedBox(height: 28),

                          // ─── ABOUT ───
                          if (profile.bio != null &&
                              profile.bio!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _sectionLabel(context, "About"),
                            const SizedBox(height: 12),
                            _bioSection(context, profile.bio!),
                            const SizedBox(height: 28),
                          ],

                          // ─── SERVICES ───
                          if (profile.services.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _sectionLabel(context, "Services"),
                            const SizedBox(height: 12),
                            ..._servicesList(context, profile.services, svcMap),
                            const SizedBox(height: 28),
                          ],

                          // ─── EDIT BUTTON ───
                          _editButton(context),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
    );
  }

  // ── IDENTITY SECTION ────────────────────────────────────────
  Widget _identitySection(
      BuildContext context, ProfileEntity profile, bool isAdmin) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar with gold ring, crown 3D fallback
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            shape: BoxShape.circle,
            border: Border.all(color: context.ksc.accent500, width: 2.5),
          ),
          child: profile.photoUrl != null && profile.photoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.network(
                    profile.photoUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _crownFallback(context),
                  ),
                )
              : _crownFallback(context),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName.toUpperCase(),
                style: AppTextStyles.h2.copyWith(
                  color: context.ksc.white,
                  fontSize: 22,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _badge(context, "★", "PILOT USER", context.ksc.accent500),
                  _badge(
                    context,
                    "⚙",
                    isAdmin ? "ADMIN" : "TECHNICIAN",
                    isAdmin ? context.ksc.error500 : context.ksc.success500,
                  ),
                  if (profile.isPublic)
                    _badge(context, "⚙", "PUBLIC", context.ksc.success500),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _crownFallback(BuildContext context) {
    return Image.asset(
      _crownIcon,
      width: 38,
      height: 38,
      color: context.ksc.accent500,
    );
  }

  // ── BADGE (pill shape, transparent bg, color text + border) ─
  Widget _badge(
      BuildContext context, String icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.50),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(
              color: color,
              fontSize: 12,
              height: 1.1,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION LABEL ────────────────────────────────────────
  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: context.ksc.accent500,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
          fontSize: 10,
        ),
      ),
    );
  }

  // ── INFO ROW (bottom-border, no card bg) ──────────────────
  Widget _infoRow(
    BuildContext context,
    String assetPath,
    String text, {
    bool isHighlighted = false,
    bool isLast = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: context.ksc.primary700.withValues(alpha: 0.5),
                ),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: isHighlighted
                    ? context.ksc.accent500
                    : context.ksc.white,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BIO SECTION (bottom-border, no card bg) ───────────────
  Widget _bioSection(BuildContext context, String bio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.ksc.primary700.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Text(
        bio,
        style: AppTextStyles.bodyMedium.copyWith(
          color: context.ksc.neutral400,
          fontStyle: FontStyle.italic,
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }

  // ── SERVICES LIST (bottom-border rows, resolved from provider) ─
  List<Widget> _servicesList(
    BuildContext context,
    List<String> serviceIds,
    Map<String, ServiceTypeEntity> svcMap,
  ) {
    final resolved = <Widget>[];
    for (final id in serviceIds) {
      final entity = svcMap[id];
      final name = entity?.name.toUpperCase() ?? id;
      final iconData = ServiceIconMap.resolve(entity?.iconName);
      resolved.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.ksc.primary700.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(iconData, color: context.ksc.accent500, size: 18),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.body.copyWith(
                    color: context.ksc.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return resolved;
  }

  // ── EDIT BUTTON (ghost, gold border, 6px radius) ──────────
  Widget _editButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => EditProfileDrawer.show(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.ksc.accent500,
          side: BorderSide(
              color: context.ksc.accent500.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(
          "EDIT PROFILE",
          style: AppTextStyles.label.copyWith(
            color: context.ksc.accent500,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // ── ERROR VIEW ─────────────────────────────────────────────
  Widget _errorView(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 64),
            const SizedBox(height: 24),
            Text(
              "FAILED TO LOAD",
              style: AppTextStyles.h2.copyWith(
                  color: context.ksc.white, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              "Could not load profile.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: context.ksc.neutral400),
            ),
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
    );
  }

  // ── EMPTY VIEW ─────────────────────────────────────────────
  Widget _emptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(_crownIcon,
                width: 72, height: 72, color: context.ksc.neutral500),
            const SizedBox(height: 24),
            Text(
              "NO PROFILE YET",
              style: AppTextStyles.h2.copyWith(
                  color: context.ksc.white, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              "Set up your profile to get started.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: context.ksc.neutral400),
            ),
            const SizedBox(height: 24),
            KsButton(
              label: "SET UP PROFILE",
              variant: KsButtonVariant.primary,
              size: KsButtonSize.small,
              fullWidth: false,
        onPressed: () => EditProfileDrawer.show(context),
            ),
          ],
        ),
      ),
    );
  }
}
