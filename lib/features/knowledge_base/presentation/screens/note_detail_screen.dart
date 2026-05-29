import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import 'package:keystone/core/widgets/ks_sliding_notification.dart';
import '../providers/notes_providers.dart';
import 'add_note_screen.dart';
import '../../domain/entities/knowledge_note_entity.dart';
import '../../domain/entities/note_attachment.dart';
import '../../../job_logging/presentation/providers/job_providers.dart';
import '../../../note_links/presentation/providers/note_link_provider.dart';
import '../../../note_links/presentation/screens/note_job_link_screen.dart';

class NoteDetailScreen extends ConsumerWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  KnowledgeNoteEntity? _findNote(NotesListState state) {
    try { return state.notes.firstWhere((n) => n.id == noteId); }
    catch (_) {
      try { return state.searchResults.firstWhere((n) => n.id == noteId); }
      catch (_) { return null; }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesListProvider);
    final note = _findNote(state);

    if (note == null) {
      if (state.isLoading) {
        return Scaffold(
          backgroundColor: context.ksc.primary900,
          appBar: const KsAppBar(title: "NOTE", showBack: true),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      if (state.errorMessage != null) {
        return Scaffold(
          backgroundColor: context.ksc.primary900,
          appBar: const KsAppBar(title: "NOTE", showBack: true),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 48, color: context.ksc.error500),
                const SizedBox(height: 16),
                Text("FAILED TO LOAD", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(state.errorMessage!, textAlign: TextAlign.center, style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400)),
              ],
            ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: context.ksc.primary900,
        appBar: const KsAppBar(title: "NOTE", showBack: true),
        body: Center(child: Text("NOTE NOT FOUND", style: TextStyle(color: context.ksc.neutral400))),
      );
    }

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "NOTE DETAIL",
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(
              note.isPinned ? LineAwesomeIcons.thumbtack_solid : LineAwesomeIcons.map_pin_solid,
              color: note.isPinned ? context.ksc.accent500 : context.ksc.neutral400,
              size: 22,
            ),
            tooltip: note.isPinned ? 'Unpin note' : 'Pin note',
            onPressed: () => ref.read(notesListProvider.notifier).togglePin(note.id),
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.edit, color: context.ksc.accent500, size: 22),
            onPressed: () => AddNoteScreen.show(context, existingNote: note),
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.archive_solid, color: context.ksc.neutral400, size: 22),
            onPressed: () async {
              final confirm = await KsConfirmDialog.show(
                context,
                title: 'ARCHIVE NOTE',
                message: 'This note will be moved to the archive.',
                confirmLabel: 'ARCHIVE',
                cancelLabel: 'CANCEL',
                isDanger: true,
                onConfirm: () {},
              );
              if (confirm == true && context.mounted) {
                await ref.read(notesListProvider.notifier).archiveNote(note.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  KsSlidingNotification.show(context, message: "Note moved to archive.", type: KsNotificationType.info);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const KsOfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // INDUSTRIAL EYEBROW
                  Text(
                    "NOTE DETAILS",
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.accent500,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note.title.toUpperCase(),
                    style: AppTextStyles.h1.copyWith(color: context.ksc.white, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(LineAwesomeIcons.calendar, size: 14, color: context.ksc.neutral500),
                      const SizedBox(width: 6),
                      Text(
                        DateFormatter.display(note.createdAt).toUpperCase(),
                        style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w700)
                      ),
                    ],
                  ),
                  if (note.lastEditedAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LineAwesomeIcons.edit, size: 12, color: context.ksc.neutral600),
                        const SizedBox(width: 6),
                        Text(
                          "EDITED ${DateFormatter.relative(note.lastEditedAt!).toUpperCase()}",
                          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, fontWeight: FontWeight.w600, fontSize: 10),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // CONTENT MODULE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: context.ksc.primary800,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: context.ksc.primary700),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ANALYSIS & SOLUTION",
                          style: AppTextStyles.caption.copyWith(
                            color: context.ksc.neutral500,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          note.description,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: context.ksc.neutral100,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          )
                        ),
                      ],
                    ),
                  ),

                  if (note.hasPhoto) ...[
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: context.ksc.primary700),
                        image: DecorationImage(
                          image: NetworkImage(note.photoUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],

                  // ── ATTACHMENTS ──
                  if (note.hasAttachments) ...[
                    const SizedBox(height: 32),
                    // Image gallery (grouped)
                    if (note.attachments.any((a) => a.type == AttachmentType.image)) ...[
                      _ImageGallery(attachments: note.attachments.where((a) => a.type == AttachmentType.image).toList()),
                      const SizedBox(height: 24),
                    ],
                    // Audio recordings
                    if (note.attachments.any((a) => a.type == AttachmentType.audio)) ...[
                      Text("RECORDINGS",
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.neutral500, letterSpacing: 1.5, fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...note.attachments.where((a) => a.type == AttachmentType.audio).map((att) => _AudioAttachmentTile(
                        attachment: att, key: ValueKey(att.id),
                      )),
                      const SizedBox(height: 16),
                    ],
                    // Documents
                    if (note.attachments.any((a) => a.type == AttachmentType.document)) ...[
                      Text("DOCUMENTS",
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.neutral500, letterSpacing: 1.5, fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...note.attachments.where((a) => a.type == AttachmentType.document).map((att) => _DocumentAttachmentTile(
                        attachment: att, key: ValueKey(att.id),
                      )),
                    ],
                  ],

                  if (note.hasTags) ...[
                    const SizedBox(height: 32),
                    Text(
                      "SYSTEM TAGS",
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.neutral500,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      )
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: note.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.ksc.primary800,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: context.ksc.primary700),
                        ),
                        child: Text(
                          "#${tag.toUpperCase()}",
                          style: AppTextStyles.caption.copyWith(
                            color: context.ksc.accent500,
                            fontWeight: FontWeight.w800,
                          )
                        ),
                      )).toList(),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // LINKED JOBS SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "LINKED JOBS",
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.neutral500,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => NoteJobLinkScreen.show(context, noteId),
                        icon: Icon(Icons.add, size: 14, color: context.ksc.accent500),
                        label: Text("LINK JOB", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _LinkedJobsList(noteId: noteId),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedJobsList extends ConsumerWidget {
  final String noteId;
  const _LinkedJobsList({required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(noteLinkByNoteProvider(noteId));
    final jobState   = ref.watch(jobListProvider);

    return linksAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: context.ksc.accent500, strokeWidth: 2)),
      ),
      error: (_, __) => Text("Could not load links.", style: AppTextStyles.caption.copyWith(color: context.ksc.error500)),
      data: (links) {
        if (links.isEmpty) {
          return const KsEmptyState(
            icon: LineAwesomeIcons.link_solid,
            title: "NO JOBS LINKED YET",
            subtitle: "Tap LINK JOB above to attach a job to this note.",
          );
        }

        return Column(
          children: links.map((link) {
            final job = jobState.allJobs.where((j) => j.id == link.jobId).firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.ksc.primary800,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: context.ksc.primary700),
                ),
                child: Row(
                  children: [
                    Icon(LineAwesomeIcons.wrench_solid, size: 14, color: context.ksc.accent500),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job != null ? job.serviceType.replaceAll('_', ' ').toUpperCase() : 'JOB #${link.jobId.substring(0, 8)}',
                            style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
                          ),
                          if (job != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              DateFormatter.display(job.jobDate).toUpperCase(),
                              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(noteLinkByNoteProvider(noteId).notifier).deleteLink(link.id),
                      child: Icon(LineAwesomeIcons.times_solid, size: 14, color: context.ksc.neutral500),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Horizontal scrollable image gallery with full-screen viewer.
class _ImageGallery extends StatelessWidget {
  final List<NoteAttachment> attachments;
  const _ImageGallery({required this.attachments});

  ImageProvider<Object> _provider(NoteAttachment a) => a.url.startsWith('file://')
      ? FileImage(File(a.url.replaceFirst('file://', ''))) as ImageProvider<Object>
      : NetworkImage(a.url);

  void _openViewer(BuildContext context, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (context, _, __) => _ImageViewer(
          attachments: attachments,
          initialIndex: index,
          provider: _provider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = attachments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("IMAGES (${images.length})",
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500, letterSpacing: 1.5, fontWeight: FontWeight.w800,
              ),
            ),
            Text("Tap to expand",
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500, fontSize: 9, fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, i) {
              final att = images[i];
              return GestureDetector(
                onTap: () => _openViewer(context, i),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: context.ksc.primary700),
                    image: DecorationImage(image: _provider(att), fit: BoxFit.cover),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text("${i + 1}",
                          style: AppTextStyles.caption.copyWith(
                            color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Full-screen image viewer page (pushed as a transparent route).
class _ImageViewer extends StatefulWidget {
  final List<NoteAttachment> attachments;
  final int initialIndex;
  final ImageProvider<Object> Function(NoteAttachment) provider;

  const _ImageViewer({
    required this.attachments,
    required this.initialIndex,
    required this.provider,
  });

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.attachments;
    final current = images[_index];
    return Stack(
      children: [
        Center(
          child: InteractiveViewer(
            child: Image(
              image: widget.provider(current),
              fit: BoxFit.contain,
              height: double.infinity,
            ),
          ),
        ),
        // Close
        Positioned(
          top: 48, right: 16,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(LineAwesomeIcons.times_solid, color: Colors.white, size: 28),
          ),
        ),
        // Prev
        if (_index > 0)
          Positioned(
            left: 8, top: 0, bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _index--),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                  child: Icon(LineAwesomeIcons.angle_left_solid, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        // Next
        if (_index < images.length - 1)
          Positioned(
            right: 8, top: 0, bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _index++),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                  child: Icon(LineAwesomeIcons.angle_right_solid, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        // Counter
        Positioned(
          bottom: 48, left: 0, right: 0,
          child: Text(
            "${_index + 1} / ${images.length}",
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white60, fontWeight: FontWeight.w700, fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline audio player using just_audio with draggable seek bar.
class _AudioAttachmentTile extends StatefulWidget {
  final NoteAttachment attachment;
  const _AudioAttachmentTile({super.key, required this.attachment});

  @override
  State<_AudioAttachmentTile> createState() => _AudioAttachmentTileState();
}

class _AudioAttachmentTileState extends State<_AudioAttachmentTile> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isCompleted = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.setUrl(widget.attachment.remoteUrl ?? widget.attachment.url);
    _player.durationStream.listen((d) {
      if (d != null && mounted) setState(() => _duration = d);
    });
    _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _isCompleted = true;
          _position = _duration;
        }
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  void _onPlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      if (_isCompleted) {
        _isCompleted = false;
        _player.seek(Duration.zero);
      }
      _player.play();
    }
  }

  void _onSeek(double fraction) {
    final target = Duration(milliseconds: (_duration.inMilliseconds * fraction.clamp(0.0, 1.0)).round());
    _player.seek(target);
    _isCompleted = false;
  }

  @override
  Widget build(BuildContext context) {
    final hasDuration = _duration.inSeconds > 0;
    final progress = hasDuration ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;
    final remaining = hasDuration ? _duration - _position : Duration.zero;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: play button + name + total duration
            Row(
              children: [
                GestureDetector(
                  onTap: _onPlayPause,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.ksc.accent500,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: context.ksc.primary900,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.attachment.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isCompleted ? context.ksc.neutral500 : context.ksc.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_isCompleted)
                        Text("Completed · Tap to replay",
                          style: AppTextStyles.caption.copyWith(
                            color: context.ksc.accent500, fontWeight: FontWeight.w700, fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.attachment.duration != null)
                  Text(
                    _formatDuration(Duration(seconds: widget.attachment.duration!)),
                    style: TextStyle(fontSize: 11, color: context.ksc.neutral400, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            // Seek bar
            if (hasDuration) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  _onSeek(progress + details.delta.dx / 200); // rough, improved below
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    return GestureDetector(
                      onTapDown: (details) {
                        final fraction = details.localPosition.dx / totalWidth;
                        _onSeek(fraction.clamp(0.0, 1.0));
                      },
                      child: Container(
                        height: 20,
                        alignment: Alignment.centerLeft,
                        child: Stack(
                          children: [
                            // Track background
                            Positioned.fill(
                              child: Container(
                                height: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: context.ksc.primary700,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            // Fill
                            Positioned(
                              left: 0, top: 8,
                              width: totalWidth * progress.clamp(0.0, 1.0),
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: context.ksc.accent500,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Time row: current + remaining
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position),
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral400, fontWeight: FontWeight.w600, fontSize: 9,
                    ),
                  ),
                  Text("-${_formatDuration(remaining)}",
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral500, fontWeight: FontWeight.w600, fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Document/PDF attachment tile — tappable card, opens file externally.
class _DocumentAttachmentTile extends StatelessWidget {
  final NoteAttachment attachment;
  const _DocumentAttachmentTile({super.key, required this.attachment});

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get _resolvedPath {
    // Prefer local file path (transient, for fast offline display)
    if (attachment.localPath != null) {
      return attachment.localPath!.startsWith('file://')
          ? attachment.localPath!.replaceFirst('file://', '')
          : attachment.localPath!;
    }
    // Fall back to remote URL (streaming)
    if (attachment.remoteUrl != null) return attachment.remoteUrl!;
    // Legacy: direct url field
    if (attachment.url.startsWith('file://')) {
      return attachment.url.replaceFirst('file://', '');
    }
    return attachment.url;
  }

  Future<void> _openFile(BuildContext context) async {
    try {
      final result = await OpenFilex.open(_resolvedPath);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          KsSlidingNotification.show(context, message: "Could not open file: ${result.message}",
              type: KsNotificationType.error);
        }
      }
    } catch (e) {
      if (context.mounted) {
        KsSlidingNotification.show(context, message: "Could not open attachment",
            type: KsNotificationType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _openFile(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.ksc.primary700),
          ),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: context.ksc.accent500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(LineAwesomeIcons.file_pdf_solid, color: context.ksc.accent500, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.ksc.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (attachment.size != null)
                      Text(
                        _formatSize(attachment.size),
                        style: TextStyle(fontSize: 10, color: context.ksc.neutral500),
                      ),
                  ],
                ),
              ),
              Text("OPEN",
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
