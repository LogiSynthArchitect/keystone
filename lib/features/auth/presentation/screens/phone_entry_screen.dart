import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_text_field.dart';
import '../../../../core/widgets/ks_logo.dart';
import '../providers/auth_notifier.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _controller = TextEditingController();
  bool _canContinue = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    setState(() => _canContinue = digits.length >= 9);
  }

  Future<void> _onContinue() async {
    final success = await ref
        .read(authNotifierProvider.notifier)
        .requestOtp(_controller.text.trim());
    if (success && mounted) {
      context.push(RouteNames.otpVerify);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),
              Center(
                child: const KsLogo(size: 120),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Keystone',
                  style: AppTextStyles.display.copyWith(
                    color: AppColors.primary700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text('Welcome back.', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Enter your phone number to continue.',
                style: AppTextStyles.body.copyWith(color: AppColors.neutral600),
              ),
              const SizedBox(height: AppSpacing.xxl),
              KsTextField(
                label: 'Phone number',
                hint: '024 412 3456',
                type: KsTextFieldType.phone,
                controller: _controller,
                onChanged: _onPhoneChanged,
                autofocus: true,
                errorText: authState.errorMessage,
                textInputAction: TextInputAction.done,
                onEditingComplete: _canContinue ? _onContinue : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              KsButton(
                label: 'Continue',
                onPressed: _canContinue && !authState.isLoading ? _onContinue : null,
                isLoading: authState.isLoading,
              ),
              const Spacer(flex: 2),
              Center(
                child: Text(
                  'By continuing you agree to our Terms of Service.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
