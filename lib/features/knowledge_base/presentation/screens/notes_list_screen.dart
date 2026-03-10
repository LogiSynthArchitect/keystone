import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_skeleton_loader.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_card.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});
  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    switch (index) {
      case 0: context.go(RouteNames.jobs); break;
      case 1: context.go(RouteNames.customers); break;
      case 2: context.go(RouteNames.notes); break;
      case 3: context.go(RouteNames.profile); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notesListProvider);

    ref.listen(notesListProvider, (prev, next) {
      if (next.errorMessage != null && mounted) {
        KsSnackbar.show(context, message: next.errorMessage!, type: KsSnackbarType.error);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.neutral050,
      appBar: const KsAppBar(title: "Notes"),
      body: Column(
        children: [
          const KsOfflineBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.md, AppSpacing.pagePadding, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (q) => ref.read(notesListProvider.notifier).search(q),
              decoration: InputDecoration(
                hintText: "Search notes or tags...",
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.neutral400),
                prefixIcon: const Icon(Icons.search, color: AppColors.neutral400, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () { _searchController.clear(); ref.read(notesListProvider.notifier).search(''); setState(() {}); },
                        child: const Icon(Icons.close, color: AppColors.neutral400, size: 20))
                    : null,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.neutral200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.neutral200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.primary600, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: state.isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.pagePadding),
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, __) => const KsSkeletonLoader(height: 88),
                  )
                : state.displayed.isEmpty
                    ? KsEmptyState(
                        icon: Icons.lightbulb_outline,
                        title: state.searchQuery.isNotEmpty ? "No results for \"${state.searchQuery}\"" : "No notes yet",
                        subtitle: state.searchQuery.isEmpty ? "Save tips, techniques and solutions you want to remember." : null,
                        actionLabel: state.searchQuery.isEmpty ? "Add note" : null,
                        onAction: state.searchQuery.isEmpty ? () => context.push(RouteNames.addNote) : null,
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(notesListProvider.notifier).refresh(),
                        color: AppColors.primary700,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding, vertical: AppSpacing.sm),
                          itemCount: state.displayed.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final note = state.displayed[index];
                            return NoteCard(
                              note: note,
                              onTap: () => context.push(RouteNames.noteDetail(note.id)),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.addNote),
        backgroundColor: AppColors.primary700,
        elevation: 4,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      bottomNavigationBar: KsBottomNav(currentIndex: 2, onTabTapped: _onTabTapped),
    );
  }
}
