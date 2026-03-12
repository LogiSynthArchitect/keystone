import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';
import '../providers/auth_notifier.dart';
import '../widgets/name_step_view.dart';
import '../widgets/services_step_view.dart';
import '../widgets/onboarding_bottom_bar.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  int _step = 0; 
  final List<ServiceType> _selectedServices = [];
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

  bool get _isValid => _nameController.text.trim().length >= 2;

  void _onContinue() async {
    if (_step == 0) {
      debugPrint('[KS:UI] Onboarding: Switching to Step 1 (Services)');
      _nameFocusNode.unfocus();
      setState(() => _step = 1);
    } else {
      debugPrint('[KS:UI] Onboarding: Attempting completeOnboarding...');
      final success = await ref.read(authNotifierProvider.notifier).completeOnboarding(
            name: _nameController.text.trim(),
            services: _selectedServices,
          );
      
      debugPrint('[KS:UI] Onboarding completeOnboarding result: $success');
      
      if (success && mounted) {
        debugPrint('[KS:UI] Onboarding SUCCESS. Invalidating authStateProvider and navigating...');
        await ref.read(authStateProvider.notifier).refresh();
        if (mounted) context.go(RouteNames.jobs);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    ref.listen<AuthUiState>(authNotifierProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        KsSnackbar.show(context, message: next.errorMessage!, type: KsSnackbarType.error);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                child: _step == 0
                    ? NameStepView(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        isFocused: _nameFocused,
                        isValid: _isValid,
                        onSubmitted: _onContinue,
                      )
                    : ServicesStepView(
                        selectedServices: _selectedServices,
                        onToggle: (type) => setState(() =>
                            _selectedServices.contains(type) 
                                ? _selectedServices.remove(type) 
                                : _selectedServices.add(type)),
                      ),
              ),
            ),
          ),
          if (!keyboardVisible || _step == 0)
            OnboardingBottomBar(
              step: _step,
              isLoading: authState.isLoading,
              onPressed: (_step == 0 && _isValid) || (_step == 1 && _selectedServices.isNotEmpty)
                  ? _onContinue
                  : null,
            ),
        ],
      ),
    );
  }
}
