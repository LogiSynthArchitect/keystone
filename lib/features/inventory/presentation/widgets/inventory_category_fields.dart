import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../domain/entities/inventory_item_entity.dart';

enum FieldType { text, number, integer, boolean, select }

/// Maps a field key to its LineAwesome icon.
IconData iconForField(String key) {
  switch (key) {
    case 'blankNumber': return LineAwesomeIcons.hashtag_solid;
    case 'keywayType': return LineAwesomeIcons.key_solid;
    case 'hasTransponder': return LineAwesomeIcons.wifi_solid;
    case 'transponderFrequency': return LineAwesomeIcons.signal_solid;
    case 'keyMaterial': return LineAwesomeIcons.archive_solid;
    case 'lockType': return LineAwesomeIcons.lock_solid;
    case 'finish': return LineAwesomeIcons.palette_solid;
    case 'backset': return LineAwesomeIcons.expand_arrows_alt_solid;
    case 'boreSize': return LineAwesomeIcons.expand_solid;
    case 'securityGrade': return LineAwesomeIcons.lock_solid;
    case 'keyRetainable': return LineAwesomeIcons.key_solid;
    case 'vehicleMake': return LineAwesomeIcons.cogs_solid;
    case 'vehicleModels': return LineAwesomeIcons.list_solid;
    case 'yearStart': return LineAwesomeIcons.calendar_solid;
    case 'yearEnd': return LineAwesomeIcons.calendar_solid;
    case 'transponderType': return LineAwesomeIcons.cogs_solid;
    case 'immobilizerSystem': return LineAwesomeIcons.lock_solid;
    case 'programmingMethod': return LineAwesomeIcons.cog_solid;
    case 'protocol': return LineAwesomeIcons.wifi_solid;
    case 'voltage': return LineAwesomeIcons.bolt_solid;
    case 'connectionType': return LineAwesomeIcons.plug_solid;
    case 'maxUsers': return LineAwesomeIcons.users_solid;
    case 'safeType': return LineAwesomeIcons.lock_solid;
    case 'fireRating': return LineAwesomeIcons.fire_solid;
    case 'lockMechanism': return LineAwesomeIcons.cog_solid;
    case 'weight': return LineAwesomeIcons.balance_scale_solid;
    case 'capacity': return LineAwesomeIcons.expand_solid;
    case 'material': return LineAwesomeIcons.archive_solid;
    case 'unitType': return LineAwesomeIcons.box_solid;
    case 'unitsPerPack': return LineAwesomeIcons.cubes_solid;
    case 'supplier': return LineAwesomeIcons.truck_solid;
    default: return LineAwesomeIcons.tag_solid;
  }
}

/// Returns predefined options for select-type fields.
List<String> optionsForField(String key) {
  switch (key) {
    case 'blankNumber':
      return ['SC1', 'SC4', 'KW1', 'Y1', 'Y159', 'SC9', 'KW10', 'Y152', 'SC17', 'SC21', 'WR3', 'WR5', 'M1', 'M2', 'D1', 'D4', 'C123', 'E1X', 'RA1', 'DA1'];
    case 'keywayType':
      return ['Schlage C', 'Kwikset KW', 'Yale Y1', 'Ilco SC1', 'Ilco SC4', 'Abus', 'Mul-T-Lock', 'Medeco', 'ASSA', 'Dom'];
    case 'keyMaterial':
      return ['Brass', 'Nickel Silver', 'Steel', 'Aluminum', 'Titanium', 'Plastic'];
    case 'lockType':
      return ['Deadbolt', 'Padlock', 'Mortise', 'Euro Cylinder', 'Cam Lock', 'Cabinet Lock', 'Gate Lock', 'Sliding Door Lock'];
    case 'finish':
      return ['US3 Brass', 'US4 Chrome', 'US5 Nickel', 'US10B Oil Rubbed Bronze', 'US15 Satin Nickel', 'US19 Matte Black', 'US26 Dull Chrome', 'Polished Brass', 'Antique Brass'];
    case 'securityGrade':
      return ['ANSI Grade 1', 'ANSI Grade 2', 'ANSI Grade 3'];
    case 'vehicleMake':
      return ['Toyota', 'Honda', 'Ford', 'BMW', 'Mercedes', 'Audi', 'Volkswagen', 'Nissan', 'Hyundai', 'Kia', 'Lexus', 'Mazda', 'Subaru', 'Mitsubishi', 'Jeep', 'Chevrolet', 'Dodge', 'Chrysler', 'Volvo', 'Land Rover'];
    case 'transponderType':
      return ['4C (Philips)', '4D (Texas)', '8E (Temic)', '11 (T5)', '13 (T6)', '40 (Philips)', '44 (Philips)', '45 (Temic)', '46 (Philips)', '47 (Philips)'];
    case 'immobilizerSystem':
      return ['Denso', 'Siemens', 'Bosch', 'Mopar', 'VDO', 'NEC', 'Mitsubishi', 'Delphi'];
    case 'programmingMethod':
      return ['Onboard (OBD)', 'Zed-Bull', 'Autel', 'Xhorse', 'Smart Pro', 'MVP', 'SKP', 'Key Programmer'];
    case 'protocol':
      return ['Wiegand 26-bit', 'Wiegand 34-bit', 'OSDP', 'Bluetooth', 'WiFi', 'Z-Wave', 'Zigbee', 'Mifare', 'iClass'];
    case 'connectionType':
      return ['Wired', 'Wireless', 'PoE', 'Bluetooth', 'WiFi'];
    case 'safeType':
      return ['Digital', 'Key', 'Fire', 'Depository', 'Wall Safe', 'Floor Safe', 'Gun Safe'];
    case 'fireRating':
      return ['30 min', '60 min', '90 min', '120 min', '180 min'];
    case 'lockMechanism':
      return ['Electronic', 'Mechanical', 'Dual (Electronic + Key)', 'Key Only'];
    case 'unitType':
      return ['Piece', 'Pack', 'Meter', 'Bag', 'Box', 'Set', 'Roll'];
    case 'material':
      return ['Brass', 'Steel', 'Nickel Silver', 'Aluminum', 'Titanium', 'Plastic', 'Nylon', 'Rubber', 'Stainless Steel'];
    case 'backset':
      return ['2-3/8"', '2-3/4"', '2-7/8"', '3"', '3-1/8"', '3-1/2"', '5"'];
    case 'boreSize':
      return ['54mm', '2-1/8"', '2-1/4"', '1-1/2"', '1-3/4"', '1"'];
    case 'voltage':
      return ['12V', '24V', '5V', '3.3V', '48V', '110V', '220V', '240V', '6V', '9V', '120V'];
    case 'supplier':
      return ['SKS Locksmith Supply', 'Clark Security', 'Anixter', 'IDN', 'Security Lock Distributors', 'All Lock', 'Keyless Entry', 'Locksmith Resource', 'Amazon', 'eBay', 'Grainger', 'McMaster-Carr'];
    default:
      return [];
  }
}

/// Returns autocomplete suggestions for combo-type fields.
List<String> suggestionsForField(String key) {
  switch (key) {
    case 'blankNumber':
      return ['SC1', 'SC4', 'KW1', 'Y1', 'Y159', 'SC9', 'KW10', 'Y152', 'SC17', 'SC21', 'WR3', 'WR5', 'M1', 'M2', 'D1', 'D4', 'C123', 'E1X', 'RA1', 'DA1'];
    case 'backset':
      return ['2-3/8"', '2-3/4"', '2-7/8"', '3"', '3-1/8"', '3-1/2"', '5"'];
    case 'boreSize':
      return ['54mm', '2-1/8"', '2-1/4"', '1-1/2"', '1-3/4"', '1"'];
    case 'voltage':
      return ['12V', '24V', '5V', '3.3V', '48V', '110V', '220V', '240V', '6V', '9V', '120V'];
    case 'supplier':
      return ['SKS Locksmith Supply', 'Clark Security', 'Anixter', 'IDN', 'Security Lock Distributors', 'All Lock', 'Keyless Entry', 'Locksmith Resource', 'Amazon', 'eBay', 'Grainger', 'McMaster-Carr'];
    case 'material':
      return ['Brass', 'Steel', 'Nickel Silver', 'Aluminum', 'Titanium', 'Plastic', 'Nylon', 'Rubber', 'Stainless Steel', 'Bronze', 'Copper', 'Zinc Alloy', 'Iron', 'Ceramic', 'Carbon Fiber'];
    default:
      return [];
  }
}

String hintForField(String key) {
  switch (key) {
    case 'blankNumber': return 'e.g. SC1, SC4, KW1';
    case 'transponderFrequency': return 'e.g. 315, 433';
    case 'backset': return 'e.g. 2-3/8"';
    case 'boreSize': return 'e.g. 54mm';
    case 'vehicleModels': return 'e.g. Corolla, Camry';
    case 'yearStart': return 'e.g. 2014';
    case 'yearEnd': return 'e.g. 2024';
    case 'voltage': return 'e.g. 12V, 24V';
    case 'maxUsers': return 'e.g. 2000';
    case 'weight': return 'e.g. 25 kg';
    case 'capacity': return 'e.g. 42 L';
    case 'unitsPerPack': return 'e.g. 10, 50, 100';
    case 'supplier': return 'e.g. SKS Supply';
    default: return '';
  }
}

class CategoryField {
  final String key;
  final String label;
  final FieldType type;
  final String? dependsOn;
  final IconData icon;

  const CategoryField({
    required this.key,
    required this.label,
    this.type = FieldType.text,
    this.dependsOn,
    this.icon = LineAwesomeIcons.tag_solid,
  });
}

List<CategoryField> fieldsForCategory(InventoryItemCategory cat) {
  switch (cat) {
    case InventoryItemCategory.key:
      return const [
        CategoryField(key: 'blankNumber', label: 'BLANK NUMBER', type: FieldType.select, icon: LineAwesomeIcons.hashtag_solid),
        CategoryField(key: 'keywayType', label: 'KEYWAY TYPE', type: FieldType.select, icon: LineAwesomeIcons.key_solid),
        CategoryField(key: 'hasTransponder', label: 'TRANSPONDER', type: FieldType.boolean, icon: LineAwesomeIcons.wifi_solid),
        CategoryField(key: 'transponderFrequency', label: 'FREQ (MHz)', type: FieldType.number, dependsOn: 'hasTransponder', icon: LineAwesomeIcons.signal_solid),
        CategoryField(key: 'keyMaterial', label: 'MATERIAL', type: FieldType.select, icon: LineAwesomeIcons.archive_solid),
      ];
    case InventoryItemCategory.lock:
      return const [
        CategoryField(key: 'lockType', label: 'LOCK TYPE', type: FieldType.select, icon: LineAwesomeIcons.lock_solid),
        CategoryField(key: 'finish', label: 'FINISH', type: FieldType.select, icon: LineAwesomeIcons.palette_solid),
        CategoryField(key: 'backset', label: 'BACKSET', type: FieldType.select, icon: LineAwesomeIcons.expand_arrows_alt_solid),
        CategoryField(key: 'boreSize', label: 'BORE SIZE', type: FieldType.select, icon: LineAwesomeIcons.expand_solid),
        CategoryField(key: 'securityGrade', label: 'SECURITY GRADE', type: FieldType.select, icon: LineAwesomeIcons.lock_solid),
        CategoryField(key: 'keyRetainable', label: 'KEY RETAINABLE', type: FieldType.boolean, icon: LineAwesomeIcons.key_solid),
      ];
    case InventoryItemCategory.automotive:
      return const [
        CategoryField(key: 'vehicleMake', label: 'VEHICLE MAKE', type: FieldType.select, icon: LineAwesomeIcons.cogs_solid),
        CategoryField(key: 'vehicleModels', label: 'COMPATIBLE MODELS', icon: LineAwesomeIcons.list_solid),
        CategoryField(key: 'yearStart', label: 'YEAR FROM', type: FieldType.integer, icon: LineAwesomeIcons.calendar_solid),
        CategoryField(key: 'yearEnd', label: 'YEAR TO', type: FieldType.integer, icon: LineAwesomeIcons.calendar_solid),
        CategoryField(key: 'transponderType', label: 'TRANSPONDER TYPE', type: FieldType.select, icon: LineAwesomeIcons.microchip_solid),
        CategoryField(key: 'immobilizerSystem', label: 'IMMOBILIZER', type: FieldType.select, icon: LineAwesomeIcons.lock_solid),
      ];
    case InventoryItemCategory.electronic:
      return const [
        CategoryField(key: 'protocol', label: 'PROTOCOL', type: FieldType.select, icon: LineAwesomeIcons.wifi_solid),
        CategoryField(key: 'voltage', label: 'VOLTAGE', type: FieldType.select, icon: LineAwesomeIcons.bolt_solid),
        CategoryField(key: 'connectionType', label: 'CONNECTION', type: FieldType.select, icon: LineAwesomeIcons.plug_solid),
        CategoryField(key: 'maxUsers', label: 'MAX USERS', type: FieldType.integer, icon: LineAwesomeIcons.users_solid),
      ];
    case InventoryItemCategory.safe:
      return const [
        CategoryField(key: 'safeType', label: 'SAFE TYPE', type: FieldType.select, icon: LineAwesomeIcons.lock_solid),
        CategoryField(key: 'fireRating', label: 'FIRE RATING', type: FieldType.select, icon: LineAwesomeIcons.fire_solid),
        CategoryField(key: 'lockMechanism', label: 'LOCK MECH', type: FieldType.select, icon: LineAwesomeIcons.cog_solid),
        CategoryField(key: 'weight', label: 'WEIGHT (kg)', type: FieldType.number, icon: LineAwesomeIcons.weight_solid),
        CategoryField(key: 'capacity', label: 'CAPACITY (L)', type: FieldType.number, icon: LineAwesomeIcons.expand_solid),
      ];
    case InventoryItemCategory.consumable:
      return const [
        CategoryField(key: 'material', label: 'MATERIAL', type: FieldType.select, icon: LineAwesomeIcons.archive_solid),
        CategoryField(key: 'unitType', label: 'UNIT TYPE', type: FieldType.select, icon: LineAwesomeIcons.box_solid),
        CategoryField(key: 'unitsPerPack', label: 'UNITS/PACK', type: FieldType.integer, icon: LineAwesomeIcons.cubes_solid),
        CategoryField(key: 'supplier', label: 'SUPPLIER', type: FieldType.select, icon: LineAwesomeIcons.truck_solid),
      ];
  }
}

class InventoryCategoryFields extends StatefulWidget {
  final InventoryItemCategory category;
  final Map<String, dynamic> attributes;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final StateSetter rebuild;

  const InventoryCategoryFields({
    super.key,
    required this.category,
    required this.attributes,
    required this.onChanged,
    required this.rebuild,
  });

  @override
  State<InventoryCategoryFields> createState() => _InventoryCategoryFieldsState();
}

class _InventoryCategoryFieldsState extends State<InventoryCategoryFields> {
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _controller(String key, String initialText) {
    return _controllers.putIfAbsent(key, () => TextEditingController(text: initialText));
  }

  @override
  void didUpdateWidget(covariant InventoryCategoryFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controllers that still exist in the new attributes
    for (final key in widget.attributes.keys) {
      final c = _controllers[key];
      if (c != null) {
        final newVal = widget.attributes[key]?.toString() ?? '';
        if (c.text != newVal) {
          c.text = newVal;
        }
      }
    }
    // Clear controllers for keys removed from attributes (e.g. category switch)
    for (final key in _controllers.keys.toList()) {
      if (!widget.attributes.containsKey(key)) {
        _controllers[key]?.text = '';
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _setAttr(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(widget.attributes);
    updated[key] = value;
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final fields = fieldsForCategory(widget.category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields.map((f) => _buildField(context, f)).toList(),
    );
  }

  Widget _buildField(BuildContext context, CategoryField field) {
    if (field.dependsOn != null) {
      final depValue = widget.attributes[field.dependsOn];
      if (depValue == null || depValue == false || depValue == '') {
        return const SizedBox.shrink();
      }
    }
    final value = widget.attributes[field.key];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: AppTextStyles.caption.copyWith(
            color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.0)),
          const SizedBox(height: 6),
          _buildInput(context, field, value),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context, CategoryField field, dynamic value) {
    switch (field.type) {
      case FieldType.boolean:
        return _buildBoolean(context, field, value ?? false);
      case FieldType.number:
        return _buildText(context, field, value?.toString() ?? '', isDecimal: true);
      case FieldType.integer:
        return _buildText(context, field, value?.toString() ?? '', isInteger: true);
      case FieldType.select:
        return _buildSelect(context, field, value as String? ?? '');
      case FieldType.text:
        return _buildText(context, field, value as String? ?? '');
    }
  }

  /// Text input with leading icon
  Widget _buildText(BuildContext context, CategoryField field, String value, {bool isDecimal = false, bool isInteger = false}) {
    final isNumber = isDecimal || isInteger;
    final isYearField = field.key == 'yearStart' || field.key == 'yearEnd';

    // Year fields use a tap → year picker approach
    // We pass ignorePointers so the readOnly TextField doesn't absorb the tap
    if (isYearField) {
      return GestureDetector(
        onTap: () => _showYearPicker(context, field, value),
        child: _buildTextContainer(context, field, value, isNumber: true, readOnly: true, isInteger: isInteger, isDecimal: isDecimal, ignorePointers: true),
      );
    }

    return _buildTextContainer(context, field, value, isNumber: isNumber, isInteger: isInteger, isDecimal: isDecimal);
  }

  /// Shared text field container with icon.
  /// [ignorePointers] wraps the TextField in [IgnorePointer] so the parent
  /// GestureDetector can receive taps (used for year picker fields).
  Widget _buildTextContainer(BuildContext context, CategoryField field, String value, {bool isNumber = false, bool readOnly = false, bool isInteger = false, bool isDecimal = false, bool ignorePointers = false}) {
    final textField = TextField(
      controller: _controller(field.key, value),
      readOnly: readOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: AppTextStyles.body.copyWith(color: context.ksc.white),
      cursorColor: context.ksc.accent500,
      decoration: InputDecoration(
        hintText: hintForField(field.key),
        hintStyle: AppTextStyles.body.copyWith(color: context.ksc.neutral500),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
      ),
      onChanged: readOnly
          ? null
          : (v) {
              if (isInteger) {
                _setAttr(field.key, int.tryParse(v) ?? 0);
              } else if (isDecimal) {
                _setAttr(field.key, double.tryParse(v) ?? 0);
              } else {
                _setAttr(field.key, v);
              }
            },
    );

    return Container(
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Row(
          children: [
            Icon(field.icon, color: context.ksc.neutral500, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: ignorePointers ? IgnorePointer(child: textField) : textField,
            ),
            if (readOnly)
              Icon(LineAwesomeIcons.calendar_solid, color: context.ksc.accent500, size: 14),
          ],
        ),
      ),
    );
  }

  void _showYearPicker(BuildContext context, CategoryField field, String currentValue) {
    final currentYear = int.tryParse(currentValue) ?? DateTime.now().year;
    showDialog(
      context: context,
      builder: (ctx) {
        int selectedYear = currentYear;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              backgroundColor: context.ksc.primary800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: context.ksc.primary700),
              ),
              title: Text(field.label, style: AppTextStyles.h2.copyWith(
                color: context.ksc.white, fontWeight: FontWeight.w900)),
              content: SizedBox(
                width: 200,
                height: 200,
                child: ListView.builder(
                  itemCount: 100,
                  itemBuilder: (context, index) {
                    final year = DateTime.now().year - 50 + index;
                    final isSelected = year == selectedYear;
                    return GestureDetector(
                      onTap: () => setInnerState(() => selectedYear = year),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? context.ksc.accent500.withValues(alpha: 0.10) : null,
                          border: Border(bottom: BorderSide(color: context.ksc.primary700)),
                        ),
                        child: Row(
                          children: [
                            Text('$year', style: AppTextStyles.body.copyWith(
                              color: isSelected ? context.ksc.accent500 : context.ksc.white,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700)),
                            if (isSelected) const Spacer(),
                            if (isSelected)
                              Icon(LineAwesomeIcons.check_solid, color: context.ksc.accent500, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('CANCEL', style: AppTextStyles.caption.copyWith(
                    color: context.ksc.neutral500, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _setAttr(field.key, selectedYear);
                    _controllers[field.key]?.text = selectedYear.toString();
                    widget.rebuild(() {});
                  },
                  child: Text('SELECT', style: AppTextStyles.caption.copyWith(
                    color: context.ksc.accent500, fontWeight: FontWeight.w800)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Boolean toggle with icon
  Widget _buildBoolean(BuildContext context, CategoryField field, bool value) {
    return GestureDetector(
      onTap: () {
        _setAttr(field.key, !value);
        widget.rebuild(() {});
      },
      child: Container(
        padding: const EdgeInsets.only(left: 14),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
        ),
        child: Row(
          children: [
            Icon(field.icon, color: context.ksc.neutral500, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value ? 'YES' : 'NO',
                style: AppTextStyles.body.copyWith(
                  color: value ? context.ksc.accent500 : context.ksc.neutral500,
                  fontWeight: FontWeight.w700)),
            ),
            Icon(value ? LineAwesomeIcons.toggle_on_solid : LineAwesomeIcons.toggle_off_solid,
              color: value ? context.ksc.accent500 : context.ksc.neutral500, size: 24),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, String fieldKey, String label, String currentValue, List<String> options) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((opt) {
                      final isSelected = opt == currentValue;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _setAttr(fieldKey, opt);
                          widget.rebuild(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? context.ksc.accent500.withValues(alpha: 0.10) : Colors.transparent,
                            border: Border(bottom: BorderSide(color: context.ksc.primary700)),
                          ),
                          child: Row(
                            children: [
                              Text(opt, style: AppTextStyles.body.copyWith(
                                color: isSelected ? context.ksc.accent500 : context.ksc.white,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              )),
                              const Spacer(),
                              if (isSelected)
                                Icon(LineAwesomeIcons.check_solid, color: context.ksc.accent500, size: 16),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Select field — tapping opens a bottom sheet picker
  Widget _buildSelect(BuildContext context, CategoryField field, String value) {
    final options = optionsForField(field.key);
    return GestureDetector(
      onTap: () => _showPicker(context, field.key, field.label, value, options),
      child: Container(
        padding: const EdgeInsets.only(left: 14),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1.5)),
        ),
        child: Row(
          children: [
            Icon(field.icon, color: context.ksc.neutral500, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value.isNotEmpty ? value : 'Select ${field.label.toLowerCase()}...',
                style: AppTextStyles.body.copyWith(
                  color: value.isNotEmpty ? context.ksc.white : context.ksc.neutral500,
                  fontWeight: FontWeight.w700)),
            ),
            Icon(LineAwesomeIcons.angle_down_solid, color: context.ksc.neutral500, size: 14),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}
