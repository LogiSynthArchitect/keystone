import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/services/internal_auth/secure_vault_service.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class LockedScreen extends ConsumerStatefulWidget {
  const LockedScreen({super.key});

  @override
  ConsumerState<LockedScreen> createState() => _LockedScreenState();
}

class _LockedScreenState extends ConsumerState<LockedScreen> {
  bool _hasBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadVaultState();
  }

  Future<void> _loadVaultState() async {
    final vault = SecureVaultService();
    final hasBio = await vault.getHasBiometric();
    if (mounted) {
      setState(() => _hasBiometric = hasBio);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ksc.primary900,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Lock icon with animated glow ──
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: context.ksc.accent500.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LineAwesomeIcons.lock_solid,
                    size: 40,
                    color: context.ksc.accent500,
                  ),
                ).animate().scale(
                  duration: 600.ms,
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),

                const SizedBox(height: 40),

                // ── Heading ──
                Text(
                  'DEVICE LOCKED',
                  style: AppTextStyles.h1.copyWith(
                    color: context.ksc.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1, end: 0),

                const SizedBox(height: 12),

                Text(
                  'Quick unlock required to access your account.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.ksc.neutral400,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const Spacer(flex: 2),

                // ── Unlock method cards ──
                if (_hasBiometric)
                  _UnlockCard(
                    icon: LineAwesomeIcons.fingerprint_solid,
                    label: 'FINGERPRINT',
                    description: 'Use device biometrics',
                    onTap: () async {
                      final supabase = ref.read(supabaseClientProvider);
                      final service = InternalAuthService(supabase);
                      final matched = await service.unlockWithDeviceAuth();
                      if (matched && context.mounted) {
                        HapticFeedback.heavyImpact();
                        ref.read(authStateProvider.notifier).setLocallyUnlocked(true);
                        if (context.mounted) context.go(RouteNames.transition);
                      } else if (context.mounted) {
                        HapticFeedback.vibrate();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Biometric unlock failed. Try again or use PIN.',
                              style: TextStyle(
                                fontFamily: 'BarlowSemiCondensed',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: context.ksc.error500,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                if (_hasBiometric) const SizedBox(height: 10),

                _UnlockCard(
                  icon: LineAwesomeIcons.lock_solid,
                  label: 'APP PIN',
                  description: 'Enter your 6-digit PIN',
                  onTap: () => context.go(RouteNames.pinUnlock),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 10),

                _UnlockCard(
                  icon: LineAwesomeIcons.key_solid,
                  label: 'PASSWORD',
                  description: 'Sign in with cloud password',
                  onTap: () => context.go(RouteNames.passwordUnlock),
                  isSecondary: true,
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool isSecondary;

  const _UnlockCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSecondary
              ? context.ksc.primary800.withValues(alpha: 0.4)
              : context.ksc.primary800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSecondary
                ? context.ksc.primary700.withValues(alpha: 0.3)
                : context.ksc.accent500.withValues(alpha: 0.2),
            width: isSecondary ? 1 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSecondary
                    ? context.ksc.primary700.withValues(alpha: 0.15)
                    : context.ksc.accent500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSecondary
                    ? context.ksc.neutral400
                    : context.ksc.accent500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'BarlowSemiCondensed',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSecondary
                          ? context.ksc.neutral400
                          : context.ksc.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'BarlowSemiCondensed',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.ksc.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LineAwesomeIcons.angle_right_solid,
              size: 16,
              color: isSecondary
                  ? context.ksc.neutral600
                  : context.ksc.accent500,
            ),
          ],
        ),
      ),
    );
  }
}
