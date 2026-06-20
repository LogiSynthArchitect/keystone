import 'dart:async' show TimeoutException;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/config/dev_mode.dart';
import '../../../../core/widgets/auth_step_header.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_success_moment.dart';
import '../../../../core/widgets/ks_logo.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../providers/auth_notifier.dart';
import '../providers/dev_auth_provider.dart';
import '../../../../core/widgets/focus_safe_text_field.dart';

/// Ghana flag emoji constant to avoid the SVG import.
const _ghanaFlag = '\u{1F1EC}\u{1F1ED}';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  String _phone = '';
  String _initialPhone = '';

  @override
  void initState() {
    super.initState();

    // DEV_MODE auto-fill phone
    if (kDevMode) {
      final devPhone = ref.read(devAutoFillPhoneProvider);
      if (devPhone != null && devPhone.isNotEmpty) {
        _initialPhone = devPhone;
        _phone = devPhone;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).reset();
    });
  }

  bool get _canContinue =>
      _phone.trim().length == 10 ||
      _phone.trim().length == 9;

  void _onPhoneChanged(String value) {
    _phone = value;
    ref.read(authNotifierProvider.notifier).clearError();
  }

  Future<void> _onContinue() async {
    final raw = _phone.trim();
    if (!_canContinue) return;

    final normalized = PhoneFormatter.normalize(raw);
    String? route;
    try {
      route = await ref
          .read(authNotifierProvider.notifier)
          .checkAuthState(normalized)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException catch (_) {
      if (mounted) {
        ref.read(authNotifierProvider.notifier).setError(
          'Connection timed out. Please check your network and try again.',
        );
      }
      return;
    }
    if (route != null && mounted) {
      if (route == RouteNames.otpVerify) {
        await KsSuccessMoment.show(
          context,
          title: 'VERIFICATION CODE SENT',
          subtitle: 'Sent to +233${raw.replaceFirst(RegExp(r'^0'), '')}',
        );
      }
      if (mounted) context.push(route);
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
                    const SizedBox(height: 20),

                    // Brand logo
                    const Center(child: KsLogo(size: 32)),

                    const SizedBox(height: 20),

                    // Step ring header
                    const Center(
                      child: AuthStepHeader(
                        totalSteps: 4,
                        currentStep: 0,
                        icon: LineAwesomeIcons.mobile_alt_solid,
                        stepLabel: 'PHONE',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Heading — "ENTER YOUR PHONE"
                    Text(
                      'ENTER YOUR PHONE',
                      style: TextStyle(
                        fontFamily: 'BarlowSemiCondensed',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: context.ksc.white,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "We'll send a verification code to get started.",
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.ksc.neutral400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Error banner
                    if (errorMessage != null && errorMessage.isNotEmpty) ...[
                      KsBanner(message: errorMessage),
                      const SizedBox(height: 16),
                    ],

                    _buildPhoneInput(context),
                  ],
                ),
              ),
            ),
            // Bottom bar — edge-to-edge KsButton(cta)
            if (!keyboardVisible)
              KsButton(
                label: 'CONTINUE',
                onPressed: _canContinue && !authState.isLoading
                    ? _onContinue
                    : null,
                variant: KsButtonVariant.cta,
                isLoading: authState.isLoading,
                edgeToEdge: true,
              ),
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
          child:
              Icon(LineAwesomeIcons.angle_left_solid, size: 18, color: context.ksc.white),
        ),
      );

  Widget _buildPhoneInput(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSafeTextField(
            initialText: _initialPhone.isNotEmpty ? _initialPhone : null,
            label: 'Phone Number',
            hint: '024 123 4567',
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (v) => _onPhoneChanged(v),
            prefix: Container(
              padding: const EdgeInsets.only(right: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _ghanaFlag,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+233',
                    style: TextStyle(
                      fontFamily: 'BarlowSemiCondensed',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: context.ksc.white,
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
          ),
          const SizedBox(height: 14),
          Text(
            "We'll send a one-time SMS to this number.",
            style: TextStyle(
              fontFamily: 'BarlowSemiCondensed',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: context.ksc.neutral400,
            ),
          ),
        ],
      );
}
