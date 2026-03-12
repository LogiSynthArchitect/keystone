import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class KsLogo extends StatelessWidget {
  final double size;
  const KsLogo({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    const navyFilter = ColorFilter.mode(AppColors.primary900, BlendMode.srcIn);
    const goldFilter = ColorFilter.mode(AppColors.accent500, BlendMode.srcIn);

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
              colorFilter: navyFilter,
            ),
            // Right Arm (Navy)
            SvgPicture.asset(
              'assets/logo/right_arm.svg', 
              width: size, 
              height: size,
              fit: BoxFit.contain,
              colorFilter: navyFilter,
            ),
            // Keystone Block (Gold)
            SvgPicture.asset(
              'assets/logo/keystone_block.svg', 
              width: size, 
              height: size,
              fit: BoxFit.contain,
              colorFilter: goldFilter,
            ),
            // Keyhole (Navy)
            SvgPicture.asset(
              'assets/logo/keyhole.svg', 
              width: size, 
              height: size,
              fit: BoxFit.contain,
              colorFilter: navyFilter,
            ),
          ],
        ),
      ),
    );
  }
}
