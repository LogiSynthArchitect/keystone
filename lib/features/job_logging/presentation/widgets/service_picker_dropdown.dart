import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/service_icon_map.dart';
import '../../../service_types/presentation/providers/service_type_provider.dart';

/// A compact dropdown-style service type selector.
///
/// Matches the Customer step's input field pattern:
/// icon + label + underline border + value/placeholder row.
/// Tap opens a bottom sheet with service types for selection.
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
    final hasSelection = selected != null && selected!.isNotEmpty;
    final iconName = hasSelection ? _iconNameFor(ref, selected!) : null;

    return InkWell(
      onTap: () => _openSheet(context, ref),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(
              iconName != null
                  ? ServiceIconMap.resolve(iconName)
                  : LineAwesomeIcons.wrench_solid,
              size: 20,
              color: hasSelection
                  ? context.ksc.accent500
                  : context.ksc.neutral500,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: hasSelection
                            ? Row(
                                children: [
                                  Text(
                                    selected!
                                        .replaceAll('_', ' ')
                                        .toUpperCase(),
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: context.ksc.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => onSelected(''),
                                    child: Icon(
                                      LineAwesomeIcons.times_solid,
                                      size: 14,
                                      color: context.ksc.neutral500,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'SELECT SERVICE TYPE',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: context.ksc.neutral600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LineAwesomeIcons.angle_down_solid,
                        size: 14,
                        color: hasSelection
                            ? context.ksc.accent500
                            : context.ksc.neutral600,
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  color: hasSelection
                      ? context.ksc.accent500
                      : const Color(0xFF2A3A4A),
                ),
              ],
            ),
          ),
        ],
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
                  // Search field — UnderlineInputBorder matching customer step
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (_) => setSheetState(() {}),
                      style: AppTextStyles.bodyLarge.copyWith(
                          color: context.ksc.white,
                          fontWeight: FontWeight.bold),
                      cursorColor: context.ksc.accent500,
                      decoration: InputDecoration(
                        hintText: "Search services...",
                        hintStyle: AppTextStyles.bodyLarge.copyWith(
                            color: context.ksc.neutral600,
                            fontWeight: FontWeight.bold),
                        prefixIcon: Icon(
                            LineAwesomeIcons.search_solid,
                            size: 18,
                            color: context.ksc.neutral600),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.only(bottom: 8),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFF2A3A4A), width: 1),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFF4A90D9), width: 1.5),
                        ),
                        border: const UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFF2A3A4A)),
                        ),
                        filled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Service list — transparent + border only
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
                                    const EdgeInsets.only(bottom: 8),
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
                                      color: Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSelected
                                            ? context.ksc.accent500
                                            : context.ksc.primary700,
                                        width:
                                            isSelected ? 1.5 : 1.0,
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
