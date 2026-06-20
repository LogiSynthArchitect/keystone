import 'dart:async';
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
import '../../../../core/widgets/ks_filter_sheet.dart';
import '../../../../core/widgets/ks_icon_well.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import 'package:arclock/core/widgets/ks_sliding_notification.dart';
import '../../../../core/widgets/ks_search_bar.dart';
import '../../../../core/widgets/ks_error_state.dart';
import '../../../../core/widgets/ks_shimmer_list.dart';
import '../../../reminders/presentation/providers/reminders_provider.dart';
import '../providers/customer_providers.dart';
import 'add_customer_screen.dart';
import '../widgets/customer_card.dart';
import '../widgets/contact_import_sheet.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});
  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    switch (index) {
      case 0: context.go(RouteNames.dashboard); break;
      case 1: context.go(RouteNames.jobs); break;
      case 2: context.go(RouteNames.customers); break;
      case 3: context.go(RouteNames.hub); break;
    }
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (ctx) {
        final provider = ref.read(customerListProvider.notifier);
        final state = ref.read(customerListProvider);
        var draftFilterType = state.filterType;
        var draftPropertyFilter = state.propertyFilter;
        var draftLeadSourceFilter = state.leadSourceFilter;
        return StatefulBuilder(
          builder: (context, setInnerState) => KsFilterSheet(
            title: "FILTER CUSTOMERS",
            onApply: () {
              provider.setFilter(draftFilterType);
              provider.setPropertyFilter(draftPropertyFilter);
              provider.setLeadSourceFilter(draftLeadSourceFilter);
            },
            onClear: () {
              draftFilterType = 'all';
              draftPropertyFilter = null;
              draftLeadSourceFilter = null;
              setInnerState(() {});
            },
            children: [
              KsFilterChipGroup(
                label: "TYPE",
                selected: draftFilterType,
                onSelect: (v) => setInnerState(() => draftFilterType = v ?? 'all'),
                options: const [
                  KsFilterOption(value: 'all', display: 'ALL', icon: '👥'),
                  KsFilterOption(value: 'recent', display: 'RECENT', icon: '🕐'),
                  KsFilterOption(value: 'repeat', display: 'REPEAT', icon: '🔄'),
                ],
              ),
              KsFilterChipGroup(
                label: "PROPERTY TYPE",
                selected: draftPropertyFilter,
                onSelect: (v) => setInnerState(() => draftPropertyFilter = v),
                options: const [
                  KsFilterOption(value: 'residential', display: 'RESIDENTIAL', icon: '🏠'),
                  KsFilterOption(value: 'commercial', display: 'COMMERCIAL', icon: '🏢'),
                  KsFilterOption(value: 'automotive', display: 'AUTOMOTIVE', icon: '🚗'),
                ],
              ),
              KsFilterChipGroup(
                label: "LEAD SOURCE",
                selected: draftLeadSourceFilter,
                onSelect: (v) => setInnerState(() => draftLeadSourceFilter = v),
                options: const [
                  KsFilterOption(value: 'referral', display: 'REFERRAL', icon: '👥'),
                  KsFilterOption(value: 'whatsapp', display: 'WHATSAPP', icon: '💬'),
                  KsFilterOption(value: 'google_maps', display: 'GOOGLE', icon: '🔍'),
                  KsFilterOption(value: 'word_of_mouth', display: 'WORD OF MOUTH', icon: '🗣️'),
                  KsFilterOption(value: 'physical_card', display: 'CARD', icon: '🃏'),
                  KsFilterOption(value: 'other', display: 'OTHER', icon: '📌'),
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
    final state = ref.watch(customerListProvider);
    final remindersCount = ref.watch(remindersProvider).activeCount;
    final hasActiveFilter = state.filterType != 'all' || state.propertyFilter != null || state.leadSourceFilter != null;

    ref.listen(customerListProvider, (prev, next) {
      if (next.errorMessage != null && mounted) {
        KsSlidingNotification.show(context, message: next.errorMessage!, type: KsNotificationType.error);
      }
    });

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "CUSTOMERS",
        actions: [
          KsIconWell(
            icon: LineAwesomeIcons.address_book_solid,
            onTap: () {
              final existing = ref.read(customerListProvider).displayed;
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: context.ksc.primary900,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
                builder: (_) => ContactImportSheet(existingCustomers: existing),
              );
            },
          ),
          KsIconWell(
            icon: LineAwesomeIcons.filter_solid,
            isActive: hasActiveFilter,
            onTap: () => _showFilterSheet(context),
          ),
          KsIconWell(
            icon: LineAwesomeIcons.bell_solid,
            isActive: remindersCount > 0,
            badgeCount: remindersCount,
            onTap: () => context.push(RouteNames.reminders),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: KsSearchBar(
              hint: "Search customers...",
              controller: _searchController,
              onChanged: (q) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                  ref.read(customerListProvider.notifier).search(q);
                });
              },
              onClear: () {
                _searchController.clear();
                ref.read(customerListProvider.notifier).search('');
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (state.customers.isNotEmpty)
            _CustomerSummaryStrip(
              totalCount: state.totalCount ?? state.customers.length,
              displayedCount: state.displayed.length,
              repeatCount: state.repeatCount,
              pendingFollowUpCount: state.pendingFollowUpCount,
              pendingSyncCount: state.pendingSyncCount,
              hasActiveFilters: hasActiveFilter,
              filterLabel: _filterLabel(state),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),

          Expanded(
            child: state.isLoading
                ? _buildLoadingState()
                : state.errorMessage != null && state.displayed.isEmpty
                    ? _buildErrorState(context, ref)
                    : state.displayed.isEmpty
                        ? _buildEmptyState(state.searchQuery)
                    : RefreshIndicator(
                        onRefresh: () => ref.read(customerListProvider.notifier).refresh(),
                        color: context.ksc.accent500,
                        backgroundColor: context.ksc.primary800,
                        child: NotificationListener<ScrollEndNotification>(
                          onNotification: (notification) {
                            if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
                              ref.read(customerListProvider.notifier).loadMore();
                            }
                            return false;
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                            itemCount: state.paged.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final customer = state.paged[index];
                              return CustomerCard(
                                customer: customer,
                                hasPendingFollowUp: state.pendingFollowUpCustomerIds.contains(customer.id),
                                onTap: () => context.push(RouteNames.customerDetail(customer.id)),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddCustomerScreen.show(context),
        backgroundColor: context.ksc.accent500,
        foregroundColor: context.ksc.primary900,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: const Icon(LineAwesomeIcons.plus_solid, size: 28),
      ),
      bottomNavigationBar: KsBottomNav(currentIndex: 2, onTabTapped: _onTabTapped),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return KsErrorState(
      subtitle: 'Could not load customers. Check your connection and try again.',
      onRetry: () => ref.read(customerListProvider.notifier).load(),
    );
  }

  Widget _buildLoadingState() {
    return const KsShimmerList(itemCount: 5, itemHeight: 72);
  }

  String _filterLabel(CustomerListState state) {
    final parts = <String>[];
    if (state.filterType == 'recent') parts.add('RECENT (7D)');
    else if (state.filterType == 'repeat') parts.add('REPEAT');
    if (state.propertyFilter != null) parts.add(state.propertyFilter!.toUpperCase());
    if (state.leadSourceFilter != null) parts.add(state.leadSourceFilter!.toUpperCase().replaceAll('_', ' '));
    return parts.isEmpty ? 'FILTERED' : parts.join(' · ');
  }

  Widget _buildEmptyState(String query) {
    final isSearching = query.isNotEmpty;
    return KsEmptyState(
      icon: isSearching ? LineAwesomeIcons.search_minus_solid : LineAwesomeIcons.users_solid,
      title: isSearching ? "NO RESULTS FOUND" : "NO CUSTOMERS YET",
      subtitle: isSearching
        ? 'Search yielded zero results for "$query".'
        : "No customers added yet.\nTap + below to add your first customer.",
    );
  }
}

class _CustomerSummaryStrip extends StatelessWidget {
  final int totalCount;
  final int displayedCount;
  final int repeatCount;
  final int pendingFollowUpCount;
  final int pendingSyncCount;
  final bool hasActiveFilters;
  final String filterLabel;

  const _CustomerSummaryStrip({
    required this.totalCount,
    required this.displayedCount,
    required this.repeatCount,
    required this.pendingFollowUpCount,
    required this.pendingSyncCount,
    required this.hasActiveFilters,
    required this.filterLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bigNumber = hasActiveFilters ? displayedCount : totalCount;
    final label = hasActiveFilters ? filterLabel : "ALL CUSTOMERS";

    return Container(
      margin: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3D hero icon
          Image.asset('assets/icons/3d/transparent/634b4b-crown.png',
            width: 36, height: 36,
            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          const SizedBox(height: 12),
          // Main count
          Text(
            "$bigNumber",
            style: AppTextStyles.h1.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, fontSize: 28),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: context.ksc.neutral500, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: context.ksc.primary700),
          const SizedBox(height: 12),
          // Secondary stats row
          Row(
            children: [
              Icon(LineAwesomeIcons.users_solid, size: 12, color: context.ksc.neutral500),
              const SizedBox(width: 4),
              Text("$repeatCount repeat", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontSize: 10, fontWeight: FontWeight.w700)),
              if (pendingFollowUpCount > 0) ...[
                const SizedBox(width: 14),
                Icon(LineAwesomeIcons.whatsapp, size: 12, color: context.ksc.accent500),
                const SizedBox(width: 4),
                Text(
                  '$pendingFollowUpCount follow-up',
                  style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
              if (pendingSyncCount > 0) ...[
                const SizedBox(width: 14),
                Icon(LineAwesomeIcons.sync_solid, size: 12, color: context.ksc.accent500),
                const SizedBox(width: 4),
                Text(
                  '$pendingSyncCount uploading',
                  style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
