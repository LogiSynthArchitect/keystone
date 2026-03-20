import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/constants/app_enums.dart';
import 'onboarding_step_indicator.dart';

class ServicesStepView extends StatelessWidget {
  final List<ServiceType> selectedServices;
  final Function(ServiceType) onToggle;

  const ServicesStepView({
    super.key,
    required this.selectedServices,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceData(ServiceType.carLockProgramming, 'Car Key\nProgramming', 'assets/services/car_key.png'),
      _ServiceData(ServiceType.doorLockInstallation, 'Door Lock\nInstallation', 'assets/services/door_install.png'),
      _ServiceData(ServiceType.doorLockRepair, 'Door Lock\nRepair', 'assets/services/door_repair.png'),
      _ServiceData(ServiceType.smartLockInstallation, 'Smart Lock\nInstallation', 'assets/services/smart_lock.png'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.ksc.primary700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(LineAwesomeIcons.tools_solid, color: Color(0xFFF9A825), size: 26),
        ),
        const SizedBox(height: 16),
        Text(
          'What services\ndo you offer?',
          style: TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: context.ksc.primary700,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Select all that apply.',
          style: TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.ksc.neutral600,
          ),
        ),
        const SizedBox(height: 24),
        const OnboardingStepIndicator(activeStep: 1),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: services.map((s) => _ServiceItem(
            data: s,
            isSelected: selectedServices.contains(s.type),
            onTap: () => onToggle(s.type),
          )).toList(),
        ),
      ],
    );
  }
}

class _ServiceData {
  final ServiceType type;
  final String label;
  final String image;
  _ServiceData(this.type, this.label, this.image);
}

class _ServiceItem extends StatelessWidget {
  final _ServiceData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceItem({required this.data, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFF9A825) : const Color(0xFFEAEAEC),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(data.image, fit: BoxFit.cover),
              Container(color: Colors.black.withValues(alpha: 0.3)),
              Positioned(
                bottom: 12,
                left: 12,
                child: Text(
                  data.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (isSelected)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Color(0xFFF9A825),
                    radius: 12,
                    child: Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
