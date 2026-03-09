import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_button.dart';
import '../providers/auth_notifier.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _pinController = TextEditingController();
  bool _hasError = false;
  int _resendCooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 0) {
        t.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _onVerify() async {
    final token = _pinController.text.trim();
    if (token.length != 6) return;

    setState(() => _hasError = false);
    final success =
        await ref.read(authNotifierProvider.notifier).verifyOtp(token);

    if (!mounted) return;
    if (success) {
      final authState = ref.read(authNotifierProvider);
      if (authState.errorMessage == null) {
        context.go(RouteNames.onboarding);
      }
    } else {
      setState(() => _hasError = true);
      _pinController.clear();
    }
  }

  Future<void> _onResend() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.phoneNumber == null) return;
    await ref
        .read(authNotifierProvider.notifier)
        .requestOtp(authState.phoneNumber!);
    setState(() => _resendCooldown = 30);
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final phone = authState.phoneNumber ?? '';

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: AppTextStyles.h2,
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.neutral300),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Enter the code.', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We sent a 6-digit code to $phone.',
                style: AppTextStyles.body.copyWith(color: AppColors.neutral600),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Pinput(
                  controller: _pinController,
                  length: 6,
                  autofocus: true,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(
                          color: AppColors.primary600, width: 1.5),
                    ),
                  ),
                  errorPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(
                          color: AppColors.error500, width: 1.5),
                    ),
                  ),
                  forceErrorState: _hasError,
                  onCompleted: (_) => _onVerify(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              KsButton(
                label: 'Verify',
                onPressed: !authState.isLoading ? _onVerify : null,
                isLoading: authState.isLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: _resendCooldown > 0
                    ? Text(
                        'Resend in 0:${_resendCooldown.toString().padLeft(2, '0')}',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.neutral400),
                      )
                    : TextButton(
                        onPressed: _onResend,
                        child: Text('Resend code',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.primary600)),
                      ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
