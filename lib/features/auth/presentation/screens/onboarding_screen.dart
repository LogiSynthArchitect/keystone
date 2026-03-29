import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../providers/auth_notifier.dart';

class _ServiceData {
  final String type;
  final String label;
  final String image;
  _ServiceData(this.type, this.label, this.image);
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  int _step = 0;
  final List<String> _selectedServices = [];
  bool _nameFocused = false;

  final List<_ServiceData> _services = [
    _ServiceData('car_lock_programming', 'CAR KEY\nPROGRAMMING', 'assets/services/car_key.png'),
    _ServiceData('door_lock_installation', 'DOOR LOCK\nINSTALLATION', 'assets/services/door_install.png'),
    _ServiceData('door_lock_repair', 'DOOR LOCK\nREPAIR', 'assets/services/door_repair.png'),
    _ServiceData('smart_lock_installation', 'SMART LOCK\nINSTALLATION', 'assets/services/smart_lock.png'),
  ];

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() => setState(() => _nameFocused = _nameFocusNode.hasFocus));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  bool get _isValidName => _nameController.text.trim().length >= 2;
  bool get _canContinue => _step == 0 ? _isValidName : _selectedServices.isNotEmpty;

  Future<void> _onContinue() async {
    ref.read(authNotifierProvider.notifier).clearError();

    if (_step == 0) {
      if (!_isValidName) return;
      _nameFocusNode.unfocus();
      setState(() => _step = 1);
    } else {
      final success = await ref.read(authNotifierProvider.notifier).completeOnboarding(
            name: _nameController.text.trim(),
            services: _selectedServices,
          );

      if (success && mounted) {
        await ref.read(authStateProvider.notifier).refresh();
        if (mounted) context.go(RouteNames.transition);
      }
    }
  }

  void _onNameChanged(String value) {
    ref.read(authNotifierProvider.notifier).clearError();
    setState(() {}); // Update button state
  }

  void _toggleService(String type) {
    ref.read(authNotifierProvider.notifier).clearError();
    setState(() {
      if (_selectedServices.contains(type)) {
        _selectedServices.remove(type);
      } else {
        _selectedServices.add(type);
      }
    });
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

                    // Animated Step Content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _step == 0
                          ? _buildNameStep(context, key: const ValueKey('step0'))
                          : _buildServicesStep(context, key: const ValueKey('step1')),
                    ),

                    // Error Banner
                    if (errorMessage != null && errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      KsBanner(message: errorMessage),
                    ],

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),

            // Bottom Bar (Hidden when keyboard is open)
            if (!keyboardVisible) _buildBottomBar(context, authState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    if (_step == 0) return const SizedBox(width: 44, height: 44);

    return GestureDetector(
      onTap: () => setState(() => _step = 0),
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
  }

  Widget _buildStepIndicator(BuildContext context) => Row(
        children: [
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: context.ksc.accent500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: _step == 1 ? context.ksc.accent500 : context.ksc.primary800,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      );

  Widget _buildNameStep(BuildContext context, {Key? key}) => Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // INDUSTRIAL EYEBROW
          Text(
            'ONBOARDING PHASE 01',
            style: AppTextStyles.caption.copyWith(
              color: context.ksc.accent500,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),

          const SizedBox(height: 8),

          Text(
            'IDENTIFY YOURSELF',
            style: AppTextStyles.h1.copyWith(
              color: context.ksc.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),

          const SizedBox(height: 24),
          Text('This name will be displayed on your professional profile.',
              style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),
          _buildStepIndicator(context),
          const SizedBox(height: 48),

          Container(
            height: 72,
            decoration: BoxDecoration(
              color: context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _nameFocused ? context.ksc.accent500 : context.ksc.primary700,
                width: _nameFocused ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              onChanged: _onNameChanged,
              textCapitalization: TextCapitalization.words,
              style: AppTextStyles.bodyLarge.copyWith(
                color: context.ksc.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 1.0,
              ),
              cursorColor: context.ksc.accent500,
              decoration: InputDecoration(
                hintText: 'Jeremie Mensah',
                hintStyle: TextStyle(color: context.ksc.neutral600),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
              ),
              onSubmitted: (_) => _onContinue(),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
        ],
      );

  Widget _buildServicesStep(BuildContext context, {Key? key}) => Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // INDUSTRIAL EYEBROW
          Text(
            'ONBOARDING PHASE 02',
            style: AppTextStyles.caption.copyWith(
              color: context.ksc.accent500,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn().slideX(begin: -0.1, end: 0),

          const SizedBox(height: 8),

          Text(
            'SELECT CAPABILITIES',
            style: AppTextStyles.h1.copyWith(
              color: context.ksc.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),

          const SizedBox(height: 24),
          Text('Identify the specialized services you provide.',
              style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),
          _buildStepIndicator(context),
          const SizedBox(height: 48),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: _services.map((service) {
              final isSelected = _selectedServices.contains(service.type);
              return GestureDetector(
                onTap: () => _toggleService(service.type),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? context.ksc.accent500 : context.ksc.primary700,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(service.image, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0.8)],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Text(
                            service.label,
                            style: AppTextStyles.label.copyWith(
                              color: context.ksc.white,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: context.ksc.accent500, shape: BoxShape.circle),
                              child: Icon(LineAwesomeIcons.check_solid, size: 12, color: context.ksc.primary900),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
        ],
      );

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
                  _step == 0 ? 'CONTINUE' : 'COMPLETE SETUP',
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
      ).animate().fadeIn(delay: 400.ms);
}
