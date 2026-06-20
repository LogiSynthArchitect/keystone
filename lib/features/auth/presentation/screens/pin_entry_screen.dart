import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_logo.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_numpad.dart';
import '../../../../core/widgets/ks_success_moment.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/services/internal_auth/models/unlock_result.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/auth_provider.dart';

/// PIN unlock screen — uses the custom [KsNumpad] widget for app-internal
/// PIN entry. Shows remaining attempts before wipe.
class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
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

                    // Brand logo
                    const Center(child: KsLogo(size: 32)),
                    const SizedBox(height: 20),

                    // PIN Wiped banner
                    if (_isWiped) ...[
                      KsBanner(
                        message: 'PIN has been wiped. Enter your password instead.',
                        type: KsBannerType.alert,
                      ),
                      const SizedBox(height: 24),
                    ],

                    KsNumpad(
                      onReady: (c) => _controls = c,
                      title: 'ENTER PIN',
                      subtitle: _isWiped
                          ? 'PIN has been wiped. Enter your password instead.'
                          : _remainingAttempts <= 3 && _remainingAttempts > 0
                              ? '$_remainingAttempts attempt(s) remaining'
                              : null,
                      onCompleted: _isWiped ? (_) {} : _onPinEntered,
                      hasError: _isWiped,
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

                    // ENTER PASSWORD button for wiped state
                    if (_isWiped) ...[
                      const SizedBox(height: 24),
                      KsButton(
                        label: 'ENTER PASSWORD',
                        onPressed: () => context.go(RouteNames.passwordUnlock),
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
        onTap: () => context.pop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.ksc.primary800.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
                color: context.ksc.primary700.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.arrow_back_ios_new,
              size: 18, color: context.ksc.white),
        ),
      );
}
