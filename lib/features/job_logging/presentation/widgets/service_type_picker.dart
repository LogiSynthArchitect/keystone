import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';

class ServiceTypePicker extends StatelessWidget {
  final ServiceType? selected;
  final ValueChanged<ServiceType> onSelected;
  const ServiceTypePicker({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final services = [
      (ServiceType.carLockProgramming,    "Car Key Programming",    Icons.car_repair),
      (ServiceType.doorLockInstallation,  "Door Lock Installation", Icons.door_front_door_outlined),
      (ServiceType.doorLockRepair,        "Door Lock Repair",       Icons.lock_outlined),
      (ServiceType.smartLockInstallation, "Smart Lock Installation",Icons.lock_outlined),
    ];
    return Column(
      children: services.map((item) {
        final type = item.$1;
        final label = item.$2;
        final icon = item.$3;
        final isSelected = selected == type;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => onSelected(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary050 : AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: isSelected ? AppColors.primary600 : AppColors.neutral200, width: isSelected ? 1.5 : 1.0),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: isSelected ? AppColors.primary700 : AppColors.neutral400),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: isSelected ? AppColors.primary700 : AppColors.neutral900))),
                  if (isSelected) const Icon(Icons.check_circle, size: 20, color: AppColors.primary700),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
