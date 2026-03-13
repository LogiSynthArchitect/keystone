import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
  bool _isSearchFocused = false;

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
    final state = ref.watch(customerListProvider);

    ref.listen(customerListProvider, (prev, next) {
      if (next.errorMessage != null && mounted) {
        KsSnackbar.show(context, message: next.errorMessage!, type: KsSnackbarType.error);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary900,
      appBar: const KsAppBar(title: "CUSTOMERS"),
      body: Column(
        children: [
          const KsOfflineBanner(),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Focus(
              onFocusChange: (hasFocus) => setState(() => _isSearchFocused = hasFocus),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary800,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _isSearchFocused ? AppColors.accent500 : Colors.white.withValues(alpha: 0.1),
                    width: _isSearchFocused ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (q) {
                    ref.read(customerListProvider.notifier).search(q);
                    setState(() {});
                  },
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                  cursorColor: AppColors.accent500,
                  decoration: InputDecoration(
                    hintText: "Search for a customer...",
                    hintStyle: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.2)),
                    prefixIcon: const Icon(LineAwesomeIcons.search_solid, color: AppColors.neutral500, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              ref.read(customerListProvider.notifier).search('');
                              setState(() {});
                            },
                            child: const Icon(LineAwesomeIcons.times_solid, color: AppColors.neutral500, size: 20))
                        : null,
                    filled: true,
                    fillColor: Colors.transparent, // FIX: Resolves the white-out bug
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Expanded(
            child: state.isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.all(24.0),
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, __) => Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary800,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                  )
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
        elevation: 4,
        child: const Icon(LineAwesomeIcons.plus_solid, size: 28),
      ),
      bottomNavigationBar: KsBottomNav(currentIndex: 1, onTabTapped: _onTabTapped),
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
              color: Colors.white.withValues(alpha: 0.05)
            ),
            const SizedBox(height: 24),
            Text(
              isSearching ? "NO RESULTS FOUND" : "NO CUSTOMERS YET", 
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(color: AppColors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)
            ),
            const SizedBox(height: 12),
            Text(
              isSearching 
                ? "No matching customers found for \"$query\"." 
                : "You haven't added any customers yet.\nTap the + button to add one.", 
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral400, height: 1.5)
            ),
          ],
        ),
      ),
    );
  }
}
