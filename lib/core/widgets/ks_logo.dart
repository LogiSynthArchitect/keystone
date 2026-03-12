import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class KsLogo extends StatelessWidget {
  final double size;
  const KsLogo({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Transform.scale(
        scale: 1.15, // Fixes the inherent small viewport scaling
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Left Arm (Navy)
            SvgPicture.asset(
              'assets/logo/left_arm.svg', 
              width: size, 
              height: size,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(AppColors.primary700, BlendMode.srcIn),
            ),
            // Right Arm (Navy)
            SvgPicture.asset(
              'assets/logo/right_arm.svg', 
              width: size, 
              height: size,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(AppColors.primary700, BlendMode.srcIn),
            ),
            // Keystone Block (Gold)
            SvgPicture.asset(
              'assets/logo/keystone_block.svg', 
              width: size, 
              height: size,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(Color(0xFFF9A825), BlendMode.srcIn),
            ),
            // Keyhole (Navy)
            SvgPicture.asset(
              'assets/logo/keyhole.svg', 
              width: size, 
              height: size,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(AppColors.primary700, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }
}
