import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:arclock/core/theme/app_text_styles.dart';
import 'package:arclock/core/theme/ks_colors.dart';
import 'package:arclock/core/utils/date_formatter.dart';
import 'package:arclock/core/widgets/ks_empty_state.dart';
import 'package:arclock/core/widgets/ks_search_bar.dart';
import 'package:arclock/core/widgets/ks_sliding_notification.dart';
import 'package:arclock/features/job_logging/domain/entities/job_entity.dart';
import 'package:arclock/features/job_logging/presentation/providers/job_providers.dart';
import 'package:arclock/features/knowledge_base/presentation/providers/notes_providers.dart';
import '../providers/note_link_provider.dart';

/// Bottom sheet for linking a note to a job.
class NoteJobLinkScreen {
  static Future<void> show(BuildContext context, String noteId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) => _NoteJobLinkSheet(noteId: noteId),
    );
  }
}

class _NoteJobLinkSheet extends ConsumerStatefulWidget {
  final String noteId;
  const _NoteJobLinkSheet({required this.noteId});

  @override
  ConsumerState<_NoteJobLinkSheet> createState() => _NoteJobLinkSheetState();
}

class _NoteJobLinkSheetState extends ConsumerState<_NoteJobLinkSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(noteLinkByNoteProvider(widget.noteId));
    final jobState   = ref.watch(jobListProvider);
    final note = ref.read(notesListProvider).notes.where((n) => n.id == widget.noteId).firstOrNull;

    final allJobs = jobState.allJobs.where((j) => !j.isArchived && !j.isDeleted).toList();

    // Filter by query
    var filtered = _searchQuery.isEmpty
        ? allJobs
        : allJobs.where((j) {
            final q = _searchQuery.toLowerCase();
            return j.serviceType.toLowerCase().contains(q) ||
                   DateFormatter.display(j.jobDate).toLowerCase().contains(q) ||
                   (j.location?.toLowerCase().contains(q) ?? false);
          }).toList();

    // Sort: most recent first
    filtered.sort((a, b) => b.jobDate.compareTo(a.jobDate));

    // Prefer jobs matching the note's service type
    if (note?.serviceType != null) {
      final matchType = note!.serviceType!;
      filtered.sort((a, b) {
        final aScore = a.serviceType == matchType ? 0 : 1;
        final bScore = b.serviceType == matchType ? 0 : 1;
        if (aScore != bScore) return aScore.compareTo(bScore);
        return b.jobDate.compareTo(a.jobDate);
      });
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.ksc.neutral600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            child: Row(
              children: [
                Text("LINK TO JOB",
                  style: AppTextStyles.h2.copyWith(
                    color: context.ksc.white, fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(LineAwesomeIcons.times_solid,
                      color: context.ksc.neutral500, size: 20),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
            child: KsSearchBar(
              hint: 'Search by service type or date...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
          const SizedBox(height: 8),
          // Job list
          Expanded(
            child: linksAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: context.ksc.accent500)),
              error: (e, _) => Center(child: Text("COULD NOT LOAD LINKS", style: AppTextStyles.caption.copyWith(color: context.ksc.error500))),
              data: (links) {
                final linkedJobIds = links.map((l) => l.jobId).toSet();

                if (filtered.isEmpty) {
                  return KsEmptyState(
                    icon: _searchQuery.isEmpty ? LineAwesomeIcons.link_solid : LineAwesomeIcons.search_minus_solid,
                    title: _searchQuery.isEmpty ? "NO JOBS FOUND" : "NO RESULTS",
                    subtitle: _searchQuery.isEmpty ? "No jobs linked to this note yet." : "No jobs match your search.",
                  );
                }

                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final job = filtered[index];
                    final isLinked = linkedJobIds.contains(job.id);
                    return _buildJobTile(context, job, isLinked, links, linkedJobIds);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTile(
    BuildContext context,
    JobEntity job,
    bool isLinked,
    List<dynamic> links,
    Set<String> linkedJobIds,
  ) {
    return GestureDetector(
      onTap: () async {
        if (isLinked) {
          final existing = links.firstWhere((l) => l.jobId == job.id);
          await ref.read(noteLinkByNoteProvider(widget.noteId).notifier).deleteLink(existing.id);
          if (!context.mounted) return;
          KsSlidingNotification.show(context, message: "Link removed", type: KsNotificationType.info);
        } else {
          final result = await ref.read(noteLinkByNoteProvider(widget.noteId).notifier).createLink(widget.noteId, job.id);
          if (!context.mounted) return;
          KsSlidingNotification.show(
            context,
            message: result != null ? "Job linked" : "Could not link job",
            type: result != null ? KsNotificationType.success : KsNotificationType.error,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isLinked ? context.ksc.accent500.withValues(alpha: 0.5) : context.ksc.primary700,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isLinked ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary900,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isLinked ? context.ksc.accent500 : context.ksc.primary700),
              ),
              child: Icon(
                isLinked ? LineAwesomeIcons.check_solid : Icons.add,
                size: 16,
                color: isLinked ? context.ksc.accent500 : context.ksc.neutral500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.serviceType.replaceAll('_', ' ').toUpperCase(),
                    style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.display(job.jobDate).toUpperCase(),
                    style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600),
                  ),
                  if (job.location != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      job.location!,
                      style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
