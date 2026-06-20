import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import 'package:arclock/core/widgets/ks_sliding_notification.dart';
import 'package:arclock/core/widgets/ks_success_moment.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../features/service_types/presentation/widgets/service_type_picker_v2.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../providers/notes_providers.dart';
import '../widgets/tag_input_field.dart';
import '../../domain/entities/knowledge_note_entity.dart';
import '../../domain/entities/note_attachment.dart';

class EditNoteScreen extends ConsumerStatefulWidget {
  final String noteId;
  const EditNoteScreen({super.key, required this.noteId});

  @override
  ConsumerState<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends ConsumerState<EditNoteScreen> {
  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _tags = [];
  String? _serviceType;
  String? _photoUrl;
  bool _isUploadingPhoto = false;
  List<NoteAttachment> _attachments = [];
  KnowledgeNoteEntity? _note;

  final _recorder = AudioRecorder();
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Synchronously populate from the already-loaded provider
    final note = ref.read(notesListProvider).notes.where((n) => n.id == widget.noteId).firstOrNull;
    if (note != null) _applyNote(note);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _recordingTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  void _applyNote(KnowledgeNoteEntity note) {
    _titleController.text       = note.title;
    _descriptionController.text = note.description;
    _tags                       = List.from(note.tags);
    _serviceType                = note.serviceType;
    _photoUrl                   = note.photoUrl;
    _attachments                = List.from(note.attachments);
    _note = note;
  }

  bool get _isDirty =>
      _titleController.text.trim().isNotEmpty ||
      _descriptionController.text.trim().isNotEmpty ||
      _attachments.isNotEmpty;

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final result = await KsConfirmDialog.show(
      context,
      title: 'DISCARD CHANGES',
      message: 'Unsaved changes will be lost.',
      confirmLabel: 'DISCARD',
      cancelLabel: 'KEEP EDITING',
      isDanger: true,
      onConfirm: () {},
    );
    return result ?? false;
  }

  Future<void> _onSave(KnowledgeNoteEntity original) async {
    HapticFeedback.heavyImpact();
    final updated = original.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      tags: _tags,
      serviceType: _serviceType,
      photoUrl: _photoUrl,
      attachments: _attachments,
    );
    final result = await ref.read(editNoteProvider.notifier).save(updated);
    if (!mounted) return;
    if (result != null) {
      ref.read(notesListProvider.notifier).updateNote(result);
      context.pop();
      await KsSuccessMoment.show(context,
        title: "Note Updated",
        subtitle: result.title,
      );
    } else {
      final error = ref.read(editNoteProvider).errorMessage;
      KsSlidingNotification.show(context, message: error ?? "Could not update note", type: KsNotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(editNoteProvider);
    final note     = _note;
    final keyboard = MediaQuery.of(context).viewInsets.bottom > 0;

    if (note == null) {
      return Scaffold(
        backgroundColor: context.ksc.primary900,
        appBar: const KsAppBar(title: "EDIT NOTE", showBack: true),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFD4A84B)),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (!context.mounted) return;
        if (ok) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: context.ksc.primary900,
        appBar: const KsAppBar(title: "EDIT NOTE", showBack: true),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NOTE CONTENT", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text("Edit the title, description, tags, and category.", style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
                    const SizedBox(height: 32),
                    _buildField(label: "NOTE TITLE", hint: "e.g. Rekeying Kwikset Deadbolt", controller: _titleController, maxLength: 200),
                    const SizedBox(height: 24),
                    _buildField(label: "DESCRIPTION", hint: "Step by step notes, tips, what worked...", controller: _descriptionController, maxLines: 6),
                    const SizedBox(height: 32),
                    Text("TAGS", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    TagInputField(tags: _tags, onChanged: (tags) => setState(() => _tags = tags)),
                    const SizedBox(height: 32),
                    Text("SERVICE CATEGORY (OPTIONAL)", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    if (_serviceType != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.ksc.primary800,
                          border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _serviceType!.replaceAll('_', ' ').toUpperCase(),
                                style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w700),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _serviceType = null),
                              child: Icon(LineAwesomeIcons.times_circle_solid, size: 20, color: context.ksc.error500),
                            ),
                          ],
                        ),
                      ),
                    GestureDetector(
                      onTap: () => _showCategoryPicker(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: context.ksc.primary800,
                          border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(LineAwesomeIcons.folder_open_solid, size: 16, color: context.ksc.neutral500),
                            const SizedBox(width: 12),
                            Text(
                              _serviceType == null ? "Select a service category..." : "Change category",
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _serviceType == null ? context.ksc.neutral500 : context.ksc.neutral400,
                              ),
                            ),
                            const Spacer(),
                            Icon(LineAwesomeIcons.chevron_right_solid, size: 14, color: context.ksc.neutral500),
                          ],
                        ),
                      ),
                    ),
                    // PHOTO SECTION
                    Text("PHOTO", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    if (_photoUrl != null) ...[
                      Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: context.ksc.primary700),
                          image: DecorationImage(image: NetworkImage(_photoUrl!), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        KsButton(
                          label: _photoUrl == null ? "TAKE PHOTO" : "REPLACE PHOTO",
                          variant: KsButtonVariant.secondary,
                          size: KsButtonSize.small,
                          fullWidth: false,
                          leadingIcon: LineAwesomeIcons.camera_solid,
                          isLoading: _isUploadingPhoto,
                          onPressed: _isUploadingPhoto ? null : () => _pickPhoto(),
                        ),
                        if (_photoUrl != null) ...[
                          const SizedBox(width: 12),
                          KsButton(
                            label: "REMOVE",
                            variant: KsButtonVariant.danger,
                            size: KsButtonSize.small,
                            fullWidth: false,
                            onPressed: () => setState(() => _photoUrl = null),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 32),
                    // ATTACHMENTS SECTION
                    Text("ATTACHMENTS", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    if (_attachments.isNotEmpty) ...[
                      ..._attachments.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.ksc.primary800,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: context.ksc.primary700),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                a.type == AttachmentType.audio ? LineAwesomeIcons.microphone_solid :
                                a.type == AttachmentType.image ? LineAwesomeIcons.image_solid :
                                LineAwesomeIcons.file_pdf_solid,
                                size: 18,
                                color: context.ksc.accent500,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  a.name,
                                  style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (a.size != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    _formatSize(a.size!),
                                    style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                                  ),
                                ),
                              GestureDetector(
                                onTap: () => setState(() => _attachments.remove(a)),
                                child: Icon(LineAwesomeIcons.times_circle_solid, size: 20, color: context.ksc.error500),
                              ),
                            ],
                          ),
                        ),
                      )),
                      const SizedBox(height: 12),
                    ],
                    if (_isRecording)
                      _buildRecordingIndicator()
                    else ...[
                      _buildActionButton(
                        icon: LineAwesomeIcons.microphone_solid,
                        label: "RECORD AUDIO",
                        onTap: _startRecording,
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        icon: LineAwesomeIcons.image_solid,
                        label: "ADD IMAGE",
                        onTap: _pickImage,
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        icon: LineAwesomeIcons.file_pdf_solid,
                        label: "ATTACH PDF",
                        onTap: _pickPdf,
                      ),
                    ],
                    if (_isUploading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator(color: Color(0xFFD4A84B))),
                    ],

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            if (!keyboard) _buildSaveButton(state.isLoading, note),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LineAwesomeIcons.camera_solid, color: Colors.white),
              title: Text('Take Photo', style: AppTextStyles.body.copyWith(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LineAwesomeIcons.image_solid, color: Colors.white),
              title: Text('Choose from Gallery', style: AppTextStyles.body.copyWith(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final file = File(picked.path);
      final cloudService = CloudinaryService();
      final cloudUrl = await cloudService.uploadMedia(
        file: file,
        publicId: 'note_${const Uuid().v4()}',
      );
      if (cloudUrl != null) {
        setState(() => _photoUrl = cloudUrl);
        return;
      }

      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id ?? 'unknown';
      final fileName = '${const Uuid().v4()}.jpg';
      final path = 'note-photos/$userId/$fileName';

      await supabase.storage.from('note-photos').upload(path, file);
      final publicUrl = supabase.storage.from('note-photos').getPublicUrl(path);
      setState(() => _photoUrl = publicUrl);
    } catch (_) {
      if (mounted) {
        KsSlidingNotification.show(context, message: "Could not upload photo", type: KsNotificationType.error);
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Widget _buildRecordingIndicator() {
    final minutes = _recordingDuration ~/ 60;
    final seconds = _recordingDuration % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.error500),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "RECORDING",
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.error500,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            timeStr,
            style: AppTextStyles.h1.copyWith(
              color: context.ksc.white,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.ksc.error500,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.stop, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: context.ksc.accent500),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: context.ksc.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.ksc.neutral600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text("SELECT CATEGORY",
                    style: AppTextStyles.h2.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w900)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(LineAwesomeIcons.times_solid,
                      color: context.ksc.neutral500, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: ServiceTypePickerV2(
                  selected: _serviceType,
                  onSelected: (type) => Navigator.pop(context, type),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() => _serviceType = result);
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        KsSlidingNotification.show(context, message: "Microphone permission denied", type: KsNotificationType.error);
      }
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${const Uuid().v4()}.m4a';

    await _recorder.start(RecordConfig(encoder: AudioEncoder.aacLc), path: filePath);

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingDuration++);
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    final filePath = await _recorder.stop();
    if (filePath == null) {
      setState(() => _isRecording = false);
      return;
    }

    final file = File(filePath);
    final fileSize = await file.length();

    setState(() {
      _isRecording = false;
      _isUploading = true;
    });

    try {
      final saved = await _saveFileLocally(file, '.m4a');
      final attachment = NoteAttachment(
        id: const Uuid().v4(),
        type: AttachmentType.audio,
        url: saved,
        name: 'Audio recording ${DateTime.now().toString().substring(0, 16)}',
        size: fileSize,
        mimeType: 'audio/mp4',
        duration: _recordingDuration,
        createdAt: DateTime.now(),
      );
      setState(() => _attachments.add(attachment));
    } catch (e) {
      if (mounted) {
        KsSlidingNotification.show(context, message: "Could not save audio", type: KsNotificationType.error);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    if (picked == null) return;
    final file = File(picked.path);
    final fileSize = await file.length();

    setState(() => _isUploading = true);
    try {
      final saved = await _saveFileLocally(file, '.jpg');
      final attachment = NoteAttachment(
        id: const Uuid().v4(),
        type: AttachmentType.image,
        url: saved,
        name: picked.name,
        size: fileSize,
        mimeType: 'image/jpeg',
        createdAt: DateTime.now(),
      );
      setState(() => _attachments.add(attachment));
    } catch (e) {
      if (mounted) {
        KsSlidingNotification.show(context, message: "Could not save image", type: KsNotificationType.error);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;
      final pickedFile = result.files.first;
      final filePath = pickedFile.path;
      if (filePath == null) return;

      final file = File(filePath);
      final fileSize = await file.length();
      final fileName = pickedFile.name;

      setState(() => _isUploading = true);

      final saved = await _saveFileLocally(file, '.pdf');
      final attachment = NoteAttachment(
        id: const Uuid().v4(),
        type: AttachmentType.document,
        url: saved,
        name: fileName,
        size: fileSize,
        mimeType: 'application/pdf',
        createdAt: DateTime.now(),
      );
      setState(() => _attachments.add(attachment));
    } catch (e) {
      debugPrint('[KS:KB] FilePicker failed: $e');
      if (mounted) {
        KsSlidingNotification.show(context, message: "Could not attach PDF: $e", type: KsNotificationType.error);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Copies [file] to a local app directory and returns the file:// URI as string.
  Future<String> _saveFileLocally(File file, String extension) async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/note_attachments');
    if (!await dir.exists()) await dir.create(recursive: true);
    final destPath = '${dir.path}/${const Uuid().v4()}$extension';
    await file.copy(destPath);
    return 'file://$destPath';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.ksc.primary700),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
            cursorColor: context.ksc.accent500,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: context.ksc.neutral500),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isLoading, KnowledgeNoteEntity note) {
    final canSave = _titleController.text.trim().length >= 3 &&
                    _descriptionController.text.trim().length >= 10;
    return Container(
      width: double.infinity,
      color: context.ksc.primary700,
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: canSave && !isLoading ? () => _onSave(note) : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SAVE CHANGES',
                style: AppTextStyles.h2.copyWith(
                  color: canSave ? context.ksc.white : context.ksc.neutral500,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              if (isLoading)
                CircularProgressIndicator(color: context.ksc.accent500)
              else
                Icon(LineAwesomeIcons.check_solid, color: canSave ? context.ksc.accent500 : context.ksc.primary700),
            ],
          ),
        ),
      ),
    );
  }
}
