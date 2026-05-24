import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/widgets/ks_step_drawer.dart';
import '../../../../features/service_types/presentation/widgets/service_type_picker_v2.dart';
import '../providers/notes_providers.dart';
import '../widgets/tag_input_field.dart';
import '../../domain/entities/note_attachment.dart';
import '../../domain/entities/knowledge_note_entity.dart';

class AddNoteScreen extends ConsumerStatefulWidget {
  const AddNoteScreen({super.key});

  /// Shows the add note sheet as a modal bottom sheet. Returns the created [KnowledgeNoteEntity] or null.
  static Future<KnowledgeNoteEntity?> show(BuildContext context) {
    return showModalBottomSheet<KnowledgeNoteEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) => const AddNoteScreen(),
    );
  }

  @override
  ConsumerState<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends ConsumerState<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _tags = [];
  String? _serviceType;
  List<NoteAttachment> _attachments = [];

  final _recorder = AudioRecorder();
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addNoteProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _recordingTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _titleController.text.trim().isNotEmpty ||
      _descriptionController.text.trim().isNotEmpty ||
      _tags.isNotEmpty ||
      _serviceType != null ||
      _attachments.isNotEmpty;

  bool _canAdvance(int step, int subStep) {
    if (step == 0) {
      return _titleController.text.trim().length >= 3 &&
          _descriptionController.text.trim().length >= 10;
    }
    return true;
  }

  void _handleBack() {
    _confirmDiscard().then((ok) {
      if (ok && context.mounted) Navigator.of(context).pop();
    });
  }

  void _handleClose() {
    _confirmDiscard().then((ok) {
      if (ok && context.mounted) Navigator.of(context).pop();
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.ksc.primary800,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: context.ksc.primary700),
            ),
            title: Text('DISCARD CHANGES?',
                style: AppTextStyles.h3.copyWith(
                    color: context.ksc.white, fontWeight: FontWeight.w900)),
            content: Text('You have unsaved notes. Leave anyway?',
                style:
                    AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('KEEP EDITING',
                    style: AppTextStyles.label.copyWith(
                        color: context.ksc.neutral400)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('DISCARD',
                    style: AppTextStyles.label.copyWith(
                        color: context.ksc.error500,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _onSave() async {
    HapticFeedback.heavyImpact();
    final note = await ref.read(addNoteProvider.notifier).save(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          tags: _tags,
          serviceType: _serviceType,
          attachments: _attachments.isNotEmpty ? _attachments : null,
        );
    if (!mounted) return;
    if (note != null) {
      Navigator.of(context).pop(note);
      KsSnackbar.show(context, message: "Note saved",
          type: KsSnackbarType.success);
    } else {
      final error = ref.read(addNoteProvider).errorMessage;
      KsSnackbar.show(context, message: error ?? "Could not save note",
          type: KsSnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KsStepDrawer(
      showBackArrow: true,
      title: "ADD NOTE",
      steps: const [
        KsStep(
          label: 'NOTE CONTENT',
          icon: LineAwesomeIcons.edit_solid,
          tip: 'Give your note a clear title and describe the steps.',
          imageAsset: 'assets/icons/3d/transparent/66b0f8-pencil.png',
        ),
        KsStep(
          label: 'TAGS & CATEGORY',
          icon: LineAwesomeIcons.tags_solid,
          tip: 'Tags help you find this note later by keywords.',
          imageAsset: 'assets/icons/3d/transparent/628100-notebook.png',
        ),
        KsStep(
          label: 'ATTACHMENTS',
          icon: LineAwesomeIcons.paperclip_solid,
          tip: 'Add audio recordings or PDF documents to your note.',
          imageAsset: 'assets/icons/3d/transparent/135b84-file-fav.png',
        ),
      ],
      onBack: _handleBack,
      onClose: _handleClose,
      nextLabel: "NEXT",
      saveLabel: "SAVE NOTE",
      canAdvance: _canAdvance,
      onSave: _onSave,
      stepContent: (step, subStep, setSheetState) {
        // Use the drawer's setState for UI updates triggered by callbacks
        switch (step) {
          case 0:
            return _buildStep1();
          case 1:
            return _buildStep2();
          case 2:
            return _buildStep3(setSheetState);
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("YOUR NOTE",
              style: AppTextStyles.h2.copyWith(
                  color: context.ksc.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text("Write down the problem and how you fixed it.",
              style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
          const SizedBox(height: 24),
          _buildDarkField(
            label: "Note Title",
            hint: "e.g. Rekeying Kwikset Deadbolt",
            controller: _titleController,
            fieldHint: "A short title helps you find this note later.",
            maxLength: 200,
          ),
          const SizedBox(height: 20),
          _buildDarkField(
            label: "Description",
            hint: "Step by step notes, tips, what worked...",
            maxLines: 5,
            controller: _descriptionController,
            fieldHint: "Write your full notes here — steps, tips, what worked.",
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ORGANISE YOUR NOTE",
              style: AppTextStyles.h2.copyWith(
                  color: context.ksc.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text("Add tags and a category to find this note easily later.",
              style:
                  AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
          const SizedBox(height: 24),
          Text("TAGS",
              style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral500,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0)),
          const SizedBox(height: 8),
          TagInputField(
              tags: _tags, onChanged: (tags) => setState(() => _tags = tags)),
          const SizedBox(height: 24),
          Text("SERVICE CATEGORY (OPTIONAL)",
              style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral500,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0)),
          const SizedBox(height: 12),
          // Selected category chip
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
                      style: AppTextStyles.bodyLarge.copyWith(
                          color: context.ksc.accent500,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _serviceType = null),
                    child: Icon(LineAwesomeIcons.times_circle_solid,
                        size: 20, color: context.ksc.error500),
                  ),
                ],
              ),
            ),
          // Tap to pick or change category
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
                  Icon(LineAwesomeIcons.folder_open_solid,
                      size: 16, color: context.ksc.neutral500),
                  const SizedBox(width: 12),
                  Text(
                    _serviceType == null
                        ? "Select a service category..."
                        : "Change category",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _serviceType == null
                          ? context.ksc.neutral500
                          : context.ksc.neutral400,
                    ),
                  ),
                  const Spacer(),
                  Icon(LineAwesomeIcons.chevron_right_solid,
                      size: 14, color: context.ksc.neutral500),
                ],
              ),
            ),
          ),
        ],
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
            // Drag handle
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

  Widget _buildStep3(StateSetter setSheetState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ATTACHMENTS",
              style: AppTextStyles.h2.copyWith(
                  color: context.ksc.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text("Add audio recordings or PDF documents to your note.",
              style:
                  AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
          const SizedBox(height: 24),
          if (_attachments.isNotEmpty) ...[
            Text("CURRENT ATTACHMENTS",
                style: AppTextStyles.caption.copyWith(
                    color: context.ksc.neutral500,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0)),
            const SizedBox(height: 8),
            ..._attachments.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.ksc.primary800,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: context.ksc.primary700),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          a.type == AttachmentType.audio
                              ? LineAwesomeIcons.microphone_solid
                              : a.type == AttachmentType.image
                                  ? LineAwesomeIcons.image_solid
                                  : LineAwesomeIcons.file_pdf_solid,
                          size: 18,
                          color: context.ksc.accent500,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            a.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                                color: context.ksc.white,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (a.size != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              _formatSize(a.size!),
                              style: AppTextStyles.caption.copyWith(
                                  color: context.ksc.neutral500),
                            ),
                          ),
                        GestureDetector(
                          onTap: () => setSheetState(() => _attachments.remove(a)),
                          child: Icon(LineAwesomeIcons.times_circle_solid,
                              size: 20, color: context.ksc.error500),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 24),
          ],
          if (_isRecording)
            _buildRecordingIndicator()
          else ...[
            _buildActionButton(
              icon: LineAwesomeIcons.microphone_solid,
              label: "RECORD AUDIO",
              onTap: _startRecording,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: LineAwesomeIcons.image_solid,
              label: "ADD IMAGE",
              onTap: _pickImage,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              icon: LineAwesomeIcons.file_pdf_solid,
              label: "ATTACH PDF",
              onTap: _pickPdf,
            ),
          ],
          if (_isUploading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator(color: Color(0xFFD4A84B))),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    final minutes = _recordingDuration ~/ 60;
    final seconds = _recordingDuration % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

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

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        KsSnackbar.show(context, message: "Microphone permission denied",
            type: KsSnackbarType.error);
      }
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${const Uuid().v4()}.m4a';

    await _recorder.start(RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath);

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });

    _recordingTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
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
        KsSnackbar.show(context, message: "Could not save audio",
            type: KsSnackbarType.error);
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
        KsSnackbar.show(context, message: "Could not save image",
            type: KsSnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickPdf() async {
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

    try {
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
      if (mounted) {
        KsSnackbar.show(context, message: "Could not save PDF",
            type: KsSnackbarType.error);
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

  Widget _buildDarkField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    String? fieldHint,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0)),
        if (fieldHint != null) ...[
          const SizedBox(height: 4),
          Text(fieldHint,
              style: AppTextStyles.caption.copyWith(
                  color: context.ksc.accent500.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.5)),
        ],
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (context,
                {required currentLength, required isFocused, maxLength}) =>
                null,
            style: AppTextStyles.bodyLarge.copyWith(
                color: context.ksc.white, fontWeight: FontWeight.w700),
            cursorColor: context.ksc.accent500,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: context.ksc.neutral500),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
