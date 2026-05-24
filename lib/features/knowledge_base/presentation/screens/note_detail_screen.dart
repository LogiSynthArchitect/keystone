import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/router/route_names.dart';
import '../providers/notes_providers.dart';
import '../../domain/entities/knowledge_note_entity.dart';
import '../../domain/entities/note_attachment.dart';
import '../../../job_logging/presentation/providers/job_providers.dart';
import '../../../note_links/presentation/providers/note_link_provider.dart';

class NoteDetailScreen extends ConsumerWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  KnowledgeNoteEntity? _findNote(NotesListState state) {
    try { return state.notes.firstWhere((n) => n.id == noteId); }
    catch (_) { return null; }
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
            icon: Icon(LineAwesomeIcons.share_alt_solid, color: context.ksc.neutral400, size: 22),
            onPressed: () {
              final text = [
                note.title.toUpperCase(),
                '',
                note.description,
                if (note.hasTags) '',
                if (note.hasTags) 'Tags: ${note.tags.map((t) => '#$t').join(' ')}',
                if (note.serviceType != null) '',
                if (note.serviceType != null) 'Category: ${note.serviceType!.replaceAll('_', ' ').toUpperCase()}',
                '',
                'Exported from Keystone',
              ].join('\n');
              Share.share(text, subject: note.title);
            },
          ),
          IconButton(
            icon: Icon(note.isPinned ? LineAwesomeIcons.thumbtack_solid : LineAwesomeIcons.thumbtack_solid, color: note.isPinned ? context.ksc.accent500 : context.ksc.neutral400, size: 22),
            onPressed: () => ref.read(notesListProvider.notifier).togglePin(note.id),
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.copy_solid, color: context.ksc.neutral400, size: 22),
            onPressed: () async {
              final newNote = await ref.read(addNoteProvider.notifier).save(
                title: '${note.title} (copy)',
                description: note.description,
                tags: note.tags,
                serviceType: note.serviceType,
              );
              if (newNote != null && context.mounted) {
                ref.read(notesListProvider.notifier).addNote(newNote);
                context.push(RouteNames.noteDetail(newNote.id));
              }
            },
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.edit, color: context.ksc.accent500, size: 22),
            onPressed: () => context.push(RouteNames.editNote(noteId)),
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
                  KsSnackbar.show(context, message: "Note moved to archive.", type: KsSnackbarType.info);
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
                    Text(
                      "ATTACHMENTS",
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.neutral500,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...note.attachments.map((att) => _AttachmentTile(
                      attachment: att,
                      key: ValueKey(att.id),
                    )),
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
                        onPressed: () => context.push(RouteNames.noteLinkJobs(noteId)),
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
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: context.ksc.primary700),
            ),
            child: Text(
              "No jobs linked yet.",
              style: AppTextStyles.body.copyWith(color: context.ksc.neutral500),
              textAlign: TextAlign.center,
            ),
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

/// Displays a single attachment tile based on its type (image/audio/document).
class _AttachmentTile extends StatelessWidget {
  final NoteAttachment attachment;
  const _AttachmentTile({super.key, required this.attachment});

  @override
  Widget build(BuildContext context) {
    switch (attachment.type) {
      case AttachmentType.image:
        return _ImageAttachmentTile(attachment: attachment);
      case AttachmentType.audio:
        return _AudioAttachmentTile(attachment: attachment);
      case AttachmentType.document:
        return _DocumentAttachmentTile(attachment: attachment);
    }
  }
}

class _ImageAttachmentTile extends StatelessWidget {
  final NoteAttachment attachment;
  const _ImageAttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.ksc.primary700),
          image: DecorationImage(
            image: attachment.url.startsWith('file://')
                ? FileImage(File(attachment.url.replaceFirst('file://', ''))) as ImageProvider
                : NetworkImage(attachment.url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// Inline audio player using just_audio.
class _AudioAttachmentTile extends StatefulWidget {
  final NoteAttachment attachment;
  const _AudioAttachmentTile({required this.attachment});

  @override
  State<_AudioAttachmentTile> createState() => _AudioAttachmentTileState();
}

class _AudioAttachmentTileState extends State<_AudioAttachmentTile> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.setUrl(widget.attachment.url);
    _player.durationStream.listen((d) {
      if (d != null && mounted) setState(() => _duration = d);
    });
    _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
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

  @override
  Widget build(BuildContext context) {
    final durLabel = widget.attachment.duration != null
        ? '${_formatDuration(Duration(seconds: widget.attachment.duration!))}'
        : (_duration.inSeconds > 0 ? _formatDuration(_duration) : null);

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
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: context.ksc.accent500,
                size: 32,
              ),
              onPressed: () {
                if (_isPlaying) {
                  _player.pause();
                } else {
                  if (_position == _duration) {
                    _player.seek(Duration.zero);
                  }
                  _player.play();
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.attachment.name,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.ksc.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (_duration.inSeconds > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _duration.inSeconds > 0 ? _position.inSeconds / _duration.inSeconds : 0,
                        backgroundColor: context.ksc.primary700,
                        valueColor: AlwaysStoppedAnimation(context.ksc.accent500),
                        minHeight: 3,
                      ),
                    ),
                ],
              ),
            ),
            if (durLabel != null)
              Text(
                durLabel,
                style: TextStyle(fontSize: 11, color: context.ksc.neutral400, fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }
}

/// Document/PDF attachment tile — opens file externally.
class _DocumentAttachmentTile extends StatelessWidget {
  final NoteAttachment attachment;
  const _DocumentAttachmentTile({required this.attachment});

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          children: [
            Icon(LineAwesomeIcons.file_pdf_solid, color: context.ksc.error500, size: 24),
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
            TextButton.icon(
              onPressed: () => OpenFilex.open(attachment.url),
              icon: Icon(LineAwesomeIcons.external_link_alt_solid, size: 12, color: context.ksc.accent500),
              label: Text("OPEN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: context.ksc.accent500, letterSpacing: 0.5)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
            ),
          ],
        ),
      ),
    );
  }
}
