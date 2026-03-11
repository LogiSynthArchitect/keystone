import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KsLogo extends StatelessWidget {
  final double size;
  const KsLogo({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo/ks_logo_combined.svg',
      width: size,
      height: size,
    );
  }
}
