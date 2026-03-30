import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/permissions_provider.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../customer_history/domain/entities/key_code_entry_entity.dart';
import '../providers/key_code_provider.dart';
import 'edit_key_code_screen.dart';

class KeyCodesScreen extends ConsumerWidget {
  final String customerId;
  const KeyCodesScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isAdmin = user?.isAdmin ?? false;

    if (!permissions.canViewKeyCodes && !isAdmin) {
      return Scaffold(
        backgroundColor: context.ksc.primary900,
        appBar: const KsAppBar(title: "KEY CODES", showBack: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Key code access is restricted by your account settings.",
              style: AppTextStyles.body.copyWith(color: context.ksc.neutral400),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final state = ref.watch(keyCodeProvider(customerId));

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: const KsAppBar(title: "KEY CODES", showBack: true),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.ksc.accent500.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: context.ksc.accent500),
                const SizedBox(width: 8),
                Expanded(child: Text("Key code data is encrypted and only visible to you.", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? Center(child: CircularProgressIndicator(color: context.ksc.accent500))
                : state.entries.isEmpty
                    ? _buildEmpty(context, ref)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.entries.length,
                        itemBuilder: (context, i) => _KeyCodeTile(
                          entry: state.entries[i],
                          customerId: customerId,
                          onDelete: () => _confirmDelete(context, ref, state.entries[i].id),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(context, null),
        backgroundColor: context.ksc.accent500,
        foregroundColor: context.ksc.primary900,
        child: const Icon(LineAwesomeIcons.plus_solid),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LineAwesomeIcons.key_solid, size: 64, color: context.ksc.primary700),
          const SizedBox(height: 16),
          Text("NO KEY CODES SAVED", style: AppTextStyles.h3.copyWith(color: context.ksc.neutral500, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text("No key codes saved for this customer yet.", style: AppTextStyles.body.copyWith(color: context.ksc.neutral600)),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context, KeyCodeEntryEntity? existing) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EditKeyCodeScreen(customerId: customerId, existing: existing),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.ksc.primary800,
        title: Text("DELETE KEY CODE?", style: AppTextStyles.h3.copyWith(color: ctx.ksc.white)),
        content: Text("This key code entry will be permanently removed.", style: AppTextStyles.body.copyWith(color: ctx.ksc.neutral400)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("CANCEL", style: AppTextStyles.label.copyWith(color: ctx.ksc.neutral400))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("DELETE", style: AppTextStyles.label.copyWith(color: ctx.ksc.error500))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(keyCodeProvider(customerId).notifier).delete(id);
      if (context.mounted) KsSnackbar.show(context, message: "Key code deleted", type: KsSnackbarType.success);
    }
  }
}

class _KeyCodeTile extends StatelessWidget {
  final KeyCodeEntryEntity entry;
  final String customerId;
  final VoidCallback onDelete;

  const _KeyCodeTile({required this.entry, required this.customerId, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: context.ksc.primary900, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
            child: Center(child: Icon(LineAwesomeIcons.key_solid, size: 20, color: context.ksc.accent500)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.keyCode.toUpperCase(), style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                if (entry.keyType != null)
                  Text(entry.keyType!.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w700, fontSize: 10)),
                if (entry.description != null) ...[
                  const SizedBox(height: 2),
                  Text(entry.description!, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 4),
                Text(DateFormatter.display(entry.createdAt).toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, fontSize: 9, letterSpacing: 0.5)),
              ],
            ),
          ),
          Consumer(
            builder: (context, ref, _) => IconButton(
              icon: Icon(LineAwesomeIcons.edit, color: context.ksc.neutral500, size: 20),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EditKeyCodeScreen(customerId: customerId, existing: entry),
              )),
            ),
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.trash_solid, color: context.ksc.error500.withValues(alpha: 0.5), size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
