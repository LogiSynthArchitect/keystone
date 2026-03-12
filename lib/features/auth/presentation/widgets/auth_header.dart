import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFF9A825), size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: AppColors.primary700,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral600,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
