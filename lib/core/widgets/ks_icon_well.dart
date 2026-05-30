import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';

/// A 34×34 rounded-square icon container for KsAppBar actions.
///
/// Provides consistent sizing, color states, and optional badge count.
/// - Rest: [iconColor] on transparent well
/// - Active: [iconColor] → [KsColors.accent500] when [isActive] is true
/// - Press: [backgroundColor] → [KsColors.neutral800] (applied by caller if needed)
class KsIconWell extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final bool isActive;
  final int? badgeCount;
  final Color? backgroundColor;
  final double size;
  final VoidCallback? onTap;

  const KsIconWell({
    super.key,
    required this.icon,
    this.iconSize = 20,
    this.iconColor,
    this.isActive = false,
    this.badgeCount,
    this.backgroundColor,
    this.size = 34,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.ksc;
    final resolvedColor = isActive
        ? theme.accent500
        : iconColor ?? theme.neutral500;

    final well = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(icon, color: resolvedColor, size: iconSize),
            ),
          ),
          if (badgeCount != null && badgeCount! > 0)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFFC62828),
                  shape: BoxShape.circle,
                ),
                child: Center(
                    child: Text(
                      badgeCount! > 9 ? '9+' : '$badgeCount',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return well;
    return GestureDetector(onTap: onTap, child: well);
  }
}
