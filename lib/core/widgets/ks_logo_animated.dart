import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class KsLogoAnimated extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? accentColor;

  const KsLogoAnimated({
    super.key, 
    this.size = 200, 
    this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color pColor = primaryColor ?? AppColors.primary700;
    final Color aColor = accentColor ?? AppColors.accent500;

    final navyFilter = ColorFilter.mode(pColor, BlendMode.srcIn);
    final goldFilter = ColorFilter.mode(aColor, BlendMode.srcIn);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 01. THE ARMS - Mechanical Slide-in (Once)
          _buildPart('assets/logo/left_arm.svg', navyFilter)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.5, end: 0, curve: Curves.easeOutBack, duration: 700.ms),

          _buildPart('assets/logo/right_arm.svg', navyFilter)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.5, end: 0, curve: Curves.easeOutBack, duration: 700.ms),

          // 02. THE GOLD KEYSTONE - Drop, Snap, then Infinite Breathing Pulse
          Animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [
              // Initial Entry (Synced timings)
              FadeEffect(delay: 600.ms, duration: 200.ms),
              MoveEffect(
                begin: const Offset(0, -100), 
                end: Offset.zero, 
                curve: Curves.bounceOut, 
                duration: 800.ms, 
                delay: 600.ms
              ),
              // The "Impact" pop
              ScaleEffect(
                begin: const Offset(1, 1), 
                end: const Offset(1.08, 1.08), 
                delay: 1400.ms, 
                duration: 150.ms, 
                curve: Curves.easeOut
              ),
              // The infinite breathing pulse (Reverse: true handles the scale back)
              ScaleEffect(
                begin: const Offset(1, 1), 
                end: const Offset(1.04, 1.04), 
                delay: 2000.ms, 
                duration: 1500.ms, 
                curve: Curves.easeInOutSine
              ),
            ],
            child: _buildPart('assets/logo/keystone_block.svg', goldFilter),
          ),

          // 03. THE KEYHOLE - Final Detail (Once)
          _buildPart('assets/logo/keyhole.svg', navyFilter)
              .animate()
              .fadeIn(delay: 1600.ms, duration: 400.ms)
              .scale(
                begin: const Offset(0.3, 0.3), 
                end: const Offset(1, 1), 
                curve: Curves.elasticOut, 
                duration: 800.ms, 
                delay: 1600.ms
              ),
        ],
      ),
    );
  }

  Widget _buildPart(String asset, ColorFilter filter) {
    return SvgPicture.asset(asset, width: size, height: size, colorFilter: filter);
  }
}
