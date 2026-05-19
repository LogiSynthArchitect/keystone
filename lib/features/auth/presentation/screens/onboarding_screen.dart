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
import '../../../../core/utils/icon_helpers.dart';
import '../../../service_types/presentation/providers/service_type_provider.dart';
import '../../../service_types/domain/entities/service_type_entity.dart';
import '../providers/auth_notifier.dart';

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
    setState(() {});
  }

  void _toggleService(String name) {
    ref.read(authNotifierProvider.notifier).clearError();
    setState(() {
      if (_selectedServices.contains(name)) {
        _selectedServices.remove(name);
      } else {
        _selectedServices.add(name);
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

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _step == 0
                          ? _buildNameStep(context, key: const ValueKey('step0'))
                          : _buildServicesStep(context, key: const ValueKey('step1')),
                    ),

                    if (errorMessage != null && errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      KsBanner(message: errorMessage),
                    ],

                    const SizedBox(height: 48),
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

  Widget _buildServicesStep(BuildContext context, {Key? key}) {
    final serviceTypesAsync = ref.watch(serviceTypeProvider);

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Text('Select the services you provide. You can customize these later.',
            style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
        _buildStepIndicator(context),
        const SizedBox(height: 48),

        serviceTypesAsync.when(
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          )),
          error: (err, _) => Center(
            child: Text('Failed to load services',
                style: AppTextStyles.caption.copyWith(color: context.ksc.error500)),
          ),
          data: (types) {
            final grouped = _groupByCategory(types);
            return ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.accent500,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ...entry.value.map((type) => _serviceTile(type)),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Map<String, List<ServiceTypeEntity>> _groupByCategory(List<ServiceTypeEntity> types) {
    final map = <String, List<ServiceTypeEntity>>{};
    for (final t in types) {
      map.putIfAbsent(t.category, () => []).add(t);
    }
    return map;
  }

  Widget _serviceTile(ServiceTypeEntity type) {
    final isSelected = _selectedServices.contains(type.name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _toggleService(type.name),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? context.ksc.accent500.withValues(alpha: 0.1)
                : context.ksc.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? context.ksc.accent500 : context.ksc.primary700,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                getLineAwesomeIcon(type.iconName),
                size: 20,
                color: isSelected ? context.ksc.accent500 : context.ksc.neutral500,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  type.name.toUpperCase(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? context.ksc.white : context.ksc.neutral400,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (isSelected)
                Icon(LineAwesomeIcons.check_circle_solid, size: 20, color: context.ksc.accent500),
            ],
          ),
        ),
      ),
    );
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
