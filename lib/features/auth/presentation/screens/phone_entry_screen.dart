import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_notifier.dart';
import '../widgets/auth_header.dart';

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
    final digits = value.replaceAll(RegExp(r'\D'), '');
    setState(() => _canContinue = digits.length >= 9);
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
                    const AuthHeader(
                      icon: LineAwesomeIcons.mobile_alt_solid,
                      title: 'Enter your\nphone number',
                      subtitle: 'We will send you a one-time code\nto verify your number.',
                    ),
                    const SizedBox(height: 32),
                    _buildPhoneInput(),
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
        onTap: () => Navigator.maybePop(context),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: const Icon(LineAwesomeIcons.angle_left_solid, size: 18, color: AppColors.primary700),
        ),
      );

  Widget _buildPhoneInput() => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isFocused ? AppColors.primary700 : const Color(0xFFEAEAEC), width: _isFocused ? 2 : 1),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                SvgPicture.asset('assets/flags/gh.svg', width: 24),
                const SizedBox(width: 8),
                const Text('+233', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary700)),
              ]),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onPhoneChanged,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '024 412 3456', border: InputBorder.none),
              ),
            ),
          ],
        ),
      );

  Widget _buildBottomBar(bool isLoading) => Container(
        width: double.infinity, color: AppColors.primary700,
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: SafeArea(top: false, child: SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: _canContinue && !isLoading ? _onContinue : null,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF9A825)),
            child: isLoading 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text('Continue'),
          ),
        )),
      );
}
