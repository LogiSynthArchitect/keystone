import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class KsLogoAnimated extends StatelessWidget {
  final double size;
  final VoidCallback? onComplete;

  const KsLogoAnimated({super.key, this.size = 200, this.onComplete});

  @override
  Widget build(BuildContext context) {
    const navyFilter = ColorFilter.mode(AppColors.primary900, BlendMode.srcIn);
    const goldFilter = ColorFilter.mode(AppColors.accent500, BlendMode.srcIn);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left Arm Assembly
          // Visual: 1200ms | Pause: 2800ms | Total: 4000ms
          SvgPicture.asset(
            'assets/logo/left_arm.svg',
            width: size,
            height: size,
            colorFilter: navyFilter,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 800.ms)
              .slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic, duration: 1200.ms)
              .then(delay: 2800.ms),

          // Right Arm Assembly
          // Visual: 1200ms | Pause: 2800ms | Total: 4000ms
          SvgPicture.asset(
            'assets/logo/right_arm.svg',
            width: size,
            height: size,
            colorFilter: navyFilter,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 800.ms)
              .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic, duration: 1200.ms)
              .then(delay: 2800.ms),

          // The Keystone Block
          // Visual ends at 2500ms (1000ms delay + 1500ms slide) | Pause: 1500ms | Total: 4000ms
          SvgPicture.asset(
            'assets/logo/keystone_block.svg',
            width: size,
            height: size,
            colorFilter: goldFilter,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(delay: 1000.ms, duration: 300.ms)
              .slideY(begin: -0.5, end: 0, curve: Curves.bounceOut, duration: 1500.ms)
              .then(delay: 1500.ms),

          // The Keyhole
          // Visual ends at 3000ms (2200ms delay + 800ms fade) | Pause: 1000ms | Total: 4000ms
          SvgPicture.asset(
            'assets/logo/keyhole.svg',
            width: size,
            height: size,
            colorFilter: navyFilter,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(delay: 2200.ms, duration: 800.ms)
              .then(delay: 1000.ms),
        ],
      ),
    );
  }
}
