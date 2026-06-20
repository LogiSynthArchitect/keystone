import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import 'package:pinput/pinput.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/widgets/auth_step_header.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/widgets/ks_success_moment.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../providers/auth_notifier.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  static const int _codeExpirySeconds = 90;
  static const int _resendCooldownSeconds = 30;
  static const int _maxResendAttempts = 3;
  int _codeCountdown = _codeExpirySeconds;
  int _resendCooldown = 0;
  int _resendAttempts = 0;
  Timer? _timer;
  Timer? _resendTimer;
  bool _canVerify = false;
  bool _codeExpired = false;

  @override
  void initState() {
    super.initState();
    _startCodeCountdown();
    _pinController.addListener(_onPinChanged);
  }

  @override
  void dispose() {
    _pinController.removeListener(_onPinChanged);
    _pinController.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _onPinChanged() {
    final canVerify = _pinController.text.trim().length == 6;
    if (canVerify != _canVerify) {
      setState(() => _canVerify = canVerify);
    }
  }

  void _startCodeCountdown() {
    _timer?.cancel();
    setState(() {
      _codeCountdown = _codeExpirySeconds;
      _codeExpired = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_codeCountdown <= 0) {
        t.cancel();
        setState(() => _codeExpired = true);
      } else {
        setState(() => _codeCountdown--);
      }
    });
  }

  Future<void> _onVerify() async {
    if (_pinController.text.length != 6 || _codeExpired) return;
    _focusNode.unfocus();
    bool success;
    try {
      success = await ref
          .read(authNotifierProvider.notifier)
          .verifyOtp(_pinController.text.trim())
          .timeout(const Duration(seconds: 15));
    } on TimeoutException catch (_) {
      ref.read(authNotifierProvider.notifier).setError(
        'Connection timed out. Please check your network and try again.',
      );
      return;
    }
    if (success && mounted) {
      HapticFeedback.heavyImpact();
      await KsSuccessMoment.show(context, title: 'VERIFIED');
      if (mounted) context.go(RouteNames.transition);
    }
  }

  Future<void> _onResend() async {
    if (_resendCooldown > 0) return;
    if (_resendAttempts >= _maxResendAttempts) {
      ref.read(authNotifierProvider.notifier).setError(
        'Too many resend attempts. Please wait a few minutes and try again.',
      );
      return;
    }

    final phone = ref.read(authNotifierProvider).phoneNumber ?? '';
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .requestOtp(phone)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException catch (_) {
      ref.read(authNotifierProvider.notifier).setError(
        'Connection timed out. Could not resend code.',
      );
      return;
    }
    _pinController.clear();
    setState(() {
      _canVerify = false;
      _codeExpired = false;
      _resendAttempts++;
      _resendCooldown = _resendCooldownSeconds;
    });
    _startCodeCountdown();
    _startResendCooldown();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_resendCooldown <= 0) {
        t.cancel();
        setState(() {});
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final phone = authState.phoneNumber ?? '';
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final errorMessage = authState.errorMessage;
    final isExpiredState = _codeExpired;
    final hasError = errorMessage != null && errorMessage.isNotEmpty;

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
                        currentStep: 1,
                        icon: LineAwesomeIcons.shield_alt_solid,
                        stepLabel: 'VERIFY',
                        subStep: 0,
                        subSteps: 1,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // heading
                    Text(
                      'ENTER VERIFICATION CODE',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h1.copyWith(
                        color: context.ksc.white,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 6),

                    // phone subtitle — "Sent to +233 24 123 4567"
                    Text(
                      'Sent to $phone',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'BarlowSemiCondensed',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.ksc.neutral400,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 28),

                    // Banner (error states)
                    if (hasError) ...[
                      KsBanner(
                        message: errorMessage,
                        type: KsBannerType.alert,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // OTP input
                    _buildOtpInput(context, authState.isLoading, isExpiredState, hasError),
                    const SizedBox(height: 20),

                    // Resend / countdown area
                    Center(child: _buildCountdownOrResend(context)),
                  ],
                ),
              ),
            ),
            if (!keyboardVisible)
              KsButton(
                label: 'VERIFY',
                variant: KsButtonVariant.cta,
                onPressed: _canVerify && !authState.isLoading && !isExpiredState
                    ? _onVerify
                    : null,
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
            border:
                Border.all(color: context.ksc.primary700.withValues(alpha: 0.3)),
          ),
          child: Icon(LineAwesomeIcons.angle_left_solid,
              size: 18, color: context.ksc.white),
        ),
      );

  Widget _buildOtpInput(
      BuildContext context, bool isLoading, bool isExpired, bool hasError) {
    final borderColor = context.ksc.primary600;
    final errorColor = context.ksc.error500;
    final accentColor = context.ksc.accent500;

    final effectiveOpacity = isExpired ? 0.3 : 1.0;

    final baseDecoration = BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: hasError ? errorColor : borderColor.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
    );

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
          bottom: BorderSide(color: accentColor, width: 2),
        ),
      ),
    );

    final errorTheme = defaultTheme.copyWith(
      decoration: baseDecoration.copyWith(
        border: Border(
          bottom: BorderSide(color: errorColor, width: 2),
        ),
      ),
    );

    return Center(
      child: Opacity(
        opacity: effectiveOpacity,
        child: Pinput(
          controller: _pinController,
          focusNode: _focusNode,
          length: 6,
          readOnly: isLoading || isExpired,
          defaultPinTheme: defaultTheme,
          focusedPinTheme: focusedTheme,
          submittedPinTheme: hasError ? errorTheme : focusedTheme,
          separatorBuilder: (_) => const SizedBox(width: 10),
          onChanged: (_) {},
          onCompleted: isExpired ? null : (_) => _onVerify(),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildCountdownOrResend(BuildContext context) {
    final codeActive = _codeCountdown > 0 && !_codeExpired;
    final canResend = _resendCooldown <= 0 && _resendAttempts < _maxResendAttempts;

    if (codeActive || (!canResend && _resendCooldown > 0)) {
      // Show whichever countdown is longer: code expiry or resend cooldown
      final displayCountdown = codeActive ? _codeCountdown : _resendCooldown;
      final label = codeActive ? 'Code expires in ' : 'Resend available in ';
      final min = (displayCountdown ~/ 60).toString().padLeft(2, '0');
      final sec = (displayCountdown % 60).toString().padLeft(2, '0');
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'BarlowSemiCondensed',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.ksc.neutral500,
            ),
          ),
          Text(
            '$min:$sec',
            style: TextStyle(
              fontFamily: 'BarlowSemiCondensed',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.ksc.accent500,
            ),
          ),
        ],
      ).animate().fadeIn(delay: 500.ms);
    }

    // "Code expired? RESEND CODE" — link is accent
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Code expired? ',
              style: TextStyle(
                fontFamily: 'BarlowSemiCondensed',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.ksc.neutral500,
              ),
            ),
            GestureDetector(
              onTap: canResend ? _onResend : null,
              child: Text(
                'RESEND CODE',
                style: TextStyle(
                  fontFamily: 'BarlowSemiCondensed',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: canResend ? context.ksc.accent500 : context.ksc.neutral600,
                ),
              ),
            ),
          ],
        ),
        if (_resendAttempts >= _maxResendAttempts) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.pop(),
            child: Text(
              'USE A DIFFERENT NUMBER',
              style: TextStyle(
                fontFamily: 'BarlowSemiCondensed',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: context.ksc.accent500,
              ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 500.ms);
  }
}
