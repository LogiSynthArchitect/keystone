import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class KsLogo extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? accentColor;

  const KsLogo({
    super.key, 
    this.size = 200,
    this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    // Defaulting to Theme if not provided
    final Color pColor = primaryColor ?? AppColors.primary900;
    final Color aColor = accentColor ?? AppColors.accent500;

    final navyFilter = ColorFilter.mode(pColor, BlendMode.srcIn);
    final goldFilter = ColorFilter.mode(aColor, BlendMode.srcIn);

    return SizedBox(
      width: size,
      height: size,
      child: Transform.scale(
        scale: 1.15, 
        child: Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset('assets/logo/left_arm.svg', width: size, height: size, colorFilter: navyFilter),
            SvgPicture.asset('assets/logo/right_arm.svg', width: size, height: size, colorFilter: navyFilter),
            SvgPicture.asset('assets/logo/keystone_block.svg', width: size, height: size, colorFilter: goldFilter),
            SvgPicture.asset('assets/logo/keyhole.svg', width: size, height: size, colorFilter: navyFilter),
          ],
        ),
      ),
    );
  }
}
