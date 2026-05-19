import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_search_bar.dart';
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
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    final types = ref.read(serviceTypeProvider).valueOrNull;
    if (types != null) {
      final categories = types.map((t) => t.category).toSet();
      _expandedCategories.addAll(categories);
    }
  }

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: KsSearchBar(
              hint: "Search services...",
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
        ),
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

    final grouped = <String, List<ServiceTypeEntity>>{};
    for (final type in filtered) {
      grouped.putIfAbsent(type.category, () => []).add(type);
    }
    final categories = grouped.keys.toList()..sort();

    return Column(
      children: [
        const KsOfflineBanner(),
        Expanded(
          child: filtered.isEmpty
              ? KsEmptyState(
                  icon: _searchQuery.isEmpty ? LineAwesomeIcons.tags_solid : LineAwesomeIcons.search_minus_solid,
                  title: _searchQuery.isEmpty ? "NO SERVICES CONFIGURED" : "NO MATCHES",
                  subtitle: _searchQuery.isEmpty ? "Add service types to get started." : null,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: categories.length,
                  itemBuilder: (context, ci) => _buildCategorySection(categories[ci], grouped[categories[ci]]!),
                ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<ServiceTypeEntity> services) {
    final isExpanded = _expandedCategories.contains(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedCategories.remove(category);
              } else {
                _expandedCategories.add(category);
              }
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(isExpanded ? LineAwesomeIcons.angle_down_solid : LineAwesomeIcons.angle_right_solid, color: context.ksc.accent500, size: 14),
                const SizedBox(width: 8),
                Text(
                  category.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const Spacer(),
                Text(
                  "${services.length}",
                  style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) => _buildServiceCard(services[index]),
          ),
        ],
      ],
    );
  }

  Widget _buildServiceCard(ServiceTypeEntity service) {
    return GestureDetector(
      onTap: () => _openPriceSheet(service),
      child: Container(
        decoration: BoxDecoration(
          color: context.ksc.primary800.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.ksc.primary700.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getLineAwesomeIcon(service.iconName),
              color: context.ksc.accent500,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              service.name,
              style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              service.defaultPrice != null
                  ? 'GHS ${(service.defaultPrice! / 100.0).toStringAsFixed(2)}'
                  : '\u2014',
              style: AppTextStyles.body.copyWith(
                color: service.defaultPrice != null ? context.ksc.accent500 : context.ksc.neutral500,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
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
