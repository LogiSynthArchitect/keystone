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
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import 'package:keystone/core/widgets/ks_sliding_notification.dart';
import '../../../../core/widgets/ks_search_bar.dart';
import '../../../job_logging/presentation/providers/job_providers.dart';
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
          IconButton(
            icon: Icon(LineAwesomeIcons.address_book_solid, color: context.ksc.neutral400, size: 22),
            onPressed: () {
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
          const KsOfflineBanner(),
          const SizedBox(height: 8),

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
                          child: Consumer(builder: (context, innerRef, _) {
                            final allJobs = innerRef.watch(jobListProvider);
                            final pendingCustomerIds = allJobs.activeJobs
                                .where((j) => !j.followUpSent && (j.status == 'completed' || j.status == 'invoiced'))
                                .map((j) => j.customerId)
                                .toSet();
                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                              itemCount: state.paged.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final customer = state.paged[index];
                                return CustomerCard(
                                  customer: customer,
                                  hasPendingFollowUp: pendingCustomerIds.contains(customer.id),
                                  onTap: () => context.push(RouteNames.customerDetail(customer.id)),
                                );
                              },
                            );
                          }),
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
              "Could not load customers. Check your connection and try again.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400, height: 1.5),
            ),
            const SizedBox(height: 24),
            KsButton(
              label: "TAP TO RETRY",
              variant: KsButtonVariant.primary,
              size: KsButtonSize.small,
              fullWidth: false,
              onPressed: () => ref.read(customerListProvider.notifier).load(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(24.0),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 72,
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
      icon: isSearching ? LineAwesomeIcons.search_minus_solid : LineAwesomeIcons.users_solid,
      title: isSearching ? "NO RESULTS FOUND" : "NO CUSTOMERS YET",
      subtitle: isSearching
        ? 'Search yielded zero results for "$query".'
        : "No customers added yet.\nTap + below to add your first customer.",
    );
  }
}
