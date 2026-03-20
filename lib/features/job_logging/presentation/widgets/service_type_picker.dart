import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/constants/app_enums.dart';

class ServiceTypePicker extends StatelessWidget {
  final ServiceType? selected;
  final ValueChanged<ServiceType> onSelected;
  final bool enabled;

  const ServiceTypePicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final services = [
      (ServiceType.carLockProgramming,    "Car Key Programming",    LineAwesomeIcons.car_solid),
      (ServiceType.doorLockInstallation,  "Door Lock Installation", LineAwesomeIcons.door_closed_solid),
      (ServiceType.doorLockRepair,        "Door Lock Repair",       LineAwesomeIcons.tools_solid),
      (ServiceType.smartLockInstallation, "Smart Lock Installation",LineAwesomeIcons.lock_solid),
    ];

    return Column(
      children: services.map((item) {
        final type = item.$1;
        final label = item.$2;
        final icon = item.$3;
        final isSelected = selected == type;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GestureDetector(
            onTap: enabled ? () => onSelected(type) : null,
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
                    Icon(icon, size: 20, color: isSelected ? context.ksc.accent500 : context.ksc.neutral500),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
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
  }
}
