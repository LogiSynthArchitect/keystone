import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_success_moment.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../providers/auth_notifier.dart';
import '../../../../core/widgets/focus_safe_text_field.dart';

const _ghanaFlag = '\u{1F1EC}\u{1F1ED}';

class ForgotAccessScreen extends ConsumerStatefulWidget {
  const ForgotAccessScreen({super.key});

  @override
  ConsumerState<ForgotAccessScreen> createState() => _ForgotAccessScreenState();
}

class _ForgotAccessScreenState extends ConsumerState<ForgotAccessScreen> {
  String _phone = '';

  bool get _canSend => _phone.trim().length >= 9;

  Future<void> _onSendCode() async {
    if (!_canSend) return;

    final phone = _phone.trim();
    final supabase = ref.read(supabaseClientProvider);
    final fullPhone = PhoneFormatter.isValid(phone) ? PhoneFormatter.normalize(phone) : '+233$phone';
    ref.read(authNotifierProvider.notifier).setPhoneNumber(fullPhone);

    try {
      await supabase.functions.invoke(
        'send-password-reset',
        body: {'phone': fullPhone},
      );

      if (mounted) {
        await KsSuccessMoment.show(context, title: 'RECOVERY CODE SENT');
        if (mounted) context.push(RouteNames.resetPassword);
      }
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
    final isLoading = authState.isLoading;

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

                    // heading — "RECOVER ACCESS"
                    Text(
                      'RECOVER ACCESS',
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
                      'Enter your phone number to receive a recovery code.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.ksc.neutral400,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    if (errorMessage != null && errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      KsBanner(message: errorMessage),
                    ],

                    const SizedBox(height: 32),
                    _buildPhoneInput(context),
                    const SizedBox(height: 16),

                    // "Not you?" link — left-aligned, neutral, underlined
                    GestureDetector(
                      onTap: () => context.go(RouteNames.phoneEntry),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'NOT YOU?',
                          style: TextStyle(
                            fontFamily: 'BarlowSemiCondensed',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.ksc.neutral500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context, isLoading),
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
            border: Border.all(color: context.ksc.primary700.withValues(alpha: 0.3)),
          ),
          child: Icon(LineAwesomeIcons.angle_left_solid, size: 18, color: context.ksc.white),
        ),
      );

  Widget _buildPhoneInput(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSafeTextField(
            label: 'Phone Number',
            hint: '024 412 3456',
            keyboardType: TextInputType.phone,
            onChanged: (v) => setState(() => _phone = v),
            onSubmitted: (_) => _onSendCode(),
            prefix: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _ghanaFlag,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 8),
                Text(
                  '+233',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.ksc.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  LineAwesomeIcons.angle_down_solid,
                  size: 12,
                  color: context.ksc.neutral400,
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);

  Widget _buildBottomBar(BuildContext context, bool isLoading) {
    return KsButton(
      label: 'SEND RECOVERY CODE',
      variant: KsButtonVariant.cta,
      edgeToEdge: true,
      isLoading: isLoading,
      onPressed: _canSend && !isLoading ? _onSendCode : null,
    ).animate().fadeIn(delay: 600.ms);
  }
}
