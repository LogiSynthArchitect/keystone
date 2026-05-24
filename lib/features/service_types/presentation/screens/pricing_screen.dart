import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_filter_sheet.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_search_bar.dart';
import '../../../../core/widgets/search_panel_body.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/widgets/ks_step_drawer.dart';
import '../../../../core/widgets/ks_success_moment.dart';
import '../../../../core/widgets/ks_watermark.dart';
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
  bool _searchOpen = false;
  List<ServiceTypeEntity>? _types;

  bool get _hasActiveFilter => _activeCategory != 'All';

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
        searchable: true,
        isSearchOpen: _searchOpen,
        onSearchToggle: () => setState(() => _searchOpen = !_searchOpen),
        goldStyle: true,
        actions: [
          IconButton(
            icon: Icon(
              LineAwesomeIcons.filter_solid,
              color: _hasActiveFilter ? context.ksc.accent500 : context.ksc.neutral400,
              size: 22,
            ),
            onPressed: () => _showFilterSheet(context, types: _types),
          ),
        ],
      ),
      body: KsWatermark(
        child: state.when(
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
        data: (types) {
          _types = types;

          // Search content that slides in/out
          final searchContent = Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: KsSearchBar(
              hint: 'Search ${types.length} services...',
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          );

          return Column(
            children: [
              // Search panel (animated) + list body
              Expanded(
                child: SearchPanelBody(
                  isOpen: _searchOpen,
                  searchContent: searchContent,
                  child: _buildBody(types),
                ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }

  void _showFilterSheet(BuildContext context, {List<ServiceTypeEntity>? types}) {
    String draftCategory = _activeCategory;

    // Derive categories from actual data, with "All" first
    final dynamicCats = types
        ?.map((t) => t.category)
        .toSet()
        .where((c) => c.isNotEmpty)
        .toList();
    dynamicCats?.sort();

    final allCats = {'All': types?.length ?? 0};
    if (types != null) {
      for (final c in dynamicCats ?? <String>[]) {
        allCats[c] = types.where((t) => t.category == c).length;
      }
    }

    const catIcons = <String, String>{
      'All': '📍',
      'Residential': '🏠',
      'Automotive': '🚗',
      'Commercial': '🏢',
      'Security Systems': '📡',
      'Specialty': '⚡',
    };

    const catDesc = <String, String>{
      'All': 'Clear all filters',
      'Residential': 'Home & apartment services',
      'Automotive': 'Vehicle lock & key',
      'Commercial': 'Business & office',
      'Security Systems': 'CCTV, alarms, access',
      'Specialty': 'Safe, gate, high-security',
    };

    final selectedCat = draftCategory;
    final selectedCount = selectedCat == 'All'
        ? types?.length
        : types?.where((t) => t.category == selectedCat).length;
    final activeLabel = selectedCat == 'All' ? null : selectedCat;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setInnerState) => PopScope(
            canPop: false,
            child: KsFilterSheet(
            title: "FILTER BY CATEGORY",
            totalCount: selectedCount,
            activeLabel: activeLabel,
            onApply: () {
              setState(() => _activeCategory = draftCategory);
            },
            onClear: () {
              draftCategory = 'All';
              setInnerState(() {});
            },
            children: [
              KsFilterChipGroup(
                label: "CATEGORY",
                selected: draftCategory,
                onSelect: (v) => setInnerState(() => draftCategory = v ?? 'All'),
                options: allCats.entries.map((e) => KsFilterOption(
                  value: e.key,
                  display: e.key == 'All' ? 'All Services' : e.key,
                  icon: catIcons[e.key] ?? '📋',
                  count: e.value,
                  description: catDesc[e.key],
                )).toList(),
              ),
            ],
          ),
        ),
      );
    },
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
        const KsOfflineBanner(),
        categoryFiltered.isEmpty
            ? Expanded(
                child: KsEmptyState(
                  icon: _searchQuery.isEmpty ? LineAwesomeIcons.tags_solid : LineAwesomeIcons.search_minus_solid,
                  title: _searchQuery.isEmpty ? "NO SERVICES CONFIGURED" : "NO MATCHES",
                  subtitle: _searchQuery.isEmpty ? "Add service types to get started." : null,
                ),
              )
            : Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
        // Category header — divider underline style, thick gold
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                category.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: context.ksc.accent500,
                ),
              ),
              const Spacer(),
              Text(
                "${services.length} ${services.length == 1 ? 'SERVICE' : 'SERVICES'}",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: context.ksc.neutral500,
                ),
              ),
            ],
          ),
        ),
        // Gold-tinted full-width divider
        Container(height: 1, color: context.ksc.accent500.withValues(alpha: 0.25)),
        const SizedBox(height: 10),
        // Service items as full-width compact cards
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            children: [
              for (final service in services) ...[
                _buildCompactCard(service),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCard(ServiceTypeEntity service) {
    // Premium tier: priced ≥ GHS 250
    final isPremium = (service.defaultPrice ?? 0) >= 25000;
    final hasPrice = service.defaultPrice != null;

    return GestureDetector(
      onTap: () => _openPriceSheet(service),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: context.ksc.primary900,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isPremium ? context.ksc.accent500 : context.ksc.primary700,
                ),
              ),
              child: Icon(
                getLineAwesomeIcon(service.iconName),
                color: isPremium ? context.ksc.accent500 : context.ksc.neutral400,
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            // Name + premium label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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
              hasPrice ? CurrencyFormatter.formatShort(service.defaultPrice!) : '\u2014',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: hasPrice ? context.ksc.accent500 : context.ksc.neutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPriceSheet(ServiceTypeEntity service) {
    final originalPesewas = service.defaultPrice;
    final controller = TextEditingController(
      text: originalPesewas != null
          ? (originalPesewas / 100.0).toStringAsFixed(2)
          : '',
    );
    // Common price presets in GHS
    const pricePresets = [50, 80, 100, 150, 200, 250, 350, 500];
    int? selectedPreset;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        String currentValue = controller.text;
        final isSavingNotifier = ValueNotifier(false);

        bool _hasPriceChanged() {
          final newPesewas = CurrencyFormatter.parseToPesewas(currentValue);
          return newPesewas != null && newPesewas != originalPesewas;
        }

        Future<void> _confirmDiscard(BuildContext discardCtx) async {
          if (!_hasPriceChanged()) {
            if (discardCtx.mounted) Navigator.pop(discardCtx);
            return;
          }
          final discard = await KsConfirmDialog.show(
            discardCtx,
            title: 'DISCARD CHANGES',
            message: 'Price changes have not been saved. Discard them?',
            confirmLabel: 'DISCARD',
            cancelLabel: 'KEEP EDITING',
            isDanger: true,
            onConfirm: () {},
          );
          if (discard == true && discardCtx.mounted) {
            Navigator.pop(discardCtx);
          }
        }

        Future<void> _close() async {
          await _confirmDiscard(sheetContext);
        }

        Future<void> _save() async {
          final newPesewas = CurrencyFormatter.parseToPesewas(currentValue);
          if (newPesewas == null || newPesewas <= 0) {
            KsSnackbar.show(sheetContext,
                message: 'Price must be greater than 0',
                type: KsSnackbarType.error);
            return;
          }
          if (newPesewas == originalPesewas) {
            Navigator.pop(sheetContext);
            return;
          }
          isSavingNotifier.value = true;
          final saved = await ref.read(serviceTypeProvider.notifier)
              .savePriceOnly(service.id, newPesewas);
          if (!saved) {
            isSavingNotifier.value = false;
            if (sheetContext.mounted) {
              KsSnackbar.show(sheetContext,
                  message: 'Failed to save price. Try again.',
                  type: KsSnackbarType.error);
            }
            return;
          }
          if (sheetContext.mounted) {
            await KsSuccessMoment.show(
              sheetContext,
              title: 'Price Updated',
              subtitle: '${service.name} → ${CurrencyFormatter.formatShort(newPesewas)}',
            );
          }
          ref.read(serviceTypeProvider.notifier).applyPriceUpdate(service.id, newPesewas);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        }

        // ── Step 0: Set Price ──
        List<Widget> _buildSetPriceStep(ServiceTypeEntity svc, BuildContext ctx, void Function(VoidCallback) ss) {
          return [
            const SizedBox(height: 8),
            // Quick preset chips
            Text('QUICK SELECT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.ksc.neutral500, letterSpacing: 1.0)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: pricePresets.map((p) {
                final isSel = selectedPreset == p;
                return GestureDetector(
                  onTap: () {
                    selectedPreset = p;
                    currentValue = '$p.00';
                    controller.text = currentValue;
                    ss(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? context.ksc.accent500.withValues(alpha: 0.10) : Colors.transparent,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isSel ? context.ksc.accent500 : context.ksc.primary700,
                      ),
                    ),
                    child: Text('GHS $p',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w800,
                        color: isSel ? context.ksc.accent500 : context.ksc.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Custom amount
            Text('CUSTOM AMOUNT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.ksc.neutral500, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('GHS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.ksc.neutral500)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.ksc.white),
                    cursorColor: context.ksc.accent500,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: context.ksc.primary700),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: context.ksc.accent500),
                      ),
                    ),
                    onChanged: (v) {
                      currentValue = v;
                      selectedPreset = null;
                      ss(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ];
        }

        // ── Step 1: Confirm Price ──
        List<Widget> _buildConfirmStep(ServiceTypeEntity svc, BuildContext ctx, void Function(VoidCallback) ss) {
          final newPesewas = CurrencyFormatter.parseToPesewas(currentValue) ?? 0;
          return [
            const SizedBox(height: 4),
            Text(svc.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.ksc.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.ksc.primary700),
                ),
              ),
              child: Column(
                children: [
                  if (originalPesewas != null && newPesewas != originalPesewas) ...[
                    Text('Current: ${CurrencyFormatter.formatShort(originalPesewas)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.ksc.neutral500, decoration: TextDecoration.lineThrough),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(CurrencyFormatter.formatShort(newPesewas),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: context.ksc.accent500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Loading indicator for save
            ListenableBuilder(
              listenable: isSavingNotifier,
              builder: (_, __) {
                return isSavingNotifier.value
                    ? const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFD4A017),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ];
        }

        return KsStepDrawer(
          title: "SET PRICE",
          steps: const [
            KsStep(label: 'PRICE', icon: LineAwesomeIcons.pen_alt_solid, subSteps: 2,
              tip: 'Set the price for this service',
              imageAsset: 'assets/icons/3d/transparent/b801dc-3d-coin.png'),
            KsStep(label: 'CONFIRM', icon: LineAwesomeIcons.check_solid,
              tip: 'Review and save the updated price',
              imageAsset: 'assets/icons/3d/transparent/1b714e-tick.png'),
          ],
          showBackArrow: true,
          onBack: _close,
          onClose: () => _confirmDiscard(sheetContext),
          nextLabel: "CONTINUE",
          saveLabel: "SAVE",
          canAdvance: (step, subStep) => step == 0 ? currentValue.isNotEmpty : true,
          onSave: _save,
          stepContent: (step, subStep, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (step == 0) ..._buildSetPriceStep(service, sheetContext, setSheetState),
                if (step == 1) ..._buildConfirmStep(service, sheetContext, setSheetState),
              ],
            ),
          ),
        );
      },
    );
  }
}
