import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/widgets/ks_text_field.dart';
import '../providers/profile_provider.dart';
import '../../domain/entities/profile_entity.dart';
import '../../../../core/constants/app_enums.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController     = TextEditingController();
  final _bioController      = TextEditingController();
  final _whatsappController = TextEditingController();
  List<ServiceType> _services = [];
  bool _isPublic = true;
  bool _initialized = false;
  bool _isUploadingPhoto = false;
  String? _pendingPhotoUrl;
  String _originalName = '';
  String _originalBio = '';
  String _originalWhatsapp = '';
  List<ServiceType> _originalServices = [];
  bool _originalIsPublic = true;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _initFromProfile(ProfileEntity profile) {
    if (_initialized) return;
    _nameController.text = profile.displayName;
    _bioController.text = profile.bio ?? '';
    _whatsappController.text = profile.whatsappNumber;
    _services = List.from(profile.services);
    _isPublic = profile.isPublic;
    _originalName = profile.displayName;
    _originalBio = profile.bio ?? '';
    _originalWhatsapp = profile.whatsappNumber;
    _originalServices = List.from(profile.services);
    _originalIsPublic = profile.isPublic;
    _initialized = true;
  }

  bool get _isDirty =>
      _pendingPhotoUrl != null ||
      _nameController.text.trim() != _originalName ||
      _bioController.text.trim() != _originalBio ||
      _whatsappController.text.trim() != _originalWhatsapp ||
      _isPublic != _originalIsPublic ||
      !_listEquals(_services, _originalServices);

  bool _listEquals(List<ServiceType> a, List<ServiceType> b) {
    if (a.length != b.length) return false;
    final sa = [...a]..sort((x, y) => x.index.compareTo(y.index));
    final sb = [...b]..sort((x, y) => x.index.compareTo(y.index));
    for (int i = 0; i < sa.length; i++) { if (sa[i] != sb[i]) return false; }
    return true;
  }

  bool get _canSave => _nameController.text.trim().length >= 2 && _services.isNotEmpty;

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Leave anyway?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard', style: TextStyle(color: AppColors.error600))),
        ],
      ),
    ) ?? false;
  }

  String _serviceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return 'Car Key Programming';
      case ServiceType.doorLockInstallation:  return 'Door Lock Installation';
      case ServiceType.doorLockRepair:        return 'Door Lock Repair';
      case ServiceType.smartLockInstallation: return 'Smart Lock Installation';
    }
  }

  Future<void> _onPickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (picked == null) return;
    setState(() => _isUploadingPhoto = true);
    final url = await ref.read(profileProvider.notifier).uploadPhoto(picked.path);
    if (!mounted) return;
    if (url != null) {
      setState(() { _pendingPhotoUrl = url; _isUploadingPhoto = false; });
    } else {
      setState(() => _isUploadingPhoto = false);
      KsSnackbar.show(context, message: 'Could not upload photo.', type: KsSnackbarType.error);
    }
  }

  Future<void> _onSave() async {
    final profile = ref.read(profileProvider).profile!;
    final updated = ProfileEntity(
      id: profile.id,
      userId: profile.userId,
      displayName: _nameController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      photoUrl: _pendingPhotoUrl ?? profile.photoUrl,
      services: _services,
      whatsappNumber: _whatsappController.text.trim(),
      isPublic: _isPublic,
      profileUrl: profile.profileUrl,
      createdAt: profile.createdAt,
      updatedAt: DateTime.now(),
    );
    final ok = await ref.read(profileProvider.notifier).update(updated);
    if (!mounted) return;
    if (ok) {
      context.pop();
      KsSnackbar.show(context, message: 'Profile updated.', type: KsSnackbarType.success);
    } else {
      final error = ref.read(profileProvider).errorMessage;
      KsSnackbar.show(context, message: error ?? 'Could not update profile.', type: KsSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    if (state.profile != null) _initFromProfile(state.profile!);
    final photoUrl = _pendingPhotoUrl ?? state.profile?.photoUrl;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final ok = await _confirmDiscard();
        if (ok) nav.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.neutral050,
        appBar: const KsAppBar(title: 'Edit profile', showBack: true),
        body: Column(
          children: [
            const KsOfflineBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: GestureDetector(
                        onTap: _isUploadingPhoto ? null : _onPickPhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: AppColors.primary100,
                              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                              child: photoUrl == null
                                  ? Text(_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                                      style: AppTextStyles.h1.copyWith(color: AppColors.primary700))
                                  : null,
                            ),
                            if (_isUploadingPhoto)
                              const Positioned.fill(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary700)),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppColors.primary700, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, size: 14, color: AppColors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    KsTextField(label: 'Display name', hint: 'Jeremie Kouassi', controller: _nameController, onChanged: (_) => setState(() {}), textInputAction: TextInputAction.next),
                    const SizedBox(height: AppSpacing.lg),
                    KsTextField(label: 'Bio', hint: 'Professional locksmith with 10 years experience...', type: KsTextFieldType.multiline, controller: _bioController, onChanged: (_) => setState(() {}), textInputAction: TextInputAction.next),
                    const SizedBox(height: AppSpacing.lg),
                    KsTextField(label: 'WhatsApp number', hint: '0201234567', type: KsTextFieldType.phone, controller: _whatsappController, onChanged: (_) => setState(() {}), textInputAction: TextInputAction.done),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Services offered', style: AppTextStyles.captionMedium.copyWith(color: AppColors.neutral700)),
                    const SizedBox(height: AppSpacing.sm),
                    ...ServiceType.values.map((type) {
                      final isSelected = _services.contains(type);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            if (isSelected) { _services.remove(type); } else { _services.add(type); }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary050 : AppColors.white,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(color: isSelected ? AppColors.primary600 : AppColors.neutral200, width: isSelected ? 1.5 : 1.0),
                            ),
                            child: Row(children: [
                              Expanded(child: Text(_serviceLabel(type), style: AppTextStyles.body.copyWith(color: isSelected ? AppColors.primary700 : AppColors.neutral900))),
                              if (isSelected) const Icon(Icons.check_circle, size: 18, color: AppColors.primary700),
                            ]),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.lg),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Public profile', style: AppTextStyles.bodyMedium),
                        Text('Allow customers to view your profile', style: AppTextStyles.caption.copyWith(color: AppColors.neutral500)),
                      ])),
                      Switch(value: _isPublic, onChanged: (v) => setState(() => _isPublic = v), activeThumbColor: AppColors.primary700),
                    ]),
                    const SizedBox(height: AppSpacing.xxxl),
                    KsButton(label: 'Save changes', onPressed: _canSave && !state.isSaving && !_isUploadingPhoto ? _onSave : null, isLoading: state.isSaving),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
