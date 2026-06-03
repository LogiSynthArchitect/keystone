import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class LockedScreen extends StatelessWidget {
  const LockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ksc.primary900,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // shield icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: context.ksc.primary800.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LineAwesomeIcons.shield_alt_solid,
                    size: 32,
                    color: context.ksc.neutral500,
                  ),
                ),
                const SizedBox(height: 36),

                // heading
                Text(
                  'KEYSECURE LOCKED',
                  style: AppTextStyles.h1.copyWith(
                    color: context.ksc.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ).animate().fadeIn().slideY(begin: -0.1, end: 0),
                const SizedBox(height: 16),

                // description
                Text(
                  'Verify your identity to access your account.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.ksc.neutral400,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const Spacer(flex: 2),

                // 3 icon row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _IconCard(
                      icon: LineAwesomeIcons.fingerprint_solid,
                      label: 'BIOMETRIC',
                      onTap: () {
                        // TODO: trigger biometric unlock
                        debugPrint('Trigger biometric unlock');
                      },
                    ),
                    const SizedBox(width: 40),
                    _IconCard(
                      icon: LineAwesomeIcons.lock_solid,
                      label: 'PIN',
                      onTap: () => context.go(RouteNames.pinEntry),
                    ),
                    const SizedBox(width: 40),
                    _IconCard(
                      icon: LineAwesomeIcons.key_solid,
                      label: 'PASSWORD',
                      onTap: () => context.go(RouteNames.passwordEntry),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),

                const Spacer(flex: 2),

                // "not you?" link
                GestureDetector(
                  onTap: () => context.go(RouteNames.phoneEntry),
                  child: Text(
                    'NOT YOU? SIGN IN AS DIFFERENT USER',
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral500,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IconCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.ksc.accent500, width: 2),
            ),
            child: Icon(icon, size: 26, color: context.ksc.accent500),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: context.ksc.accent500,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
