import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import 'package:pinput/pinput.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../providers/auth_notifier.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  int _resendCooldown = 30;
  Timer? _timer;
  bool _canVerify = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    if (mounted) setState(() => _resendCooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 0) {
        t.cancel();
      } else if (mounted) {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _onVerify() async {
    if (_pinController.text.length != 6) return;
    final success = await ref.read(authNotifierProvider.notifier).verifyOtp(_pinController.text.trim());
    if (success && mounted) {
      HapticFeedback.heavyImpact();
      context.go(RouteNames.transition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final phone = authState.phoneNumber ?? '';
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final errorMessage = authState.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.primary900,
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
                    _buildBackButton(),
                    const SizedBox(height: 48),

                    // INDUSTRIAL EYEBROW
                    Text(
                      'AUTHORIZATION REQUIRED',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent500,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'VERIFY ACCESS CODE',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 24),
                    
                    Text(
                      'A 6-digit security code has been transmitted to $phone.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.neutral400,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 48),
                    
                    if (errorMessage != null && errorMessage.isNotEmpty) ...[
                      KsBanner(message: errorMessage),
                      const SizedBox(height: 24),
                    ],

                    _buildOtpInput(authState.isLoading),
                    const SizedBox(height: 32),
                    _buildResendRow(phone),
                  ],
                ),
              ),
            ),
            if (!keyboardVisible) _buildBottomBar(authState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() => GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primary700),
          ),
          child: const Icon(LineAwesomeIcons.angle_left_solid, size: 20, color: Colors.white),
        ),
      );

  Widget _buildOtpInput(bool isLoading) {
    final defaultTheme = PinTheme(
      width: 48,
      height: 64,
      textStyle: AppTextStyles.h2.copyWith(
        color: AppColors.white,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary700),
      ),
    );

    return Pinput(
      controller: _pinController,
      focusNode: _focusNode,
      length: 6,
      readOnly: isLoading,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: defaultTheme.copyWith(
        decoration: defaultTheme.decoration!.copyWith(
          border: Border.all(color: AppColors.accent500, width: 2),
        ),
      ),
      separatorBuilder: (index) => const SizedBox(width: 8),
      onChanged: (v) {
        ref.read(authNotifierProvider.notifier).clearError();
        setState(() => _canVerify = v.length == 6);
      },
      onCompleted: (_) => _onVerify(),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildResendRow(String phone) => Row(
        children: [
          Text(
            "Didn't receive the code?  ",
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral400,
              fontWeight: FontWeight.w600,
            ),
          ),
          _resendCooldown > 0
              ? Text(
                  'Wait 0:${_resendCooldown.toString().padLeft(2, '0')}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    ref.read(authNotifierProvider.notifier).requestOtp(phone);
                    _startCooldown();
                  },
                  child: Text(
                    'RESEND',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.accent500,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
        ],
      ).animate().fadeIn(delay: 500.ms);

  Widget _buildBottomBar(bool isLoading) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.primary800,
          border: Border(top: BorderSide(color: AppColors.primary700)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _canVerify && !isLoading ? _onVerify : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VERIFY ACCESS',
                  style: AppTextStyles.h2.copyWith(
                    color: _canVerify ? AppColors.white : AppColors.neutral600,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
                if (isLoading)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent500))
                else
                  Icon(
                    LineAwesomeIcons.angle_right_solid,
                    color: _canVerify ? AppColors.accent500 : AppColors.neutral700,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: 600.ms);
}
