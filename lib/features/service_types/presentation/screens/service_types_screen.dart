import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/constants/service_categories.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/service_icon_map.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_content_drawer.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_filter_sheet.dart';
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
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 48, color: context.ksc.error500),
              const SizedBox(height: 16),
              Text("FAILED TO LOAD", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text("Could not load service types.", style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400)),
              const SizedBox(height: 24),
              KsButton(
                label: "TAP TO RETRY",
                variant: KsButtonVariant.primary,
                size: KsButtonSize.small,
                fullWidth: false,
                onPressed: () => ref.invalidate(serviceTypeProvider),
              ),
            ],
          ),
        ),
        data: (types) {
          if (types.isEmpty) {
            return KsEmptyState(
              icon: LineAwesomeIcons.tools_solid,
              title: "NO SERVICE TYPES YET",
              subtitle: "Add service types you offer.\nTap + below to get started.",
              actionLabel: "ADD YOUR FIRST ONE",
              onAction: () => _showAddSheet(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
              return _ServiceTypeTile(
                type: type,
                onTap: () => _showEditSheet(context, ref, type),
                onLongPress: () => _confirmDelete(context, ref, type),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref),
        backgroundColor: context.ksc.accent500,
        foregroundColor: context.ksc.primary900,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: const Icon(LineAwesomeIcons.plus_solid, size: 28),
      ),
    );
  }

  static void _showAddSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    var selectedCategory = ServiceCategory.all.first;
    var selectedIcon = selectedCategory.defaultIconName;

    KsContentDrawer.show<void>(
      context,
      icon: LineAwesomeIcons.tools_solid,
      title: "ADD SERVICE TYPE",
      child: StatefulBuilder(
        builder: (_, setInnerState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Name ──
              Text("NAME", style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: TextStyle(color: context.ksc.white),
                decoration: const InputDecoration(
                  hintText: "e.g. Custom Gate Opener",
                  hintStyle: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
              const SizedBox(height: 24),
              KsFilterChipGroup(
                label: "CATEGORY",
                selected: selectedCategory.key,
                options: ServiceCategory.all.map((c) => KsFilterOption(
                  value: c.key,
                  display: '${c.emoji}  ${c.display}',
                )).toList(),
                onSelect: (v) {
                  if (v != null) {
                    final cat = ServiceCategory.fromKey(v);
                    if (cat != null) {
                      setInnerState(() {
                        selectedCategory = cat;
                        selectedIcon = cat.defaultIconName;
                      });
                    }
                  }
                },
                borderRadius: 4,
              ),
              const SizedBox(height: 24),
              // ── Icon ──
              Text("ICON", style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              _IconPicker(
                selectedIcon: selectedIcon,
                onSelected: (v) => setInnerState(() => selectedIcon = v),
              ),
            ],
          ),
        ),
      ),
      bottomLabel: "ADD",
      bottomOnPressed: () {
        if (nameCtrl.text.trim().isNotEmpty) {
          ref.read(serviceTypeProvider.notifier).createServiceType(
            nameCtrl.text.trim(),
            selectedCategory.key,
            selectedIcon,
          );
          Navigator.pop(context);
        }
      },
    );
  }

  static void _showEditSheet(BuildContext context, WidgetRef ref, ServiceTypeEntity type) {
    final nameCtrl = TextEditingController(text: type.name);
    final initialCat = ServiceCategory.fromKey(type.category) ?? ServiceCategory.all.first;
    var selectedCategory = initialCat;
    var selectedIcon = type.iconName;

    KsContentDrawer.show<void>(
      context,
      icon: ServiceIconMap.resolve(type.iconName),
      title: "EDIT SERVICE TYPE",
      child: StatefulBuilder(
        builder: (_, setInnerState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Name ──
              Text("NAME", style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: TextStyle(color: context.ksc.white),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF0A1628),
                ),
              ),
              const SizedBox(height: 24),
              KsFilterChipGroup(
                label: "CATEGORY",
                selected: selectedCategory.key,
                options: ServiceCategory.all.map((c) => KsFilterOption(
                  value: c.key,
                  display: '${c.emoji}  ${c.display}',
                )).toList(),
                onSelect: (v) {
                  if (v != null) {
                    final cat = ServiceCategory.fromKey(v);
                    if (cat != null) {
                      setInnerState(() {
                        selectedCategory = cat;
                        selectedIcon = cat.defaultIconName;
                      });
                    }
                  }
                },
                borderRadius: 4,
              ),
              const SizedBox(height: 24),
              // ── Icon ──
              Text("ICON", style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              _IconPicker(
                selectedIcon: selectedIcon,
                onSelected: (v) => setInnerState(() => selectedIcon = v),
              ),
            ],
          ),
        ),
      ),
      bottomLabel: "SAVE",
      bottomOnPressed: () {
        if (nameCtrl.text.trim().isNotEmpty) {
          ref.read(serviceTypeProvider.notifier).updateServiceType(type.copyWith(
            name: nameCtrl.text.trim(),
            category: selectedCategory.key,
            iconName: selectedIcon,
          ));
          Navigator.pop(context);
        }
      },
    );
  }

  static void _confirmDelete(BuildContext context, WidgetRef ref, ServiceTypeEntity type) {
    KsConfirmDialog.show(
      context,
      title: "DELETE SERVICE TYPE",
      message: "Are you sure you want to remove '${type.name}'?",
      confirmLabel: "DELETE",
      cancelLabel: "CANCEL",
      isDanger: true,
      onConfirm: () {
        ref.read(serviceTypeProvider.notifier).deleteServiceType(type.id);
      },
    );
  }
}

// ── Icon Picker Widget ──
class _IconPicker extends StatelessWidget {
  final String selectedIcon;
  final ValueChanged<String> onSelected;

  const _IconPicker({required this.selectedIcon, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ServiceIconMap.allIcons.map((iconName) {
        final isSelected = iconName == selectedIcon;
        return GestureDetector(
          onTap: () => onSelected(iconName),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? context.ksc.accent500.withValues(alpha: 0.15) : context.ksc.primary800,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? context.ksc.accent500 : context.ksc.primary700,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              ServiceIconMap.resolve(iconName),
              color: isSelected ? context.ksc.accent500 : context.ksc.neutral400,
              size: 20,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Tile ──
class _ServiceTypeTile extends ConsumerWidget {
  final ServiceTypeEntity type;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ServiceTypeTile({
    required this.type,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ServiceCategory.fromKey(type.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.ksc.primary900,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.ksc.primary700),
                  ),
                  child: Icon(
                    ServiceIconMap.resolve(type.iconName),
                    color: context.ksc.accent500,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.name.toUpperCase(),
                        style: AppTextStyles.body.copyWith(
                          color: context.ksc.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            cat?.emoji ?? '',
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (cat?.display ?? type.category).toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: context.ksc.neutral500,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(LineAwesomeIcons.chevron_right_solid, color: context.ksc.neutral500, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
