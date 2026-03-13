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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.8, -0.8),
                radius: 1.5,
                colors: [Color(0xFF1E3F7A), AppColors.primary900],
              ),
            ),
          ),
          SafeArea(
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
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary700,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.accent500.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(LineAwesomeIcons.mobile_alt_solid, size: 24, color: AppColors.accent500),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'ENTER PHONE NUMBER',
                              style: AppTextStyles.h2.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                        const SizedBox(height: 24),
                        Text(
                          'Provide your credentials to access the business backbone.',
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
        ],
      ),
    );
  }

  Widget _buildBackButton() => GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary700.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
            color: _isFocused ? AppColors.accent500 : Colors.white.withValues(alpha: 0.1),
            width: _isFocused ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 2),
              blurRadius: 4,
              spreadRadius: -1,
            ),
          ],
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
                ),
                cursorColor: AppColors.accent500,
                decoration: InputDecoration(
                  hintText: '024 412 3456',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
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

  Widget _buildBottomBar(bool isLoading) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary700,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        padding: const EdgeInsets.all(24.0),
        child: InkWell(
          onTap: _canContinue && !isLoading ? _onContinue : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CONTINUE',
                style: AppTextStyles.h2.copyWith(
                  color: _canContinue ? AppColors.white : Colors.white.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              if (isLoading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent500))
              else
                Icon(
                  Icons.arrow_forward,
                  color: _canContinue ? AppColors.accent500 : Colors.white.withValues(alpha: 0.1),
                ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 600.ms);
}
