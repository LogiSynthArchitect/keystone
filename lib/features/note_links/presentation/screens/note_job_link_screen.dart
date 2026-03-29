import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:keystone/core/theme/app_text_styles.dart';
import 'package:keystone/core/theme/ks_colors.dart';
import 'package:keystone/core/utils/date_formatter.dart';
import 'package:keystone/core/widgets/ks_app_bar.dart';
import 'package:keystone/core/widgets/ks_offline_banner.dart';
import 'package:keystone/core/widgets/ks_snackbar.dart';
import 'package:keystone/features/job_logging/domain/entities/job_entity.dart';
import 'package:keystone/features/job_logging/presentation/providers/job_providers.dart';
import '../providers/note_link_provider.dart';

class NoteJobLinkScreen extends ConsumerStatefulWidget {
  final String noteId;
  const NoteJobLinkScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteJobLinkScreen> createState() => _NoteJobLinkScreenState();
}

class _NoteJobLinkScreenState extends ConsumerState<NoteJobLinkScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(noteLinkByNoteProvider(widget.noteId));
    final jobState   = ref.watch(jobListProvider);

    final allJobs = jobState.allJobs.where((j) => !j.isArchived && !j.isDeleted).toList();

    final filtered = _searchQuery.isEmpty
        ? allJobs
        : allJobs.where((j) {
            final q = _searchQuery.toLowerCase();
            return j.serviceType.toLowerCase().contains(q) ||
                   DateFormatter.display(j.jobDate).toLowerCase().contains(q) ||
                   (j.location?.toLowerCase().contains(q) ?? false);
          }).toList();

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: const KsAppBar(title: "LINK TO JOB", showBack: true),
      body: Column(
        children: [
          const KsOfflineBanner(),
          _buildSearchBar(context),
          Expanded(
            child: linksAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: context.ksc.accent500)),
              error: (e, _) => Center(child: Text("COULD NOT LOAD LINKS", style: AppTextStyles.caption.copyWith(color: context.ksc.error500))),
              data: (links) {
                final linkedJobIds = links.map((l) => l.jobId).toSet();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty ? "NO JOBS FOUND" : "NO RESULTS",
                      style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, letterSpacing: 1.5),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      color: context.ksc.primary800,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: AppTextStyles.body.copyWith(color: context.ksc.white),
        cursorColor: context.ksc.accent500,
        decoration: InputDecoration(
          hintText: "Search by service type or date...",
          hintStyle: AppTextStyles.body.copyWith(color: context.ksc.neutral500),
          prefixIcon: Icon(LineAwesomeIcons.search_solid, color: context.ksc.neutral500, size: 18),
          filled: true,
          fillColor: context.ksc.primary900,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: context.ksc.primary700)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: context.ksc.primary700)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: context.ksc.accent500)),
        ),
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
          KsSnackbar.show(context, message: "Link removed", type: KsSnackbarType.info);
        } else {
          final result = await ref.read(noteLinkByNoteProvider(widget.noteId).notifier).createLink(widget.noteId, job.id);
          if (!context.mounted) return;
          KsSnackbar.show(
            context,
            message: result != null ? "Job linked" : "Could not link job",
            type: result != null ? KsSnackbarType.success : KsSnackbarType.error,
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
              width: 32,
              height: 32,
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
