import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';

class ServiceTypePicker extends StatelessWidget {
  final ServiceType? selected;
  final ValueChanged<ServiceType> onSelected;
  const ServiceTypePicker({super.key, required this.selected, required this.onSelected});

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
            onTap: () => onSelected(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent500.withValues(alpha: 0.1) : AppColors.primary800,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppColors.accent500 : Colors.white.withValues(alpha: 0.1), 
                  width: isSelected ? 2.0 : 1.0
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: isSelected ? AppColors.accent500 : AppColors.neutral500),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label, 
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected ? AppColors.white : AppColors.neutral400,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        letterSpacing: 0.5,
                      )
                    )
                  ),
                  if (isSelected) const Icon(LineAwesomeIcons.check_circle_solid, size: 20, color: AppColors.accent500),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
