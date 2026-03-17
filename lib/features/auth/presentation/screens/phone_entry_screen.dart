import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_banner.dart';
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

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
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
    final success = await ref.read(authNotifierProvider.notifier).requestOtp(_controller.text.trim());
    if (success && mounted) context.push(RouteNames.otpVerify);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
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
                      'SECURE ACCESS',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent500,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'INITIALIZE BACKBONE',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Provide your phone number to authorize this terminal.',
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

                    _buildPhoneInput(),
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
          decoration: const BoxDecoration(
            color: AppColors.primary800,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            border: Border(
              top: BorderSide(color: AppColors.primary700),
              bottom: BorderSide(color: AppColors.primary700),
              left: BorderSide(color: AppColors.primary700),
              right: BorderSide(color: AppColors.primary700),
            ),
          ),
          child: const Icon(LineAwesomeIcons.angle_left_solid, size: 20, color: Colors.white),
        ),
      );

  Widget _buildPhoneInput() => Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _isFocused ? AppColors.accent500 : AppColors.primary700,
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
                      color: AppColors.white,
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
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 2.0,
                ),
                cursorColor: AppColors.accent500,
                decoration: const InputDecoration(
                  hintText: '024 412 3456',
                  hintStyle: TextStyle(color: AppColors.neutral600),
                  contentPadding: EdgeInsets.only(right: 16),
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
            onTap: _canContinue && !isLoading ? _onContinue : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CONTINUE',
                  style: AppTextStyles.h2.copyWith(
                    color: _canContinue ? AppColors.white : AppColors.neutral600,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
                if (isLoading)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent500))
                else
                  Icon(
                    LineAwesomeIcons.angle_right_solid,
                    color: _canContinue ? AppColors.accent500 : AppColors.neutral700,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: 600.ms);
}
