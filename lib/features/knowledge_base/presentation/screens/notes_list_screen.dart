import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
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
  final _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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

    final v1Types = [
      'car_lock_programming',
      'door_lock_installation',
      'door_lock_repair',
      'smart_lock_installation',
    ];

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "KNOWLEDGE BASE",
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
        ],
      ),
      body: Column(
        children: [
          const KsOfflineBanner(),

          // Search Bar - INDUSTRIAL COMMAND STYLE
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.ksc.primary800,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _isSearchFocused ? context.ksc.accent500 : context.ksc.primary700,
                      width: _isSearchFocused ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (q) {
                      ref.read(notesListProvider.notifier).search(q);
                    },
                    style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
                    cursorColor: context.ksc.accent500,
                    decoration: InputDecoration(
                      hintText: "Search your notes...",
                      hintStyle: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, letterSpacing: 1.0),
                      prefixIcon: Icon(LineAwesomeIcons.search_solid, color: _isSearchFocused ? context.ksc.accent500 : context.ksc.neutral500, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                ref.read(notesListProvider.notifier).search('');
                              },
                              child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20))
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // TACTICAL FILTER MODULE
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: "ALL",
                        isSelected: state.filterCategory == null,
                        onTap: () => ref.read(notesListProvider.notifier).filterByCategory(null),
                      ),
                      const SizedBox(width: 8),
                      ...v1Types.map((type) {
                        final labels = {
                          'car_lock_programming': "CAR KEY",
                          'door_lock_installation': "INSTALL",
                          'door_lock_repair': "REPAIR",
                          'smart_lock_installation': "SMART",
                        };
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildFilterChip(
                            label: labels[type]!,
                            isSelected: state.filterCategory == type,
                            onTap: () => ref.read(notesListProvider.notifier).filterByCategory(type),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: state.isLoading
                ? _buildLoadingState()
                : state.displayed.isEmpty
                    ? _buildEmptyState(state.searchQuery)
                    : RefreshIndicator(
                        onRefresh: () => ref.read(notesListProvider.notifier).refresh(),
                        color: context.ksc.accent500,
                        backgroundColor: context.ksc.primary800,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          itemCount: state.displayed.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
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
        backgroundColor: context.ksc.accent500,
        foregroundColor: context.ksc.primary900,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: const Icon(LineAwesomeIcons.plus_solid, size: 28),
      ),
      bottomNavigationBar: KsBottomNav(currentIndex: 2, onTabTapped: _onTabTapped),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? LineAwesomeIcons.search_minus_solid : LineAwesomeIcons.lightbulb,
              size: 80,
              color: context.ksc.primary800
            ),
            const SizedBox(height: 24),
            Text(
              isSearching ? "NO RESULTS FOUND" : "NO NOTES YET",
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)
            ),
            const SizedBox(height: 12),
            Text(
              isSearching
                ? "Search yielded zero results for \"$query\"."
                : "No notes created yet.\nTap + below to write your first note.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400, height: 1.5)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.ksc.accent500 : context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? context.ksc.accent500 : context.ksc.primary700,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? context.ksc.primary900 : context.ksc.neutral400,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
