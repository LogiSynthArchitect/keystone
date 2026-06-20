import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/widgets/ks_logo.dart';
import '../../../../core/widgets/auth_step_header.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_success_moment.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/services/internal_auth/biometric_service.dart';
import '../../../../core/services/internal_auth/models/auth_method.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/widgets/focus_safe_text_field.dart';
import '../providers/auth_notifier.dart';

class PasswordEntryScreen extends ConsumerStatefulWidget {
  const PasswordEntryScreen({super.key});

  @override
  ConsumerState<PasswordEntryScreen> createState() =>
      _PasswordEntryScreenState();
}

class _PasswordEntryScreenState extends ConsumerState<PasswordEntryScreen> {
  String _password = '';

  bool get _canSubmit => _password.length >= 8;

  Future<void> _onSubmit() async {
    if (!_canSubmit) return;
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);
    final phone = ref.read(authNotifierProvider).phoneNumber ?? '';

    final session =
        await service.verifyPassword(phone, _password);
    if (session != null && mounted) {
      await ref.read(authStateProvider.notifier).refresh();
      if (!mounted) return;
      ref.read(authStateProvider.notifier).setLocallyUnlocked(true);
      await KsSuccessMoment.show(context, title: 'WELCOME BACK');
      if (mounted) context.go(RouteNames.transition);
    } else if (mounted) {
      authNotifier.setError('Invalid password. Please try again.');
    }
  }

  Future<void> _promptFastUnlock(InternalAuthService service) async {
    try {
      await service.enrollBiometric();
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
    }
    // PIN is mandatory — biometric is optional
    if (mounted) context.push(RouteNames.pinSetup);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final phone = authState.phoneNumber ?? '';
    final errorMessage = authState.errorMessage;

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildBackButton(context),
                    const SizedBox(height: 20),

                    // Brand logo
                    const Center(child: KsLogo(size: 32)),
                    const SizedBox(height: 20),

                    // Step ring header
                    const Center(
                      child: AuthStepHeader(
                        totalSteps: 4,
                        currentStep: 2,
                        icon: LineAwesomeIcons.lock_solid,
                        stepLabel: 'PASSWORD',
                        subStep: 0,
                        subSteps: 1,
                      ),
                    ),

                    const SizedBox(height: 40),

                    Text(
                      'Sign in for',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.ksc.neutral400,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    Text(
                      phone,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 24),

                    Text(
                      'ENTER PASSWORD',
                      style: TextStyle(
                        fontFamily: 'BarlowSemiCondensed',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: context.ksc.white,
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 24),

                    if (errorMessage != null && errorMessage.isNotEmpty) ...[
                      KsBanner(message: errorMessage),
                      const SizedBox(height: 24),
                    ],

                    _buildPasswordField(context),
                    const SizedBox(height: 16),
                    _buildLinks(context),
                  ],
                ),
              ),
            ),
            KsButton(
              label: 'SIGN IN',
              variant: KsButtonVariant.cta,
              onPressed: _canSubmit && !authState.isLoading ? _onSubmit : null,
              isLoading: authState.isLoading,
              edgeToEdge: true,
            ).animate().fadeIn(delay: 600.ms),
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
          child: Icon(LineAwesomeIcons.angle_left_solid,
              size: 18, color: context.ksc.white),
        ),
      );

  Widget _buildPasswordField(BuildContext context) {
    return FocusSafeTextField(
      label: 'PASSWORD',
      hint: 'Enter your password',
      obscureText: true,
      onChanged: (v) => setState(() => _password = v),
      onSubmitted: (_) => _onSubmit(),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.push(RouteNames.forgotAccess),
          child: Text(
            'Forgot access?',
            style: TextStyle(
              fontFamily: 'BarlowSemiCondensed',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              color: context.ksc.neutral500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => context.go(RouteNames.phoneEntry),
          child: Text(
            'Not you?',
            style: TextStyle(
              fontFamily: 'BarlowSemiCondensed',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              color: context.ksc.neutral500,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

}
