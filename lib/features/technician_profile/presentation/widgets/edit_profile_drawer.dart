import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:arclock/core/widgets/focus_safe_text_field.dart';
import 'package:arclock/core/widgets/ks_sliding_notification.dart';
import 'package:arclock/core/widgets/ks_step_drawer.dart';
import 'package:arclock/core/widgets/ks_confirm_dialog.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../providers/profile_provider.dart';
import '../../domain/entities/profile_entity.dart';
import '../../../service_types/presentation/providers/service_type_provider.dart';
import '../../../service_types/domain/entities/service_type_entity.dart';

/// Edit profile as a KsStepDrawer — replaces the old EditProfileScreen route.
///
/// Steps:
///   1. PROFILE INFO — Name → Photo
///   2. CONTACT    — WhatsApp number
///   3. ABOUT      — Bio
///   4. SETTINGS   — Services toggle chips → Public + Save
class EditProfileDrawer extends ConsumerStatefulWidget {
  const EditProfileDrawer({super.key});

  @override
  ConsumerState<EditProfileDrawer> createState() => _EditProfileDrawerState();

  /// Show the edit profile drawer as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const EditProfileDrawer(),
    );
  }
}

class _EditProfileDrawerState extends ConsumerState<EditProfileDrawer> {
  final _nameCtrl     = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  List<String> _services = [];
  bool _isPublic = true;
  bool _inited = false;
  bool _isUploading = false;
  String? _pendingPhoto;

  late String _origName;
  late String _origBio;
  late String _origWhatsapp;
  late List<String> _origServices;
  late bool _origPublic;

  // All available service types loaded from provider
  List<ServiceTypeEntity> _cachedServices = [];

  @override void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  void _init(ProfileEntity p) {
    if (_inited) return;
    _nameCtrl.text = p.displayName;
    _bioCtrl.text = p.bio ?? '';
    _whatsappCtrl.text = p.whatsappNumber;
    _services = List.from(p.services);
    _isPublic = p.isPublic;
    _origName = p.displayName;
    _origBio = p.bio ?? '';
    _origWhatsapp = p.whatsappNumber;
    _origServices = List.from(p.services);
    _origPublic = p.isPublic;
    _inited = true;
  }

  bool get _dirty =>
      _pendingPhoto != null ||
      _nameCtrl.text.trim() != _origName ||
      _bioCtrl.text.trim() != _origBio ||
      _whatsappCtrl.text.trim() != _origWhatsapp ||
      _isPublic != _origPublic ||
      !_listEq(_services, _origServices);

  bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = [...a]..sort(), sb = [...b]..sort();
    for (int i = 0; i < sa.length; i++) { if (sa[i] != sb[i]) return false; }
    return true;
  }

  bool get _canSave => _nameCtrl.text.trim().length >= 2 && _services.isNotEmpty;

  Future<bool> _confirmDiscard(BuildContext ctx) async {
    if (!_dirty) return true;
    return await KsConfirmDialog.show(
      ctx,
      title: 'DISCARD CHANGES?',
      message: 'You have unsaved changes. Leave anyway?',
      confirmLabel: 'DISCARD',
      cancelLabel: 'KEEP EDITING',
      isDanger: true,
      onConfirm: () {},
    ) ?? false;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _isUploading = true);
    final url = await ref.read(profileProvider.notifier).uploadPhoto(picked.path);
    if (!mounted) return;
    if (url != null) {
      setState(() { _pendingPhoto = url; _isUploading = false; });
    } else {
      setState(() => _isUploading = false);
      KsSlidingNotification.show(context, message: 'Could not upload photo.', type: KsNotificationType.error);
    }
  }

  Future<void> _save() async {
    final whatsapp = _whatsappCtrl.text.trim();
    if (whatsapp.length != 10 || !whatsapp.startsWith('0')) {
      if (context.mounted) {
        KsSlidingNotification.show(context,
            message: 'Enter a valid 10-digit Ghana WhatsApp number starting with 0',
            type: KsNotificationType.error);
      }
      return;
    }

    final profile = ref.read(profileProvider).profile;
    if (profile == null) return;

    final updated = profile.copyWith(
      displayName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      photoUrl: _pendingPhoto ?? profile.photoUrl,
      services: _services,
      whatsappNumber: whatsapp,
      isPublic: _isPublic,
      updatedAt: DateTime.now(),
    );
    final ok = await ref.read(profileProvider.notifier).update(updated);
    if (!mounted) return;
    if (ok) {
      if (context.mounted) {
        Navigator.of(context).pop();
        KsSlidingNotification.show(context,
            message: 'Profile updated.', type: KsNotificationType.success);
      }
    } else {
      if (context.mounted) {
        final err = ref.read(profileProvider).errorMessage;
        KsSlidingNotification.show(context,
            message: err ?? 'Could not update profile.', type: KsNotificationType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final profile = state.profile;
    if (profile != null) _init(profile);
    final photoUrl = _pendingPhoto ?? profile?.photoUrl;

    // Load all service types from provider — replaced hardcoded V1 list
    final svcTypesAsync = ref.watch(serviceTypeProvider);
    final loadedTypes = svcTypesAsync.valueOrNull;
    if (loadedTypes != null) _cachedServices = loadedTypes;

    if (profile == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // ── Step 1 · Sub 1: Name ──
    List<Widget> _nameStep(BuildContext ctx, void Function(VoidCallback) ss) => [
      const SizedBox(height: 8),
      Text('FULL NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.8, color: ctx.ksc.accent500)),
      const SizedBox(height: 8),
      FocusSafeTextField(
        hint: 'e.g. JEREMIE MENSAH',
        maxLength: 100,
        textCapitalization: TextCapitalization.words,
        onChanged: (_) => ss(() {}),
      ),
    ];

    // ── Step 1 · Sub 2: Photo ──
    List<Widget> _photoStep(BuildContext ctx, void Function(VoidCallback) ss) => [
      const SizedBox(height: 8),
      Text('PROFILE PHOTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.8, color: ctx.ksc.accent500)),
      const SizedBox(height: 12),
      Center(
        child: GestureDetector(
          onTap: _isUploading ? null : _pickPhoto,
          child: Stack(
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: ctx.ksc.primary900,
                  shape: BoxShape.circle,
                  border: Border.all(color: ctx.ksc.primary700, width: 2),
                  image: (photoUrl != null && photoUrl.isNotEmpty)
                      ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Center(child: Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : '?',
                        style: AppTextStyles.h1.copyWith(color: ctx.ksc.white)))
                    : null,
              ),
              if (_isUploading)
                Positioned.fill(
                  child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: ctx.ksc.accent500))),
                ),
              Positioned(
                bottom: 2, right: 2,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: ctx.ksc.accent500, shape: BoxShape.circle),
                  child: Icon(LineAwesomeIcons.camera_solid, size: 16, color: ctx.ksc.primary900),
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    // ── Step 2: WhatsApp ──
    List<Widget> _phoneStep(BuildContext ctx, void Function(VoidCallback) ss) => [
      const SizedBox(height: 8),
      Text('WHATSAPP NUMBER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.8, color: ctx.ksc.accent500)),
      const SizedBox(height: 8),
      FocusSafeTextField(
        hint: '054 412 3456',
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        onChanged: (_) => ss(() {}),
      ),
      const SizedBox(height: 12),
      Text('ENTER YOUR 10-DIGIT GHANA NUMBER STARTING WITH 0',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: ctx.ksc.neutral500)),
    ];

    // ── Step 3: Bio ──
    List<Widget> _bioStep(BuildContext ctx, void Function(VoidCallback) ss) => [
      const SizedBox(height: 8),
      Text('PROFESSIONAL BIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.8, color: ctx.ksc.accent500)),
      const SizedBox(height: 8),
      FocusSafeTextField(
        hint: 'Describe your expertise...',
        maxLines: 5,
        maxLength: 300,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => ss(() {}),
      ),
    ];

    // ── Step 4 · Sub 1: Services ──
    List<Widget> _servicesStep(BuildContext ctx, void Function(VoidCallback) ss) {
      // Compute fallback items for selected IDs that don't match any entity
      final matchedIds = _cachedServices.map((s) => s.id).toSet();
      final orphanIds = _services.where((id) => !matchedIds.contains(id)).toList();
      return [
        const SizedBox(height: 8),
        Text('OFFERED SERVICES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.8, color: ctx.ksc.accent500)),
        const SizedBox(height: 4),
        if (_cachedServices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: ctx.ksc.accent500)),
            ),
          ),
        ...orphanIds.map((id) => GestureDetector(
          onTap: () {
            setState(() { _services.remove(id); });
            ss(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: ctx.ksc.primary700.withValues(alpha: 0.5), width: 1.5),
              ),
            ),
            child: Row(children: [
              Icon(LineAwesomeIcons.question_circle_solid, color: ctx.ksc.error500, size: 18),
              const SizedBox(width: 14),
              Expanded(child: Text(
                'UNKNOWN (${id.substring(0, 8)}…)',
                style: AppTextStyles.body.copyWith(color: ctx.ksc.error500, fontWeight: FontWeight.w600, fontSize: 14),
              )),
              Icon(LineAwesomeIcons.trash_alt_solid, size: 16, color: ctx.ksc.error500),
            ]),
          ),
        )),
        ..._cachedServices.map((svc) {
        final sel = _services.contains(svc.id);
        return GestureDetector(
          onTap: () {
            setState(() { if (sel) { _services.remove(svc.id); } else { _services.add(svc.id); } });
            ss(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: ctx.ksc.primary700.withValues(alpha: 0.5), width: 1.5),
              ),
            ),
            child: Row(children: [
              Expanded(child: Text(
                svc.name.toUpperCase(),
                style: AppTextStyles.body.copyWith(
                  color: sel ? ctx.ksc.accent500 : ctx.ksc.neutral400,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                ),
              )),
              if (sel) Icon(LineAwesomeIcons.check_circle_solid, size: 16, color: ctx.ksc.accent500),
            ]),
          ),
        );
      }),
    ];
  }

    // ── Step 4 · Sub 2: Public toggle ──
    List<Widget> _publicStep(BuildContext ctx, void Function(VoidCallback) ss) => [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ctx.ksc.primary700.withValues(alpha: 0.5), width: 1.5),
          ),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PUBLIC PROFILE', style: AppTextStyles.body.copyWith(color: ctx.ksc.white, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text('ALLOW CUSTOMERS TO VIEW YOUR PROFILE', style: AppTextStyles.caption.copyWith(color: ctx.ksc.neutral500)),
          ])),
          Switch(
            value: _isPublic,
            onChanged: (v) { setState(() => _isPublic = v); ss(() {}); },
            activeThumbColor: ctx.ksc.accent500,
            activeTrackColor: ctx.ksc.accent500.withValues(alpha: 0.3),
            inactiveThumbColor: ctx.ksc.neutral500,
            inactiveTrackColor: ctx.ksc.primary700,
          ),
        ]),
      ),
    ];

    return KsStepDrawer(
      title: "EDIT PROFILE",
      steps: const [
        KsStep(label: 'PROFILE INFO', icon: LineAwesomeIcons.user_circle_solid, subSteps: 2,
          tip: 'Update your display name and profile photo',
          imageAsset: 'assets/icons/3d/transparent/634b4b-crown.png'),
        KsStep(label: 'CONTACT', icon: LineAwesomeIcons.phone_solid,
          tip: 'Enter your WhatsApp number for customer contact',
          imageAsset: 'assets/icons/3d/transparent/1b19dc-call-only.png'),
        KsStep(label: 'ABOUT', icon: LineAwesomeIcons.pen_alt_solid,
          tip: 'Describe your experience and expertise',
          imageAsset: 'assets/icons/3d/transparent/0ef25b-calender.png'),
        KsStep(label: 'SETTINGS', icon: LineAwesomeIcons.cog_solid, subSteps: 2,
          tip: 'Select services you offer and set your profile visibility',
          imageAsset: 'assets/icons/3d/transparent/ff5be0-tools.png'),
      ],
      showBackArrow: true,
      onBack: () => _confirmDiscard(context),
      onClose: () => _confirmDiscard(context),
      nextLabel: "CONTINUE",
      saveLabel: "SAVE PROFILE",
      canAdvance: (step, subStep) {
        if (step == 0 && subStep == 0) return _nameCtrl.text.trim().length >= 2;
        return true;
      },
      onSave: _save,
      stepContent: (step, subStep, rebuild, _) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (step == 0 && subStep == 0) ..._nameStep(context, rebuild),
            if (step == 0 && subStep == 1) ..._photoStep(context, rebuild),
            if (step == 1) ..._phoneStep(context, rebuild),
            if (step == 2) ..._bioStep(context, rebuild),
            if (step == 3 && subStep == 0) ..._servicesStep(context, rebuild),
            if (step == 3 && subStep == 1) ..._publicStep(context, rebuild),
          ],
        ),
      ),
    );
  }
}
