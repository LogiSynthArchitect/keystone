import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/auth_step_header.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/widgets/ks_success_moment.dart';
import '../../../../core/services/internal_auth/internal_auth_service.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../providers/auth_notifier.dart';

class CreatePasswordScreen extends ConsumerStatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  ConsumerState<CreatePasswordScreen> createState() =>
      _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends ConsumerState<CreatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _passwordFocused = false;
  bool _confirmFocused = false;

  @override
  void initState() {
    super.initState();
    _passwordFocus.addListener(
        () => setState(() => _passwordFocused = _passwordFocus.hasFocus));
    _confirmFocus.addListener(
        () => setState(() => _confirmFocused = _confirmFocus.hasFocus));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final pw = _passwordController.text;
    final confirm = _confirmController.text;
    return pw.length >= 8 &&
        pw.contains(RegExp(r'[A-Za-z]')) &&
        pw.contains(RegExp(r'[0-9]')) &&
        confirm.isNotEmpty &&
        pw == confirm;
  }

  Future<void> _onSubmit() async {
    if (!_canSubmit) return;
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final supabase = ref.read(supabaseClientProvider);
    final service = InternalAuthService(supabase);
    final phone = ref.read(authNotifierProvider).phoneNumber ?? '';

    final success =
        await service.enrollPassword(phone, _passwordController.text);
    if (success && mounted) {
      await authNotifier.setPasswordCreated();
      await KsSuccessMoment.show(context, title: 'PASSWORD CREATED');
      if (mounted) context.push(RouteNames.biometricEnroll);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
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
                        icon: LineAwesomeIcons.key_solid,
                        stepLabel: 'PASSWORD',
                        subStep: 0,
                        subSteps: 2,
                      ),
                    ),

                    const SizedBox(height: 40),

                    Text(
                      'Create a password for',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.ksc.neutral400,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    Text(
                      authState.phoneNumber ?? '',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 24),

                    Text(
                      'CREATE PASSWORD',
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
                    const SizedBox(height: 24),
                    _buildConfirmField(context),
                    const SizedBox(height: 20),
                    _buildPasswordHint(context),
                  ],
                ),
              ),
            ),
            KsButton(
              label: 'CREATE PASSWORD',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required String hint,
    required VoidCallback onChanged,
    String? label,
    VoidCallback? onSubmitted,
    TextInputAction textInputAction = TextInputAction.next,
    Iterable<String>? autofillHints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: TextStyle(
              fontFamily: 'BarlowSemiCondensed',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: context.ksc.neutral400,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (_) => onChanged(),
                obscureText: obscure,
                style: TextStyle(
                  fontFamily: 'BarlowSemiCondensed',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.ksc.white,
                ),
                cursorColor: context.ksc.accent500,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: textInputAction,
                autofillHints: autofillHints,
                decoration: InputDecoration(
                  hintText: hint,
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
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                onSubmitted: (_) => onSubmitted?.call(),
              ),
            ),
            GestureDetector(
              onTap: onToggleObscure,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  obscure
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
          opacity: isFocused ? 1.0 : 0.4,
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
    );
  }

  Widget _buildPasswordField(BuildContext context) =>
      _buildTextField(
        controller: _passwordController,
        focusNode: _passwordFocus,
        isFocused: _passwordFocused,
        obscure: _obscurePassword,
        hint: 'Enter password',
        label: 'PASSWORD',
        onToggleObscure: () =>
            setState(() => _obscurePassword = !_obscurePassword),
        onChanged: () => setState(() {}),
        onSubmitted: () => _confirmFocus.requestFocus(),
        autofillHints: const [AutofillHints.newPassword],
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);

  Widget _buildConfirmField(BuildContext context) =>
      _buildTextField(
        controller: _confirmController,
        focusNode: _confirmFocus,
        isFocused: _confirmFocused,
        obscure: _obscureConfirm,
        hint: 'Confirm password',
        label: 'CONFIRM PASSWORD',
        onToggleObscure: () =>
            setState(() => _obscureConfirm = !_obscureConfirm),
        onChanged: () => setState(() {}),
        onSubmitted: () => _onSubmit(),
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.newPassword],
      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);

  Widget _buildPasswordHint(BuildContext context) {
    final pw = _passwordController.text;
    final min8 = pw.length >= 8;
    final hasLetter = pw.contains(RegExp(r'[A-Za-z]'));
    final hasNumber = pw.contains(RegExp(r'[0-9]'));
    final match = _confirmController.text.isNotEmpty &&
        _confirmController.text == _passwordController.text;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hintRow(context, 'Minimum 8 characters', min8),
          const SizedBox(height: 4),
          _hintRow(context, 'At least 1 letter', hasLetter),
          const SizedBox(height: 4),
          _hintRow(context, 'At least 1 number', hasNumber),
          const SizedBox(height: 4),
          _hintRow(context, 'Passwords match', match),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _hintRow(BuildContext context, String text, bool valid) {
    return Row(
      children: [
        Icon(
          valid
              ? LineAwesomeIcons.check_circle_solid
              : LineAwesomeIcons.times_circle_solid,
          size: 14,
          color: valid ? context.ksc.success500 : context.ksc.neutral500,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color:
                valid ? context.ksc.success500 : context.ksc.neutral400,
          ),
        ),
      ],
    );
  }

}
