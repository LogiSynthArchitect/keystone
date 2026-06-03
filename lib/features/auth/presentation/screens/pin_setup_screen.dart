import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_numpad.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/widgets/auth_step_header.dart';

/// Full-screen PIN setup with Enter + Confirm steps.
///
/// Flow: Choose PIN (6 digits) -> Confirm PIN (6 digits) -> enroll -> pop
/// Returns `true` if enrollment succeeded, `null` if cancelled.
///
/// Pass `popOnSuccess: true` (via GoRouter `extra`) to pop back with
/// result instead of navigating to onboarding. Used by the biometric
/// enroll checklist screen so user can select PIN + biometric together.
class PinSetupScreen extends ConsumerStatefulWidget {
  final bool popOnSuccess;

  const PinSetupScreen({super.key, this.popOnSuccess = false});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  KsNumpadControls? _controls;
  String? _firstPin;
  String? _error;

  _PinStep get _step =>
      _firstPin == null ? _PinStep.choose : _PinStep.confirm;

  @override
  Widget build(BuildContext context) {
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      body: SafeArea(
        child: Column(
          children: [
            // Top section: back button + step header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  _AuthBackButton(onTap: () => context.pop()),
                  const SizedBox(height: 32),
                  const AuthStepHeader(
                    totalSteps: 4,
                    currentStep: 3,
                    icon: LineAwesomeIcons.lock_solid,
                    stepLabel: 'PIN',
                  ),
                ],
              ),
            ),
            // Numpad fills remaining space, no scroll
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    KsNumpad(
                      onReady: (c) => _controls = c,
                      title: _step == _PinStep.choose
                          ? 'CREATE A PIN'
                          : 'CONFIRM PIN',
                      subtitle: _step == _PinStep.choose
                          ? 'Choose a 6-digit PIN to unlock the app'
                          : 'Enter your PIN again to confirm',
                      hasError: _error != null,
                      onCompleted: (code) => _onComplete(code, service),
                      onChanged: (_) {
                        if (_error != null) {
                          setState(() => _error = null);
                        }
                      },
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: KsBanner(
                          message: _error!,
                          type: KsBannerType.alert,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onComplete(String code, InternalAuthService service) async {
    if (_step == _PinStep.choose) {
      setState(() => _firstPin = code);
      _controls?.clear();
      return;
    }

    // Confirm step
    if (code != _firstPin) {
      setState(() => _error = 'PINs do not match. Try again.');
      _controls?.shakeAndClear();
      setState(() => _firstPin = null); // Reset to step 1
      return;
    }

    debugPrint('[KS:PIN_SETUP] _onComplete step=${_step} popOnSuccess=${widget.popOnSuccess}');
    try {
      final ok = await service.enrollPin(code);
      debugPrint('[KS:PIN_SETUP] enrollPin result=$ok');
      if (ok && mounted) {
        debugPrint('[KS:PIN_SETUP] refreshing auth state...');
        await ref.read(authStateProvider.notifier).refresh();
        debugPrint('[KS:PIN_SETUP] auth refreshed, navigating...');
        if (mounted) {
          if (widget.popOnSuccess) {
            debugPrint('[KS:PIN_SETUP] pop(true) back to checklist');
            context.pop(true);
          } else {
            debugPrint('[KS:PIN_SETUP] pushReplacement to biometricEnroll');
            context.pushReplacement(RouteNames.biometricEnroll);
          }
        }
      } else if (mounted) {
        debugPrint('[KS:PIN_SETUP] enrollPin returned false');
        setState(() => _error = 'Failed to save PIN. Try again.');
        _controls?.shakeAndClear();
        setState(() => _firstPin = null);
      }
    } catch (e) {
      debugPrint('[KS:PIN_SETUP] enrollPin error: $e');
      if (mounted) {
        setState(() => _error = 'Something went wrong. Try again.');
        _controls?.shakeAndClear();
        setState(() => _firstPin = null);
      }
    }
  }
}

enum _PinStep { choose, confirm }

/// Shared circular back button.
class _AuthBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AuthBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: context.ksc.primary800.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: context.ksc.primary700.withValues(alpha: 0.3)),
        ),
        child: Icon(LineAwesomeIcons.angle_left_solid,
            size: 14, color: context.ksc.white),
      ),
    );
  }
}