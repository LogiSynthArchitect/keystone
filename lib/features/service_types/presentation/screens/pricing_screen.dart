import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/icon_helpers.dart';
import '../providers/service_type_provider.dart';
import '../../domain/entities/service_type_entity.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeCategory = 'All';
  static const _allCategories = ['All', 'Residential', 'Automotive', 'Commercial', 'Security Systems', 'Specialty'];

  // Services considered "premium" (higher price indicator)
  static const _premiumServices = {
    'Master Key Systems', 'Safe Opening', 'Gate Automation',
    'High-Security Locks', 'Access Control', 'Smart Lock Install',
    'Transponder Key Programming', 'CCTV Installation', 'Electric Fence Installation',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serviceTypeProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "SERVICE PRICING",
        showBack: true,
      ),
      body: state.when(
        loading: () => Center(child: CircularProgressIndicator(color: context.ksc.accent500)),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LineAwesomeIcons.exclamation_triangle_solid, color: context.ksc.error500, size: 48),
              const SizedBox(height: 16),
              Text("FAILED TO LOAD", style: AppTextStyles.h2.copyWith(color: context.ksc.white)),
              const SizedBox(height: 8),
              KsButton(
                onPressed: () => ref.read(serviceTypeProvider.notifier).loadServiceTypes(),
                label: "TAP TO RETRY",
              ),
            ],
          ),
        ),
        data: (types) => _buildBody(types),
      ),
    );
  }

  Widget _buildBody(List<ServiceTypeEntity> types) {
    final filtered = _searchQuery.isEmpty
        ? types
        : types.where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    final categoryFiltered = _activeCategory == 'All'
        ? filtered
        : filtered.where((t) => t.category == _activeCategory).toList();

    final grouped = <String, List<ServiceTypeEntity>>{};
    for (final type in categoryFiltered) {
      grouped.putIfAbsent(type.category, () => []).add(type);
    }
    final categories = grouped.keys.toList()..sort();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF060607),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.ksc.primary700),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: context.ksc.white, fontSize: 14, fontWeight: FontWeight.w300),
              cursorColor: context.ksc.accent500,
              decoration: InputDecoration(
                hintText: 'Search services...',
                hintStyle: TextStyle(color: context.ksc.neutral600, fontSize: 14, fontWeight: FontWeight.w300),
                prefixIcon: Icon(LineAwesomeIcons.search_solid, color: context.ksc.neutral600, size: 16),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral600, size: 14),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
        // Filter chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: _allCategories.map((cat) {
              final isActive = _activeCategory == cat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _activeCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? context.ksc.accent500.withValues(alpha: 0.15)
                          : context.ksc.primary800,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? context.ksc.accent500 : context.ksc.primary700,
                      ),
                    ),
                    child: Text(
                      cat.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: isActive ? context.ksc.accent500 : context.ksc.neutral500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const KsOfflineBanner(),
        // List
        Expanded(
          child: categoryFiltered.isEmpty
              ? KsEmptyState(
                  icon: _searchQuery.isEmpty ? LineAwesomeIcons.tags_solid : LineAwesomeIcons.search_minus_solid,
                  title: _searchQuery.isEmpty ? "NO SERVICES CONFIGURED" : "NO MATCHES",
                  subtitle: _searchQuery.isEmpty ? "Add service types to get started." : null,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: categories.length,
                  itemBuilder: (context, ci) => _buildCategorySection(categories[ci], grouped[categories[ci]]!),
                ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<ServiceTypeEntity> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Category header (gold, uppercase, always expanded)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Text(
                category.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.accent500,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.ksc.primary800,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${services.length}",
                  style: TextStyle(fontSize: 10, color: context.ksc.neutral500, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        // Service items as list
        ...services.map((service) => _buildServiceRow(service)),
      ],
    );
  }

  Widget _buildServiceRow(ServiceTypeEntity service) {
    final isPremium = _premiumServices.contains(service.name);
    final hasPrice = service.defaultPrice != null;

    return GestureDetector(
      onTap: () => _openPriceSheet(service),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.ksc.primary800, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.ksc.primary800,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPremium ? context.ksc.accent500 : context.ksc.primary700,
                  width: isPremium ? 1 : 1,
                ),
              ),
              child: Icon(
                getLineAwesomeIcon(service.iconName),
                color: isPremium ? context.ksc.accent500 : context.ksc.neutral400,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            // Name + category tag
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isPremium ? FontWeight.w500 : FontWeight.w300,
                      color: context.ksc.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isPremium)
                    Text(
                      'PREMIUM',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: context.ksc.accent500,
                      ),
                    ),
                ],
              ),
            ),
            // Price
            Text(
              hasPrice ? 'GHS ${(service.defaultPrice! / 100.0).toStringAsFixed(0)}' : '\u2014',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hasPrice ? context.ksc.accent500 : context.ksc.neutral600,
              ),
            ),
            const SizedBox(width: 8),
            // Edit icon
            Icon(
              LineAwesomeIcons.pen_alt_solid,
              size: 12,
              color: context.ksc.neutral600,
            ),
          ],
        ),
      ),
    );
  }

  void _openPriceSheet(ServiceTypeEntity service) {
    final controller = TextEditingController(
      text: service.defaultPrice != null
          ? (service.defaultPrice! / 100.0).toStringAsFixed(2)
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        String currentValue = controller.text;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      // Drag handle
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: context.ksc.neutral600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Header
                      Text(
                        'SET PRICE',
                        style: AppTextStyles.h2.copyWith(
                          color: context.ksc.accent500,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Icon circle
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: context.ksc.primary900,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.ksc.accent500, width: 2),
                        ),
                        child: Icon(
                          getLineAwesomeIcon(service.iconName),
                          color: context.ksc.accent500,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Service name
                      Text(
                        service.name.toUpperCase(),
                        style: AppTextStyles.h3.copyWith(
                          color: context.ksc.white,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.ksc.primary900,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: context.ksc.primary700),
                        ),
                        child: Text(
                          service.category.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: context.ksc.neutral400,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Current price label
                      Text(
                        service.defaultPrice != null
                            ? 'Current: GHS ${(service.defaultPrice! / 100.0).toStringAsFixed(2)}'
                            : 'No price set',
                        style: AppTextStyles.body.copyWith(
                          color: context.ksc.neutral500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price input
                      Container(
                        decoration: BoxDecoration(
                          color: context.ksc.primary900,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.ksc.primary700),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              'GHS',
                              style: AppTextStyles.h2.copyWith(
                                color: context.ksc.neutral500,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                autofocus: true,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: context.ksc.white,
                                ),
                                cursorColor: context.ksc.accent500,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                onChanged: (v) {
                                  currentValue = v;
                                  setSheetState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      KsButton(
                        label: 'SAVE CHANGES',
                        onPressed: currentValue.isNotEmpty
                            ? () {
                                final pesewas = CurrencyFormatter.parseToPesewas(currentValue);
                                ref.read(serviceTypeProvider.notifier).updateServiceTypePrice(service.id, pesewas);
                                Navigator.pop(sheetContext);
                              }
                            : null,
                        variant: KsButtonVariant.primary,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              );
              },
            );
          },
        );
  }
}
