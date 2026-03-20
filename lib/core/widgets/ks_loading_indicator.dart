import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';

class KsLoadingIndicator extends StatelessWidget {
  final bool fullScreen;

  const KsLoadingIndicator({super.key, this.fullScreen = false});

  @override
  Widget build(BuildContext context) {
    if (fullScreen) {
      return Scaffold(
        backgroundColor: context.ksc.neutral050,
        body: Center(child: CircularProgressIndicator(
          color: context.ksc.primary700,
          strokeWidth: 2.5,
        )),
      );
    }
    return Center(child: CircularProgressIndicator(
      color: context.ksc.primary700,
      strokeWidth: 2.5,
    ));
  }
}
