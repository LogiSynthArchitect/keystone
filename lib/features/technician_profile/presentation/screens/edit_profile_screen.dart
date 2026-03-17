import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
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
        backgroundColor: AppColors.primary800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text('DISCARD CHANGES?', style: AppTextStyles.h2.copyWith(color: AppColors.white)),
        content: Text('You have unsaved changes. Leave anyway?', style: AppTextStyles.body.copyWith(color: AppColors.neutral300)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('KEEP EDITING', style: AppTextStyles.label.copyWith(color: AppColors.neutral400))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text('DISCARD', style: AppTextStyles.label.copyWith(color: AppColors.error500))),
        ],
      ),
    ) ?? false;
  }

  String _serviceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.carLockProgramming:    return 'CAR KEY PROGRAMMING';
      case ServiceType.doorLockInstallation:  return 'DOOR LOCK INSTALLATION';
      case ServiceType.doorLockRepair:        return 'DOOR LOCK REPAIR';
      case ServiceType.smartLockInstallation: return 'SMART LOCK INSTALLATION';
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
    final updated = profile.copyWith(
      displayName: _nameController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      photoUrl: _pendingPhotoUrl ?? profile.photoUrl,
      services: _services,
      whatsappNumber: _whatsappController.text.trim(),
      isPublic: _isPublic,
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
        backgroundColor: AppColors.primary900,
        appBar: const KsAppBar(title: 'EDIT PROFILE', showBack: true),
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
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: AppColors.primary800,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary700, width: 2),
                                image: photoUrl != null ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                              ),
                              child: photoUrl == null
                                  ? Center(child: Text(_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                                      style: AppTextStyles.h1.copyWith(color: AppColors.white)))
                                  : null,
                            ),
                            if (_isUploadingPhoto)
                              const Positioned.fill(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent500)),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: AppColors.accent500, shape: BoxShape.circle),
                                child: const Icon(LineAwesomeIcons.camera_solid, size: 14, color: AppColors.primary900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    
                    _buildInputField(label: 'DISPLAY NAME', controller: _nameController, hint: 'e.g. JEREMIE MENSAH'),
                    const SizedBox(height: AppSpacing.lg),
                    _buildInputField(label: 'PROFESSIONAL BIO', controller: _bioController, hint: 'Describe your expertise...', isMultiline: true),
                    const SizedBox(height: AppSpacing.lg),
                    _buildInputField(label: 'WHATSAPP NUMBER', controller: _whatsappController, hint: '024 412 3456', isPhone: true),
                    
                    const SizedBox(height: AppSpacing.xl),
                    Text('OFFERED SERVICES', style: AppTextStyles.caption.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    const SizedBox(height: AppSpacing.md),
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
                              color: isSelected ? AppColors.primary800.withValues(alpha: 0.5) : AppColors.primary800,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isSelected ? AppColors.accent500 : AppColors.primary700, width: 1.0),
                            ),
                            child: Row(children: [
                              Expanded(child: Text(_serviceLabel(type), style: AppTextStyles.body.copyWith(color: isSelected ? AppColors.white : AppColors.neutral400, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500))),
                              if (isSelected) const Icon(LineAwesomeIcons.check_circle_solid, size: 18, color: AppColors.accent500),
                            ]),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary800,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.primary700),
                      ),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('PUBLIC PROFILE', style: AppTextStyles.body.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('ALLOW CUSTOMERS TO VIEW YOUR PROFILE', style: AppTextStyles.caption.copyWith(color: AppColors.neutral500)),
                        ])),
                        Switch(
                          value: _isPublic, 
                          onChanged: (v) => setState(() => _isPublic = v), 
                          activeThumbColor: AppColors.accent500,
                          activeTrackColor: AppColors.accent500.withValues(alpha: 0.3),
                          inactiveThumbColor: AppColors.neutral500,
                          inactiveTrackColor: AppColors.primary700,
                        ),
                      ]),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
            _buildBottomBar(state.isSaving),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required TextEditingController controller, required String hint, bool isMultiline = false, bool isPhone = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primary700),
          ),
          child: TextField(
            controller: controller,
            maxLines: isMultiline ? 4 : 1,
            keyboardType: isPhone ? TextInputType.phone : (isMultiline ? TextInputType.multiline : TextInputType.text),
            style: AppTextStyles.body.copyWith(color: AppColors.white, fontWeight: FontWeight.w600),
            cursorColor: AppColors.accent500,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.neutral600),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isLoading) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary800,
        border: Border(top: BorderSide(color: AppColors.primary700)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canSave && !isLoading && !_isUploadingPhoto ? _onSave : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SAVE SYSTEM CHANGES',
                style: AppTextStyles.h2.copyWith(
                  color: _canSave ? AppColors.white : AppColors.neutral600,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              if (isLoading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent500))
              else
                Icon(
                  LineAwesomeIcons.save_solid,
                  color: _canSave ? AppColors.accent500 : AppColors.neutral700,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
