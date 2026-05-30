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
    final tabs = [
      ('DASHBOARD', LineAwesomeIcons.chart_bar_solid),
      ('JOBS', LineAwesomeIcons.briefcase_solid),
      ('CUSTOMERS', LineAwesomeIcons.users_solid),
      ('HUB', LineAwesomeIcons.th_large_solid),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.ksc.primary900,
        border: Border(top: BorderSide(color: context.ksc.primary700, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    label: tabs[i].$1,
                    icon: tabs[i].$2,
                    isActive: currentIndex == i,
                    onTap: () => onTabTapped(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.ksc;
    final activeColor = theme.accent500;
    final inactiveColor = theme.neutral400;

    return Semantics(
      button: true,
      label: label,
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            // Gold active indicator bar
            Container(
              height: 2.5,
              color: isActive ? activeColor : Colors.transparent,
            ),
            const Spacer(),
            Icon(
              icon,
              size: 20,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
