import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../providers/service_type_provider.dart';
import '../../domain/entities/service_type_entity.dart';

class ServiceTypesScreen extends ConsumerWidget {
  const ServiceTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceTypeProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: const KsAppBar(
        title: "SERVICE TYPES",
        showBack: true,
      ),
      body: state.when(
        loading: () => Center(child: CircularProgressIndicator(color: context.ksc.accent500)),
        error: (err, _) => Center(child: Text("ERROR LOADING SERVICE TYPES", style: AppTextStyles.caption.copyWith(color: context.ksc.error500))),
        data: (types) {
          if (types.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LineAwesomeIcons.tools_solid, size: 64, color: context.ksc.primary800),
                  const SizedBox(height: 16),
                  Text("NO SERVICE TYPES YET", style: AppTextStyles.h2.copyWith(color: context.ksc.neutral500)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showAddDialog(context, ref),
                    style: ElevatedButton.styleFrom(backgroundColor: context.ksc.accent500),
                    child: Text("ADD YOUR FIRST ONE", style: AppTextStyles.label.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
              return _ServiceTypeTile(type: type);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: context.ksc.accent500,
        foregroundColor: context.ksc.primary900,
        child: const Icon(LineAwesomeIcons.plus_solid),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary800,
        title: Text("ADD SERVICE TYPE", style: AppTextStyles.h2.copyWith(color: context.ksc.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: context.ksc.white),
          decoration: InputDecoration(
            hintText: "e.g. Safe Opening",
            hintStyle: TextStyle(color: context.ksc.neutral500),
            filled: true,
            fillColor: context.ksc.primary900,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: AppTextStyles.label.copyWith(color: context.ksc.neutral400))),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(serviceTypeProvider.notifier).createServiceType(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text("ADD", style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}

class _ServiceTypeTile extends ConsumerWidget {
  final ServiceTypeEntity type;
  const _ServiceTypeTile({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Row(
        children: [
          Icon(LineAwesomeIcons.tools_solid, color: context.ksc.accent500, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              type.name.toUpperCase(),
              style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.edit, color: context.ksc.neutral500, size: 20),
            onPressed: () => _showEditDialog(context, ref),
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.trash_solid, color: context.ksc.error500.withValues(alpha: 0.5), size: 20),
            onPressed: () => _showDeleteConfirm(context, ref),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: type.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary800,
        title: Text("EDIT SERVICE TYPE", style: AppTextStyles.h2.copyWith(color: context.ksc.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: context.ksc.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.ksc.primary900,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: AppTextStyles.label.copyWith(color: context.ksc.neutral400))),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(serviceTypeProvider.notifier).updateServiceType(type.copyWith(name: controller.text.trim()));
                Navigator.pop(ctx);
              }
            },
            child: Text("SAVE", style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary800,
        title: Text("DELETE SERVICE TYPE?", style: AppTextStyles.h2.copyWith(color: context.ksc.white)),
        content: Text("Are you sure you want to remove '${type.name}'?", style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: AppTextStyles.label.copyWith(color: context.ksc.neutral400))),
          TextButton(
            onPressed: () {
              ref.read(serviceTypeProvider.notifier).deleteServiceType(type.id);
              Navigator.pop(ctx);
            },
            child: Text("DELETE", style: AppTextStyles.label.copyWith(color: context.ksc.error500)),
          ),
        ],
      ),
    );
  }
}
