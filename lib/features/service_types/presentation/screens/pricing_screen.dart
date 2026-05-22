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
              color: _hasActiveFilter ? context.ksc.accent500 : context.ksc.primary900,
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
        // Category header (gold, uppercase) — label spec: 12px w700, ls 1.0
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                category.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: context.ksc.accent500,
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
                  style: TextStyle(fontSize: 11, color: context.ksc.neutral500, fontWeight: FontWeight.w700),
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
    // Premium tier: priced ≥ GHS 250 or marked premium in data
    final isPremium = (service.defaultPrice ?? 0) >= 25000;
    final hasPrice = service.defaultPrice != null;

    return GestureDetector(
      onTap: () => _openPriceSheet(service),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      fontSize: 15,
                      fontWeight: isPremium ? FontWeight.w700 : FontWeight.w600,
                      color: context.ksc.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isPremium)
                    Text(
                      'PREMIUM',
                      style: TextStyle(
                        fontSize: 11,
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
                fontSize: 15,
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
        int _step = 0; // 0 = set price, 1 = confirm

        bool isDirty() {
          final newPesewas = CurrencyFormatter.parseToPesewas(currentValue);
          return newPesewas != originalPesewas;
        }

        Future<bool> _confirmDiscard() async {
          final result = await KsConfirmDialog.show(
            sheetContext,
            title: 'Discard Changes?',
            message: 'You have unsaved price changes.',
            confirmLabel: 'Discard',
            cancelLabel: 'Keep Editing',
            isDanger: true,
            onConfirm: () {},
          );
          return result ?? false;
        }

        Future<void> _close() async {
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        }

        Future<void> _save() async {
          final newPesewas = CurrencyFormatter.parseToPesewas(currentValue);

          // Validate: must be > 0
          if (newPesewas == null || newPesewas <= 0) {
            KsSnackbar.show(sheetContext,
                message: 'Price must be greater than 0',
                type: KsSnackbarType.error);
            return;
          }

          // Skip if unchanged
          if (newPesewas == originalPesewas) {
            Navigator.pop(sheetContext);
            return;
          }

          // Show loading state
          isSavingNotifier.value = true;

          // Save locally — returns true if local save worked
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

          // Show success animation
          if (sheetContext.mounted) {
            await KsSuccessMoment.show(
              sheetContext,
              title: 'Price Updated',
              subtitle: '${service.name} → ${CurrencyFormatter.formatShort(newPesewas)}',
            );
          }

          // Apply state update + close
          ref.read(serviceTypeProvider.notifier).applyPriceUpdate(service.id, newPesewas);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        }

        // ── Step 0: Set Price ──
        List<Widget> _buildSetPriceStep(ServiceTypeEntity svc, BuildContext ctx, void Function(VoidCallback) ss) {
          return [
            // Header: SET PRICE + service name
            Row(
              children: [
                Icon(LineAwesomeIcons.pen_alt_solid, color: context.ksc.accent500, size: 16),
                const SizedBox(width: 8),
                Text('SET PRICE',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: context.ksc.accent500),
                ),
                const Spacer(),
                Text(svc.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.ksc.neutral500),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick preset chips — pill-shaped
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

            // Custom amount — underline input
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
            const SizedBox(height: 24),

            // Buttons: CANCEL (secondary) | CONTINUE (primary)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _close,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.ksc.accent500),
                      ),
                      child: Center(
                        child: Text('CANCEL',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.ksc.accent500),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: currentValue.isNotEmpty ? () {
                      final parsed = CurrencyFormatter.parseToPesewas(currentValue);
                      if (parsed == null || parsed <= 0) {
                        KsSnackbar.show(ctx, message: 'Price must be greater than 0', type: KsSnackbarType.error);
                        return;
                      }
                      ss(() => _step = 1);
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: currentValue.isNotEmpty ? context.ksc.accent500 : context.ksc.accent500.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: currentValue.isNotEmpty ? [
                          BoxShadow(
                            color: context.ksc.accent500.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 0),
                          ),
                        ] : null,
                      ),
                      child: Center(child: Text(
                        currentValue.isNotEmpty ? 'CONTINUE — GHS ${currentValue}' : 'ENTER PRICE',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: context.ksc.primary900),
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ];
        }

        // ── Step 1: Confirm Price ──
        List<Widget> _buildConfirmStep(ServiceTypeEntity svc, BuildContext ctx, void Function(VoidCallback) ss) {
          final newPesewas = CurrencyFormatter.parseToPesewas(currentValue) ?? 0;
          return [
            // Confirm icon
            Icon(LineAwesomeIcons.check_circle_solid, color: context.ksc.accent500, size: 32),
            const SizedBox(height: 16),

            // Label
            Text('CONFIRM PRICE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: context.ksc.accent500),
            ),
            const SizedBox(height: 20),

            // Service name
            Text(svc.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.ksc.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Price display — clean, transparent, underline
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

            // Buttons: EDIT (secondary) | SAVE (primary)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => ss(() => _step = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.ksc.accent500),
                      ),
                      child: Center(child: Text('EDIT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.ksc.accent500))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ListenableBuilder(
                    listenable: isSavingNotifier,
                    builder: (_, __) {
                      final saving = isSavingNotifier.value;
                      return GestureDetector(
                        onTap: saving ? null : _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: saving ? context.ksc.accent500.withValues(alpha: 0.35) : context.ksc.accent500,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: saving ? null : [
                              BoxShadow(
                                color: context.ksc.accent500.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Center(
                            child: saving
                              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: context.ksc.primary900))
                              : Text('SAVE — GHS ${CurrencyFormatter.formatShort(newPesewas)}',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: context.ksc.primary900),
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ];
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (isDirty()) {
              final discard = await _confirmDiscard();
              if (discard && sheetContext.mounted) Navigator.pop(sheetContext);
            } else {
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            }
          },
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        width: 36, height: 4,
                        decoration: BoxDecoration(
                          color: context.ksc.neutral600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_step == 0) ..._buildSetPriceStep(service, sheetContext, setSheetState),
                      if (_step == 1) ..._buildConfirmStep(service, sheetContext, setSheetState),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
