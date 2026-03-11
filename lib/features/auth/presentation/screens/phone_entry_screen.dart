import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_notifier.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _canContinue = false;
  bool _isFocused = false;

  String? _bannerMessage;
  bool _bannerIsError = true;
  late AnimationController _bannerController;
  late Animation<double> _bannerSlide;
  late Animation<double> _bannerFade;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
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
    _controller.dispose();
    _focusNode.dispose();
    _bannerController.dispose();
    super.dispose();
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

  void _onPhoneChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    setState(() => _canContinue = digits.length >= 9);
  }

  Future<void> _onContinue() async {
    _focusNode.unfocus();
    final success = await ref
        .read(authNotifierProvider.notifier)
        .requestOtp(_controller.text.trim());
    if (!mounted) return;
    if (success) {
      context.push(RouteNames.otpVerify);
    } else {
      final err = ref.read(authNotifierProvider).errorMessage;
      _showBanner(err ?? 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

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
                      onTap: () => Navigator.maybePop(context),
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
                        LineAwesomeIcons.mobile_alt_solid,
                        color: Color(0xFFF9A825),
                        size: 28,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Heading
                    Text(
                      'Enter your\nphone number',
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

                    Text(
                      'We will send you a one-time code\nto verify your number.',
                      style: TextStyle(
                        fontFamily: 'BarlowSemiCondensed',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral600,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Feedback banner
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

                    // Phone input label
                    Text(
                      'Phone number',
                      style: TextStyle(
                        fontFamily: 'BarlowSemiCondensed',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutral600,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Phone input — one unified container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isFocused
                              ? AppColors.primary700
                              : const Color(0xFFE0E0E0),
                          width: _isFocused ? 2 : 1,
                        ),
                        boxShadow: _isFocused
                            ? [
                                BoxShadow(
                                  color: AppColors.primary700.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          // Ghana flag + prefix — no border, no decoration
                          Padding(
                            padding: const EdgeInsets.only(left: 14, right: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/flags/gh.svg',
                                  width: 24,
                                  height: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+233',
                                  style: TextStyle(
                                    fontFamily: 'BarlowSemiCondensed',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Number input — fills rest of box
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              onChanged: _onPhoneChanged,
                              autofocus: true,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              onSubmitted: _canContinue
                                  ? (_) => _onContinue()
                                  : null,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              style: TextStyle(
                                fontFamily: 'BarlowSemiCondensed',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral900,
                              ),
                              decoration: InputDecoration(
                                hintText: '024 412 3456',
                                hintStyle: TextStyle(
                                  fontFamily: 'BarlowSemiCondensed',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.neutral400,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),

                          // Gold check / clear icon
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _controller.clear();
                                setState(() => _canContinue = false);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: Icon(
                                  _canContinue
                                      ? LineAwesomeIcons.check_circle
                                      : LineAwesomeIcons.times_circle,
                                  color: _canContinue
                                      ? const Color(0xFFF9A825)
                                      : AppColors.neutral400,
                                  size: 22,
                                ),
                              ),
                            ),
                        ],
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
                        onPressed: _canContinue && !authState.isLoading
                            ? _onContinue
                            : null,
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
                                'Continue',
                                style: TextStyle(
                                  fontFamily: 'BarlowSemiCondensed',
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'By continuing you agree to our Terms of Service.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'BarlowSemiCondensed',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                  onPressed: _canContinue && !authState.isLoading
                      ? _onContinue
                      : null,
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
                    'Continue',
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
