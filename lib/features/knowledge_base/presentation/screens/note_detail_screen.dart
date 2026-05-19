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
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/router/route_names.dart';
import '../providers/notes_providers.dart';
import '../../domain/entities/knowledge_note_entity.dart';
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
