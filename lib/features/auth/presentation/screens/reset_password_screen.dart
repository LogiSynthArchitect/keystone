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
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_success_moment.dart';
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
  bool _isSessionExpired = false;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    _newPasswordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  bool get _allPasswordHintsMet {
    final pw = _newPasswordController.text;
    if (pw.isEmpty) return false;
    if (pw.length < 8) return false;
    if (!pw.contains(RegExp(r'[A-Za-z]'))) return false;
    if (!pw.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  bool get _passwordsMatch => _confirmController.text == _newPasswordController.text
      && _confirmController.text.isNotEmpty;

  bool get _canReset {
    return _codeController.text.length == 6
        && _allPasswordHintsMet
        && _passwordsMatch
        && !_isSessionExpired;
  }

  Future<void> _onReset() async {
    if (!_canReset) return;
    final supabase = ref.read(supabaseClientProvider);
    final phone = ref.read(authNotifierProvider).phoneNumber ?? '';

    if (phone.isEmpty) {
      setState(() => _isSessionExpired = true);
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
        await KsSuccessMoment.show(context, title: 'PASSWORD RESET');
        if (mounted) context.go(RouteNames.transition);
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

                    // heading changes based on phase
                    Text(
                      _codeEntered ? 'NEW PASSWORD' : 'ENTER RESET CODE',
                      style: TextStyle(
                        fontFamily: 'BarlowSemiCondensed',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: context.ksc.white,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 24),
                    Text(
                      _codeEntered
                          ? 'Create a strong password for your account.'
                          : 'Enter the recovery code sent to your phone.',
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
                      _buildPasswordFields(context),
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
    final borderColor = context.ksc.primary600;
    final hasError = _isSessionExpired;

    final baseDecoration = BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: hasError ? context.ksc.error500 : borderColor.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
    );

    final effectiveOpacity = _isSessionExpired ? 0.3 : 1.0;

    final defaultTheme = PinTheme(
      width: 44,
      height: 52,
      textStyle: TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: context.ksc.white.withValues(alpha: effectiveOpacity),
      ),
      decoration: baseDecoration,
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: baseDecoration.copyWith(
        border: Border(
          bottom: BorderSide(color: context.ksc.accent500, width: 2),
        ),
      ),
    );

    return Center(
      child: Opacity(
        opacity: effectiveOpacity,
        child: Pinput(
          controller: _codeController,
          length: 6,
          readOnly: _isSessionExpired,
          defaultPinTheme: defaultTheme,
          focusedPinTheme: focusedTheme,
          submittedPinTheme: hasError ? defaultTheme : focusedTheme,
          onCompleted: (code) {
            if (!_isSessionExpired) {
              setState(() => _codeEntered = true);
              HapticFeedback.heavyImpact();
            }
          },
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildPasswordFields(BuildContext context) {
    final pw = _newPasswordController.text;
    final minCharsMet = pw.length >= 8;
    final hasLetterMet = pw.contains(RegExp(r'[A-Za-z]'));
    final hasNumberMet = pw.contains(RegExp(r'[0-9]'));
    final matchMet = _passwordsMatch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Password" label
        Text(
          'Password',
          style: TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: context.ksc.neutral400,
          ),
        ),
        const SizedBox(height: 8),
        // New password field — transparent bg + gradient underline
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _newPasswordController,
              focusNode: _newPasswordFocus,
              onChanged: (_) => setState(() {}),
              obscureText: _obscureNew,
              style: AppTextStyles.bodyLarge.copyWith(
                color: context.ksc.white,
                fontWeight: FontWeight.w800,
              ),
              cursorColor: context.ksc.accent500,
              decoration: InputDecoration(
                hintText: 'New password',
                hintStyle: TextStyle(color: context.ksc.neutral600),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? LineAwesomeIcons.eye_solid : LineAwesomeIcons.eye_slash_solid,
                    color: context.ksc.neutral400, size: 20,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
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
          ],
        ),
        const SizedBox(height: 24),
        // "Confirm Password" label
        Text(
          'Confirm Password',
          style: TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: context.ksc.neutral400,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _confirmController,
              focusNode: _confirmFocus,
              onChanged: (_) => setState(() {}),
              obscureText: _obscureConfirm,
              style: AppTextStyles.bodyLarge.copyWith(
                color: context.ksc.white,
                fontWeight: FontWeight.w800,
              ),
              cursorColor: context.ksc.accent500,
              decoration: InputDecoration(
                hintText: 'Confirm new password',
                hintStyle: TextStyle(color: context.ksc.neutral600),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? LineAwesomeIcons.eye_solid : LineAwesomeIcons.eye_slash_solid,
                    color: context.ksc.neutral400, size: 20,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
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
          ],
        ),
        const SizedBox(height: 24),
        // Validation hints
        _hintItem('At least 8 characters', minCharsMet),
        const SizedBox(height: 4),
        _hintItem('Includes a letter', hasLetterMet),
        const SizedBox(height: 4),
        _hintItem('Includes a number', hasNumberMet),
        const SizedBox(height: 4),
        _hintItem('Passwords match', matchMet),
      ],
    );
  }

  Widget _hintItem(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? LineAwesomeIcons.check_circle_solid : Icons.circle,
          size: 12,
          color: met ? context.ksc.success500 : context.ksc.neutral600,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'BarlowSemiCondensed',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: met ? context.ksc.success500 : context.ksc.neutral500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isLoading) {
    return KsButton(
      label: 'RESET PASSWORD',
      variant: KsButtonVariant.cta,
      edgeToEdge: true,
      isLoading: isLoading,
      onPressed: _canReset && !isLoading ? _onReset : null,
    ).animate().fadeIn(delay: 600.ms);
  }
}
