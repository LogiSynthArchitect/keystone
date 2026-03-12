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
    const navyFilter = ColorFilter.mode(AppColors.primary700, BlendMode.srcIn);
    const goldFilter = ColorFilter.mode(AppColors.accent500, BlendMode.srcIn);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 01. THE ARMS
          _buildPart('assets/logo/left_arm.svg', navyFilter)
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.3, end: 0, curve: Curves.easeOutQuart, duration: 800.ms)
              .fadeOut(delay: 3500.ms, duration: 500.ms), // All parts vanish at exactly 3.5s

          _buildPart('assets/logo/right_arm.svg', navyFilter)
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.3, end: 0, curve: Curves.easeOutQuart, duration: 800.ms)
              .fadeOut(delay: 3500.ms, duration: 500.ms),

          // 02. THE KEYSTONE
          _buildPart('assets/logo/keystone_block.svg', goldFilter)
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(delay: 800.ms, duration: 200.ms)
              .slideY(begin: -0.4, end: 0, curve: Curves.bounceOut, duration: 1000.ms, delay: 800.ms)
              .fadeOut(delay: 3500.ms, duration: 500.ms),

          // 03. THE KEYHOLE
          _buildPart('assets/logo/keyhole.svg', navyFilter)
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(delay: 1800.ms, duration: 300.ms)
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: Curves.elasticOut, duration: 600.ms, delay: 1800.ms)
              .fadeOut(delay: 3500.ms, duration: 500.ms),
        ],
      ),
    );
  }

  Widget _buildPart(String asset, ColorFilter filter) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: filter,
    );
  }
}
