import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
import '../providers/auth_notifier.dart';

class PasswordEntryScreen extends ConsumerStatefulWidget {
  const PasswordEntryScreen({super.key});

  @override
  ConsumerState<PasswordEntryScreen> createState() =>
      _PasswordEntryScreenState();
}

class _PasswordEntryScreenState extends ConsumerState<PasswordEntryScreen> {
  final _passwordController = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscure = true;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
        () => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canSubmit => _passwordController.text.length >= 8;

  Future<void> _onSubmit() async {
    if (!_canSubmit) return;
    _focusNode.unfocus();
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);
    final phone = ref.read(authNotifierProvider).phoneNumber ?? '';

    final session =
        await service.verifyPassword(phone, _passwordController.text);
    if (session != null && mounted) {
      await ref.read(authStateProvider.notifier).refresh();
      if (!mounted) return;
      final method = await service.getEnrolledMethod();
      if (method == AuthMethod.none) {
        await _promptFastUnlock(service);
        if (!mounted) return;
        await ref.read(authStateProvider.notifier).refresh();
      }
      if (!mounted) return;
      ref.read(authStateProvider.notifier).setLocallyUnlocked(true);
      await KsSuccessMoment.show(context, title: 'WELCOME BACK');
      if (mounted) context.go(RouteNames.transition);
    } else if (mounted) {
      authNotifier.setError('Invalid password. Please try again.');
    }
  }

  Future<void> _promptFastUnlock(InternalAuthService service) async {
    final shouldEnroll = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: context.ksc.primary700),
        ),
        title: Text('FAST UNLOCK',
            style:
                AppTextStyles.h2.copyWith(color: context.ksc.white)),
        content: Text(
          'Set up fingerprint or PIN for faster logins on this device?',
          style: AppTextStyles.bodyMedium.copyWith(
              color: context.ksc.neutral400, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('SKIP',
                style: TextStyle(
                    color: context.ksc.neutral500,
                    fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: context.ksc.accent500),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('SET UP',
                style: TextStyle(
                    color: context.ksc.primary900,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (shouldEnroll != true || !mounted) return;

    try {
      final enrolled = await service.enrollBiometric();
      if (enrolled || !mounted) return;
      if (mounted) context.push(RouteNames.pinSetup);
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
      if (mounted) context.push(RouteNames.pinSetup);
    }
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
                    const SizedBox(height: 48),

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PASSWORD',
          style: TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: context.ksc.neutral400,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _passwordController,
                focusNode: _focusNode,
                onChanged: (_) => setState(() {}),
                obscureText: _obscure,
                style: TextStyle(
                  fontFamily: 'BarlowSemiCondensed',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.ksc.white,
                ),
                cursorColor: context.ksc.accent500,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(
                    fontFamily: 'BarlowSemiCondensed',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: context.ksc.neutral500,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: (_) => _onSubmit(),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  _obscure
                      ? LineAwesomeIcons.eye_solid
                      : LineAwesomeIcons.eye_slash_solid,
                  size: 18,
                  color: context.ksc.neutral400.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
        AnimatedOpacity(
          opacity: _isFocused ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.ksc.accent500,
                  context.ksc.primary500,
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ],
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
