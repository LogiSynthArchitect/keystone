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

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen>
    with SingleTickerProviderStateMixin {
  final _pinController = TextEditingController();
  int _resendCooldown = 30;
  Timer? _timer;

  // Banner
  String? _bannerMessage;
  bool _bannerIsError = true;
  late AnimationController _bannerController;
  late Animation<double> _bannerSlide;
  late Animation<double> _bannerFade;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bannerSlide = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(parent: _bannerController, curve: Curves.easeOut),
    );
    _bannerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bannerController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    if (mounted) setState(() => _resendCooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 0) {
        t.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  void _showBanner(String message, {bool isError = true}) {
    setState(() {
      _bannerMessage = message;
      _bannerIsError = isError;
    });
    _bannerController.forward(from: 0);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismissBanner();
    });
  }

  void _dismissBanner() {
    _bannerController.reverse().then((_) {
      if (mounted) setState(() => _bannerMessage = null);
    });
  }

  Future<void> _onVerify() async {
    final token = _pinController.text.trim();
    if (token.length != 6) return;
    final success =
        await ref.read(authNotifierProvider.notifier).verifyOtp(token);
    if (!mounted) return;
    if (success) {
      await ref.read(authStateProvider.notifier).refresh();
    } else {
      _pinController.clear();
      final err = ref.read(authNotifierProvider).errorMessage;
      _showBanner(err ?? 'Invalid code. Please try again.');
    }
  }

  Future<void> _onResend() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.phoneNumber == null) return;
    await ref
        .read(authNotifierProvider.notifier)
        .requestOtp(authState.phoneNumber!);
    _startCooldown();
    _showBanner('Code resent successfully.', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final phone = authState.phoneNumber ?? '';
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // Pin themes
    final defaultTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(
        fontFamily: 'BarlowSemiCondensed',
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCCCCCC), width: 1.5),
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary700, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary700.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final filledTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: AppColors.primary700,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary700, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [

          // ── TOP ───────────────────────────────────────────
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Back button
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFE0E0E0), width: 1),
                        ),
                        child: Icon(
                          LineAwesomeIcons.angle_left_solid,
                          size: 18,
                          color: AppColors.primary700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Icon badge
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LineAwesomeIcons.shield_alt_solid,
                        color: Color(0xFFF9A825),
                        size: 28,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Heading
                    Text(
                      'Verify your\nnumber',
                      style: TextStyle(
                        fontFamily: 'BarlowSemiCondensed',
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary700,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 10),

                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'BarlowSemiCondensed',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF757575),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Code sent to '),
                          TextSpan(
                            text: phone,
                            style: TextStyle(
                              color: AppColors.primary700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Banner
                    if (_bannerMessage != null)
                      AnimatedBuilder(
                        animation: _bannerController,
                        builder: (context, child) => Opacity(
                          opacity: _bannerFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _bannerSlide.value),
                            child: child,
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _bannerIsError
                                ? const Color(0xFFFFEBEB)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _bannerIsError
                                  ? const Color(0xFFE57373)
                                  : const Color(0xFF66BB6A),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _bannerIsError
                                    ? LineAwesomeIcons.exclamation_circle_solid
                                    : LineAwesomeIcons.check_circle,
                                color: _bannerIsError
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF43A047),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _bannerMessage!,
                                  style: TextStyle(
                                    fontFamily: 'BarlowSemiCondensed',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _bannerIsError
                                        ? const Color(0xFFB71C1C)
                                        : const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _dismissBanner,
                                child: Icon(
                                  LineAwesomeIcons.times_solid,
                                  size: 16,
                                  color: _bannerIsError
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFF43A047),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // OTP boxes
                    Center(
                      child: Pinput(
                        controller: _pinController,
                        length: 6,
                        autofocus: true,
                        defaultPinTheme: defaultTheme,
                        focusedPinTheme: focusedTheme,
                        submittedPinTheme: filledTheme,
                        onCompleted: (_) => _onVerify(),
                        separatorBuilder: (_) => const SizedBox(width: 8),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Resend
                    Center(
                      child: _resendCooldown > 0
                          ? RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'BarlowSemiCondensed',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9E9E9E),
                                ),
                                children: [
                                  const TextSpan(text: 'Resend code in '),
                                  TextSpan(
                                    text:
                                        '0:${_resendCooldown.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: AppColors.primary700,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GestureDetector(
                              onTap: _onResend,
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontFamily: 'BarlowSemiCondensed',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF9E9E9E),
                                  ),
                                  children: [
                                    TextSpan(text: "Didn't receive a code? "),
                                    TextSpan(
                                      text: 'Resend',
                                      style: TextStyle(
                                        color: Color(0xFFF9A825),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // ── BOTTOM navy ────────────────────────────────────
          if (!keyboardVisible)
            Container(
              width: double.infinity,
              color: AppColors.primary700,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: !authState.isLoading ? _onVerify : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF9A825),
                          foregroundColor: AppColors.primary700,
                          disabledBackgroundColor:
                              const Color(0xFFF9A825).withOpacity(0.4),
                          disabledForegroundColor:
                              AppColors.primary700.withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Verify',
                                style: TextStyle(
                                  fontFamily: 'BarlowSemiCondensed',
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

          // Keyboard visible — floating button
          if (keyboardVisible)
            Container(
              color: const Color(0xFFFAFAF8),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: !authState.isLoading ? _onVerify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary700.withOpacity(0.3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Verify',
                    style: TextStyle(
                      fontFamily: 'BarlowSemiCondensed',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
