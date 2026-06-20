import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/router/route_names.dart'
    show RouteNames;
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/focus_safe_text_field.dart';
import '../../../../core/widgets/ks_banner.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_success_moment.dart';
import '../../../../core/utils/icon_helpers.dart';
import '../../../service_types/presentation/providers/service_type_provider.dart'
    show serviceTypeProvider;
import '../../../service_types/domain/entities/service_type_entity.dart';
import '../providers/auth_notifier.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final List<String> _selectedServices = [];
  bool _termsScrolledToBottom = false;
  String _termsContent = '';
  bool _termsLoading = true;
  ScrollController? _termsScrollController;
  final ValueNotifier<bool> _nameValid = ValueNotifier(false);
  String _nameValue = '';

  int get _termsVersion => RouteNames.currentTermsVersion;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  void _onTermsScroll() {
    final ctrl = _termsScrollController;
    if (ctrl == null || !ctrl.hasClients) return;
    final scrolled = ctrl.position.pixels >=
        ctrl.position.maxScrollExtent * 0.98;
    if (scrolled != _termsScrolledToBottom) {
      setState(() => _termsScrolledToBottom = scrolled);
    }
  }

  Future<void> _loadTerms() async {
    try {
      final content = await rootBundle.loadString('assets/legal/terms.md');
      if (mounted) setState(() => _termsContent = content);
    } catch (_) {
      if (mounted) setState(() => _termsContent = 'Terms & Conditions could not be loaded.');
    } finally {
      if (mounted) setState(() => _termsLoading = false);
    }
  }

  @override
  void dispose() {
    _nameValid.dispose();
    _termsScrollController?.removeListener(_onTermsScroll);
    _termsScrollController?.dispose();
    super.dispose();
  }

  bool get _isValidName => _nameValid.value;
  bool get _canContinue => switch (_step) {
        0 => _isValidName,
        1 => _selectedServices.isNotEmpty,
        2 => _termsScrolledToBottom,
        _ => false,
      };

  Future<void> _onContinue() async {
    ref.read(authNotifierProvider.notifier).clearError();

    if (_step == 0) {
      if (!_isValidName) return;
      ref.invalidate(serviceTypeProvider);
      setState(() => _step = 1);
    } else if (_step == 1) {
      setState(() => _step = 2);
    } else {
      final success = await ref.read(authNotifierProvider.notifier).completeOnboarding(
            name: _nameValue.trim(),
            services: _selectedServices,
            termsAcceptedAt: DateTime.now(),
            termsVersion: _termsVersion,
          );

      if (success && mounted) {
        await ref.read(authStateProvider.notifier).refresh();
        await KsSuccessMoment.show(context, title: 'ONBOARDING COMPLETE');
        if (mounted) context.go(RouteNames.transition);
      }
    }
  }

  void _onNameChanged(String value) {
    _nameValue = value;
    final valid = value.trim().length >= 2;
    if (valid != _nameValid.value) {
      _nameValid.value = valid;
    }
    ref.read(authNotifierProvider.notifier).clearError();
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
        child: _step == 2
            ? _buildTermsView(keyboardVisible, errorMessage, authState.isLoading)
            : _step == 1
                ? _buildServicesView(keyboardVisible, errorMessage, authState.isLoading)
                : Column(
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
                              _buildNameStep(context, key: const ValueKey('step0')),
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

  /// Step 1 layout: fixed header + scrollable services list.
  Widget _buildServicesView(bool keyboardVisible, String? errorMessage, bool isLoading) {
    final serviceTypesAsync = ref.watch(serviceTypeProvider);
    return Column(
      children: [
        // Fixed header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildBackButton(context),
              const SizedBox(height: 48),
              Text(
                'YOUR SERVICES',
                style: AppTextStyles.h1.copyWith(
                  color: context.ksc.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
              const SizedBox(height: 24),
              Text('Select what you offer.',
                  style: AppTextStyles.bodyLarge.copyWith(
                      color: context.ksc.neutral400, fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              _buildStepIndicator(context),
              const SizedBox(height: 24),
              if (errorMessage != null && errorMessage.isNotEmpty) ...[
                KsBanner(message: errorMessage),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
        // Scrollable services list
        Expanded(
          child: serviceTypesAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
            error: (_, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                KsBanner(message: 'Failed to load services.'),
                const SizedBox(height: 12),
                KsButton(
                  label: 'RETRY',
                  onPressed: () => ref.invalidate(serviceTypeProvider),
                  edgeToEdge: false,
                ),
              ],
            ),
            data: (types) {
              final grouped = _groupByCategory(types);
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        if (!keyboardVisible) _buildBottomBar(context, isLoading),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  SHARED WIDGETS
  // ═══════════════════════════════════════════════

  Widget _buildBackButton(BuildContext context) {
    if (_step == 0) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => setState(() => _step--),
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
  }

  Widget _buildStepIndicator(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [0, 1, 2].map((i) {
          final isActive = _step >= i;
          return Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? context.ksc.accent500 : Colors.transparent,
              border: Border.all(
                color: isActive ? context.ksc.accent500 : context.ksc.primary600,
                width: 1.5,
              ),
            ),
          );
        }).toList(),
      );

  Widget _buildNameStep(BuildContext context, {Key? key}) => Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR NAME',
            style: AppTextStyles.h1.copyWith(
              color: context.ksc.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),

          const SizedBox(height: 8),
          Text('How should we address you?',
              style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),

          _buildStepIndicator(context),
          const SizedBox(height: 40),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Full Name',
                style: TextStyle(
                  fontFamily: 'BarlowSemiCondensed',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: context.ksc.neutral400,
                ),
              ),
              const SizedBox(height: 8),
              FocusSafeTextField(
                hint: 'Jeremie Mensah',
                textCapitalization: TextCapitalization.words,
                onChanged: _onNameChanged,
                autofocus: true,
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
        ],
      );

  Widget _buildTermsView(bool keyboardVisible, String? errorMessage, bool isLoading) {
    _termsScrollController ??= ScrollController()..addListener(_onTermsScroll);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildBackButton(context),
              const SizedBox(height: 48),

              Text(
                'TERMS & CONDITIONS',
                style: AppTextStyles.h1.copyWith(
                  color: context.ksc.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 24),

              Text('Read and scroll to accept.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.ksc.neutral400,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 32),
              _buildStepIndicator(context),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // Terms content fills viewport between header and bottom bar
        Expanded(
          child: _termsLoading
              ? const Center(child: CircularProgressIndicator())
              : Markdown(
                  controller: _termsScrollController,
                  data: _termsContent,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 64),
                  styleSheet: MarkdownStyleSheet(
                    h1: AppTextStyles.h3.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800),
                    h2: AppTextStyles.bodyLarge.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    p: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral300, fontSize: 16, height: 1.7),
                    listBullet: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400, fontSize: 15),
                    strong: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
                  ),
                ).animate().fadeIn(delay: 200.ms),
        ),

        if (errorMessage != null && errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: KsBanner(message: errorMessage),
          ),

        if (!keyboardVisible) _buildBottomBar(context, isLoading),
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

  String get _bottomBarLabel {
    return switch (_step) {
      0 => 'CONTINUE',
      1 => 'CONTINUE',
      2 => 'I ACCEPT',
      _ => '',
    };
  }

  Widget _buildBottomBar(BuildContext context, bool isLoading) {
    Widget button(String label, bool enabled, VoidCallback? onPressed) {
      return KsButton(
        label: label,
        variant: KsButtonVariant.cta,
        edgeToEdge: true,
        isLoading: isLoading,
        onPressed: enabled ? onPressed : null,
      ).animate().fadeIn(delay: 600.ms);
    }

    if (_step == 0) {
      return ValueListenableBuilder<bool>(
        valueListenable: _nameValid,
        builder: (_, valid, __) => button(_bottomBarLabel, valid, _onContinue),
      );
    }

    return button(_bottomBarLabel, _canContinue, _onContinue);
  }
}
