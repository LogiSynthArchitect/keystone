import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/widgets/auth_step_header.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import 'pin_setup_screen.dart';

/// Full screen Focus Strip Biometric Enroll page.
///
/// Multi-select checklist: user can enable biometric unlock, set an app PIN,
/// or both. PIN is mandatory. No SKIP option.
///
/// [returnRoute] — if set, user came from upgrade flow; navigate there
/// on completion instead of onboarding. Also adjusts copy and hides
/// onboarding step indicator.
class BiometricEnrollPage extends ConsumerStatefulWidget {
  const BiometricEnrollPage({super.key, this.returnRoute});

  final String? returnRoute;

  @override
  ConsumerState<BiometricEnrollPage> createState() => _BiometricEnrollPageState();
}

class _BiometricEnrollPageState extends ConsumerState<BiometricEnrollPage> {
  bool _hasBiometrics = false;
  bool _hasCheckedBiometrics = false;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  bool _enrollingBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricCapability();
  }

  Future<void> _checkBiometricCapability() async {
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);
    final bio = await service.biometric.getAvailableBiometrics();
    if (mounted) {
      setState(() {
        _hasBiometrics = bio.isNotEmpty;
        _hasCheckedBiometrics = true;
      });
    }
  }

  Future<void> _toggleBiometric() async {
    if (_biometricEnabled) return;
    setState(() => _enrollingBiometric = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final service = InternalAuthService(supabase);
      final success = await service.enrollBiometric();
      if (mounted && success) {
        setState(() => _biometricEnabled = true);
      }
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Biometric authentication failed. Please try again or set up an app PIN instead.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on BiometricAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.userMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enrollingBiometric = false);
    }
  }

  Future<void> _togglePin() async {
    if (_pinEnabled) return;
    // Use native Navigator.push so this page stays alive underneath
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PinSetupScreen(popOnSuccess: true),
        fullscreenDialog: true,
      ),
    );
    if (mounted && result == true) {
      setState(() => _pinEnabled = true);
    }
  }

  Future<void> _onContinue() async {
    await ref.read(authStateProvider.notifier).refresh();
    final route = widget.returnRoute ?? RouteNames.onboarding;
    if (mounted) context.go(route);
  }

  bool get _canContinue => _pinEnabled;

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
                    _AuthBackButton(onTap: () => context.pop()),
                    const SizedBox(height: 32),
                    if (widget.returnRoute != null) ...[
                      // Upgrade user — concise, no step indicator
                      Text(
                        'ACCOUNT SECURITY',
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.accent500,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LOCAL UNLOCK',
                        style: AppTextStyles.h1.copyWith(
                          color: context.ksc.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set an app PIN to secure offline access. '
                        'Fingerprint is optional.',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: context.ksc.neutral400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      // New user — step 3 of onboarding
                      const AuthStepHeader(
                        totalSteps: 4,
                        currentStep: 3,
                        icon: LineAwesomeIcons.fingerprint_solid,
                        stepLabel: 'BIOMETRIC',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Choose at least one quick unlock method to skip SMS waiting.',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: context.ksc.neutral400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    if (_hasCheckedBiometrics && _hasBiometrics)
                      _ChecklistCard(
                        icon: LineAwesomeIcons.fingerprint_solid,
                        title: 'FINGERPRINT / FACE UNLOCK',
                        subtitle: 'Fastest \u2014 uses your device biometrics',
                        isSelected: _biometricEnabled,
                        isLoading: _enrollingBiometric,
                        onTap: _toggleBiometric,
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                    if (_hasCheckedBiometrics && _hasBiometrics)
                      const SizedBox(height: 12),
                    _ChecklistCard(
                      icon: LineAwesomeIcons.lock_solid,
                      title: 'APP PIN',
                      subtitle: _pinEnabled
                          ? 'Already set \u2014 required for offline unlock'
                          : (widget.returnRoute != null
                              ? 'Required to unlock the app offline'
                              : 'Custom 6-digit PIN \u2014 works offline, no device lock required'),
                      isSelected: _pinEnabled,
                      locked: _pinEnabled,
                      onTap: _pinEnabled ? null : _togglePin,
                    ).animate().fadeIn(delay: _hasBiometrics ? 400.ms : 300.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (_canContinue)
              KsButton(
                label: 'CONTINUE',
                variant: KsButtonVariant.cta,
                edgeToEdge: true,
                trailingIcon: LineAwesomeIcons.arrow_right_solid,
                onPressed: _onContinue,
              ),
            if (!_canContinue)
              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
                child: Text(
                  'Set an app PIN to continue',
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.neutral500,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet variant used from password entry flow.
class BiometricEnrollSheet extends ConsumerStatefulWidget {
  const BiometricEnrollSheet({super.key});

  @override
  ConsumerState<BiometricEnrollSheet> createState() => _BiometricEnrollSheetState();
}

class _BiometricEnrollSheetState extends ConsumerState<BiometricEnrollSheet> {
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  bool _enrollingBiometric = false;

  Future<void> _toggleBiometric() async {
    if (_biometricEnabled) return;
    setState(() => _enrollingBiometric = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final service = InternalAuthService(supabase);
      final success = await service.enrollBiometric();
      if (mounted && success) {
        setState(() => _biometricEnabled = true);
      }
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Biometric authentication failed. Please try again or set up an app PIN instead.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on BiometricAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.userMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enrollingBiometric = false);
    }
  }

  Future<void> _togglePin() async {
    if (_pinEnabled) return;
    // Use native Navigator.push so this page stays alive underneath
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PinSetupScreen(popOnSuccess: true),
        fullscreenDialog: true,
      ),
    );
    if (mounted && result == true) {
      setState(() => _pinEnabled = true);
    }
  }

  Future<void> _onContinue() async {
    Navigator.of(context).pop();
    await ref.read(authStateProvider.notifier).refresh();
    if (mounted) context.go(RouteNames.onboarding);
  }

  bool get _canContinue => _biometricEnabled || _pinEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.ksc.primary900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.ksc.neutral600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'SECURE YOUR ACCOUNT',
            style: AppTextStyles.caption.copyWith(
              color: context.ksc.accent500,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'FAST UNLOCK OPTIONS',
            style: AppTextStyles.h2.copyWith(
              color: context.ksc.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose at least one method to skip waiting for SMS.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.ksc.neutral400,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _ChecklistCard(
            icon: LineAwesomeIcons.fingerprint_solid,
            title: 'FINGERPRINT / FACE UNLOCK',
            subtitle: 'Fastest \u2014 uses your device biometrics',
            isSelected: _biometricEnabled,
            isLoading: _enrollingBiometric,
            onTap: _toggleBiometric,
          ),
          const SizedBox(height: 12),
          _ChecklistCard(
            icon: LineAwesomeIcons.lock_solid,
            title: 'SET APP PIN',
            subtitle: 'Custom 6-digit PIN \u2014 works offline, no device lock required',
            isSelected: _pinEnabled,
            onTap: _togglePin,
          ),
          const SizedBox(height: 16),
          if (_canContinue)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.ksc.accent500,
                  foregroundColor: context.ksc.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('CONTINUE',
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
                ),
              ),
            ),
          if (!_canContinue)
            Text(
              'Select at least one option above to continue',
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Shared circular back button used in BiometricEnrollPage header.
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

/// Shared checklist card with checkmark indicator for multi-select.
class _ChecklistCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isLoading;
  final bool locked;
  final VoidCallback? onTap;

  const _ChecklistCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isSelected = false,
    this.isLoading = false,
    this.locked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.6 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: locked || isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? context.ksc.accent500 : context.ksc.primary700,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? context.ksc.accent500 : context.ksc.neutral400,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.label.copyWith(
                          color: context.ksc.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.neutral400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _ToggleIndicator(
                  isSelected: isSelected,
                  isLoading: isLoading,
                  locked: locked,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill toggle indicator matching HTML `.toggle` pattern.
class _ToggleIndicator extends StatelessWidget {
  final bool isSelected;
  final bool isLoading;
  final bool locked;

  const _ToggleIndicator({
    required this.isSelected,
    this.isLoading = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 44,
        height: 24,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.ksc.neutral400,
            ),
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? context.ksc.accent500 : context.ksc.neutral600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: isSelected
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.ksc.white,
            ),
          ),
        ],
      ),
    );
  }
}
