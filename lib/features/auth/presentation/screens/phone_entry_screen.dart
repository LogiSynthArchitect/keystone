import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../providers/auth_notifier.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _canContinue = false;
  bool _isFocused = false;
  int _devTapCount = 0;
  bool _showDevBypass = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).reset();
    });
  }

  void _onPhoneChanged(String value) {
    ref.read(authNotifierProvider.notifier).clearError();

    if (value.isEmpty) {
      setState(() => _canContinue = false);
      return;
    }

    final bool startsWithZero = value.startsWith('0');
    final int requiredLength = startsWithZero ? 10 : 9;

    setState(() => _canContinue = value.length == requiredLength);
  }

  Future<void> _onContinue() async {
    _focusNode.unfocus();
    final phone = _controller.text.trim();
    if (!_canContinue) return;

    final normalized = '+233$phone';
    ref.read(authNotifierProvider.notifier).setPhoneNumber(normalized);

    try {
      final strategy = await ref.read(supabaseClientProvider).rpc(
        'get_auth_strategy',
        params: {'p_phone': normalized},
      ) as String?;

      if (!mounted) return;

      switch (strategy) {
        case 'NEW_USER':
          context.push(RouteNames.createPassword);
        case 'PASSWORD_USER':
          context.push(RouteNames.passwordEntry);
        case 'OTP_USER':
          final success = await ref.read(authNotifierProvider.notifier).requestOtp(phone);
          if (success && mounted) context.push(RouteNames.otpVerify);
        default:
          context.push(RouteNames.createPassword);
      }
    } catch (_) {
      if (mounted) {
        ref.read(authNotifierProvider.notifier).setError(
          'Network error. Check your connection and try again.',
        );
      }
    }
  }

  Future<void> _onDevBypass() async {
    _focusNode.unfocus();
    final phone = _controller.text.trim();
    if (phone.isEmpty) return;

    final normalized = '+233$phone';
    ref.read(authNotifierProvider.notifier).setPhoneNumber(normalized);

    final success = await ref.read(authNotifierProvider.notifier).bypassOtp(normalized);
    if (success && mounted) {
      context.pushReplacement(RouteNames.initialSync);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
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

                    // INDUSTRIAL EYEBROW
                    Text(
                      'SECURE ACCESS',
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.accent500,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: () {
                        _devTapCount++;
                        if (_devTapCount >= 5) {
                          setState(() => _showDevBypass = true);
                          _devTapCount = 0;
                        }
                      },
                      child: Text(
                        'SIGN IN',
                        style: AppTextStyles.h1.copyWith(
                          color: context.ksc.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 24),

                    Text(
                      'Enter your phone number to sign in or create an account.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.ksc.neutral400,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    if (_showDevBypass) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _onDevBypass(),
                          icon: const Icon(Icons.developer_mode, size: 18),
                          label: const Text('DEV BYPASS (TEMP)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ).animate().fadeIn(),
                    ],

                    const SizedBox(height: 48),

                    if (errorMessage != null && errorMessage.isNotEmpty) ...[
                      KsBanner(message: errorMessage),
                      const SizedBox(height: 24),
                    ],

                    _buildPhoneInput(context),
                    const SizedBox(height: 24),
                    _buildPasswordLink(context),
                  ],
                ),
              ),
            ),
            if (!keyboardVisible) _buildBottomBar(context, authState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) => GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            border: Border(
              top: BorderSide(color: context.ksc.primary700),
              bottom: BorderSide(color: context.ksc.primary700),
              left: BorderSide(color: context.ksc.primary700),
              right: BorderSide(color: context.ksc.primary700),
            ),
          ),
          child: Icon(LineAwesomeIcons.angle_left_solid, size: 20, color: context.ksc.white),
        ),
      );

  Widget _buildPhoneInput(BuildContext context) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _isFocused ? context.ksc.accent500 : context.ksc.primary700,
            width: _isFocused ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                children: [
                  SvgPicture.asset('assets/flags/gh.svg', width: 24),
                  const SizedBox(width: 12),
                  Text(
                    '+233',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onPhoneChanged,
                keyboardType: TextInputType.text,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: AppTextStyles.bodyLarge.copyWith(
                  color: context.ksc.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 2.0,
                ),
                cursorColor: context.ksc.accent500,
                decoration: InputDecoration(
                  hintText: '024 412 3456',
                  hintStyle: TextStyle(color: context.ksc.neutral600),
                  contentPadding: const EdgeInsets.only(right: 16),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);

  Widget _buildPasswordLink(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => context.push(RouteNames.passwordEntry),
            child: Text(
              'SIGN IN WITH PASSWORD',
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.accent500,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              final phone = _controller.text.trim();
              if (phone.isNotEmpty) {
                ref.read(authNotifierProvider.notifier).setPhoneNumber('+233$phone');
              }
              context.push(RouteNames.otpVerify);
            },
            child: Text(
              'Need help? Login with OTP',
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildBottomBar(BuildContext context, bool isLoading) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          border: Border(top: BorderSide(color: context.ksc.primary700)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _canContinue && !isLoading ? _onContinue : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CONTINUE',
                  style: AppTextStyles.h2.copyWith(
                    color: _canContinue ? context.ksc.white : context.ksc.neutral600,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
                if (isLoading)
                  SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: context.ksc.accent500))
                else
                  Icon(
                    LineAwesomeIcons.angle_right_solid,
                    color: _canContinue ? context.ksc.accent500 : context.ksc.neutral700,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: 600.ms);
}
