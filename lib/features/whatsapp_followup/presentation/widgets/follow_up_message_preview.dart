import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class FollowUpMessagePreview extends StatelessWidget {
  final String message;
  const FollowUpMessagePreview({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF8C6), // WhatsApp bubble green
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0xFFB2DFAB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.chat, size: 16, color: Color(0xFF25D366)),
            const SizedBox(width: AppSpacing.xs),
            Text("Message preview", style: AppTextStyles.labelSmall.copyWith(color: const Color(0xFF075E54))),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppTextStyles.body.copyWith(color: AppColors.neutral900, height: 1.5)),
        ],
      ),
    );
  }
}
