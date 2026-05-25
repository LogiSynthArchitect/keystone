import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_filter_sheet.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/widgets/ks_search_bar.dart';
import '../providers/notes_providers.dart';
import 'add_note_screen.dart';
import '../../../reminders/presentation/providers/reminders_provider.dart';
import '../widgets/note_card.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});
  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final currentCategory = ref.read(notesListProvider).filterCategory;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (ctx) {
        var draftCategory = currentCategory;
        return StatefulBuilder(
          builder: (context, setInnerState) => KsFilterSheet(
            title: "FILTER NOTES",
            onApply: () => ref.read(notesListProvider.notifier).filterByCategory(draftCategory),
            onClear: () {
              draftCategory = null;
              setInnerState(() {});
            },
            children: [
              KsFilterChipGroup(
                label: "CATEGORY",
                selected: draftCategory,
                onSelect: (v) => setInnerState(() => draftCategory = v),
                options: const [
                  KsFilterOption(value: 'car_lock_programming', display: 'CAR KEY', icon: '🚗'),
                  KsFilterOption(value: 'door_lock_installation', display: 'INSTALL', icon: '🔧'),
                  KsFilterOption(value: 'door_lock_repair', display: 'REPAIR', icon: '🔨'),
                  KsFilterOption(value: 'smart_lock_installation', display: 'SMART', icon: '🏠'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesListProvider);
    final remindersCount = ref.watch(remindersProvider).activeCount;
    final hasActiveFilter = state.filterCategory != null;

    ref.listen(notesListProvider, (prev, next) {
      if (next.errorMessage != null && mounted) {
        KsSnackbar.show(context, message: next.errorMessage!, type: KsSnackbarType.error);
      }
    });

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "KNOWLEDGE BASE",
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(
              state.showArchived ? LineAwesomeIcons.eye_solid : LineAwesomeIcons.archive_solid,
              color: state.showArchived ? context.ksc.accent500 : context.ksc.neutral500,
              size: 22,
            ),
            onPressed: () => ref.read(notesListProvider.notifier).toggleArchived(),
            tooltip: state.showArchived ? "Show Active" : "Show Archived",
          ),
          IconButton(
            icon: Icon(LineAwesomeIcons.filter_solid, color: hasActiveFilter ? context.ksc.accent500 : context.ksc.neutral400, size: 22),
            onPressed: () => _showFilterSheet(context),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(LineAwesomeIcons.bell_solid, color: remindersCount > 0 ? context.ksc.accent500 : context.ksc.neutral400, size: 22),
                onPressed: () => context.push(RouteNames.reminders),
              ),
              if (remindersCount > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(color: context.ksc.error500, shape: BoxShape.circle),
                    child: Center(child: Text('$remindersCount', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: context.ksc.white))),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: KsSearchBar(
              hint: "Search your notes...",
              controller: _searchController,
              onChanged: (q) => ref.read(notesListProvider.notifier).search(q),
              onClear: () {
                _searchController.clear();
                ref.read(notesListProvider.notifier).search('');
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const KsOfflineBanner(),
          const SizedBox(height: 8),

          Expanded(
            child: state.isLoading
                ? _buildLoadingState()
                : state.errorMessage != null && state.displayed.isEmpty
                    ? _buildErrorState(context, ref)
                    : state.displayed.isEmpty
                        ? _buildEmptyState(state.searchQuery)
                        : NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              if (n is ScrollEndNotification && n.metrics.extentAfter < 200) {
                                ref.read(notesListProvider.notifier).loadMore();
                              }
                              return false;
                            },
                            child: RefreshIndicator(
                              onRefresh: () => ref.read(notesListProvider.notifier).refresh(),
                              color: context.ksc.accent500,
                              backgroundColor: context.ksc.primary800,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                                itemCount: state.paged.length + (state.hasMore ? 1 : 0),
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  if (index == state.paged.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Center(
                                        child: CircularProgressIndicator(strokeWidth: 2, color: context.ksc.accent500),
                                      ),
                                    );
                                  }
                                  final note = state.paged[index];
                                  return Dismissible(
                                    key: ValueKey(note.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 24),
                                      decoration: BoxDecoration(
                                        color: context.ksc.neutral500,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(LineAwesomeIcons.archive_solid, color: context.ksc.white, size: 24),
                                    ),
                                    confirmDismiss: (_) async {
                                      await ref.read(notesListProvider.notifier).archiveNote(note.id);
                                      if (context.mounted) {
                                        KsSnackbar.show(context, message: "Note archived", type: KsSnackbarType.success);
                                      }
                                      return true;
                                    },
                                    child: NoteCard(
                                      note: note,
                                      onTap: () => context.push(RouteNames.noteDetail(note.id)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final note = await AddNoteScreen.show(context);
          if (note != null && context.mounted) {
            ref.read(notesListProvider.notifier).addNote(note);
          }
        },
        backgroundColor: context.ksc.accent500,
        foregroundColor: context.ksc.primary900,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: const Icon(LineAwesomeIcons.plus_solid, size: 28),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 64, color: context.ksc.error500),
            const SizedBox(height: 24),
            Text(
              "FAILED TO LOAD",
              style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, letterSpacing: 1.0),
            ),
            const SizedBox(height: 12),
            Text(
              "Could not load notes. Check your connection and try again.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400, height: 1.5),
            ),
            const SizedBox(height: 24),
            KsButton(
              label: "TAP TO RETRY",
              variant: KsButtonVariant.primary,
              size: KsButtonSize.small,
              fullWidth: false,
              onPressed: () => ref.read(notesListProvider.notifier).load(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(24.0),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.ksc.primary700),
        ),
      ).animate(onPlay: (controller) => controller.repeat())
       .shimmer(duration: 1200.ms, color: context.ksc.primary700.withValues(alpha: 0.5)),
    );
  }

  Widget _buildEmptyState(String query) {
    final isSearching = query.isNotEmpty;
    return KsEmptyState(
      icon: isSearching ? LineAwesomeIcons.search_minus_solid : LineAwesomeIcons.lightbulb,
      title: isSearching ? "NO RESULTS FOUND" : "NO NOTES YET",
      subtitle: isSearching
        ? 'Search yielded zero results for "$query".'
        : "No notes created yet.\nTap + below to write your first note.",
    );
  }
}
