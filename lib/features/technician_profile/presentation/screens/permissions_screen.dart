import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_permissions.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/permissions_provider.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';

class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;

    // Hard guard — should never be reached from UI if not admin, but protect anyway.
    if (user?.isAdmin != true) {
      return Scaffold(
        backgroundColor: context.ksc.primary900,
        appBar: KsAppBar(title: 'PERMISSIONS', showBack: true),
        body: Center(
          child: Text('Access restricted.', style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
        ),
      );
    }

    final perms = ref.watch(permissionsProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(title: 'TECHNICIAN PERMISSIONS', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'These settings apply to technician accounts. Admin accounts always have full access.',
              style: AppTextStyles.body.copyWith(color: context.ksc.neutral400, height: 1.6),
            ),
            const SizedBox(height: 32),
            _buildToggle(
              context,
              ref,
              label: 'CAN EDIT FINAL PRICE',
              subtitle: 'Allow technicians to change the final price of their own jobs.',
              value: perms.canEditFinalPrice,
              onChanged: (v) => _save(ref, perms.copyWith(canEditFinalPrice: v)),
            ),
            _buildToggle(
              context,
              ref,
              label: 'CAN DELETE JOBS',
              subtitle: 'Allow technicians to soft-delete (archive) their own jobs.',
              value: perms.canDeleteJobs,
              onChanged: (v) => _save(ref, perms.copyWith(canDeleteJobs: v)),
            ),
            _buildToggle(
              context,
              ref,
              label: 'CAN VIEW KEY CODES',
              subtitle: 'Allow technicians to view key code data on customer profiles.',
              value: perms.canViewKeyCodes,
              onChanged: (v) => _save(ref, perms.copyWith(canViewKeyCodes: v)),
            ),
          ],
        ),
      ),
    );
  }

  void _save(WidgetRef ref, UserPermissions updated) {
    HiveService.settings.put('technician_permissions', updated.toJson());
    // Invalidate the provider so UI gates re-evaluate.
    ref.invalidate(permissionsProvider);
  }

  Widget _buildToggle(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
