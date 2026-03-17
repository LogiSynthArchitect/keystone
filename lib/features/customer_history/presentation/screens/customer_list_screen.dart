import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_bottom_nav.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../providers/customer_providers.dart';
import '../widgets/customer_card.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});
  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
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
    final state = ref.watch(customerListProvider);

    ref.listen(customerListProvider, (prev, next) {
      if (next.errorMessage != null && mounted) {
        KsSnackbar.show(context, message: next.errorMessage!, type: KsSnackbarType.error);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary900,
      appBar: const KsAppBar(title: "CUSTOMER DATABASE"),
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
                    color: AppColors.primary800,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _isSearchFocused ? AppColors.accent500 : AppColors.primary700,
                      width: _isSearchFocused ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (q) {
                      ref.read(customerListProvider.notifier).search(q);
                      setState(() {});
                    },
                    style: AppTextStyles.body.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                    cursorColor: AppColors.accent500,
                    decoration: InputDecoration(
                      hintText: "SEARCH CUSTOMER RECORDS...",
                      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.neutral600, letterSpacing: 1.0),
                      prefixIcon: Icon(LineAwesomeIcons.search_solid, color: _isSearchFocused ? AppColors.accent500 : AppColors.neutral500, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                ref.read(customerListProvider.notifier).search('');
                                setState(() {});
                              },
                              child: const Icon(LineAwesomeIcons.times_solid, color: AppColors.neutral500, size: 20))
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
                        isSelected: state.filterType == 'all',
                        onTap: () => ref.read(customerListProvider.notifier).setFilter('all'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: "RECENT", 
                        isSelected: state.filterType == 'recent',
                        onTap: () => ref.read(customerListProvider.notifier).setFilter('recent'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: "REPEAT", 
                        isSelected: state.filterType == 'repeat',
                        onTap: () => ref.read(customerListProvider.notifier).setFilter('repeat'),
                      ),
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
                        onRefresh: () => ref.read(customerListProvider.notifier).refresh(),
                        color: AppColors.accent500,
                        backgroundColor: AppColors.primary800,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          itemCount: state.displayed.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final customer = state.displayed[index];
                            return CustomerCard(
                              customer: customer,
                              onTap: () => context.push(RouteNames.customerDetail(customer.id)),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.addCustomer),
        backgroundColor: AppColors.accent500,
        foregroundColor: AppColors.primary900,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: const Icon(LineAwesomeIcons.plus_solid, size: 28),
      ),
      bottomNavigationBar: KsBottomNav(currentIndex: 1, onTabTapped: _onTabTapped),
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
          color: AppColors.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.primary700),
        ),
      ).animate(onPlay: (controller) => controller.repeat())
       .shimmer(duration: 1200.ms, color: AppColors.primary700.withValues(alpha: 0.5)),
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
              isSearching ? LineAwesomeIcons.search_minus_solid : LineAwesomeIcons.users_solid, 
              size: 80, 
              color: AppColors.primary800
            ),
            const SizedBox(height: 24),
            Text(
              isSearching ? "NO MATCHING RECORDS" : "NO CUSTOMER ENTITIES", 
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(color: AppColors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)
            ),
            const SizedBox(height: 12),
            Text(
              isSearching 
                ? "Search yielded zero results for \"$query\"." 
                : "No customer data detected in local database.\nInitialize your first customer log.", 
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral400, height: 1.5)
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
          color: isSelected ? AppColors.accent500 : AppColors.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.accent500 : AppColors.primary700,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.primary900 : AppColors.neutral400,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
