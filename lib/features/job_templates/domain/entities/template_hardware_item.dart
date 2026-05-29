import '../../../../core/utils/forward_compatible.dart';

class TemplateHardwareItem {
  static const _kKnown = {'id', 'name', 'quantity', 'unit_sale_price', 'inventory_item_id'};

  final String id;
  final String name;
  final int quantity;
  final int? unitSalePrice; // in pesewas, snapshot at save time
  final String? inventoryItemId; // optional link back to inventory
  final Map<String, dynamic> preserved;

  const TemplateHardwareItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.unitSalePrice,
    this.inventoryItemId,
    this.preserved = const {},
  });

  Map<String, dynamic> toJson() {
    final fields = <String, dynamic>{
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit_sale_price': unitSalePrice,
      'inventory_item_id': inventoryItemId,
    };
    return ForwardCompatible.buildJson(preserved, fields);
  }

  factory TemplateHardwareItem.fromJson(Map<String, dynamic> json) =>
      TemplateHardwareItem(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 1,
        unitSalePrice: json['unit_sale_price'] as int?,
        inventoryItemId: json['inventory_item_id'] as String?,
        preserved: ForwardCompatible.extractPreserved(json, _kKnown),
      );

  TemplateHardwareItem copyWith({
    String? id,
    String? name,
    int? quantity,
    int? unitSalePrice,
    String? inventoryItemId,
    Map<String, dynamic>? preserved,
  }) =>
      TemplateHardwareItem(
        id: id ?? this.id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unitSalePrice: unitSalePrice ?? this.unitSalePrice,
        inventoryItemId: inventoryItemId ?? this.inventoryItemId,
        preserved: preserved ?? this.preserved,
      );
}
