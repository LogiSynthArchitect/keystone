import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

class KsLogoAnimated extends StatelessWidget {
  final double size;
  final VoidCallback? onComplete;

  const KsLogoAnimated({super.key, this.size = 200, this.onComplete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left Arm Assembly
          SvgPicture.asset('assets/logo/left_arm.svg', width: size, height: size)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic, duration: 600.ms),

          // Right Arm Assembly
          SvgPicture.asset('assets/logo/right_arm.svg', width: size, height: size)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic, duration: 600.ms),

          // The Keystone Block (The Impact)
          SvgPicture.asset('assets/logo/keystone_block.svg', width: size, height: size)
              .animate(delay: 600.ms)
              .fadeIn(duration: 100.ms)
              .slideY(begin: -0.5, end: 0, curve: Curves.bounceOut, duration: 800.ms),

          // The Keyhole (The Access)
          SvgPicture.asset('assets/logo/keyhole.svg', width: size, height: size)
              .animate(delay: 1200.ms)
              .fadeIn(duration: 400.ms),
        ],
      ).animate(onComplete: (_) => onComplete?.call()).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 200.ms,
            delay: 1400.ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}
