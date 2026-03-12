import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/auth_provider.dart';
import '../providers/auth_notifier.dart';
import '../widgets/auth_header.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _pinController = TextEditingController();
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
    final uiState = ref.read(authNotifierProvider);
    if (uiState.isLoading) return;

    final token = _pinController.text.trim();
    if (token.length != 6) return;

    final success = await ref.read(authNotifierProvider.notifier).verifyOtp(token);
    
    if (!mounted) return;
    if (success) {
      await ref.read(authStateProvider.notifier).refresh();
    } else {
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final phone = authState.phoneNumber ?? '';
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildBackButton(),
                    const SizedBox(height: 32),
                    AuthHeader(
                      icon: LineAwesomeIcons.shield_alt_solid,
                      title: 'Verify your\nnumber',
                      subtitle: 'Code sent to $phone',
                    ),
                    const SizedBox(height: 32),
                    _buildOtpInput(authState.isLoading),
                    const SizedBox(height: 24),
                    _buildResendRow(phone),
                  ],
                ),
              ),
            ),
          ),
          if (!keyboardVisible) _buildBottomBar(authState.isLoading),
        ],
      ),
    );
  }

  Widget _buildBackButton() => GestureDetector(
    onTap: () => context.pop(),
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: const Color(0xFFE0E0E0))
      ),
      child: const Icon(LineAwesomeIcons.angle_left_solid, size: 18, color: AppColors.primary700),
    ),
  );

  Widget _buildOtpInput(bool isLoading) {
    final defaultTheme = PinTheme(
      width: 52, height: 60,
      textStyle: const TextStyle(fontFamily: 'BarlowSemiCondensed', fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary700),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEC)),
      ),
    );

    return Center(
      child: Pinput(
        controller: _pinController,
        length: 6,
        readOnly: isLoading,
        defaultPinTheme: defaultTheme,
        focusedPinTheme: defaultTheme.copyWith(
          decoration: defaultTheme.decoration!.copyWith(
            border: Border.all(color: AppColors.primary700, width: 2),
          ),
        ),
        submittedPinTheme: defaultTheme.copyWith(
          decoration: BoxDecoration(color: AppColors.primary700, borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        onCompleted: (_) => _onVerify(),
      ),
    );
  }

  Widget _buildResendRow(String phone) => Center(
    child: _resendCooldown > 0
        ? Text('Resend code in 0:${_resendCooldown.toString().padLeft(2, '0')}', 
            style: const TextStyle(fontFamily: 'BarlowSemiCondensed', fontWeight: FontWeight.w600, color: Color(0xFF9E9E9E)))
        : GestureDetector(
            onTap: () {
              ref.read(authNotifierProvider.notifier).requestOtp(phone);
              _startCooldown();
            },
            child: const Text('Resend', style: TextStyle(color: Color(0xFFF9A825), fontWeight: FontWeight.w700))
          ),
  );

  Widget _buildBottomBar(bool isLoading) => Container(
    width: double.infinity, color: AppColors.primary700,
    padding: const EdgeInsets.all(AppSpacing.pagePadding),
    child: SafeArea(top: false, child: SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _onVerify,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF9A825)),
        child: isLoading 
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
          : const Text('Verify', style: TextStyle(fontFamily: 'BarlowSemiCondensed', fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary700)),
      ),
    )),
  );
}
