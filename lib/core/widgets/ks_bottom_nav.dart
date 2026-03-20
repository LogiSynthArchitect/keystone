import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

class KsBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabTapped;

  const KsBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.ksc.primary900,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _buildNavItem(context, 0, 'JOBS', LineAwesomeIcons.briefcase_solid),
              _buildNavItem(context, 1, 'CUSTOMERS', LineAwesomeIcons.users_solid),
              _buildNavItem(context, 2, 'NOTES', LineAwesomeIcons.lightbulb_solid),
              _buildNavItem(context, 3, 'PROFILE', LineAwesomeIcons.user_circle_solid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String label, IconData icon) {
    final isActive = currentIndex == index;
    final color = isActive ? context.ksc.accent500 : Colors.white.withValues(alpha: 0.3);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isActive ? context.ksc.accent500 : Colors.transparent,
                width: 2,
              ),
            ),
            color: isActive ? context.ksc.primary800.withValues(alpha: 0.3) : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
