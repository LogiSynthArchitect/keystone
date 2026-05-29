import '../../../../core/utils/forward_compatible.dart';

class TemplatePartItem {
  static const _kKnown = {'id', 'name', 'quantity', 'unit_price', 'inventory_item_id'};

  final String id;
  final String name;
  final int quantity;
  final int? unitPrice; // in pesewas, snapshot at save time
  final String? inventoryItemId; // optional link back to inventory
  final Map<String, dynamic> preserved;

  const TemplatePartItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.unitPrice,
    this.inventoryItemId,
    this.preserved = const {},
  });

  Map<String, dynamic> toJson() {
    final fields = <String, dynamic>{
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'inventory_item_id': inventoryItemId,
    };
    return ForwardCompatible.buildJson(preserved, fields);
  }

  factory TemplatePartItem.fromJson(Map<String, dynamic> json) =>
      TemplatePartItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 1,
        unitPrice: json['unit_price'] as int?,
        inventoryItemId: json['inventory_item_id'] as String?,
        preserved: ForwardCompatible.extractPreserved(json, _kKnown),
      );

  TemplatePartItem copyWith({
    String? id,
    String? name,
    int? quantity,
    int? unitPrice,
    String? inventoryItemId,
    Map<String, dynamic>? preserved,
  }) =>
      TemplatePartItem(
        id: id ?? this.id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        inventoryItemId: inventoryItemId ?? this.inventoryItemId,
        preserved: preserved ?? this.preserved,
      );
}
