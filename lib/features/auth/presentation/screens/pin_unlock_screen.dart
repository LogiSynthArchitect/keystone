import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/services/internal_auth/models/unlock_result.dart';
import '../../../../core/widgets/ks_numpad.dart';
import '../../../../core/widgets/ks_success_moment.dart';

/// Dedicated PIN unlock screen from LockedScreen.
/// Back arrow returns to LockedScreen. "Forgot PIN?" link goes to password unlock.
class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen> {
  KsNumpadControls? _controls;
  int _remainingAttempts = 5;
  bool _isWiped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAttempts());
  }

  Future<void> _loadAttempts() async {
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);
    final remaining = await service.pin.getRemainingAttempts();
    final wiped = await service.pin.isWiped();
    if (mounted) {
      setState(() {
        _remainingAttempts = remaining;
        _isWiped = wiped;
      });
    }
  }

  Future<void> _onPinEntered(String code) async {
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);
    final result = await service.unlockWithPin(code);

    if (!mounted) return;

    if (result is UnlockSuccess) {
      HapticFeedback.heavyImpact();
      ref.read(authStateProvider.notifier).setLocallyUnlocked(true);
      if (!mounted) return;
      await KsSuccessMoment.show(context, title: 'UNLOCKED');
      if (mounted) context.go(RouteNames.transition);
    } else if (result is UnlockLocked) {
      setState(() => _remainingAttempts--);
      _controls?.shakeAndClear();
    } else {
      // Wiped or needs online — redirect to password unlock
      if (mounted) context.go(RouteNames.passwordUnlock);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ksc.primary900,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildBackButton(context),
                    const SizedBox(height: 20),

                    // Lock icon
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: context.ksc.accent500, width: 3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          LineAwesomeIcons.lock_solid,
                          color: context.ksc.accent500,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        'ENTER PIN',
                        style: TextStyle(
                          fontFamily: 'BarlowSemiCondensed',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          color: Colors.white,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 8),

                    if (_isWiped)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'PIN has been wiped. Use your password instead.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'BarlowSemiCondensed',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDA3633),
                          ),
                        ),
                      )
                    else ...[
                      Center(
                        child: Text(
                          _remainingAttempts <= 3 && _remainingAttempts > 0
                              ? '$_remainingAttempts attempt(s) remaining'
                              : 'Enter your 6-digit PIN',
                          style: const TextStyle(
                            fontFamily: 'BarlowSemiCondensed',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8B949E),
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],

                    const SizedBox(height: 28),

                    KsNumpad(
                      onReady: (c) => _controls = c,
                      title: 'ENTER PIN',
                      subtitle: _isWiped
                          ? 'PIN has been wiped'
                          : _remainingAttempts <= 3 && _remainingAttempts > 0
                              ? '$_remainingAttempts attempt(s) remaining'
                              : null,
                      onCompleted: _isWiped ? (_) {} : _onPinEntered,
                      hasError: _isWiped,
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

                    // "Forgot PIN?" link
                    if (!_isWiped) ...[
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => context.go(RouteNames.passwordUnlock),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LineAwesomeIcons.key_solid,
                              size: 12,
                              color: context.ksc.accent500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Forgot PIN? Use your password instead',
                              style: TextStyle(
                                fontFamily: 'BarlowSemiCondensed',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                color: context.ksc.accent500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // PASSWORD button for wiped state
                    if (_isWiped) ...[
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => context.go(RouteNames.passwordUnlock),
                        child: Text(
                          'USE PASSWORD INSTEAD',
                          style: TextStyle(
                            fontFamily: 'BarlowSemiCondensed',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.ksc.accent500,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) => GestureDetector(
        onTap: () => context.go(RouteNames.locked),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.ksc.primary800.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border:
                Border.all(color: context.ksc.primary700.withValues(alpha: 0.3)),
          ),
          child: Icon(LineAwesomeIcons.angle_left_solid,
              size: 18, color: context.ksc.white),
        ),
      );
}
