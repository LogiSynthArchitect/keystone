import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class FollowUpButton extends StatelessWidget {
  final bool isSent;
  final bool isLoading;
  final VoidCallback? onTap;

  const FollowUpButton({super.key, required this.isSent, required this.isLoading, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isSent) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.success100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.success500),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.success600),
          const SizedBox(width: AppSpacing.sm),
          Text("Follow-up sent", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success600)),
        ]),
      );
    }

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: const [BoxShadow(color: Color(0x3325D366), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isLoading)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          else
            const Icon(Icons.chat, size: 20, color: Colors.white),
          const SizedBox(width: AppSpacing.sm),
          Text(isLoading ? "Opening WhatsApp..." : "Send follow-up via WhatsApp",
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
        ]),
      ),
    );
  }
}
