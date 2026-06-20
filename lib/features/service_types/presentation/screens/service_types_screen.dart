import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/service_categories.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/icon_helpers.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../providers/service_type_provider.dart';
import '../../domain/entities/service_type_entity.dart';
import 'service_detail_screen.dart';

/// Category color map — must match the mockup's 3px left strip colors.
Color _catColor(String key) {
  switch (key) {
    case 'Residential':     return const Color(0xFF4A6EC4);
    case 'Automotive':      return const Color(0xFF2E7D32);
    case 'Commercial':      return const Color(0xFFB8860B);
    case 'Security Systems': return const Color(0xFFC62828);
    case 'Specialty':       return const Color(0xFF6B7280);
    default:                return const Color(0xFF6B7280);
  }
}

class ServiceTypesScreen extends ConsumerStatefulWidget {
  const ServiceTypesScreen({super.key});

  @override
  ConsumerState<ServiceTypesScreen> createState() => _ServiceTypesScreenState();
}

class _ServiceTypesScreenState extends ConsumerState<ServiceTypesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _activeCategory = 'All';

  List<ServiceTypeEntity> _filter(List<ServiceTypeEntity> types) {
    var result = types;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      result = result.where((t) => t.name.toLowerCase().contains(q)).toList();
    }
    if (_activeCategory != 'All') {
      result = result.where((t) => t.category == _activeCategory).toList();
    }
    return result;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serviceTypeProvider);
    final c = context.ksc;

    return Scaffold(
      backgroundColor: c.primary900,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            // ── Status bar spacer ──
            const SizedBox(height: 8),
            // ── App Bar row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: SizedBox(
                        width: 36, height: 36,
                        child: Center(
                          child: Text('\u2190',
                            style: TextStyle(fontSize: 18, color: c.neutral400)),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text('Services',
                      style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900,
                        letterSpacing: -0.3, color: c.white)),
                    const Spacer(),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
            ),
            // ── Underline Search ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _query.isNotEmpty ? const Color(0xFFD4A017) : c.primary700,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text('\u{1F50D}',
                      style: TextStyle(fontSize: 14, color: c.neutral500)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: c.white),
                        decoration: InputDecoration(
                          hintText: 'Search by name or category...',
                          hintStyle: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: c.neutral500),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        child: Text('\u2715',
                          style: TextStyle(fontSize: 12, color: c.neutral500)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('!', style: TextStyle(fontSize: 48, color: c.error500)),
                const SizedBox(height: 16),
                Text('Failed to Load',
                  style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w900,
                    color: c.neutral500)),
                const SizedBox(height: 8),
                Text('Could not load service types.',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: c.neutral500)),
                const SizedBox(height: 24),
                KsButton(
                  label: 'TAP TO RETRY',
                  variant: KsButtonVariant.primary,
                  size: KsButtonSize.small,
                  fullWidth: false,
                  onPressed: () => ref.invalidate(serviceTypeProvider),
                ),
              ],
            ),
          ),
        ),
        data: (types) {
          final filtered = _filter(types);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Filter Chips ──
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    'All', 'Residential', 'Automotive',
                    'Commercial', 'Security Systems', 'Specialty',
                  ].map((cat) {
                    final active = cat == _activeCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: active
                                ? const Color(0xFFD4A017)
                                : Colors.transparent,
                            border: Border.all(
                              color: active
                                  ? const Color(0xFFD4A017)
                                  : c.primary700,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            cat == 'Security Systems' ? 'SECURITY' : cat.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: active
                                  ? const Color(0xFF0A1628)
                                  : c.neutral400),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 4),

              // ── List ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: c.primary800,
                                  border: Border.all(color: c.primary700),
                                ),
                                child: Center(
                                  child: Text('\u{1F50D}',
                                    style: TextStyle(fontSize: 20, color: c.neutral500)),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text('No Matches',
                                style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w900,
                                  color: c.neutral500)),
                              const SizedBox(height: 4),
                              Text('Try a different search or filter',
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: c.neutral500)),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _ServiceCard(
                          service: filtered[i],
                          onTap: () => _openDetail(filtered[i]),
                          onLongPress: () => _confirmDelete(filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref, null),
        backgroundColor: const Color(0xFFD4A017),
        foregroundColor: const Color(0xFF0A1628),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _openDetail(ServiceTypeEntity service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(service: service),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, ServiceTypeEntity? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(
      text: existing?.defaultPrice != null
          ? '${(existing!.defaultPrice! / 100.0).toStringAsFixed(2)}'
          : '',
    );
    var selectedCategory = existing != null
        ? (ServiceCategory.fromKey(existing.category) ?? ServiceCategory.all.first)
        : ServiceCategory.all.first;
    var selectedDuration = '30 min';
    var selectedSkill = 'Intermediate';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (_, setInner) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              left: 16, right: 16, top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──
                  Center(
                    child: Container(
                      width: 32, height: 4,
                      decoration: BoxDecoration(
                        color: context.ksc.primary700,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    existing != null ? 'Edit Service' : 'New Service',
                    style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900,
                      color: context.ksc.white),
                  ),
                  const SizedBox(height: 20),

                  // ── Name (underline input) ──
                  _UnderlineField(
                    label: 'Service name',
                    controller: nameCtrl,
                    placeholder: 'e.g. House Lockout',
                  ),
                  const SizedBox(height: 16),

                  // ── Description (underline textarea) ──
                  _UnderlineField(
                    label: 'Description',
                    controller: descCtrl,
                    placeholder: 'Describe what this service covers...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // ── Category + Duration row ──
                  Row(
                    children: [
                      Expanded(
                        child: _UnderlineDropdown(
                          label: 'Category',
                          value: selectedCategory.key,
                          options: ServiceCategory.all
                              .map((c) => (c.key, c.display))
                              .toList(),
                          onChanged: (v) {
                            final cat = ServiceCategory.fromKey(v);
                            if (cat != null) setInner(() => selectedCategory = cat);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _UnderlineDropdown(
                          label: 'Duration',
                          value: selectedDuration,
                          options: const [
                            ('15 min', '15 min'),
                            ('30 min', '30 min'),
                            ('45 min', '45 min'),
                            ('1 hr', '1 hr'),
                            ('2 hrs', '2 hrs'),
                            ('3 hrs', '3 hrs'),
                            ('4+ hrs', '4+ hrs'),
                          ],
                          onChanged: (v) => setInner(() => selectedDuration = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Price + Skill row ──
                  Row(
                    children: [
                      Expanded(
                        child: _UnderlineField(
                          label: 'Base price (GHS)',
                          controller: priceCtrl,
                          placeholder: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _UnderlineDropdown(
                          label: 'Skill level',
                          value: selectedSkill,
                          options: const [
                            ('Beginner', 'Beginner'),
                            ('Intermediate', 'Intermediate'),
                            ('Advanced', 'Advanced'),
                            ('Master', 'Master'),
                          ],
                          onChanged: (v) => setInner(() => selectedSkill = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Side-by-side buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(sheetCtx),
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: context.ksc.primary700),
                            ),
                            child: Text('CANCEL',
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: context.ksc.neutral400)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (nameCtrl.text.trim().isEmpty) return;
                            final price = double.tryParse(priceCtrl.text) ?? 0;
                            final pricePesewas = (price * 100).round();

                            if (existing != null) {
                              ref.read(serviceTypeProvider.notifier).updateServiceType(
                                existing.copyWith(
                                  name: nameCtrl.text.trim(),
                                  category: selectedCategory.key,
                                  defaultPrice: pricePesewas > 0 ? pricePesewas : null,
                                ),
                              );
                            } else {
                              ref.read(serviceTypeProvider.notifier).createServiceType(
                                nameCtrl.text.trim(),
                                selectedCategory.key,
                                selectedCategory.defaultIconName,
                              );
                            }
                            Navigator.pop(sheetCtx);
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFFD4A017),
                            ),
                            child: Text(
                              existing != null ? 'SAVE' : 'ADD',
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: const Color(0xFF0A1628)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(ServiceTypeEntity service) {
    KsConfirmDialog.show(
      context,
      title: 'DELETE SERVICE',
      message: "Are you sure you want to remove '${service.name}'?",
      confirmLabel: 'DELETE',
      cancelLabel: 'CANCEL',
      isDanger: true,
      onConfirm: () {
        ref.read(serviceTypeProvider.notifier).deleteServiceType(service.id);
      },
    );
  }
}

// ─── Underline TextField ───
class _UnderlineField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final int? maxLines;
  final TextInputType? keyboardType;

  const _UnderlineField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.maxLines,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ksc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800,
            letterSpacing: 1.5, color: c.neutral400)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines ?? 1,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: c.white),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: c.neutral500),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: c.primary700, width: 1.5),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: c.primary700, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: const Color(0xFFD4A017), width: 1.5),
            ),
            isDense: true,
            contentPadding: EdgeInsets.only(
              top: 8, bottom: 8,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Underline Dropdown ───
class _UnderlineDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  const _UnderlineDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ksc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800,
            letterSpacing: 1.5, color: c.neutral400)),
        const SizedBox(height: 4),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: c.primary800,
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: c.white),
            underline: Container(
              height: 1.5,
              color: c.primary700,
            ),
            items: options.map((o) {
              final (k, v) = o;
              return DropdownMenuItem(
                value: k,
                child: Text(v),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

// ─── Service Card (color-coded left strip) ───
class _ServiceCard extends StatelessWidget {
  final ServiceTypeEntity service;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ServiceCard({
    required this.service,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ksc;
    final cat = ServiceCategory.fromKey(service.category);
    final color = _catColor(service.category);
    final icon = getLineAwesomeIcon(service.iconName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: c.primary800,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.primary700),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // ── 3px color strip ──
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // ── Icon (no container) ──
                SizedBox(
                  width: 24,
                  child: Center(
                    child: Icon(icon, size: 16, color: c.neutral400),
                  ),
                ),
                const SizedBox(width: 10),
                // ── Info ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.name,
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800,
                            color: c.white),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Text(service.isDefault ? 'Default' : 'Custom',
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: c.neutral500)),
                            const SizedBox(width: 6),
                            Container(
                              width: 3, height: 3,
                              decoration: BoxDecoration(
                                color: c.neutral500,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (cat?.display ?? service.category).toUpperCase(),
                              style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: color),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Price ──
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (service.defaultPrice != null) ...[
                        Text('GHS',
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: c.neutral500)),
                        Text('${(service.defaultPrice! / 100).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900,
                            color: c.white)),
                      ] else
                        Text('--',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: c.neutral500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
