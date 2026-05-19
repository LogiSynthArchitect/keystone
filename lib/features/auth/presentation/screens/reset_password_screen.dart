import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../providers/auth_notifier.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _newPasswordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _codeEntered = false;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    _newPasswordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? get _passwordError {
    final pw = _newPasswordController.text;
    if (pw.isEmpty) return null;
    if (pw.length < 8) return 'Minimum 8 characters';
    if (!pw.contains(RegExp(r'[A-Za-z]'))) return 'Must include a letter';
    if (!pw.contains(RegExp(r'[0-9]'))) return 'Must include a number';
    return null;
  }

  bool get _canReset {
    return _codeController.text.length == 6
        && _passwordError == null
        && _newPasswordController.text.isNotEmpty
        && _confirmController.text == _newPasswordController.text;
  }

  Future<void> _onReset() async {
    if (!_canReset) return;
    final supabase = ref.read(supabaseClientProvider);
    final phone = ref.read(authNotifierProvider).phoneNumber ?? '';

    if (phone.isEmpty) {
      ref.read(authNotifierProvider.notifier).setError('Session expired. Request a new code.');
      return;
    }

    try {
      await supabase.functions.invoke(
        'verify-password-reset',
        body: {
          'phone': phone,
          'code': _codeController.text.trim(),
          'newPassword': _newPasswordController.text,
        },
      );

      if (mounted) {
        await ref.read(authStateProvider.notifier).refresh();
        context.go(RouteNames.transition);
      }
    } catch (e) {
      final err = e.toString();
      if (err.contains('401')) {
        ref.read(authNotifierProvider.notifier).setError('Invalid or expired code.');
      } else if (err.contains('404')) {
        ref.read(authNotifierProvider.notifier).setError('Account not found.');
      } else if (err.contains('429') || err.contains('limit')) {
        ref.read(authNotifierProvider.notifier).setError('Too many attempts. Try again later.');
      } else {
        ref.read(authNotifierProvider.notifier).setError('Reset failed. Try again.');
      }
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
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: context.ksc.primary800,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: context.ksc.primary700),
                        ),
                        child: Icon(LineAwesomeIcons.angle_left_solid, size: 20, color: context.ksc.white),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'RECOVERY',
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.accent500,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      'RESET PASSWORD',
                      style: AppTextStyles.h1.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 24),
                    Text(
                      'Enter the recovery code sent to your phone.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.ksc.neutral400,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 48),
                    if (errorMessage != null && errorMessage.isNotEmpty) ...[
                      KsBanner(message: errorMessage),
                      const SizedBox(height: 24),
                    ],
                    _buildCodeInput(context),
                    if (_codeEntered) ...[
                      const SizedBox(height: 24),
                      _buildNewPasswordField(context),
                      const SizedBox(height: 16),
                      _buildConfirmField(context),
                    ],
                  ],
                ),
              ),
            ),
            if (_codeEntered) _buildBottomBar(context, authState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeInput(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 48, height: 64,
      textStyle: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
    );

    return Pinput(
      controller: _codeController,
      length: 6,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: defaultTheme.copyWith(
        decoration: defaultTheme.decoration!.copyWith(
          border: Border.all(color: context.ksc.accent500, width: 2),
        ),
      ),
      onCompleted: (code) {
        setState(() => _codeEntered = true);
        HapticFeedback.heavyImpact();
      },
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildNewPasswordField(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: TextField(
        controller: _newPasswordController,
        focusNode: _newPasswordFocus,
        onChanged: (_) => setState(() {}),
        obscureText: _obscureNew,
        style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800),
        cursorColor: context.ksc.accent500,
        decoration: InputDecoration(
          hintText: 'New password',
          hintStyle: TextStyle(color: context.ksc.neutral600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNew ? LineAwesomeIcons.eye_solid : LineAwesomeIcons.eye_slash_solid,
              color: context.ksc.neutral400, size: 20,
            ),
            onPressed: () => setState(() => _obscureNew = !_obscureNew),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmField(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: TextField(
        controller: _confirmController,
        focusNode: _confirmFocus,
        onChanged: (_) => setState(() {}),
        obscureText: _obscureConfirm,
        style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800),
        cursorColor: context.ksc.accent500,
        decoration: InputDecoration(
          hintText: 'Confirm new password',
          hintStyle: TextStyle(color: context.ksc.neutral600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? LineAwesomeIcons.eye_solid : LineAwesomeIcons.eye_slash_solid,
              color: context.ksc.neutral400, size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isLoading) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        border: Border(top: BorderSide(color: context.ksc.primary700)),
      ),
      padding: const EdgeInsets.all(24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canReset && !isLoading ? _onReset : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RESET PASSWORD',
                style: AppTextStyles.h2.copyWith(
                  color: _canReset ? context.ksc.white : context.ksc.neutral600,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(
                LineAwesomeIcons.angle_right_solid,
                color: _canReset ? context.ksc.accent500 : context.ksc.neutral700,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
