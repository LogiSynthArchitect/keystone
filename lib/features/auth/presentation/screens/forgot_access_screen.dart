import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../providers/auth_notifier.dart';

class ForgotAccessScreen extends ConsumerStatefulWidget {
  const ForgotAccessScreen({super.key});

  @override
  ConsumerState<ForgotAccessScreen> createState() => _ForgotAccessScreenState();
}

class _ForgotAccessScreenState extends ConsumerState<ForgotAccessScreen> {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) return;

    final supabase = ref.read(supabaseClientProvider);
    final fullPhone = '+233$phone';
    ref.read(authNotifierProvider.notifier).setPhoneNumber(fullPhone);

    try {
      await supabase.functions.invoke(
        'send-password-reset',
        body: {'phone': fullPhone},
      );

      if (mounted) context.push(RouteNames.resetPassword);
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('429') || errStr.contains('limit')) {
        ref.read(authNotifierProvider.notifier).setError(
          'Monthly recovery limit reached (2/2). Try again next month.',
        );
      } else if (errStr.contains('NetworkError') || errStr.contains('SocketException')) {
        ref.read(authNotifierProvider.notifier).setError(
          'Network error. Check your connection and try again.',
        );
      } else {
        ref.read(authNotifierProvider.notifier).setError(
          'Recovery failed. Please try again later.',
        );
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
                      'FORGOT ACCESS',
                      style: AppTextStyles.h1.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 24),
                    Text(
                      'Enter your phone number to receive a recovery code.',
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
                    _buildPhoneField(context),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context, authState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context) {
    return Container(
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
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Text('+233', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _focusNode,
              keyboardType: TextInputType.phone,
              style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800),
              cursorColor: context.ksc.accent500,
              decoration: InputDecoration(
                hintText: '024 412 3456',
                hintStyle: TextStyle(color: context.ksc.neutral600),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onSubmitted: (_) => _onSendCode(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildBottomBar(BuildContext context, bool isLoading) {
    final canSend = _phoneController.text.trim().length >= 9;
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
          onTap: canSend && !isLoading ? _onSendCode : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SEND RECOVERY CODE',
                style: AppTextStyles.h2.copyWith(
                  color: canSend ? context.ksc.white : context.ksc.neutral600,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(
                LineAwesomeIcons.angle_right_solid,
                color: canSend ? context.ksc.accent500 : context.ksc.neutral700,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
