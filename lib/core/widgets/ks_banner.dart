import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum KsBannerType { alert, success, info }

class KsBanner extends StatelessWidget {
  final String message;
  final KsBannerType type;
  final bool shouldShake;

  const KsBanner({
    super.key,
    required this.message,
    this.type = KsBannerType.alert,
    this.shouldShake = true,
  });

  @override
  Widget build(BuildContext context) {
    // Industrial Color Mapping
    final Color bgColor = type == KsBannerType.alert 
        ? const Color(0xFF4A1010) // Deep Warning Red
        : AppColors.primary700;
        
    final Color borderColor = type == KsBannerType.alert 
        ? const Color(0xFFE53935) // High-Intensity Safety Red
        : AppColors.accent500;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            type == KsBannerType.alert 
                ? LineAwesomeIcons.exclamation_triangle_solid 
                : LineAwesomeIcons.info_circle_solid,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  type == KsBannerType.alert ? 'SYSTEM ALERT' : 'NOTIFICATION',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.toUpperCase(),
                  style: AppTextStyles.captionMedium.copyWith(
                    color: const Color(0xFFFFCDD2),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate()
     .fadeIn(duration: 200.ms)
     .then(delay: 50.ms)
     .shake(hz: 4, curve: Curves.easeInOutCubic, duration: 400.ms);
  }
}
