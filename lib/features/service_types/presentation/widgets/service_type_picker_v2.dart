import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../providers/service_type_provider.dart';

class ServiceTypePickerV2 extends ConsumerWidget {
  final String? selected;
  final ValueChanged<String> onSelected;
  final bool enabled;

  const ServiceTypePickerV2({
    super.key,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceTypeProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text("ERROR LOADING SERVICES", style: AppTextStyles.caption.copyWith(color: context.ksc.error500))),
      data: (types) {
        if (types.isEmpty) {
          return Center(child: Text("NO SERVICE TYPES CONFIGURED", style: AppTextStyles.body.copyWith(color: context.ksc.neutral500)));
        }

        return Column(
          children: types.map((type) {
            final isSelected = selected == type.name;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GestureDetector(
                onTap: enabled ? () => onSelected(type.name) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.ksc.accent500.withValues(alpha: 0.1)
                        : enabled ? context.ksc.primary800 : context.ksc.primary900.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? context.ksc.accent500
                          : context.ksc.primary700,
                      width: isSelected ? 2.0 : 1.0
                    ),
                  ),
                  child: Opacity(
                    opacity: enabled ? 1.0 : 0.4,
                    child: Row(
                      children: [
                        Icon(LineAwesomeIcons.tools_solid, size: 20, color: isSelected ? context.ksc.accent500 : context.ksc.neutral500),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            type.name.toUpperCase(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected ? context.ksc.white : context.ksc.neutral400,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              letterSpacing: 0.5,
                            )
                          )
                        ),
                        if (isSelected) Icon(LineAwesomeIcons.check_circle_solid, size: 20, color: context.ksc.accent500),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
