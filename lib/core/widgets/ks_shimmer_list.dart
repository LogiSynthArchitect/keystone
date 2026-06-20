import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/ks_colors.dart';

class KsShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double separatorHeight;
  final bool shimmerEnabled;

  const KsShimmerList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 100,
    this.separatorHeight = 12,
    this.shimmerEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(24.0),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: separatorHeight),
      itemBuilder: (_, __) {
        final tile = Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.ksc.primary700),
          ),
        );
        if (!shimmerEnabled) return tile;
        return tile.animate(onPlay: (c) => c.repeat()).shimmer(
              duration: 1200.ms,
              color: context.ksc.primary700.withValues(alpha: 0.5),
            );
      },
    );
  }
}
