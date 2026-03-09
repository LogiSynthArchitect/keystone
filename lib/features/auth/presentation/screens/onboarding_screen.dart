import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_avatar.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_text_field.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../technician_profile/domain/entities/profile_entity.dart';
import '../providers/auth_notifier.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final List<ServiceType> _selectedServices = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().length >= 2 && _selectedServices.isNotEmpty;

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Future<void> _onGetStarted() async {
    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final authUser = supabase.auth.currentUser;
      if (authUser == null) return;

      final datasource = ref.read(authRemoteDatasourceProvider);
      // Check if user already exists — skip create if so
      final existing = await datasource.getCurrentUser(authUser.id);
      if (existing == null) {
        await datasource.createUser(
          authId: authUser.id,
          fullName: _nameController.text.trim(),
          phoneNumber: authUser.phone ?? '',
        );
      }

      if (mounted) context.go(RouteNames.jobs);
    } catch (e, stack) {
      debugPrint('=== ONBOARDING ERROR ===');
      debugPrint('Type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      debugPrint('========================');
      if (mounted) {
        KsSnackbar.show(context,
            message: 'Could not save your profile. Please try again.',
            type: KsSnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _serviceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return 'Car Key Programming';
      case ServiceType.doorLockInstallation:  return 'Door Lock Installation';
      case ServiceType.doorLockRepair:        return 'Door Lock Repair';
      case ServiceType.smartLockInstallation: return 'Smart Lock Installation';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral050,
      appBar: const KsAppBar(title: 'Set up your profile'),
      body: Column(
        children: [
          const KsOfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: KsAvatar(
                      size: KsAvatarSize.xl,
                      initials: _initials(_nameController.text),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  KsTextField(
                    label: 'Full name',
                    hint: 'Jeremie Mensah',
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Services you offer', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Select all that apply.',
                    style: AppTextStyles.body.copyWith(color: AppColors.neutral600),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...ServiceType.values.map((type) {
                    final selected = _selectedServices.contains(type);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedServices.remove(type);
                            } else {
                              _selectedServices.add(type);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary050 : AppColors.white,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: selected ? AppColors.primary600 : AppColors.neutral200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected ? Icons.check_circle : Icons.circle_outlined,
                                color: selected ? AppColors.primary700 : AppColors.neutral400,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(_serviceLabel(type), style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.xxxl),
                  KsButton(
                    label: 'Get started',
                    onPressed: _canSubmit && !_isLoading ? _onGetStarted : null,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
