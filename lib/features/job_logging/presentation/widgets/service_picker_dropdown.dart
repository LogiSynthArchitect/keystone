import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/service_icon_map.dart';
import '../../../service_types/presentation/providers/service_type_provider.dart';

/// A compact dropdown-style service type selector.
///
/// Shows a field with underline border, icon, and either a placeholder
/// ("SELECT SERVICE TYPE") or a gold chip with the selected name.
/// Tap opens a bottom sheet with all service types for selection.
class ServicePickerDropdown extends ConsumerWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const ServicePickerDropdown({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconName = selected != null && selected!.isNotEmpty
        ? _iconNameFor(ref, selected!)
        : null;
    final hasSelection = selected != null && selected!.isNotEmpty;

    return InkWell(
      onTap: () => _openSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: hasSelection
                  ? context.ksc.accent500
                  : context.ksc.primary700,
              width: hasSelection ? 1.5 : 1.0,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              iconName != null
                  ? ServiceIconMap.resolve(iconName)
                  : LineAwesomeIcons.wrench_solid,
              size: 20,
              color: hasSelection
                  ? context.ksc.accent500
                  : context.ksc.neutral500,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: hasSelection
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            context.ksc.accent500.withValues(alpha: 0.1),
                        border: Border.all(color: context.ksc.accent500),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              selected!.replaceAll('_', ' ').toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                color: context.ksc.accent500,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => onSelected(''),
                            child: Icon(
                              LineAwesomeIcons.times_solid,
                              size: 12,
                              color: context.ksc.accent500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      'SELECT SERVICE TYPE',
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.neutral500,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Icon(
              LineAwesomeIcons.angle_down_solid,
              size: 14,
              color: hasSelection
                  ? context.ksc.accent500
                  : context.ksc.neutral500,
            ),
          ],
        ),
      ),
    );
  }

  String? _iconNameFor(WidgetRef ref, String name) {
    final types = ref.read(serviceTypeProvider).valueOrNull ?? [];
    return types.where((t) => t.name == name).firstOrNull?.iconName;
  }

  void _openSheet(BuildContext context, WidgetRef ref) {
    final types = ref.read(serviceTypeProvider).valueOrNull ?? [];
    if (types.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        final searchCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchCtrl.text.toLowerCase().trim();
            final filtered = query.isEmpty
                ? types
                : types
                    .where((t) =>
                        t.name.toLowerCase().contains(query) ||
                        (t.category?.toLowerCase().contains(query) ??
                            false))
                    .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.ksc.neutral600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text("SELECT SERVICE",
                              style: AppTextStyles.h2.copyWith(
                                  color: context.ksc.white,
                                  fontWeight: FontWeight.w900)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(LineAwesomeIcons.times_solid,
                              color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.ksc.primary900,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: context.ksc.primary700),
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (_) => setSheetState(() {}),
                        style: AppTextStyles.body.copyWith(
                            color: context.ksc.white,
                            fontWeight: FontWeight.w600),
                        cursorColor: context.ksc.accent500,
                        decoration: InputDecoration(
                          hintText: "Search services...",
                          hintStyle: AppTextStyles.caption.copyWith(
                              color: context.ksc.neutral600),
                          prefixIcon: Icon(
                              LineAwesomeIcons.search_solid,
                              size: 16,
                              color: context.ksc.neutral600),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Service list
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(ctx).size.height * 0.45,
                    ),
                    child: filtered.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                                child: Text("No services found")),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final type = filtered[i];
                              final isSelected =
                                  selected == type.name;
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 4),
                                child: InkWell(
                                  onTap: () {
                                    onSelected(type.name);
                                    Navigator.pop(ctx);
                                  },
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? context.ksc.accent500
                                              .withValues(alpha: 0.1)
                                          : context.ksc.primary900,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSelected
                                            ? context.ksc.accent500
                                            : context.ksc.primary700,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          ServiceIconMap.resolve(
                                              type.iconName),
                                          size: 20,
                                          color: isSelected
                                              ? context.ksc.accent500
                                              : context.ksc
                                                  .neutral500,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            type.name.toUpperCase(),
                                            style: AppTextStyles
                                                .bodyMedium
                                                .copyWith(
                                              color: isSelected
                                                  ? context.ksc.white
                                                  : context.ksc
                                                      .neutral400,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.w900
                                                      : FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                              LineAwesomeIcons
                                                  .check_circle_solid,
                                              size: 18,
                                              color: context
                                                  .ksc.accent500),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
